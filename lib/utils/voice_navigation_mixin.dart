import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:nav_aif_fyp/services/microphone_manager.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/pages/camera_page.dart';
import 'package:nav_aif_fyp/pages/navigation_page.dart';
import 'package:nav_aif_fyp/pages/saved_routes_page.dart';
import 'package:nav_aif_fyp/pages/guide.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';


mixin VoiceNavigationMixin<T extends StatefulWidget> on State<T> {
  final FlutterTts flutterTts = FlutterTts();
  final stt.SpeechToText _speech = stt.SpeechToText();
  
  bool _isListening = false;
  bool _isSpeaking = false;
  

  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  
  String _statusMessage = '';
  bool _isNavigating = false;
  

  String get pageTitle;
  
  Future<bool> onCommand(String command) async {
    return false;
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    stopVoice();
    super.dispose();
  }
  
  Future<void> stopVoice() async {
    try {
      await VoiceManager.safeStopListening(_speech);
    } catch (_) {}
    try {
      await flutterTts.stop();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isListening = false;
        _isSpeaking = false;
      });
    }
  }


  Future<void> startVoiceNavigation() async {
    if (!mounted) return;
    

    await Lang.init();


    await _initTTS();
    

    await speakPageEntry();
    

    if (mounted && !_isNavigating) {
      await startListening();
    }
  }
  
  Future<void> _initTTS() async {
    try {
      await flutterTts.setLanguage(Lang.isUrdu ? 'ur-PK' : 'en-US');
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.awaitSpeakCompletion(true);
      
      flutterTts.setStartHandler(() {

        _speech.stop();
        if (mounted) setState(() {
          _isSpeaking = true;
          _isListening = false;
        });
      });
      
      flutterTts.setCompletionHandler(() {
        if (mounted) setState(() => _isSpeaking = false);
      });
      
      flutterTts.setErrorHandler((msg) {
        if (mounted) setState(() => _isSpeaking = false);
      });
      
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }


  Future<void> speakPageEntry() async {
    if (!mounted) return;
    

    String status = Lang.isUrdu ? "کھل گیا ہے۔" : "is opened.";
    String intro = "$pageTitle $status";
    
    String instructions = Lang.isUrdu 
        ? "آپ مختلف صفحات پر جانے کے لیے ان کا نام لے سکتے ہیں، یا واپس جانے کے لیے 'واپس' کہہ سکتے ہیں۔" 
        : "You can say page names to navigate, or say 'Back' to return.";
        
    await _speakConfirmed("$intro $instructions");
  }
  
  Future<void> _speakConfirmed(String text) async {
    if (!mounted) return;
    try {

      await VoiceManager.safeStopListening(_speech);
      
      await VoiceManager.safeSpeak(flutterTts, text);
      await flutterTts.awaitSpeakCompletion(true);
      
    } catch (e) {
      print("Speak Error: $e");
    }
  }

  Future<void> startListening() async {
    if (_isNavigating || !mounted || _isSpeaking) {

      return;
    }




    bool available = await _speech.initialize(
      onStatus: (status) {


        if (status == "done" && !_isListening && mounted && !_isNavigating && !_isSpeaking) {

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted && !_isNavigating && !_isSpeaking) {
              startListening();
            }
          });
        }
      },
      onError: (error) {

        if (mounted) {
          setState(() => _isListening = false);

          if (!_isNavigating && !_isSpeaking) {

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && !_isNavigating && !_isSpeaking) {
                startListening();
              }
            });
          }
        }
      },
    );

    if (!available) {


      if (!_isNavigating && !_isSpeaking) {

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isNavigating && !_isSpeaking) {
            startListening();
          }
        });
      }
      return;
    }


    bool micReady = await MicrophoneManager.initializeMicrophone(
      speech: _speech,
      context: context,
      onStatusUpdate: (msg) {
        if (mounted) setState(() => _statusMessage = msg);
      },
      isUrdu: Lang.isUrdu,
    );
    
    if (!micReady) {

      return;
    }

    if (mounted) setState(() => _isListening = true);

    final localeId = Lang.isUrdu ? 'ur-PK' : 'en-US';
    
    try {

      final options = MicrophoneManager.getContinuousListenOptions(isUrdu: Lang.isUrdu);
      
      await _speech.listen(
        localeId: options['localeId'],
        onResult: (result) {
          if (result.finalResult) {
            String recognized = result.recognizedWords.toLowerCase().trim();
            if (recognized.isNotEmpty) {
              print('🎤 Recognized: $recognized');
              handleVoiceCommand(recognized);
            }
          }
        },
        listenFor: options['listenFor'],
        pauseFor: options['pauseFor'],
        cancelOnError: false,
        partialResults: false,
      );

    } catch (e) {

      if (mounted) setState(() => _isListening = false);

      if (!_isNavigating && !_isSpeaking) {

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && !_isNavigating && !_isSpeaking) {
            startListening();
          }
        });
      }
    }
  }
  
  Future<void> handleVoiceCommand(String command) async {
    await _speech.stop();
    if (mounted) setState(() => _isListening = false);
    



    if (await onCommand(command)) {
      if (mounted && !_isNavigating) startListening();
      return;
    }
    

    if (await _handleGlobalNavigation(command)) {
      return;
    }


    if (_isBackCommand(command)) {
      _goBack();
      return;
    }
    

    if (mounted && !_isNavigating) {
      await Future.delayed(const Duration(milliseconds: 500));
      startListening();
    }
  }
  
  bool _isBackCommand(String cmd) {
    return cmd.contains('back') || 
           cmd.contains('home') || 
           cmd.contains('wapis') || 
           cmd.contains('wapas') || 
           cmd.contains('peechay') || 
           cmd.contains('peeche') || 
           cmd.contains('واپس') ||
           cmd.contains('return') ||
           cmd.contains('exit');
  }
  
  Future<bool> _handleGlobalNavigation(String cmd) async {

    if (cmd.contains('dashboard') || 
        cmd.contains('ڈیش بورڈ') || 
        cmd.contains('main menu') || 
        cmd.contains('home')) {
      _navigateTo(() => DashboardScreen(), Lang.isUrdu ? "ڈیش بورڈ" : "Dashboard");
      return true;
    }


    if (cmd.contains('guide') || 
        cmd.contains('گائیڈ') || 
        cmd.contains('help') || 
        cmd.contains('mdad') || // phonetic
        cmd.contains('مدد') ||
        (cmd.contains('go to') && cmd.contains('guide'))) {

       if (widget is GuidePage) return false;
       _navigateTo(() => GuidePage(), Lang.isUrdu ? "گائیڈ" : "Guide");
       return true;
    }


    if (cmd.contains('saved') || 
        cmd.contains('history') || 
        cmd.contains('mahfooz') || // phonetic
        cmd.contains('محفوظ') ||
        (cmd.contains('go to') && cmd.contains('routes'))) {
       if (widget is SavedRoutesPage) return false;
       _navigateTo(() => SavedRoutesPage(), Lang.isUrdu ? "محفوظ راستے" : "Saved Routes");
       return true;
    }


    if (cmd.contains('navigation') || 
        cmd.contains('map') || 
        cmd.contains('nav') ||
        cmd.contains('rasta') ||
        cmd.contains('نیویگیشن') || 
        cmd.contains('راستہ') ||
        (cmd.contains('go to') && cmd.contains('nav'))) {
       if (widget is NavigationPage) return false;
       _navigateTo(() => NavigationPage(), Lang.isUrdu ? "نیویگیشن" : "Navigation");
       return true;
    }


    if (cmd.contains('camera') || 
        cmd.contains('object') || 
        cmd.contains('detect') || 
        cmd.contains('کیمرہ') || 
        cmd.contains('آبجیکٹ') ||
        (cmd.contains('go to') && cmd.contains('camera'))) {

       if (widget is ObjectDetectionPage) return false;
       _navigateTo(() => ObjectDetectionPage(), Lang.isUrdu ? "آبجیکٹ ڈیٹیکشن" : "Object Detection");
       return true;
    }


    if (cmd.contains('setting') || 
        cmd.contains('سیٹنگ') ||
        (cmd.contains('go to') && cmd.contains('setting'))) {
       if (widget is SettingsPage) return false;
       _navigateTo(() => SettingsPage(), Lang.isUrdu ? "سیٹنگز" : "Settings");
       return true;
    }
    

    if (cmd.contains('profile') || 
        cmd.contains('account') ||
        cmd.contains('پروفائل') ||
        (cmd.contains('go to') && cmd.contains('profile'))) {
       if (widget is ProfileScreen) return false;
       _navigateTo(() => ProfileScreen(), Lang.isUrdu ? "پروفائل" : "Profile");
       return true;
    }
    
    return false;
  }
  
      
  Future<void> _navigateTo(Widget Function() pageBuilder, String destinationName) async {
    _isNavigating = true;
    await stopVoice();
    

    String msg = Lang.isUrdu 
       ? "$destinationName ${Lang.t('opening')}..." 
       : "Opening $destinationName...";
       
    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => pageBuilder()),
      );
    }
  }
  
  Future<void> _goBack() async {
    _isNavigating = true;
    await stopVoice();
    
    String msg = Lang.isUrdu ? "واپس جا رہے ہیں..." : "Returning...";
    await VoiceManager.safeSpeak(flutterTts, msg);
    await flutterTts.awaitSpeakCompletion(true);
    
    if (mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        // If can't pop, we must be at root or equivalent, go to dashboard
        Navigator.of(context).pushReplacement(
           MaterialPageRoute(builder: (context) => DashboardScreen())
        );
      }
    }
  }
}
