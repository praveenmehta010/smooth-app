import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:openfoodfacts/model/Product.dart';
import 'package:openfoodfacts/personalized_search/matched_product.dart';
import 'package:provider/provider.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_error.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_found.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_loading.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_not_found.dart';
import 'package:smooth_app/cards/product_cards/smooth_product_card_thanks.dart';
import 'package:smooth_app/data_models/continuous_scan_model.dart';
import 'package:smooth_app/data_models/product_preferences.dart';
import 'package:smooth_app/data_models/smooth_it_model.dart';
import 'package:smooth_app/pages/personalized_ranking_page.dart';
import 'package:smooth_app/pages/scan/search_page.dart';
import 'package:smooth_app/themes/smooth_theme.dart';

class SmoothProductCarousel extends StatefulWidget {
  const SmoothProductCarousel({
    this.showSearchCard = false,
    required this.height,
  });

  final bool showSearchCard;
  final double height;

  @override
  State<SmoothProductCarousel> createState() => _SmoothProductCarouselState();
}

class _SmoothProductCarouselState extends State<SmoothProductCarousel> {
  final CarouselController _controller = CarouselController();
  List<String> barcodes = <String>[];

  int get _searchCardAdjustment => widget.showSearchCard ? 1 : 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ContinuousScanModel model = context.watch<ContinuousScanModel>();
    setState(() {
      barcodes = model.getBarcodes();
    });
    _controller.animateToPage(barcodes.length - 1 + _searchCardAdjustment);
  }

  @override
  Widget build(BuildContext context) {
    return CarouselSlider.builder(
      itemCount: barcodes.length + _searchCardAdjustment,
      itemBuilder: (BuildContext context, int itemIndex, int itemRealIndex) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: widget.showSearchCard && itemIndex == 0
              ? SearchCard()
              : Center(
                  child: SizedBox(
                    height: 170.0,
                    child: _getWidget(itemIndex - _searchCardAdjustment),
                  ),
                ),
        );
      },
      carouselController: _controller,
      options: CarouselOptions(
        enlargeCenterPage: false,
        viewportFraction: 0.95,
        height: widget.height,
        enableInfiniteScroll: false,
      ),
    );
  }

  /// Displays the card for this [index] of a list of [barcodes]
  ///
  /// There are special cases when the item display is refreshed
  /// after the product disappeared and before the whole carousel is refreshed.
  /// In those cases, we don't want the app to crash and display a Container
  /// instead in the meanwhile.
  Widget _getWidget(final int index) {
    if (index >= barcodes.length) {
      return Container();
    }
    final String barcode = barcodes[index];
    final ContinuousScanModel model = context.watch<ContinuousScanModel>();
    final ProductPreferences productPreferences =
        context.watch<ProductPreferences>();
    switch (model.getBarcodeState(barcode)!) {
      case ScannedProductState.FOUND:
      case ScannedProductState.CACHED:
        final Product product = model.getProduct(barcode);
        final MatchedProduct matchedProduct =
            MatchedProduct(product, productPreferences);
        return SmoothProductCardFound(
          heroTag: barcode,
          product: product,
          backgroundColor: PersonalizedRankingPage.getColor(
            colorScheme: Theme.of(context).colorScheme,
            matchIndex: SmoothItModel.getMatchIndex(matchedProduct),
            colorDestination: ColorDestination.SURFACE_BACKGROUND,
          ),
        );
      case ScannedProductState.LOADING:
        return SmoothProductCardLoading(barcode: barcode);
      case ScannedProductState.NOT_FOUND:
        return SmoothProductCardNotFound(
          product: Product(barcode: barcode),
          callback: () =>
              model.setBarcodeState(barcode, ScannedProductState.THANKS),
        );
      case ScannedProductState.THANKS:
        return const SmoothProductCardThanks();
      case ScannedProductState.ERROR:
        return SmoothProductCardError(barcode: barcode);
    }
  }
}

class SearchCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final AppLocalizations localizations = AppLocalizations.of(context)!;
    return Card(
      color: Colors.white.withOpacity(0.95),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              localizations.welcomeToOpenFoodFacts,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 36.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              localizations.searchPanelHeader,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18.0),
            ),
            SearchField(
              onFocus: () => _openSearchPage(context),
              showClearButton: false,
            ),
          ],
        ),
      ),
    );
  }

  void _openSearchPage(BuildContext context) {
    Navigator.push<Widget>(
      context,
      MaterialPageRoute<Widget>(
        builder: (BuildContext context) => SearchPage(),
      ),
    );
  }
}
