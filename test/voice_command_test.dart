
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_aif_fyp/services/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser Tests', () {
    
    test('Dashboard Commands - Navigation', () {
      expect(VoiceCommandParser.parseDashboardCommand('navigation'), DashboardAction.navigation);
      expect(VoiceCommandParser.parseDashboardCommand('open map'), DashboardAction.navigation);
      expect(VoiceCommandParser.parseDashboardCommand('show me directions'), DashboardAction.navigation);
      expect(VoiceCommandParser.parseDashboardCommand('راستہ دکھاؤ'), DashboardAction.navigation); // Urdu
    });

    test('Dashboard Commands - Object Detection', () {
      expect(VoiceCommandParser.parseDashboardCommand('object detection'), DashboardAction.objectDetection);
      expect(VoiceCommandParser.parseDashboardCommand('open camera'), DashboardAction.objectDetection);
      expect(VoiceCommandParser.parseDashboardCommand('detect'), DashboardAction.objectDetection);
      expect(VoiceCommandParser.parseDashboardCommand('آبجیکٹ'), DashboardAction.objectDetection); // Urdu
    });

    test('Dashboard Commands - Saved Routes', () {
      expect(VoiceCommandParser.parseDashboardCommand('saved routes'), DashboardAction.savedRoutes);
      expect(VoiceCommandParser.parseDashboardCommand('my paths'), DashboardAction.savedRoutes);
      expect(VoiceCommandParser.parseDashboardCommand('history'), DashboardAction.savedRoutes);
    });

    test('Dashboard Commands - Guide', () {
      expect(VoiceCommandParser.parseDashboardCommand('guide me'), DashboardAction.guide);
      expect(VoiceCommandParser.parseDashboardCommand('help'), DashboardAction.guide);
      expect(VoiceCommandParser.parseDashboardCommand('instruction'), DashboardAction.guide);
      expect(VoiceCommandParser.parseDashboardCommand('مدد'), DashboardAction.guide);
    });

    test('Dashboard Commands - Invalid/Numeric (Should be None)', () {
      expect(VoiceCommandParser.parseDashboardCommand('first'), DashboardAction.none, reason: "Numeric 'first' should be removed");
      expect(VoiceCommandParser.parseDashboardCommand('second'), DashboardAction.none, reason: "Numeric 'second' should be removed");
      expect(VoiceCommandParser.parseDashboardCommand('hello world'), DashboardAction.none);
    });

    test('Back Commands - Bilingual & Phonetic', () {
      // Standard English
      expect(VoiceCommandParser.isBackCommand('back'), true);
      expect(VoiceCommandParser.isBackCommand('home'), true);
      expect(VoiceCommandParser.isBackCommand('go back'), true);
      
      // Urdu
      expect(VoiceCommandParser.isBackCommand('wapas'), true); 
      expect(VoiceCommandParser.isBackCommand('بیک'), true);

      // Phonetic Misinterpretations (Crucial for Fix Verification)
      expect(VoiceCommandParser.isBackCommand('war pass'), true, reason: "Phonetic 'war pass' should be detected as Back");
      expect(VoiceCommandParser.isBackCommand('what pass'), true, reason: "Phonetic 'what pass' should be detected as Back");
      expect(VoiceCommandParser.isBackCommand('warp us'), true);
      expect(VoiceCommandParser.isBackCommand('office'), true);
      expect(VoiceCommandParser.isBackCommand('walkers'), true);
      
      // Negative Test
      expect(VoiceCommandParser.isBackCommand('random text'), false);
    });
  });
}
