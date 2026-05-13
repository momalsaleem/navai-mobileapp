import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:nav_aif_fyp/services/database_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/services/route_tts_observer.dart';
import 'package:nav_aif_fyp/pages/lang.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';

Future<void> _testFirebaseConnection() async {
  try {
    print('\n======================================================');
    print('[FIREBASE TEST] 🚀 Starting automated Firebase test...');
    DatabaseService db = DatabaseService();
    
    // 1. Add Test Data
    print('[FIREBASE TEST] Adding test user...');
    await db.addUser('test_user_999', {
      'name': 'Automated Test Bot',
      'platform': 'NavAI Flutter',
      'timestamp': DateTime.now().toIso8601String()
    });
    
    print('[FIREBASE TEST] Adding test route...');
    await db.addRoute('test_route_999', {
      'name': 'Virtual Run',
      'waypoints': {
        'wpt_1': {'lat': 31.5204, 'lng': 74.3587},
      }
    });

    print('[FIREBASE TEST] Adding test recording...');
    await db.saveRecording('test_record_999', {
      'routeId': 'test_route_999',
      'duration': 60,
    });
    
    // 2. Try Calling (Reading) Data back
    print('[FIREBASE TEST] Fetching all routes back from Firebase...');
    final routes = await db.getAllRoutes();
    print('[FIREBASE TEST] 🎯 Success! Data successfully retrieved.');
    print('[FIREBASE TEST] Total Routes Found: ${routes?.length ?? 0}');
    print('[FIREBASE TEST] Sample Output Array: ${routes?.keys.take(3)}');
    print('======================================================\n');
  } catch(e) {
    print('\n[FIREBASE TEST ERROR] ❌ Connection failed: $e\n');
  }
}

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // We await Firebase initialization but DO NOT run the heavy test immediately
    await Firebase.initializeApp();
    
    await PreferencesManager.init();
    await Lang.init();
    
    // We can run the test call after a slight delay or once the app is ready
    // _testFirebaseConnection(); 
    
    runApp(const NavAIApp());
  }, (error, stack) {
    debugPrint('🚨 Uncaught error: $error\n$stack');
  });
}

class NavAIApp extends StatelessWidget {
  const NavAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NavAI',
      theme: ThemeData.dark(),
      home: const NavAIHomePage(),
      routes: {'/lang': (context) => NavAILanguagePage()},
      navigatorObservers: [routeObserver],
    );
  }
}

class NavAIHomePage extends StatefulWidget {
  const NavAIHomePage({super.key});

  @override
  State<NavAIHomePage> createState() => _NavAIHomePageState();
}

