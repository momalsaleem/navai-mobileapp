import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/services/route_tts_observer.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/services/microphone_manager.dart';
import 'package:android_intent_plus/android_intent.dart';

export 'package:nav_aif_fyp/utils/lang.dart';

class NavAILanguagePage extends StatelessWidget {
  const NavAILanguagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const LanguageSelectionScreen();
  }
}

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen>
    with RouteAwareTtsStopper {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  String selectedLanguage = "";
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isNavigating = false;
  String _statusMessage = 'Initializing...';
  bool _pageHasSpoken = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeLanguagePage();
    });
  }

  Future<void> _initializeLanguagePage() async {
    await _clearAllSpeechAndTts();

    if (mounted) {
      setState(() {
        selectedLanguage = "";
        _isListening = false;
        _isSpeaking = false;
        _isNavigating = false;
        _pageHasSpoken = false;
        _statusMessage = 'Initializing...';
      });
    }

    try {
      setState(() => _statusMessage = 'Initializing voice system...');

      await _initTTS();

      setState(() {
        _isSpeaking = true;
        _statusMessage = 'Reading language selection...';
      });

      await Future.delayed(const Duration(milliseconds: 300));
      await _speakBilingualIntroduction();

      _pageHasSpoken = true;

      setState(() {
        _isSpeaking = false;
        _statusMessage = 'Listening... Say "English" or "Urdu" to select';
      });

      try {
        await _speech.stop();
        await _speech.cancel();
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 200));

      await _startListening();
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Please select your language.');
      }
    }
  }

  Future<void> _clearAllSpeechAndTts() async {
    try {
      await _speech.stop();
      await _speech.cancel();
      await _speech.initialize(); // Re-initialize to clear state
    } catch (e) {}

    try {
      await flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      await flutterTts.speak("");
      await flutterTts.stop();
    } catch (e) {}
  }

  Future<void> _initTTS() async {
    try {
      await flutterTts.setLanguage('en-US');
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.awaitSpeakCompletion(true);

      flutterTts.setStartHandler(() {
        if (mounted) setState(() => _isSpeaking = true);
      });

      flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      flutterTts.setErrorHandler((message) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> _speakBilingualIntroduction() async {
    try {
      await flutterTts.stop();
      await Future.delayed(const Duration(milliseconds: 200));

      await flutterTts.setLanguage('en-US');
      await flutterTts.speak('Welcome to language selection. '
          'Please select your preferred language. '
          'Say English for English interface, or Urdu for Urdu interface. '
          'You can also tap the language buttons on screen.');
      await flutterTts.awaitSpeakCompletion(true);

      await Future.delayed(const Duration(milliseconds: 800));

      try {
        await flutterTts.setLanguage('ur-PK');
        await flutterTts.speak('زبان کی منتخب میں خوش آمدید۔ '
            'براہ کرم اپنی پسندیدہ زبان منتخب کریں۔ '
            'انگریزی انٹرفیس کے لیے انگلش کہیں، یا اردو انٹرفیس کے لیے اردو کہیں۔ '
            'آپ سکرین پر زبان کے بٹنز پر ٹیپ بھی کر سکتے ہیں۔');
        await flutterTts.awaitSpeakCompletion(true);
      } catch (e) {}
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _startListening() async {
    if (selectedLanguage.isNotEmpty || _isNavigating) {
      return;
    }

    bool hasPerm = await MicrophoneManager.hasPermission();
    if (!hasPerm) {
      // Speak guidance in English (default for setup)
      await flutterTts.setLanguage('en-US');
      await flutterTts.speak(
          "To hear you, we need microphone access. Please double tap Allow when the permission dialog appears.");
      await flutterTts.awaitSpeakCompletion(true);
    }

    bool micReady = await MicrophoneManager.initializeMicrophone(
      speech: _speech,
      context: context,
      onStatusUpdate: (message) {
        if (mounted) {
          setState(() => _statusMessage = message);
        }
      },
      isUrdu: false, // Language page is bilingual
    );

    if (!micReady) {
      if (mounted) setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == "done" &&
            !_isListening &&
            mounted &&
            !_isNavigating &&
            selectedLanguage.isEmpty) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isNavigating && selectedLanguage.isEmpty) {
              _startListening();
            }
          });
        }
      },
      onError: (val) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusMessage = 'Retrying...';
          });

          if (!_isNavigating && selectedLanguage.isEmpty) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && !_isNavigating && selectedLanguage.isEmpty) {
                _startListening();
              }
            });
          }
        }
      },
    );

    if (available && !_isNavigating && selectedLanguage.isEmpty) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _statusMessage = 'Listening... Say "English" or "Urdu" to select';
        });
      }

      await _speech.listen(
        // Rely on system default or auto-detect

        onResult: (result) {
          if (result.finalResult) {
            String recognized = result.recognizedWords.toLowerCase().trim();

            if (recognized.isNotEmpty) {
              _processCommand(recognized);
            }
          }
        },

        partialResults: false,
      );
    } else if (!available) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = 'Please select language using buttons.';
        });
      }
    }
  }

  void _processCommand(String recognized) async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);

    if (recognized.contains('english') ||
        recognized.contains('inglish') ||
        recognized.contains('انگریزی') ||
        recognized == 'en' ||
        recognized == 'angrezi' ||
        recognized.contains('angrezi') ||
        recognized == 'انگلش') {
      await _selectLanguageAndNavigate("English");
      return;
    } else if (recognized.contains('urdu') ||
        recognized.contains('اردو') ||
        recognized == 'urdu' ||
        recognized.contains('ordo') ||
        recognized.contains('urdo') ||
        recognized.contains('aurdo') ||
        recognized.contains('اردو زبان') ||
        recognized.contains('urdu language')) {
      await _selectLanguageAndNavigate("Urdu");
      return;
    }

    await _askToRepeat();
  }

  Future<void> _askToRepeat() async {
    if (mounted) {
      setState(() => _statusMessage = 'Please say "English" or "Urdu"');
    }

    HapticFeedback.vibrate();

    await flutterTts.setLanguage('en-US');
    await flutterTts.speak(
        "I didn't understand. Please say: English or Urdu to select your language.");
    await flutterTts.awaitSpeakCompletion(true);

    if (mounted && !_isNavigating && selectedLanguage.isEmpty) {
      await _startListening();
    }
  }

  Future<void> _selectLanguageAndNavigate(String language) async {
    if (_isNavigating) {
      return;
    }

    _isNavigating = true;
    await _speech.stop();

    if (mounted) {
      setState(() {
        _isListening = false;
        selectedLanguage = language;
        _statusMessage = '$language selected. Checking...';
      });
    }

    HapticFeedback.mediumImpact();

    if (language == "Urdu") {
      final isUrduAvailable = await _checkUrduAvailability();

      if (!isUrduAvailable) {
        await _handleMissingUrdu();
        return; // Stop here, user needs to install Urdu
      }
    }

    if (language == "Urdu") {
      await Lang.setLanguage('ur');
      await PreferencesManager.setLanguage('ur');
    } else {
      await Lang.setLanguage('en');
      await PreferencesManager.setLanguage('en');
    }

    if (mounted) {
      setState(() {
        _statusMessage = '$language selected. Redirecting...';
      });
    }

    await _speakSelectionConfirmation(language);

    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _speakSelectionConfirmation(String language) async {
    if (language == "Urdu") {
      try {
        await flutterTts.setLanguage('ur-PK');
        await flutterTts.speak(
            'آپ نے اردو زبان کا انٹرفیس منتخب کیا۔ شکریہ۔ اب آپ کو ڈیش بورڈ پر منتقل کیا جا رہا ہے۔');
        await flutterTts.awaitSpeakCompletion(true);
      } catch (e) {}
    } else {
      await flutterTts.setLanguage('en-US');
      await flutterTts.speak(
          "You selected English language interface. Thank you. Now redirecting you to the dashboard.");
      await flutterTts.awaitSpeakCompletion(true);
    }
  }

  Future<bool> _checkUrduAvailability() async {
    try {
      final isAvailable = await flutterTts.isLanguageAvailable("ur-PK");
      return isAvailable == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _handleMissingUrdu() async {
    if (mounted) {
      setState(() {
        _statusMessage = 'Urdu voice not installed. Opening settings...';
        _isNavigating = false; // Reset navigation flag
        selectedLanguage = ""; // Reset selection
      });
    }

    await flutterTts.setLanguage('en-US');
    await flutterTts.speak('Urdu voice is not installed on your device. '
        'Opening installation screen. '
        'Please tap install next to Urdu, then return to the app and select Urdu again.');
    await flutterTts.awaitSpeakCompletion(true);

    try {
      final intent = AndroidIntent(
        action: 'android.speech.tts.engine.INSTALL_TTS_DATA',
      );
      await intent.launch();
    } catch (e) {
      try {
        final settingsIntent = AndroidIntent(
          action: 'com.android.settings.TTS_SETTINGS',
        );
        await settingsIntent.launch();
      } catch (e2) {
        // Show error message
        if (mounted) {
          setState(() {
            _statusMessage = 'Please install Urdu voice from device settings';
          });
        }
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted && !_isNavigating && selectedLanguage.isEmpty) {
      await _startListening();
    }
  }

  Future<void> _onLanguageSelected(String language) async {
    if (_isNavigating) return;

    try {
      await _speech.stop();
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isListening = false;
        selectedLanguage = language;
      });
    }

    await _selectLanguageAndNavigate(language);
  }

  Widget _buildLanguageOption(String language) {
    final bool isSelected = selectedLanguage == language;
    final bool isDisabled =
        _isNavigating || (selectedLanguage.isNotEmpty && !isSelected);

    return GestureDetector(
      onTap: isDisabled ? null : () => _onLanguageSelected(language),
      child: Opacity(
        opacity: isDisabled ? 0.5 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1349EC).withAlpha((0.2 * 255).round())
                : Colors.white.withAlpha((0.05 * 255).round()),
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: const Color(0xFF1349EC), width: 2)
                : Border.all(
                    color: Colors.white.withAlpha((0.1 * 255).round()),
                    width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                language,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDisabled
                      ? Colors.white.withAlpha((0.5 * 255).round())
                      : Colors.white,
                ),
              ),
              Radio<String>(
                value: language,
                groupValue: selectedLanguage,
                onChanged: isDisabled
                    ? null
                    : (value) {
                        if (value != null) _onLanguageSelected(value);
                      },
                activeColor: const Color(0xFF1349EC),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  Expanded(
                    child: Text(
                      'Language Selection',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 30),
                      child: Column(
                        children: [
                          Text(
                            'Select Your Language',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'اپنی زبان منتخب کریں',
                            style: TextStyle(
                              fontSize: 18,
                              color:
                                  Colors.white.withAlpha((0.7 * 255).round()),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      children: [
                        _buildLanguageOption("Urdu"),
                        const SizedBox(height: 16),
                        _buildLanguageOption("English"),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // Loading indicator when initializing
                    if (_statusMessage.contains('Initializing') ||
                        _statusMessage.contains('Reading'))
                      Column(
                        children: [
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF2563eb)),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _statusMessage,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9DA4B9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),

                    // Status indicators
                    if (_isSpeaking)
                      _buildStatusIndicator(
                        icon: Icons.volume_up,
                        text: 'Speaking language options...',
                        color: Colors.blue,
                      ),

                    if (_isListening)
                      _buildStatusIndicator(
                        icon: Icons.mic,
                        text: 'Listening for your choice...',
                        color: Colors.green,
                      ),

                    if (!_isSpeaking &&
                        !_isListening &&
                        selectedLanguage.isEmpty &&
                        _pageHasSpoken)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Column(
                          children: [
                            Text(
                              _statusMessage,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF9DA4B9),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Say "English" or "Urdu"',
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    Colors.white.withAlpha((0.6 * 255).round()),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),

                    if (selectedLanguage.isNotEmpty)
                      Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStatusIndicator(
                            icon: Icons.check_circle,
                            text: '$selectedLanguage selected. Redirecting...',
                            color: Colors.green,
                          ),
                          const SizedBox(height: 20),
                          const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1349EC)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color.withAlpha((0.9 * 255).round())),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: color.withAlpha((0.9 * 255).round()),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // print('♻️ Disposing LanguageSelectionScreen');
    try {
      VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      flutterTts.stop();
    } catch (_) {}
    super.dispose();
  }

  @override
  Future<void> stopTtsAndListening() async {
    // print('⏹ Stopping TTS and listening in language page');
    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await flutterTts.stop();
    } catch (_) {}
  }

  // Remove duplicate @override and fix async callback for didPush
  @override
  void didPush() {
    // print('📱 Language page pushed - clearing previous audio');
    super.didPush();

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _clearAllSpeechAndTts();
        if (mounted) {
          setState(() {
            selectedLanguage = "";
            _isListening = false;
            _isSpeaking = false;
            _pageHasSpoken = false;
          });
        }
      });
    }
  }
}
