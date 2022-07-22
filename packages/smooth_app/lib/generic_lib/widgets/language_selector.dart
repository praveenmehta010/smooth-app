import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart'
    show AppLocalizations;
import 'package:openfoodfacts/utils/LanguageHelper.dart';
import 'package:smooth_app/data_models/user_preferences.dart';
import 'package:smooth_app/generic_lib/dialogs/smooth_alert_dialog.dart';
import 'package:smooth_app/pages/preferences/user_preferences_languages_list.dart';

class LanguageSelectorSettings extends StatelessWidget {
  const LanguageSelectorSettings({
    required this.userPreferences,
    required this.appLocalizations,
  });

  final UserPreferences userPreferences;
  final AppLocalizations appLocalizations;

  static final Languages _languages = Languages();

  @override
  Widget build(BuildContext context) {
    // The languages that are supported by flutter widget
    final String currentLanguageCode = userPreferences.appLanguageCode ??
        Localizations.localeOf(context).toString();
    final String nameInLanguage =
        _languages.getLanguageNameInEnglishFromOpenFoodFactsLanguage(
            LanguageHelper.fromJson(currentLanguageCode));
    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(
        appLocalizations.choose_app_language,
      ),
      subtitle: Text(
        '$nameInLanguage ($currentLanguageCode)',
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      onTap: () async {
        final List<OpenFoodFactsLanguage> leftovers =
            _languages.getSupportedLanguagesNameInEnglish();
        leftovers.sort((OpenFoodFactsLanguage a, OpenFoodFactsLanguage b) =>
            _languages
                .getLanguageNameInEnglishFromOpenFoodFactsLanguage(a)
                .compareTo(_languages
                    .getLanguageNameInEnglishFromOpenFoodFactsLanguage(b)));
        List<OpenFoodFactsLanguage> filteredList = leftovers;
        await showDialog<void>(
            context: context,
            builder: (BuildContext context) {
              return StatefulBuilder(
                builder: (BuildContext context,
                    void Function(VoidCallback fn) setState) {
                  return SmoothAlertDialog(
                    body: Column(
                      children: <Widget>[
                        TextField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            enabledBorder: const UnderlineInputBorder(),
                            labelText: appLocalizations.search,
                          ),
                          onChanged: (String query) {
                            setState(
                              () {
                                filteredList = leftovers
                                    .where((OpenFoodFactsLanguage item) =>
                                        _languages
                                            .getLanguageNameInEnglishFromOpenFoodFactsLanguage(
                                                item)
                                            .toLowerCase()
                                            .contains(query.toLowerCase()) ||
                                        item.code.contains(query))
                                    .toList();
                              },
                            );
                          },
                        ),
                        ...List<ListTile>.generate(
                          filteredList.length,
                          (int index) {
                            final OpenFoodFactsLanguage openFoodFactsLanguage =
                                filteredList[index];
                            final String nameInLanguage = _languages
                                .getLanguageNameInLanguageFromOpenFoodFactsLanguage(
                                    openFoodFactsLanguage);
                            return ListTile(
                              title: Text(
                                '$nameInLanguage (${_languages.getLanguageNameInEnglishFromOpenFoodFactsLanguage(openFoodFactsLanguage)})',
                                softWrap: false,
                                overflow: TextOverflow.fade,
                              ),
                              onTap: () {
                                userPreferences.setAppLanguageCode(
                                    openFoodFactsLanguage.code);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    positiveAction: SmoothActionButton(
                      onPressed: () => Navigator.pop(context),
                      text: appLocalizations.cancel,
                    ),
                  );
                },
              );
            });
      },
    );
  }
}