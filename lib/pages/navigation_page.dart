import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:nav_aif_fyp/utils/voice_navigation_mixin.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/services/microphone_manager.dart';

class NavigationPage extends StatefulWidget {
  const NavigationPage({super.key});

  @override
  State<NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends State<NavigationPage>
    with VoiceNavigationMixin {
  @override
  String get pageTitle => Lang.isUrdu ? "نیویگیشن" : "Navigation";

  final List<Map<String, String>> _availableRoutes = [
    {'en': 'Home to Library', 'ur': 'گھر سے لائبریری'},
    {'en': 'Lab A to Cafeteria', 'ur': 'لیب اے سے کیفے ٹیریا'},
    {'en': 'Reception to Room 204', 'ur': 'رسیپشن سے کمرہ 204'},
    {'en': 'Main Gate to Admin Block', 'ur': 'مین گیٹ سے ایڈمن بلاک'},
    {'en': 'Parking to Lecture Hall 3', 'ur': 'پارکنگ سے لیکچر ہال 3'},
  ];

  String? _selectedRoute;
  bool _isNavigating = false;

  Timer? _simulationTimer;
  int _currentStepIndex = 0;
  List<String> _currentSteps = [];

  String _getRouteName(Map<String, String> route) {
    return Lang.isUrdu ? route['ur']! : route['en']!;
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      startVoiceNavigation();
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  @override
  Future<void> speakPageEntry() async {
    if (!mounted) return;

    String msg = '';
    if (Lang.isUrdu) {
      msg = 'نیویگیشن کا صفحہ۔ ';
      if (_availableRoutes.isEmpty) {
        msg += 'کوئی راستہ دستیاب نہیں ہے۔ ';
      } else {
        msg += 'دستیاب راستے یہ ہیں: ';
        for (int i = 0; i < _availableRoutes.length; i++) {
          msg += 'راستہ ${i + 1}۔ ${_availableRoutes[i]['ur']}۔ ';
        }
        msg += 'منتخب کرنے کے لیے "راستہ 1" یا "پہلا راستہ" کہیں۔ ';
      }
      msg += 'واپس جانے کے لیے "واپس" کہیں۔';
    } else {
      msg = 'Navigation page. ';
      if (_availableRoutes.isEmpty) {
        msg += 'No routes available. ';
      } else {
        msg += 'Available routes are: ';
        for (int i = 0; i < _availableRoutes.length; i++) {
          msg += 'Route ${i + 1}. ${_availableRoutes[i]['en']}. ';
        }
        msg += 'To select, say "Route 1" or "number 1". ';
      }
      msg += 'Say "Back" to return.';
    }

    await flutterTts.stop();
    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);
  }

  @override
  Future<bool> onCommand(String command) async {
    for (int i = 0; i < _availableRoutes.length; i++) {
      String numStr = (i + 1).toString();
      String urduNum = _getUrduNumberString(i + 1);

      bool isMatch = false;

      if (command.contains('route $numStr') ||
          command.contains('number $numStr') ||
          command.contains('select $numStr')) {
        isMatch = true;
      }

      // We'll check for digits and common keywords.
      if (command.contains('رستہ $numStr') ||
          command.contains('راستہ $numStr') ||
          command.contains('نمبر $numStr')) {
        isMatch = true;
      }

      if (isMatch) {
        await _selectRouteByIndex(i);
        return true;
      }
    }

    if (command.contains('start') ||
        command.contains('شروع') ||
        command.contains('begin') ||
        command.contains('hlo') ||
        command.contains('navigate')) {
      if (_selectedRoute != null) {
        await _startNavigation();
        return true;
      } else {
        await _speakNoRouteSelected();
        return true;
      }
    }

    if (command.contains('stop') ||
        command.contains('رکیں') ||
        command.contains('ruk') ||
        command.contains('end') ||
        command.contains('cancel')) {
      if (_isNavigating) {
        await _stopNavigation();
        return true;
      }
    }

    if (command.contains('repeat') ||
        command.contains('دہرائیں') ||
        command.contains('where') ||
        command.contains('kahan') ||
        command.contains('again')) {
      if (_isNavigating) {
        await _repeatCurrentInstruction();
        return true;
      }
    }

    if (command.contains('next') ||
        command.contains('agla') ||
        command.contains('age')) {
      if (_isNavigating) {
        _advanceSimulation();
        return true;
      }
    }

    return false;
  }

  String _getUrduNumberString(int i) {
    return i.toString();
  }

  Future<void> _selectRouteByIndex(int index) async {
    if (index < 0 || index >= _availableRoutes.length) return;

    await stopVoice();

    setState(() {
      _selectedRoute = _getRouteName(_availableRoutes[index]);
    });

    String msg = Lang.isUrdu
        ? 'راستہ منتخب کیا گیا: $_selectedRoute۔ نیویگیشن شروع کرنے کے لیے "شروع کریں" کہیں۔'
        : 'Selected: $_selectedRoute. Say "Start" to begin navigation.';

    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);

    if (mounted) startListening();
  }

