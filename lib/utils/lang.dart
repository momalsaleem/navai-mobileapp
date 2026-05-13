import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';

class Lang {
  static String _currentLanguage = 'en';
  static Map<String, String> _localizedStrings = {};


  static bool get isUrdu => _currentLanguage == 'ur';
  static bool get isInitialized => _localizedStrings.isNotEmpty;


  static String get speechLocaleId => _currentLanguage == 'ur' ? 'ur_PK' : 'en_US';


  static Future<void> init() async {
    final saved = await PreferencesManager.getLanguage();
    await loadLanguage(saved);
  }


  static Future<void> loadLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    final String jsonString =
        await rootBundle.loadString('assets/langs/$languageCode.json');
    Map<String, dynamic> jsonMap;
    try {
      jsonMap = json.decode(jsonString);
    } catch (e) {
      // Attempt a tolerant parse.

      String cleaned = jsonString
          .replaceAll(RegExp(r'/\*.*?\*/', dotAll: true), '')
          .replaceAll(RegExp(r'//.*'), '')
          .replaceAll(RegExp(r',\s*([}\]])'), r'$1');
      try {
        jsonMap = json.decode(cleaned);
      } catch (e2) {


        _localizedStrings = {};
        return;
      }
    }

    _localizedStrings = jsonMap.map((key, value) => MapEntry(key, value.toString()));
  }


  static Future<void> setLanguage(String languageCode) async {
    await PreferencesManager.setLanguage(languageCode);
    await loadLanguage(languageCode);
  }


  static String t(String key) {
    return _localizedStrings[key] ?? key;
  }
}
