import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    await _initTTS();
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await VoiceManager.safeSpeak(_tts, Lang.t('privacy_title'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
      await _startListening();
    }
  }

  Future<void> _initTTS() async {
    if (Lang.isUrdu) {
      try {
        await _tts.setLanguage('ur-PK');
      } catch (_) {
        await _tts.setLanguage('en-US');
      }
    } else {
      await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.5);
  }

  Future<void> _startListening() async {
    final available = await VoiceManager.safeInitializeSpeech(
      _speech,
      onStatus: (val) {
        if (val == "done" && !_isListening) {
          _startListening();
        }
      },
      onError: (val) {
        setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() => _isListening = true);
      await VoiceManager.safeListen(
        _speech,
        localeId: Lang.speechLocaleId,
        onResult: (result) {
          final recognized =
              (result.recognizedWords ?? '').toString().toLowerCase().trim();
          if (recognized.isNotEmpty) {
            _processCommand(recognized);
          }
        },
      );
    } else {
      setState(() => _isListening = false);
    }
  }

  Future<void> _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await VoiceManager.safeSpeak(_tts, Lang.t('please_repeat'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
      await _startListening();
    }
  }

  Future<void> _processCommand(String recognized) async {
    bool matched = false;
    if (recognized.contains('location') || recognized.contains('لوکیشن')) {
      matched = true;
      await VoiceManager.safeSpeak(_tts, Lang.t('location_services'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
    } else if (recognized.contains('security') ||
        recognized.contains('سیکیورٹی')) {
      matched = true;
      await VoiceManager.safeSpeak(_tts, Lang.t('data_security'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
    } else if (recognized.contains('sharing') || recognized.contains('شیئر')) {
      matched = true;
      await VoiceManager.safeSpeak(_tts, Lang.t('data_sharing'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
    } else if (recognized.contains('delete') || recognized.contains('حذف')) {
      matched = true;
      await VoiceManager.safeSpeak(_tts, Lang.t('delete_data'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
    } else if (recognized.contains('policy') || recognized.contains('پالیسی')) {
      matched = true;
      await VoiceManager.safeSpeak(_tts, Lang.t('privacy_policy'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
    }
    if (!matched && recognized.length > 2) {
      await _askToRepeat();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(Lang.t('privacy_title')),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _privacyCard(
            icon: Icons.location_on,
            title: Lang.t('location_services'),
            subtitle: Lang.t('location_services_desc'),
            onTap: () {
              _speakIfEnabled(Lang.t('location_services'));
            },
          ),
          _privacyCard(
            icon: Icons.security,
            title: Lang.t('data_security'),
            subtitle: Lang.t('data_security_desc'),
            onTap: () {
              _speakIfEnabled(Lang.t('data_security'));
            },
          ),
          _privacyCard(
            icon: Icons.share,
            title: Lang.t('data_sharing'),
            subtitle: Lang.t('data_sharing_desc'),
            onTap: () {
              _speakIfEnabled(Lang.t('data_sharing'));
            },
          ),
          _privacyCard(
            icon: Icons.delete,
            title: Lang.t('delete_data'),
            subtitle: Lang.t('delete_data_desc'),
            onTap: () {
              _speakIfEnabled(Lang.t('delete_data'));
            },
          ),
          _privacyCard(
            icon: Icons.privacy_tip,
            title: Lang.t('privacy_policy'),
            subtitle: Lang.t('privacy_policy_desc'),
            onTap: () {
              _speakIfEnabled(Lang.t('privacy_policy'));
            },
          ),
        ],
      ),
    );
  }

  Widget _privacyCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 13), // 0.05 * 255 ≈ 13
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb)
                    .withValues(alpha: 64), // 0.25 * 255 ≈ 64
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2563eb)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white
                          .withValues(alpha: 153), // 0.6 * 255 ≈ 153
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _speakIfEnabled(String text) async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _initTTS();
      await VoiceManager.safeSpeak(_tts, text);
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
    }
  }

  @override
  void dispose() {
    VoiceManager.safeStopListening(_speech);
    _tts.stop();
    super.dispose();
  }
}