  Future<void> _speakNoRouteSelected() async {
    await stopVoice();
    String msg = Lang.isUrdu
        ? 'براہ کرم پہلے راستہ منتخب کریں۔ آپ "راستہ 1" یا "راستہ 2" کہہ سکتے ہیں۔'
        : 'Please select a route first. You can say "Route 1" or "Route 2".';
    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);
    if (mounted) startListening();
  }

  Future<void> _startNavigation() async {
    if (_selectedRoute == null) return;

    await stopVoice();

    setState(() {
      _isNavigating = true;
      _currentStepIndex = -1; // Will increment to 0
    });

    _currentSteps = _generateSimulatedSteps(_selectedRoute!);

    String msg = '';
    if (Lang.isUrdu) {
      msg = 'نیویگیشن شروع کر رہے ہیں۔ ';
    } else {
      msg = 'Starting navigation. ';
    }

    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);

    _advanceSimulation();
  }

  List<String> _generateSimulatedSteps(String routeName) {
    if (Lang.isUrdu) {
      return [
        'سیدھا جائیں۔ مین کوریڈور کی طرف بڑھیں۔',
        'بائیں طرف مڑیں اور 20 قدم چلیں۔',
        'آپ سیڑھیوں کے قریب ہیں۔ محتاط رہیں۔',
        'اوپر جائیں اور دائیں مڑیں۔',
        'آپ اپنی منزل، $routeName پر پہنچ گئے ہیں۔',
      ];
    } else {
      return [
        'Go straight towards the main corridor.',
        'Turn left and walk 20 steps.',
        'You are approaching stairs. Please be careful.',
        'Go upstairs and turn right.',
        'You have reached your destination, $routeName.',
      ];
    }
  }

  void _advanceSimulation() {
    _simulationTimer?.cancel();

    _currentStepIndex++;
    if (_currentStepIndex >= _currentSteps.length) {
      _finishNavigation();
      return;
    }

    _speakCurrentStep();

    _simulationTimer = Timer(const Duration(seconds: 8), () {
      if (mounted && _isNavigating) {
        _advanceSimulation();
      }
    });
  }

  Future<void> _speakCurrentStep() async {
    if (!_isNavigating || _currentStepIndex >= _currentSteps.length) return;

    await stopVoice();

    String step = _currentSteps[_currentStepIndex];
    await VoiceManager.safeSpeak(flutterTts, step);
    await flutterTts.awaitSpeakCompletion(true);

    if (mounted && _isNavigating) {
      startListening();
    }
  }

  Future<void> _finishNavigation() async {
    await stopVoice();
    setState(() => _isNavigating = false);

    String msg = Lang.isUrdu
        ? 'نیویگیشن مکمل ہو گئی۔ کیا آپ واپس جانا چاہتے ہیں؟'
        : 'Navigation completed. Do you want to return?';

    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);

    if (mounted) startListening();
  }

  Future<void> _stopNavigation() async {
    _simulationTimer?.cancel();
    await stopVoice();

    setState(() => _isNavigating = false);

    String msg = Lang.isUrdu ? 'نیویگیشن رک گئی۔' : 'Navigation stopped.';

    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);

    if (mounted) startListening();
  }

  Future<void> _repeatCurrentInstruction() async {
    if (_currentStepIndex >= 0 && _currentStepIndex < _currentSteps.length) {
      await _speakCurrentStep();
    } else {
      await stopVoice();
      await VoiceManager.safeSpeak(flutterTts,
          Lang.isUrdu ? "کوئی ہدایت نہیں ہے۔" : "No instruction available.");
      await flutterTts.awaitSpeakCompletion(true);
      if (mounted) startListening();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        title: Text(
          Lang.isUrdu ? "نیویگیشن" : 'Navigation',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0d1b2a),
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen())),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              if (isSpeaking || isListening)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSpeaking ? Icons.volume_up : Icons.mic,
                        color: isSpeaking ? Colors.orange : Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isSpeaking
                            ? (Lang.isUrdu ? 'بول رہا ہے' : 'Speaking')
                            : (Lang.isUrdu ? 'سن رہا ہے' : 'Listening'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              if (_isNavigating)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.navigation,
                              color: Colors.green, size: 30),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              Lang.isUrdu
                                  ? 'نیویگیشن جاری ہے'
                                  : 'Navigation Active',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_currentStepIndex >= 0 &&
                          _currentStepIndex < _currentSteps.length)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            _currentSteps[_currentStepIndex],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        )
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Lang.isUrdu ? 'راستہ منتخب کریں' : 'Select Route',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _selectedRoute,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFF1a2233),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        hintText:
                            Lang.isUrdu ? 'راستہ منتخب کریں' : 'Choose a route',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                      dropdownColor: const Color(0xFF1a2233),
                      style: const TextStyle(color: Colors.white),
                      items: _availableRoutes.map((route) {
                        String routeName = _getRouteName(route);
                        return DropdownMenuItem<String>(
                          value: routeName,
                          child: Text(routeName),
                        );
                      }).toList(),
                      onChanged: _isNavigating
                          ? null
                          : (value) {
                              setState(() => _selectedRoute = value);
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!_isNavigating)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2563eb).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF2563eb).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFF2563eb),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          Lang.isUrdu
                              ? "کہیں: \"راستہ 1\"، \"شروع کریں\""
                              : 'Say: "Route 1", "Start", "Select Route 2"',
                          style: const TextStyle(
                            color: Color(0xFF2563eb),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const Spacer(),
              if (!_isNavigating)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _selectedRoute == null ? null : _startNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: Colors.grey,
                    ),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(
                      Lang.isUrdu ? 'نیویگیشن شروع کریں' : 'Start Navigation',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _stopNavigation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.stop),
                    label: Text(
                      Lang.isUrdu ? 'نیویگیشن رکیں' : 'Stop Navigation',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _simulationTimer?.cancel();
                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const DashboardScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563eb),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(
                    Lang.isUrdu
                        ? "ڈیش بورڈ پر واپس جائیں"
                        : "Back to Dashboard",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
