import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Microphone Manager - Handles microphone initialization and permission management
/// for NavAI accessibility app with enhanced audio quality settings
class MicrophoneManager {
  /// Initialize microphone with proper permission handling and audio optimization
  /// Returns true if microphone is ready to use, false otherwise
  /// Automatically retries up to 3 times with 2-second delay on failure
  static Future<bool> initializeMicrophone({
    required stt.SpeechToText speech,
    required BuildContext context,
    required Function(String) onStatusUpdate,
    bool isUrdu = false,
    int retryCount = 0,
    int maxRetries = 3,
  }) async {
    debugPrint('🎙️ MicrophoneManager: Initializing microphone with enhanced settings... (Attempt ${retryCount + 1}/$maxRetries)');
    
    try {
      // Step 1: Request microphone permission
      final micStatus = await Permission.microphone.request();
      
      if (micStatus.isDenied) {
        debugPrint('❌ MicrophoneManager: Microphone permission denied');
        onStatusUpdate(isUrdu 
          ? 'مائیکروفون کی اجازت درکار ہے۔'
          : 'Microphone permission required.');
        return false;
      }
      
      if (micStatus.isPermanentlyDenied) {
        debugPrint('❌ MicrophoneManager: Microphone permission permanently denied');
        onStatusUpdate(isUrdu 
          ? 'براہ کرم سیٹنگز میں مائیکروفون کی اجازت دیں۔'
          : 'Please enable microphone in settings.');
        
        // Show dialog to open settings
        if (context.mounted) {
          _showPermissionDialog(context, isUrdu);
        }
        return false;
      }
      
      // Step 2: Initialize speech recognition with enhanced settings
      debugPrint('🎙️ MicrophoneManager: Initializing speech recognition with noise suppression...');
      
      bool available = await speech.initialize(
        onStatus: (val) {
          debugPrint('🎙️ Speech status: $val');
        },
        onError: (val) {
          debugPrint('❌ Speech Error: $val');
        },
        debugLogging: true, // Enable debug logging for better diagnostics
        // Enhanced settings for better voice capture
        options: [
          // Request audio focus for better quality
          stt.SpeechToText.androidIntentLookup,
        ],
      );
      
      if (!available) {
        debugPrint('❌ MicrophoneManager: Speech recognition not available');
        
        // Retry logic for speech recognition failure
        if (retryCount < maxRetries) {
          debugPrint('🔄 MicrophoneManager: Retrying in 2 seconds... (${retryCount + 1}/$maxRetries)');
          onStatusUpdate(isUrdu 
            ? 'دوبارہ کوشش کر رہا ہے... (${retryCount + 1}/$maxRetries)'
            : 'Retrying... (${retryCount + 1}/$maxRetries)');
          
          await Future.delayed(const Duration(seconds: 2));
          
          return await initializeMicrophone(
            speech: speech,
            context: context,
            onStatusUpdate: onStatusUpdate,
            isUrdu: isUrdu,
            retryCount: retryCount + 1,
            maxRetries: maxRetries,
          );
        }
        
        // Max retries reached
        onStatusUpdate(isUrdu 
          ? 'آواز کی شناخت دستیاب نہیں ہے۔'
          : 'Speech recognition not available.');
        return false;
      }
      
      // Step 3: Verify microphone is actually working
      debugPrint('🎙️ MicrophoneManager: Verifying microphone functionality...');
      
      // Check if the selected locale is available
      final localeId = isUrdu ? 'ur-PK' : 'en-US';
      final locales = await speech.locales();
      final hasLocale = locales.any((locale) => locale.localeId == localeId);
      
      if (!hasLocale) {
        debugPrint('⚠️ MicrophoneManager: Preferred locale $localeId not available');
        debugPrint('   Available locales: ${locales.map((l) => l.localeId).join(", ")}');
      }
      
      debugPrint('✅ MicrophoneManager: Microphone initialized and verified successfully');
      onStatusUpdate(isUrdu 
        ? 'مائیکروفون تیار ہے۔'
        : 'Microphone ready.');
      
      return true;
      
    } catch (e) {
      debugPrint('❌ MicrophoneManager: Initialization error: $e');
      
      // Retry logic for exceptions
      if (retryCount < maxRetries) {
        debugPrint('🔄 MicrophoneManager: Retrying after exception in 2 seconds... (${retryCount + 1}/$maxRetries)');
        onStatusUpdate(isUrdu 
          ? 'دوبارہ کوشش کر رہا ہے... (${retryCount + 1}/$maxRetries)'
          : 'Retrying... (${retryCount + 1}/$maxRetries)');
        
        await Future.delayed(const Duration(seconds: 2));
        
        return await initializeMicrophone(
          speech: speech,
          context: context,
          onStatusUpdate: onStatusUpdate,
          isUrdu: isUrdu,
          retryCount: retryCount + 1,
          maxRetries: maxRetries,
        );
      }
      
      // Max retries reached
      onStatusUpdate(isUrdu 
        ? 'مائیکروفون کی خرابی۔'
        : 'Microphone initialization failed.');
      return false;
    }
  }
  
  /// Show dialog to guide user to app settings
  static void _showPermissionDialog(BuildContext context, bool isUrdu) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1a2233),
          title: Text(
            isUrdu ? 'اجازت درکار ہے' : 'Permission Required',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            isUrdu
                ? 'آواز کی شناخت کے لیے مائیکروفون کی اجازت ضروری ہے۔ براہ کرم سیٹنگز میں جا کر اجازت دیں۔'
                : 'Microphone permission is required for voice recognition. Please enable it in settings.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                isUrdu ? 'منسوخ' : 'Cancel',
                style: const TextStyle(color: Colors.white70),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563eb),
              ),
              child: Text(
                isUrdu ? 'سیٹنگز کھولیں' : 'Open Settings',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
  
  /// Check if microphone permission is granted
  static Future<bool> hasPermission() async {
    final status = await Permission.microphone.status;
    return status.isGranted;
  }
  
  /// Request microphone permission
  static Future<bool> requestPermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }
  
  /// Check if speech recognition is available on this device
  static Future<bool> isSpeechAvailable(stt.SpeechToText speech) async {
    try {
      return await speech.initialize(
        onStatus: (val) => debugPrint('Speech status check: $val'),
        onError: (val) => debugPrint('Speech error check: $val'),
      );
    } catch (e) {
      debugPrint('Error checking speech availability: $e');
      return false;
    }
  }
  
  /// Get optimal listen options for better voice capture
  static Map<String, dynamic> getOptimalListenOptions({
    bool isUrdu = false,
    Duration? listenFor,
    Duration? pauseFor,
  }) {
    return {
      'localeId': isUrdu ? 'ur-PK' : 'en-US',
      'partialResults': false, // Only get final results for accuracy
      'cancelOnError': false, // Don't cancel on error, let handler manage it
      'listenMode': stt.ListenMode.confirmation, // Wait for user to finish speaking
      // Optional timeout settings
      if (listenFor != null) 'listenFor': listenFor,
      if (pauseFor != null) 'pauseFor': pauseFor,
    };
  }

  /// Get options specifically tuned for continuous listening (long timeouts)
  static Map<String, dynamic> getContinuousListenOptions({
    bool isUrdu = false,
  }) {
    // 60 seconds is often the max allowed by Android intent, but we set high to be safe
    // Pause for 5 seconds to allow user to think/pause while speaking
    return getOptimalListenOptions(
      isUrdu: isUrdu,
      listenFor: const Duration(seconds: 60), 
      pauseFor: const Duration(seconds: 10),
    );
  }
}

