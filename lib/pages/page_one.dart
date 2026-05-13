import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/page_two.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/services/route_tts_observer.dart';

class NameInputPage extends StatefulWidget {
  const NameInputPage({super.key});

  @override
  State<NameInputPage> createState() => _NameInputPageState();
}

class _NameInputPageState extends State<NameInputPage>
    with RouteAwareTtsStopper {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final TextEditingController _nameController = TextEditingController();
  bool _isListening = false;

  String get _instructionText => Lang.t('name_question');

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    await _initTTS();

    if (isVoiceModeEnabled) {
      await _speakInstruction();
      await _startListening();
    }
  }

  Future<void> _initTTS() async {
    final locale = Lang.speechLocaleId;
    try {
      await _tts.setLanguage(locale);
    } catch (_) {
      await _tts.setLanguage('en-US');
    }
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
  }

  Future<void> _speakInstruction() async {
    await VoiceManager.safeSpeak(_tts, _instructionText);
    await VoiceManager.safeAwaitSpeakCompletion(_tts);
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
        debugPrint('Speech Error: $val');
        setState(() => _isListening = false);
      },
    );

    if (available) {
      setState(() => _isListening = true);
      await VoiceManager.safeListen(
        _speech,
        localeId: Lang.speechLocaleId,
        onResult: (result) {
          String recognized =
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

  void _processCommand(String recognized) async {
    debugPrint("🎙 Name Input Recognized: $recognized");

    if (recognized.isNotEmpty &&
        !recognized.contains('continue') &&
        !recognized.contains('next') &&
        recognized.length > 1) {
      await VoiceManager.safeStopListening(_speech);
      setState(() {
        _isListening = false;
        _nameController.text = recognized;
      });

      final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
      if (isVoiceModeEnabled) {
        await _initTTS();
        await VoiceManager.safeSpeak(
            _tts, 'Hello $recognized. ${Lang.t('continue')}.');
        await VoiceManager.safeAwaitSpeakCompletion(_tts);
      }

      Future.delayed(const Duration(milliseconds: 500), () {
        _navigateToNext();
      });
    } else if (recognized.isNotEmpty && recognized.length > 2) {
      await _askToRepeat();
    }
  }

  Future<void> _askToRepeat() async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (isVoiceModeEnabled) {
      await _initTTS();
      await VoiceManager.safeSpeak(_tts, Lang.t('please_repeat'));
      await VoiceManager.safeAwaitSpeakCompletion(_tts);
    }
  }

  Future<void> _navigateToNext() async {
    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}

    if (mounted) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const UseLocationPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    VoiceManager.safeStopListening(_speech);
    try {
      _tts.stop();
    } catch (_) {}
    _nameController.dispose();
    super.dispose();
  }

  @override
  Future<void> stopTtsAndListening() async {
    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          size: 28,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        Lang.t('navai'),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    _instructionText,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Stack(
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: Lang.t('your_name'),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF9DA4B9),
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: Color(0xFF1349EC),
                              width: 2,
                            ),
                          ),
                        ),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: 0,
                        bottom: 0,
                        child: IconButton(
                          onPressed: () {
                            if (_isListening) {
                              _speech.stop();
                              setState(() => _isListening = false);
                            } else {
                              _startListening();
                            }
                          },
                          icon: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: _isListening
                                ? Colors.red
                                : const Color(0xFF9DA4B9),
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isListening)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.red, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.mic, size: 16, color: Colors.red[300]),
                          const SizedBox(width: 8),
                          Text(
                            'Listening for your name...',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[300],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1349EC),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    onPressed: () {
                      _navigateToNext();
                    },
                    child: Text(
                      Lang.t('save_continue'),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
