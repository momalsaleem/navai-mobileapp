import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:nav_aif_fyp/pages/guide.dart';
import 'package:nav_aif_fyp/pages/camera_page.dart';
import 'package:nav_aif_fyp/pages/navigation_page.dart';
import 'package:nav_aif_fyp/pages/saved_routes_page.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/services/route_tts_observer.dart';
import 'package:nav_aif_fyp/pages/camera_page.dart';
import 'package:nav_aif_fyp/pages/saved_routes_page.dart';
import 'package:nav_aif_fyp/services/microphone_manager.dart';
import 'package:nav_aif_fyp/pages/navigation_page.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with RouteAwareTtsStopper {
  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  bool _isSpeaking = false;
  int? _hoveredIndex;
  bool _isInitialized = false;
  bool _pageHasSpoken = false;
  String _statusMessage = 'Initializing...';
  bool _isNavigating = false;

  List<Map<String, dynamic>> _cards = [];

  void _buildCards() {
    _cards = [
      {
        'icon': Icons.camera_alt,
        'titleKey': "object_detection",
        'subtitleKey': "object_detection_desc",
        'onTap': _openObjectDetection,
      },
      {
        'icon': Icons.navigation,
        'titleKey': "navigation",
        'subtitleKey': "navigation_desc",
        'onTap': () => _handleCardTap('navigation'),
      },
      {
        'icon': Icons.route,
        'titleKey': "saved_routes",
        'subtitleKey': "saved_routes_desc",
        'onTap': () => _handleCardTap('saved_routes'),
      },
      {
        'icon': Icons.book,
        'titleKey': "guide",
        'subtitleKey': "guide_desc",
        'onTap': () => _handleCardTap('guide'),
      },
    ];
  }

  void _openObjectDetection() async {
    await _initTTS();
    await _speakMessage('${Lang.t('opening')} ${Lang.t('object_detection')}.');

    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}

    _isNavigating = true;
    if (mounted) {
      await Navigator.of(context)
          .push(
            MaterialPageRoute(
                builder: (context) => const ObjectDetectionPage()),
          )
          .then((_) => _onReturnToDashboard());
      _isNavigating = false;
    }
  }

  void _handleCardTap(String feature) async {
    await _initTTS();
    await _speakMessage('${Lang.t(feature)} ${Lang.t('selected')}.');

    if (feature == 'saved_routes') {
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      _isNavigating = true;
      if (mounted) {
        await Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (context) => const SavedRoutesPage()),
            )
            .then((_) => _onReturnToDashboard());
        _isNavigating = false;
      }
      return;
    } else if (feature == 'navigation') {
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      _isNavigating = true;
      if (mounted) {
        await Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (context) => const NavigationPage()),
            )
            .then((_) => _onReturnToDashboard());
        _isNavigating = false;
      }
      return;
    } else if (feature == 'guide') {
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      _isNavigating = true;
      if (mounted) {
        await Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (context) => const GuidePage()),
            )
            .then((_) => _onReturnToDashboard());
        _isNavigating = false;
      }
      return;
      _isNavigating = true;
      if (mounted) {
        await Navigator.of(context)
            .push(
              MaterialPageRoute(builder: (context) => const GuidePage()),
            )
            .then((_) => _onReturnToDashboard());
        _isNavigating = false;
      }
      return;
    } else if (feature == 'settings') {
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      _isNavigating = true;
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        _isNavigating = false;
      }
      return;
    } else if (feature == 'profile') {
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      _isNavigating = true;
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        );
        _isNavigating = false;
      }
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _buildCards();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboardPage();
    });
  }

  Future<void> _initializeDashboardPage() async {
    await _clearAllSpeechAndTts();

    if (mounted) {
      setState(() {
        _isListening = false;
        _isSpeaking = false;
        _pageHasSpoken = false;
        _isNavigating = false;
        _statusMessage = 'Initializing...';
      });
    }

    try {
      setState(() => _statusMessage = 'Initializing voice system...');

      // No need to Lang.init() again if results are already loaded
      if (!Lang.isInitialized) {
         await Lang.init();
      }

      await _initTTS();

      setState(() {
        _isSpeaking = true;
        _statusMessage = Lang.isUrdu
            ? 'ڈیش بورڈ کا تعارف پڑھا جا رہا ہے...'
            : 'Reading dashboard introduction...';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      await _speakDashboardIntroduction();

      _pageHasSpoken = true;

      setState(() {
        _isSpeaking = false;
        _statusMessage = Lang.isUrdu
            ? 'سن رہا ہے... آپ "آبجیکٹ"، "نیویگیشن"، "محفوظ راستے"، یا "گائیڈ" کہہ سکتے ہیں۔'
            : 'Listening... You can say "object", "navigation", "saved routes", or "guide".';
      });

      try {
        await _speech.stop();
        await _speech.cancel();
      } catch (_) {}

      await Future.delayed(const Duration(milliseconds: 800));

      await _startListening();

      _isInitialized = true;
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = Lang.isUrdu
              ? 'براہ کرم آپشنز کو منتخب کرنے کے لیے ٹیپ کریں۔'
              : 'Please tap to select options.';
        });
      }
    }
  }

  Future<void> _onReturnToDashboard() async {
    if (!mounted) return;

    await _clearAllSpeechAndTts();

    setState(() {
      _isNavigating = false;
      _isListening = false;
      _isSpeaking = false;
      _statusMessage = 'Returning...';
    });

    await _speakDashboardIntroduction(isReturn: true);

    await Future.delayed(const Duration(milliseconds: 800));

    if (mounted && !_isNavigating) {
      setState(() {
        _statusMessage = Lang.isUrdu ? 'سن رہا ہے...' : 'Listening...';
      });
      await _startListening();
    }
  }

  Future<void> _clearAllSpeechAndTts() async {
    try {
      await _speech.stop();
      await _speech.cancel();
      await _speech.initialize(); // Re-initialize to clear state
    } catch (e) {}

    try {
      await _tts.stop();
      await Future.delayed(const Duration(milliseconds: 100));

      await _tts.speak("");
      await _tts.stop();
    } catch (e) {}
  }

  Future<void> _initTTS() async {
    try {
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
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.awaitSpeakCompletion(true);

      _tts.setStartHandler(() {
        _speech.stop();
        if (mounted)
          setState(() {
            _isSpeaking = true;
            _isListening = false;
          });
      });

      _tts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });

      _tts.setErrorHandler((message) {
        if (mounted) setState(() => _isSpeaking = false);
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> _speakDashboardIntroduction({bool isReturn = false}) async {
    try {
      await _tts.stop();

      try {
        await _speech.stop();
        await _speech.cancel();
      } catch (_) {}
      if (mounted) setState(() => _isListening = false);

      await Future.delayed(const Duration(milliseconds: 200));

      if (Lang.isUrdu) {
        try {
          await _tts.setLanguage('ur-PK');
        } catch (_) {
          await _tts.setLanguage('en-US');
        }

        String intro = isReturn
            ? 'ہم ڈیش بورڈ پر واپس آگئے ہیں۔ '
            : 'نوے اے آئی ڈیش بورڈ پر خوش آمدید۔ ';

        await _tts.speak(intro +
            'آپ کے پاس چار آپشنز ہیں۔ '
                'پہلا، آبجیکٹ ڈیٹیکشن۔ منتخب کرنے کے لیے  "کیمرہ" کہیں۔ '
                'دوسرا، نیویگیشن۔ منتخب کرنے کے لیے "نیویگیشن" کہیں۔ '
                'تیسرا، محفوظ شدہ راستے۔ "محفوظ راستے" کہیں۔ '
                'چوتھا، گائیڈ۔ "گائیڈ کہیں۔ '
                'آپ کسی بھی آپشن کو منتخب کرنے کے لیے بول سکتے ہیں یا ٹیپ کر سکتے ہیں۔');
        await _tts.awaitSpeakCompletion(true);
      } else {
        await _tts.setLanguage('en-US');

        String intro = isReturn
            ? 'We are back to dashboard. '
            : 'Welcome to Nav AI Dashboard. ';

        await _tts.speak(intro +
            'You have four options. '
                'First, Object Detection. Say "Object" or "Camera" to select. '
                'Second, Navigation. Say "Navigation" or "Map" to select. '
                'Third, Saved Routes. Say "Saved Routes" or "Path" to select. '
                'Fourth, Guide. Say "Guide" or "Help" to select. '
                'You can speak or tap to select any option.');
        await _tts.awaitSpeakCompletion(true);
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    try {
      VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      _tts.stop();
    } catch (_) {}
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

  Future<void> _speakMessage(String text) async {
    try {
      await _initTTS();
      await VoiceManager.safeSpeak(_tts, text);
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {}
  }

  Future<void> _startListening() async {
    if (_isNavigating) {
      return;
    }

    bool hasPerm = await MicrophoneManager.hasPermission();
    if (!hasPerm) {
      await _tts.setLanguage(Lang.isUrdu ? 'ur-PK' : 'en-US');
      if (Lang.isUrdu) {
        await VoiceManager.safeSpeak(_tts,
            "ہمیں مائیکروفون کی اجازت درکار ہے۔ براہ کرم اجازت دیں بٹن پر ڈبل ٹیپ کریں۔");
      } else {
        await VoiceManager.safeSpeak(_tts,
            "To hear you, we need microphone access. Please double tap Allow when the permission dialog appears.");
      }
      await _tts.awaitSpeakCompletion(true);
    }

    bool micReady = await MicrophoneManager.initializeMicrophone(
      speech: _speech,
      context: context,
      onStatusUpdate: (message) {
        if (mounted) {
          setState(() => _statusMessage = message);
        }
      },
      isUrdu: Lang.isUrdu,
    );

    if (!micReady) {
      if (mounted) setState(() => _isListening = false);
      return;
    }

    final localeId = Lang.isUrdu ? 'ur-PK' : 'en-US';

    bool available = await _speech.initialize(
      onStatus: (val) {
        if (val == "done" && !_isListening && mounted && !_isNavigating) {
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isNavigating) {
              _startListening();
            }
          });
        }
      },
      onError: (val) {
        if (mounted) {
          setState(() {
            _isListening = false;
            _statusMessage =
                Lang.isUrdu ? 'دوبارہ کوشش کر رہا ہے...' : 'Retrying...';
          });

          if (!_isNavigating) {
            Future.delayed(const Duration(seconds: 1), () {
              if (mounted && !_isNavigating) {
                _startListening();
              }
            });
          }
        }
      },
    );

    if (available && !_isNavigating) {
      if (mounted) {
        setState(() {
          _isListening = true;
          _statusMessage = Lang.isUrdu
              ? 'سن رہا ہے... آپ "آبجیکٹ"، "نیویگیشن"، "محفوظ راستے"، یا "گائیڈ" کہہ سکتے ہیں۔'
              : 'Listening... You can say "object", "navigation", "saved routes", or "guide".';
        });
      }

      final options =
          MicrophoneManager.getContinuousListenOptions(isUrdu: Lang.isUrdu);

      await _speech.listen(
        localeId: options['localeId'],
        onResult: (result) {
          if (result.finalResult) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            if (recognized.isNotEmpty) {
              processVoiceCommand(recognized);
            }
          }
        },
        listenFor: options['listenFor'],
        pauseFor: options['pauseFor'],
        cancelOnError: false,
        partialResults: false,
      );
    } else if (!available) {
      if (mounted) {
        setState(() {
          _isListening = false;
          _statusMessage = Lang.isUrdu
              ? 'براہ کرم آپشنز کو منتخب کرنے کے لیے ٹیپ کریں۔'
              : 'Please tap to select options.';
        });
      }
    }
  }

  Future<void> processVoiceCommand(String recognized) async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);

    bool commandMatched = false;

    if (recognized.contains('object') ||
        recognized.contains('آبجیکٹ') ||
        recognized.contains('camera') ||
        recognized.contains('کیمرہ') ||
        recognized.contains('detect') ||
        (recognized.contains('go to') && recognized.contains('camera')) ||
        recognized.contains('بیٹین')) {
      // Phonetic fix for detection
      commandMatched = true;

      _openObjectDetection();
    } else if (recognized.contains('navigation') ||
        recognized.contains('نیویگیشن') ||
        recognized.contains('navigate') ||
        recognized.contains('map') ||
        recognized.contains('direction') ||
        (recognized.contains('go to') && recognized.contains('nav')) ||
        recognized.contains('راستہ')) {
      commandMatched = true;

      await _speakMessage('${Lang.t('opening')} ${Lang.t('navigation')}.');

      _isNavigating = true;
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (context) => const NavigationPage()),
              )
              .then((_) => _onReturnToDashboard());
        }
      });
    } else if (recognized.contains('saved') ||
        recognized.contains('محفوظ') ||
        recognized.contains('route') ||
        recognized.contains('راستہ') ||
        recognized.contains('path') ||
        (recognized.contains('go to') && recognized.contains('routes')) ||
        recognized.contains('history')) {
      commandMatched = true;

      await _speakMessage('${Lang.t('opening')} ${Lang.t('saved_routes')}.');

      _isNavigating = true;
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(
                    builder: (context) => const SavedRoutesPage()),
              )
              .then((_) => _onReturnToDashboard());
        }
      });
    } else if (recognized.contains('guide') ||
        recognized.contains('گائیڈ') ||
        recognized.contains('help') ||
        recognized.contains('instruction') ||
        (recognized.contains('go to') && recognized.contains('guide')) ||
        recognized.contains('مدد')) {
      commandMatched = true;

      await _speakMessage('${Lang.t('opening')} ${Lang.t('guide')}.');

      _isNavigating = true;
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context)
              .push(
                MaterialPageRoute(builder: (context) => const GuidePage()),
              )
              .then((_) => _onReturnToDashboard());
        }
      });
    } else if (recognized.contains('settings') ||
        (recognized.contains('go to') && recognized.contains('setting')) ||
        recognized.contains('سیٹنگز')) {
      commandMatched = true;

      await _speakMessage('${Lang.t('opening')} ${Lang.t('settings')}.');

      _isNavigating = true;
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const SettingsPage()),
          );
        }
      });
    } else if (recognized.contains('profile') ||
        (recognized.contains('go to') && recognized.contains('profile')) ||
        recognized.contains('پروفائل')) {
      commandMatched = true;

      await _speakMessage('${Lang.t('opening')} ${Lang.t('profile')}.');

      _isNavigating = true;
      try {
        await VoiceManager.safeStopListening(_speech);
      } catch (_) {}
      try {
        await _tts.stop();
      } catch (_) {}

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        }
      });
    } else if (recognized.contains('help') ||
        recognized.contains('مدد') ||
        recognized.contains('repeat') ||
        recognized.contains('دہرائیں') ||
        recognized.contains('what') ||
        recognized.contains('کیا')) {
      commandMatched = true;

      await _askToRepeat();
    } else if (recognized.contains('home') ||
        recognized.contains('گھر') ||
        recognized.contains('main') ||
        recognized.contains('menu')) {
      commandMatched = true;

      await _speakMessage(Lang.isUrdu
          ? 'آپ پہلے سے ہی ڈیش بورڈ پر ہیں۔'
          : 'You are already on the dashboard.');
      if (mounted && !_isNavigating) {
        await _startListening();
      }
    }

    if (!commandMatched && recognized.length > 2) {
      // print('❌ Command not recognized: $recognized');
      await _askToRepeat();
    } else if (!commandMatched) {
      if (mounted && !_isNavigating) {
        await _startListening();
      }
    }
  }

  /// Ask user to repeat in user's selected language ONLY
  Future<void> _askToRepeat() async {
    // print('🔊 Dashboard: Asking user to repeat command in ${Lang.isUrdu ? "Urdu" : "English"}...');

    if (mounted) {
      setState(() => _statusMessage = Lang.isUrdu
          ? 'براہ کرم ان میں سے ایک آپشن کہیں: آبجیکٹ، نیویگیشن، محفوظ راستے، گائیڈ'
          : 'Please say one of these: object, navigation, saved routes, guide');
    }

    HapticFeedback.vibrate();

    // Speak ONLY in user's selected language
    await _initTTS();
    if (Lang.isUrdu) {
      await _tts.speak(
          "میں نے نہیں سمجھا۔ براہ کرم کہیں: آبجیکٹ، نیویگیشن، محفوظ راستے، یا گائیڈ۔");
    } else {
      await _tts.speak(
          "I didn't understand. Please say: object, navigation, saved routes, or guide.");
    }
    await _tts.awaitSpeakCompletion(true);

    // Resume listening
    if (mounted && !_isNavigating) {
      // print('🔄 Restarting listening after repeat prompt');
      await _startListening();
    }
  }

  // Add this method to handle RouteAware callbacks
  @override
  void didPush() {
    // print('📱 Dashboard page pushed - clearing previous audio');
    super.didPush();

    // Clear everything when page is pushed
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _clearAllSpeechAndTts();
        // Reset state to ensure fresh start
        if (mounted) {
          setState(() {
            _isListening = false;
            _isSpeaking = false;
            _pageHasSpoken = false;
            _isNavigating = false;
          });
        }
        // Re-initialize the dashboard
        _initializeDashboardPage();
      });
    }
  }

  @override
  void didPopNext() {
    // print('🔄 Dashboard: Returning from sub-page (didPopNext)');
    super.didPopNext();

    if (mounted) {
      // Small delay to let "Returning to dashboard" finish
      Future.delayed(const Duration(milliseconds: 1500), () async {
        if (mounted) {
          await _speakDashboardIntroduction(isReturn: true);
          if (mounted) {
            await _startListening();
          }
        }
      });
    }
  }

  Widget _buildCard(int index, IconData icon, String titleKey,
      String subtitleKey, VoidCallback onTap) {
    final isHovered = _hoveredIndex == index;
    final borderColor =
        isHovered ? const Color(0xFF1349ec) : Colors.transparent;
    final iconColor =
        isHovered ? const Color(0xFF1349ec) : const Color(0xFF2563eb);
    final bgColor = isHovered
        ? const Color(0xFF1A202C)
        : Colors.white.withAlpha((0.05 * 255).round());

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = null),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withAlpha((0.2 * 255).round()),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Lang.t(titleKey),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      Lang.t(subtitleKey),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
      IconData icon, String label, bool active, BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          _isNavigating = true;
          try {
            await VoiceManager.safeStopListening(_speech);
          } catch (_) {}
          try {
            await _tts.stop();
          } catch (_) {}

          if (label == Lang.t('settings')) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsPage()),
            );
          } else if (label == Lang.t('profile')) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            );
          } else if (label == Lang.t('saved_routes')) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SavedRoutesPage()),
            );
          }
          _isNavigating = false;
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: active ? const Color(0xFF2563eb) : Colors.white60,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: active ? const Color(0xFF2563eb) : Colors.white60,
                ),
              ),
            ],
          ),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        automaticallyImplyLeading: false, // Remove back button
        centerTitle: true,
        backgroundColor: const Color(0xFF0d1b2a),
        elevation: 0.5,
        title: Text(
          Lang.t('navai'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Status messages
                  if (_statusMessage.contains('Initializing') ||
                      _statusMessage.contains('Reading') ||
                      _statusMessage.contains('پڑھا'))
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Color(0xFF2563eb)),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF9DA4B9),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Cards container
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: List.generate(_cards.length, (index) {
                          final card = _cards[index];
                          return _buildCard(
                            index,
                            card['icon'] as IconData,
                            card['titleKey'] as String,
                            card['subtitleKey'] as String,
                            card['onTap'] as VoidCallback,
                          );
                        }),
                      ),
                    ),
                  ),

                  // Status indicators
                  if (_isSpeaking)
                    _buildStatusIndicator(
                      icon: Icons.volume_up,
                      text: _statusMessage,
                      color: Colors.blue,
                    ),

                  if (_isListening)
                    _buildStatusIndicator(
                      icon: Icons.mic,
                      text: _statusMessage,
                      color: Colors.green,
                    ),

                  if (!_isSpeaking && !_isListening && _pageHasSpoken)
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
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
                          const SizedBox(height: 5),
                          Text(
                            Lang.isUrdu
                                ? 'منتخب کرنے کے لیے نام پکاریں'
                                : 'Say the name to select',
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
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom navigation bar removed for simpler single-list accessibility
    );
  }
}