class _NavAIHomePageState extends State<NavAIHomePage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _pathController;
  late AnimationController _starController;
  final FlutterTts _flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isSpeaking = false;
  bool _isListening = false;
  bool _autoRedirectEnabled = true;
  bool _hasSpokenIntro = false;
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAnimations();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeVoiceSystemSequentially();
    });
  }





  void _initAnimations() {
    _pathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 7000),
    );

    _pathController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _starController.forward(from: 0.0);
      }
    });

    _starController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _autoRedirectEnabled) {
            _pathController.reset();
            _starController.reset();
            _pathController.forward(from: 0.0);
          }
        });
      }
    });

    _pathController.forward();
  }


  Future<void> _initializeVoiceSystemSequentially() async {
    try {

      final hasConfig = await PreferencesManager.hasLanguageConfigured();
      
      if (hasConfig) {
        setState(() => _statusMessage = 'Loading your preferences...');
        

        await Lang.init();
        

        await _speakReturningUserIntro();
        

        if (mounted) {
          // Add a small delay for TTS to definitely finish or be ready to stop
          await Future.delayed(const Duration(milliseconds: 300));
          if (!mounted) return;
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
        return;
      }

      await PreferencesManager.clearAll();
      
      setState(() => _statusMessage = 'Initializing voice system...');

      await _initTTS();

      setState(() {
        _isSpeaking = true;
        _statusMessage = 'Welcome to NavAI...';
      });
      

      await _speakBilingualIntroduction();
      
      setState(() {
        _isSpeaking = false;
        _hasSpokenIntro = true;
        _statusMessage = 'Redirecting to language selection...';
      });

      await Future.delayed(const Duration(milliseconds: 500));
      

      _navigateToLang();
      
    } catch (e) {

      if (mounted) {
        setState(() => _statusMessage = 'System initializing...');

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _autoRedirectEnabled) {
            _navigateToLang();
          }
        });
      }
    }
  }




  Future<void> _safeSpeak(String text) async {
    if (!mounted) return;
    setState(() => _isSpeaking = true);
    try {
      await _flutterTts.speak(text);

    } catch (e) {

      if (mounted) {
        setState(() => _isSpeaking = false);
      }
    }
  }

  Future<void> _safeAwaitSpeakCompletion() async {
    try {

      final completer = Completer<void>();
      
      _flutterTts.setCompletionHandler(() {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      

      await completer.future.timeout(const Duration(seconds: 30));
    } on TimeoutException catch (_) {

    } catch (e) {

    }
  }


  Future<void> _initTTS() async {
    await _flutterTts.setLanguage('en-US');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setVolume(1.0);


    _flutterTts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });

    _flutterTts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });

    _flutterTts.setErrorHandler((message) {

      if (mounted) setState(() => _isSpeaking = false);
    });


  }

  Future<void> _speakBilingualIntroduction() async {
    try {

      await _flutterTts.setLanguage('en-US');
      await _safeSpeak(
        'Hello! Welcome to Nav AI. '
        'This application is designed to help blind and visually impaired users navigate their surroundings. '
        'We interpret the world for you using object detection and voice guidance. '
        'Please wait a moment while we initialize the system for your first use. '
        'We will shortly redirect you to choose your preferred language.',
      );
      await _safeAwaitSpeakCompletion();
      
      await Future.delayed(const Duration(milliseconds: 800));


      try {
        await _flutterTts.setLanguage('ur-PK');
        await _safeSpeak(
          'السلام علیکم! نوے اے آئی میں خوش آمدید۔ '
          'یہ ایپلی کیشن نابینا اور کمزور بصارت والے افراد کی مدد کے لیے بنائی گئی ہے۔ '
          'ہم آپ کی رہنمائی کے لیے جدید ٹیکنالوجی استعمال کرتے ہیں۔ '
          'براہ کرم انتظار کریں جب تک ہم آپ کے لیے سسٹم تیار کرتے ہیں۔ '
          'ہم آپ کو جلد ہی زبان کے انتخاب کی سکرین پر لے جائیں گے۔',
        );
        await _safeAwaitSpeakCompletion();
      } catch (e) {

      }



    } catch (e) {

    }
  }

  Future<void> _speakReturningUserIntro() async {
    try {
      if (Lang.isUrdu) {
        await _flutterTts.setLanguage('ur-PK');
        await _safeSpeak(
          'نوے اے آئی میں خوش آمدید۔ لیجئے آپ کا ڈیش بورڈ تیار ہے۔'
        );
      } else {
        await _flutterTts.setLanguage('en-US');
        await _safeSpeak(
          'Welcome to Nav AI. Loading your dashboard.'
        );
      }
      await _safeAwaitSpeakCompletion();
    } catch (e) {

    }
  }

  Future<void> _navigateToLang() async {
    _autoRedirectEnabled = false;

    try {
      VoiceManager.safeStopListening(_speech);
    } catch (_) {}

    if (mounted) setState(() => _isListening = false);

    VoiceManager.resetMicrophoneState();

    try {
      await _flutterTts.stop();
    } catch (_) {}

    if (mounted) {
      final hasConfig = await PreferencesManager.hasLanguageConfigured();
      if (hasConfig) {

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => NavAILanguagePage()),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoRedirectEnabled = false;
    try {
      _flutterTts.stop();
      VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    _pathController.dispose();
    _starController.dispose();
    VoiceManager.resetMicrophoneState();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: _buildBackground(),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Container(
                    color: const Color(0xFF0d1b2a),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 450),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30, vertical: 40),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [

                              SizedBox(
                                height: 250,
                                width: double.infinity,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(15),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Color(0xFF0a192f),
                                        Color(0xFF0d253f),
                                      ],
                                    ),
                                  ),
                                  child: AnimatedBuilder(
                                    animation: Listenable.merge(
                                        [_pathController, _starController]),
                                    builder: (context, child) {
                                      return CustomPaint(
                                        painter: PathAnimationPainter(
                                          pathAnimation: _pathController,
                                          starAnimation: Tween<double>(
                                            begin: 0.0,
                                            end: 1.0,
                                          ).animate(
                                            CurvedAnimation(
                                              parent: _starController,
                                              curve: Curves.easeInOut,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              

                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'NavAI: AI-Powered Indoor Guidance & Object Detection',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 10),
                              

                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  'Smart navigation, designed for you.\nسمارٹ نیویگیشن، آپ کے لیے تیار کی گئی۔',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFcbd5e0),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 30),
                              

                              const CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563eb)),
                                strokeWidth: 3,
                              ),
                              const SizedBox(height: 20),
                              

                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  children: [
                                    if (_isSpeaking)
                                      _buildStatusIndicator(
                                        icon: Icons.volume_up,
                                        text: 'Speaking... / بول رہا ہے...',
                                        color: Colors.blue,
                                      ),
                                    
                                    if (!_isSpeaking)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8),
                                        child: Text(
                                          _statusMessage,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF9DA4B9),
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha((0.2 * 255).round()),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color.withAlpha((0.8 * 255).round())),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: color.withAlpha((0.8 * 255).round()),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _buildBackground() {
    return const BoxDecoration(
      gradient: RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Color(0xFF0f2027),
          Color(0xFF203a43),
          Color(0xFF2c5364),
        ],
      ),
    );
  }
}

