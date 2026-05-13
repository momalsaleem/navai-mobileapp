import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/utils/voice_navigation_mixin.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/services/microphone_manager.dart';
import 'package:nav_aif_fyp/services/voice_command_parser.dart';

class GuidePage extends StatefulWidget {
  const GuidePage({Key? key}) : super(key: key);

  @override
  State<GuidePage> createState() => _GuidePageState();
}

class _GuidePageState extends State<GuidePage> with VoiceNavigationMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  String _lastCommand = '';
  bool _isGuideSpeaking = false;

  @override
  String get pageTitle => Lang.isUrdu ? 'گائیڈ' : 'Guide';

  List<Map<String, String>> get _instructions => Lang.isUrdu
      ? [
          {
            'title': 'تعارف',
            'desc':
                'Nav AI نابینا اور کمزور بصارت والے افراد کے لیے تیار کی گئی ایک ایپ ہے۔ یہ آپ کو راستہ تلاش کرنے، اشیا کی شناخت اور محفوظ راستے استعمال کرنے میں مدد دیتی ہے۔'
          },
          {
            'title': 'زبان منتخب کریں',
            'desc':
                'ایپ کی زبان منتخب کرنے کے لیے سیٹنگز میں جائیں۔ آپ اردو یا انگریزی منتخب کر سکتے ہیں۔'
          },
          {
            'title': 'ڈیش بورڈ',
            'desc':
                'ڈیش بورڈ پر چار اہم آپشنز ہیں: آبجیکٹ ڈیٹیکشن، نیویگیشن، محفوظ راستے، اور گائیڈ۔'
          },
          {
            'title': 'آبجیکٹ ڈیٹیکشن',
            'desc':
                'یہ فیچر کیمرہ استعمال کر کے آپ کے سامنے موجود اشیا کی شناخت کرتا ہے۔ آبجیکٹ ڈیٹیکشن آپشن منتخب کریں اور کیمرہ کو اشیا کی طرف کریں۔'
          },
          {
            'title': 'نیویگیشن',
            'desc':
                'نیویگیشن آپشن سے آپ منزل منتخب کر کے راستہ سن سکتے ہیں۔ منزل منتخب کریں اور ہدایات سنیں۔'
          },
          {
            'title': 'محفوظ راستے',
            'desc':
                'اگر آپ کسی راستے کو دوبارہ استعمال کرنا چاہتے ہیں تو اسے محفوظ کر لیں۔ محفوظ راستے آپشن سے اپنے محفوظ شدہ راستے دیکھیں اور استعمال کریں۔'
          },
          {
            'title': 'آواز کے ذریعے استعمال',
            'desc':
                'آپ ایپ کو آواز کے ذریعے بھی استعمال کر سکتے ہیں۔ آپشنز منتخب کرنے کے لیے بولیں یا ٹیپ کریں۔'
          },
          {
            'title': 'مدد',
            'desc':
                'اگر آپ کو کسی بھی وقت مدد چاہیے تو "گائیڈ" آپشن منتخب کریں۔'
          },
        ]
      : [
          {
            'title': 'Introduction',
            'desc':
                'Nav AI is developed and designed to support blind and visually impaired persons. It helps you find routes, detect objects, and use saved paths easily.'
          },
          {
            'title': 'Select Language',
            'desc':
                'Go to settings to choose your preferred app language. You can select English or Urdu.'
          },
          {
            'title': 'Dashboard',
            'desc':
                'The dashboard has four main options: Object Detection, Navigation, Saved Routes, and Guide.'
          },
          {
            'title': 'Object Detection',
            'desc':
                'This feature uses your camera to identify objects in front of you. Select Object Detection and point your camera towards objects.'
          },
          {
            'title': 'Navigation',
            'desc':
                'With Navigation, you can select a destination and get spoken directions. Choose your destination and listen to the instructions.'
          },
          {
            'title': 'Saved Routes',
            'desc':
                'Save any route for future use. Access your saved routes from the Saved Routes option and use them anytime.'
          },
          {
            'title': 'Voice Usage',
            'desc':
                'You can use the app by speaking commands or tapping options. Just say the option name or tap to select.'
          },
          {
            'title': 'Help',
            'desc':
                'If you need help at any time, select the Guide option for instructions.'
          },
        ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));

      startVoiceNavigation();
    });
  }

  Future<void> _initSpeech() async {
    try {
      await _speech.initialize();
      print('✅ Speech recognition initialized for GuidePage');
    } catch (e) {
      print('❌ Error initializing speech: $e');
    }
  }

  Future<void> _startListening() async {
    if (!mounted || _isListening) return;

    bool hasPerm = await MicrophoneManager.hasPermission();
    if (!hasPerm) {
      print('🎤 Permission missing - Providing voice guidance');
      await flutterTts.setLanguage(Lang.isUrdu ? 'ur-PK' : 'en-US');
      if (Lang.isUrdu) {
        await VoiceManager.safeSpeak(flutterTts,
            "ہمیں مائیکروفون کی اجازت درکار ہے۔ براہ کرم اجازت دیں بٹن پر ڈبل ٹیپ کریں۔");
      } else {
        await VoiceManager.safeSpeak(flutterTts,
            "To hear you, we need microphone access. Please double tap Allow when the permission dialog appears.");
      }
      await flutterTts.awaitSpeakCompletion(true);
    }

    try {
      bool micReady = await MicrophoneManager.initializeMicrophone(
        speech: _speech,
        context: context,
        onStatusUpdate: (message) {
          print('Mic Status: $message');
        },
        isUrdu: Lang.isUrdu,
      );

      if (micReady && mounted) {
        setState(() => _isListening = true);

        if (Lang.isUrdu) {
          await _speech.listen(
            onResult: _onSpeechResult,
            localeId: 'ur_PK',
            listenMode: stt.ListenMode.dictation,
            cancelOnError: true,
            partialResults: true,
          );
        } else {
          await _speech.listen(
            onResult: _onSpeechResult,
            localeId: 'en_US',
            listenMode: stt.ListenMode.dictation,
            cancelOnError: true,
            partialResults: true,
          );
        }

        print('🎤 Started listening for voice commands (continuous)');
      }
    } catch (e) {
      print('Error starting listening: $e');
      _restartListening();
    }
  }

  void _onSpeechResult(dynamic result) {
    if (!mounted) return;

    String transcript = '';
    try {
      transcript = result.recognizedWords ?? '';
    } catch (_) {
      transcript = result.toString();
    }

    transcript = transcript.trim().toLowerCase();

    if (transcript.isNotEmpty && transcript != _lastCommand) {
      print('🎤 Voice command detected: "$transcript"');
      _lastCommand = transcript;

      _processVoiceCommand(transcript);
    }
  }

  void _processVoiceCommand(String command) {
    print('🔄 Processing command: "$command"');

    bool shouldNavigate = VoiceCommandParser.isBackCommand(command);

    if (shouldNavigate) {
      print(
          '🚀 Navigation command detected: "$command" - IMMEDIATELY redirecting to Dashboard');

      _stopAllSpeechImmediately();

      _navigateToDashboardImmediately();
    } else {
      print('ℹ️ Command "$command" is not a navigation command');
    }
  }

  Future<void> _stopAllSpeechImmediately() async {
    try {
      _isGuideSpeaking = false;

      await flutterTts.stop();

      VoiceManager.safeStopListening(_speech);

      print('⏹️ Stopped all speech immediately');
    } catch (e) {
      print('❌ Error stopping speech: $e');
    }
  }

  void _navigateToDashboardImmediately() {
    if (!mounted) return;

    VoiceManager.safeStopListening(_speech);
    flutterTts.stop();
    _isGuideSpeaking = false;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => DashboardScreen(),
      ),
    );
  }

  void _restartListening() {
    if (!mounted) return;

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_isListening) {
        _startListening();
      }
    });
  }

  @override
  Future<void> speakPageEntry() async {
    if (!mounted) return;

    print(
        '🗣️ Guide: Starting guide reading in ${Lang.isUrdu ? "Urdu" : "English"}...');

    if (mounted) {
      setState(() {
        _isSpeaking = true;
        _isGuideSpeaking = true;
      });
    }

    try {
      await super.speakPageEntry();

      if (!mounted || !_isGuideSpeaking) {
        print('⚠️ Guide speaking interrupted after title');
        return;
      }

      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted || !_isGuideSpeaking) return;

      await _speakGuideIntroduction();
    } catch (e) {
      print('❌ Error in speakPageEntry: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSpeaking = false;
          _isGuideSpeaking = false;
        });
      }
    }
  }

  Future<void> _speakGuideIntroduction() async {
    try {
      await flutterTts.setLanguage(Lang.isUrdu ? 'ur-PK' : 'en-US');

      String fullGuide = '';

      if (Lang.isUrdu) {
        fullGuide = 'گائیڈ کے حصے: ';
        for (var instruction in _instructions) {
          if (!_isGuideSpeaking || !mounted) {
            print('⚠️ Guide speaking interrupted during Urdu section');
            return;
          }

          fullGuide += '${instruction['title']}۔ ${instruction['desc']}۔ ';
        }
        fullGuide +=
            'آپ کسی بھی وقت "واپس"، "گھر"، "ہوم"، یا "ڈیش بورڈ" کہہ کر واپس جا سکتے ہیں۔';
      } else {
        fullGuide = 'Guide sections: ';
        for (var instruction in _instructions) {
          if (!_isGuideSpeaking || !mounted) {
            print('⚠️ Guide speaking interrupted during English section');
            return;
          }

          fullGuide += '${instruction['title']}. ${instruction['desc']}. ';
        }
        fullGuide +=
            'You can say "Back", "Home", or "Dashboard" at any time to return.';
      }

      if (!_isGuideSpeaking || !mounted) {
        print('⚠️ Guide speaking interrupted before speaking final text');
        return;
      }

      print('📖 Speaking guide text (${fullGuide.length} chars)');

      await VoiceManager.safeSpeak(flutterTts, fullGuide);

      await flutterTts.awaitSpeakCompletion(true);

      print('✅ Guide reading complete - Mixin will now initialize mic');
    } catch (e) {
      print('❌ Guide: Error reading guide: $e');
    }
  }

  Future<void> _waitForTtsCompletionWithInterruptionCheck() async {
    try {
      final completer = Completer<void>();

      flutterTts.setCompletionHandler(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      await completer.future.timeout(const Duration(seconds: 60));
    } on TimeoutException {
      print('⚠️ Guide TTS timeout');
    } catch (e) {
      print('⚠️ Error waiting for TTS: $e');
    }
  }

  Future<void> _speakInstruction(int index) async {
    try {
      final instruction = _instructions[index];

      await flutterTts.stop();

      if (mounted) {
        setState(() {
          _isSpeaking = true;
        });
      }

      await flutterTts.setLanguage(Lang.isUrdu ? 'ur-PK' : 'en-US');

      await VoiceManager.safeSpeak(
          flutterTts, '${instruction['title']}. ${instruction['desc']}');

      await _waitForTtsCompletionWithInterruptionCheck();
    } catch (e) {
      print('❌ Error speaking instruction: $e');
    } finally {
      if (mounted) {
        setState(() => _isSpeaking = false);
      }

      _restartListening();
    }
  }

  Widget _buildCard(String title, String desc, int index) {
    return GestureDetector(
      onTap: () => _speakInstruction(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A202C),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF2563eb), width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb).withAlpha((0.25 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.info, color: Color(0xFF2563eb), size: 48),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withAlpha((0.7 * 255).round()),
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

  @override
  void dispose() {
    _isGuideSpeaking = false;
    VoiceManager.safeStopListening(_speech);
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF0d1b2a),
        elevation: 0.5,
        title: Text(
          Lang.isUrdu ? 'گائیڈ' : 'Guide',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _navigateToDashboardImmediately,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb).withAlpha((0.2 * 255).round()),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2563eb), width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isSpeaking ? Icons.volume_up : Icons.mic,
                        color: _isSpeaking
                            ? Colors.orange
                            : (_isListening
                                ? Colors.green
                                : const Color(0xFF2563eb)),
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isSpeaking
                              ? (Lang.isUrdu
                                  ? 'گائیڈ پڑھ رہا ہوں... "واپس" کہہ کر روکیں'
                                  : 'Reading guide... Say "Back" to stop')
                              : (_isListening
                                  ? (Lang.isUrdu
                                      ? 'آواز سن رہا ہوں۔ "واپس"، "گھر" یا "ڈیش بورڈ" کہیں'
                                      : 'Listening. Say "Back", "Home" or "Dashboard"')
                                  : (Lang.isUrdu
                                      ? 'ٹیپ کریں یا بولیں'
                                      : 'Tap or speak')),
                          style: TextStyle(
                            color: Colors.white.withAlpha((0.9 * 255).round()),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isSpeaking || _isListening)
                    LinearProgressIndicator(
                      backgroundColor: const Color(0xFF2563eb)
                          .withAlpha((0.1 * 255).round()),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        (_isSpeaking ? Colors.orange : Colors.green)
                            .withAlpha((0.8 * 255).round()),
                      ),
                      minHeight: 4,
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_instructions.length, (index) {
                    final item = _instructions[index];
                    return _buildCard(item['title']!, item['desc']!, index);
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: ElevatedButton(
                onPressed: _navigateToDashboardImmediately,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563eb),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      Lang.isUrdu ? 'واپس ڈیش بورڈ' : 'Back to Dashboard',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_isListening) {
            VoiceManager.safeStopListening(_speech);
            setState(() => _isListening = false);
          } else {
            _startListening();
          }
        },
        backgroundColor: _isListening ? Colors.red : const Color(0xFF2563eb),
        child: Icon(
          _isListening ? Icons.mic_off : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }
}
