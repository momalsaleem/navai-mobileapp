import 'package:shared_preferences/shared_preferences.dart';

/// Centralized service for managing app preferences
/// Handles voice mode and language preferences persistence
class PreferencesManager {
  static const String _keyVoiceModeEnabled = 'voice_mode_enabled';
  static const String _keyLanguage = 'selected_language'; // 'en', 'ur', or 'bilingual'

  static SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  static Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Voice Mode Preferences
  static Future<bool> isVoiceModeEnabled() async {
    await init();
    return _prefs!.getBool(_keyVoiceModeEnabled) ?? false;
  }

  static Future<void> setVoiceModeEnabled(bool enabled) async {
    await init();
    await _prefs!.setBool(_keyVoiceModeEnabled, enabled);
  }

  /// Language Preferences
  static Future<String> getLanguage() async {
    await init();
    return _prefs!.getString(_keyLanguage) ?? 'en';
  }

  /// Check if language has been explicitly set by the user
  static Future<bool> hasLanguageConfigured() async {
    await init();
    return _prefs!.containsKey(_keyLanguage);
  }

  /// Accepts either short codes like 'en'/'ur' or locale IDs like 'en-US'/'ur-PK'.
  /// Internally stores normalized short codes ('en' or 'ur') for compatibility.
  static Future<void> setLanguage(String language) async {
    await init();
    final normalized = _normalizeLanguage(language);
    await _prefs!.setString(_keyLanguage, normalized);
  }

  /// Returns a speech locale identifier suitable for speech packages.
  /// e.g. returns 'en-US' for English and 'ur-PK' for Urdu.
  static Future<String> getSpeechLocale() async {
    final lang = await getLanguage();
    if (lang == 'ur') return 'ur-PK';
    return 'en-US';
  }

  static String _normalizeLanguage(String language) {
    final lower = language.toLowerCase();
    if (lower.contains('ur')) return 'ur';
    return 'en';
  }

  /// Clear all preferences (useful for testing or logout)
  static Future<void> clearAll() async {
    await init();
    await _prefs!.clear();
  }
}