class PathAnimationPainter extends CustomPainter {
  final Animation<double> pathAnimation;
  final Animation<double> starAnimation;
  static const Size viewBox = Size(400, 200);

  PathAnimationPainter(
      {required this.pathAnimation, required this.starAnimation})
      : super(repaint: Listenable.merge([pathAnimation, starAnimation]));

  Path _getPath1() {
    final path = Path()..moveTo(0, 120);
    path.quadraticBezierTo(150, 40, 250, 90);
    path.quadraticBezierTo(350, 140, 400, 50);
    return path;
  }

  Path _getPath2() {
    final path = Path()..moveTo(0, 200);
    path.quadraticBezierTo(150, 120, 250, 170);
    path.quadraticBezierTo(350, 220, 400, 130);
    return path;
  }

  Path _createStarShape(double size) {
    final path = Path();
    const double normalizer = 22.0;

    final List<Offset> points = [
      const Offset(12.00, 2.00),
      const Offset(9.42, 8.66),
      const Offset(2.00, 10.47),
      const Offset(7.60, 15.34),
      const Offset(6.18, 22.00),
      const Offset(12.00, 18.50),
      const Offset(17.82, 22.00),
      const Offset(16.40, 15.34),
      const Offset(22.00, 10.47),
      const Offset(14.58, 8.66),
    ].map((p) => Offset(p.dx / normalizer, p.dy / normalizer)).toList();

    const Offset centerOffset = Offset(0.5, 0.5);

    path.moveTo(
      (points[0].dx - centerOffset.dx) * size,
      (points[0].dy - centerOffset.dy) * size,
    );

    for (int i = 1; i < points.length; i++) {
      path.lineTo(
        (points[i].dx - centerOffset.dx) * size,
        (points[i].dy - centerOffset.dy) * size,
      );
    }

    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final double scaleX = size.width / viewBox.width;
    final double scaleY = size.height / viewBox.height;

    canvas.scale(scaleX, scaleY);

    final path1 = _getPath1();
    final path2 = _getPath2();

    final ui.PathMetric m1 = path1.computeMetrics().first;
    final ui.PathMetric m2 = path2.computeMetrics().first;

    final double drawLen1 = m1.length * pathAnimation.value;
    final double drawLen2 =
        m2.length * math.max(0.0, pathAnimation.value - 0.075);

    final double strokeWidth = 3 / scaleX;

    final paint1 = Paint()
      ..color = const Color(0xFF3a9df8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final paint2 = Paint()
      ..color = const Color(0xFF00f7ff)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawPath(m1.extractPath(0, drawLen1), paint1);
    canvas.drawPath(m2.extractPath(0, drawLen2), paint2);

    if (starAnimation.value > 0.0) {
      int steps = 100;
      Path midpointPath = Path();
      for (int i = 0; i <= steps; i++) {
        double t = i / steps;
        final ui.Tangent? p1 = m1.getTangentForOffset(m1.length * t);
        final ui.Tangent? p2 = m2.getTangentForOffset(m2.length * t);
        if (p1 != null && p2 != null) {
          Offset mid = Offset(
            (p1.position.dx + p2.position.dx) / 2,
            (p1.position.dy + p2.position.dy) / 2,
          );
          if (i == 0) {
            midpointPath.moveTo(mid.dx, mid.dy);
          } else {
            midpointPath.lineTo(mid.dx, mid.dy);
          }
        }
      }

      final ui.PathMetric midMetric = midpointPath.computeMetrics().first;
      final double distance = midMetric.length * starAnimation.value;
      final ui.Tangent? tangent = midMetric.getTangentForOffset(distance);

      if (tangent != null) {
        double starSize = 40 + 10 * math.sin(math.pi * starAnimation.value);
        double opacity = 1.0;


        const double invisibleFracStart = 0.2 / 7.0;
        const double invisibleFracEnd = 0.5 / 7.0;
        if (starAnimation.value < invisibleFracStart) {
          opacity = 0.0;
        } else if (starAnimation.value < invisibleFracStart + 0.1) {
          opacity = (starAnimation.value - invisibleFracStart) / 0.1;
        } else if (starAnimation.value < 1.0 - invisibleFracEnd - 0.1) {
          opacity = 1.0;
        } else if (starAnimation.value < 1.0 - invisibleFracEnd) {
          opacity = (1.0 - invisibleFracEnd - starAnimation.value) / 0.1;
        } else {
          opacity = 0.0;
        }

        canvas.save();
        canvas.translate(tangent.position.dx, tangent.position.dy);
        canvas.scale(1 / scaleX, 1 / scaleY);

        final star = _createStarShape(starSize);

        final starPaint = Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5.0);

        canvas.drawPath(star, starPaint);

        final starPaintSolid = Paint()
          ..color = Colors.white.withOpacity(opacity);

        canvas.drawPath(star, starPaintSolid);

        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant PathAnimationPainter oldDelegate) => true;
}