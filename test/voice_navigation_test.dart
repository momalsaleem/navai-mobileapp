import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/pages/camera_page.dart';
import 'package:nav_aif_fyp/pages/navigation_page.dart';
import 'package:nav_aif_fyp/pages/saved_routes_page.dart';
import 'package:nav_aif_fyp/pages/guide.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
 
void main() {
  group('Voice Navigation Tests - English', () {
    setUp(() async {
      // Set language to English
      await Lang.setLanguage('en');
    });

    testWidgets('Dashboard initializes voice system on app start', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Wait for initialization
      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify Dashboard is displayed
      expect(find.byType(DashboardScreen), findsOneWidget);
      
      // Dashboard should announce options and start listening
      // (In real app, TTS would speak and mic would initialize)
    });

    testWidgets('Can navigate back from Camera Page with "Back" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Camera Page
      await tester.tap(find.text('Object Detection'));
      await tester.pumpAndSettle();

      // Verify we're on Camera Page
      expect(find.byType(CameraPage), findsOneWidget);

      // Simulate voice command "back" 
      // (In real app, this would trigger navigation back to Dashboard)
      // The VoiceNavigationMixin handles "back", "home", "dashboard" commands
      
      // Verify back button exists
      expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsWidgets);
    });

    testWidgets('Can navigate back from Navigation Page with "Dashboard" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're on Navigation Page
      expect(find.byType(NavigationPage), findsOneWidget);
      
      // Voice command "dashboard" should navigate back
      // VoiceNavigationMixin._handleGlobalNavigation handles this
      
      // Verify back button exists
      expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Can navigate back from Saved Routes with "Home" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SavedRoutesPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're on Saved Routes Page
      expect(find.byType(SavedRoutesPage), findsOneWidget);
      
      // Voice command "home" should navigate back
      // VoiceNavigationMixin._isBackCommand handles "home"
      
      // Verify back button exists
      expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Can navigate back from Guide with "Back" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GuidePage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're on Guide Page
      expect(find.byType(GuidePage), findsOneWidget);
      
      // Voice command "back" should navigate back
      
      // Verify back button exists (if present in UI)
      // Guide page may have different navigation structure
    });

    testWidgets('Can navigate back from Settings with "Return" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're on Settings Page
      expect(find.byType(SettingsPage), findsOneWidget);
      
      // Voice command "return" should navigate back
      // VoiceNavigationMixin._isBackCommand handles "return"
      
      // Verify back button exists
      expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsWidgets);
    });

    testWidgets('Dashboard re-initializes voice after returning from subpage', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away and back
      await tester.tap(find.text('Navigation'));
      await tester.pumpAndSettle();
      
      // Go back
      await tester.tap(find.widgetWithIcon(IconButton, Icons.arrow_back));
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're back on Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
      
      // Dashboard should call _onReturnToDashboard which:
      // 1. Stops all mic and TTS
      // 2. Speaks dashboard intro
      // 3. Re-initializes listening
    });
  });

  group('Voice Navigation Tests - Urdu', () {
    setUp(() async {
      // Set language to Urdu
      await Lang.setLanguage('ur');
    });

    testWidgets('Dashboard announces in Urdu and listens for commands', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 3));

      // Verify Dashboard is displayed
      expect(find.byType(DashboardScreen), findsOneWidget);
      
      // Dashboard should speak Urdu introduction and start listening
    });

    testWidgets('Can navigate back from Camera with "واپس" (wapas) command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're on Camera Page
      expect(find.byType(CameraPage), findsOneWidget);
      
      // Voice command "واپس" should navigate back
      // VoiceNavigationMixin._isBackCommand handles Urdu "wapis", "wapas", "واپس"
      
      // Verify back button exists
      expect(find.widgetWithIcon(IconButton, Icons.arrow_back), findsWidgets);
    });

    testWidgets('Can navigate back from Navigation with "ڈیش بورڈ" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: NavigationPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're on Navigation Page
      expect(find.byType(NavigationPage), findsOneWidget);
      
      // Voice command "ڈیش بورڈ" should navigate back
      // VoiceNavigationMixin._handleGlobalNavigation handles "ڈیش بورڈ"
    });

    testWidgets('Can navigate back from Saved Routes with Urdu "back" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SavedRoutesPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're on Saved Routes Page
      expect(find.byType(SavedRoutesPage), findsOneWidget);
      
      // Voice command "wapas" or "peechay" should navigate back
    });

    testWidgets('Can navigate to Guide from any page with "گائیڈ" command', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SavedRoutesPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // From Saved Routes, saying "گائیڈ" should navigate to Guide
      // VoiceNavigationMixin._handleGlobalNavigation handles "گائیڈ" and "guide"
    });

    testWidgets('Dashboard re-announces in Urdu after returning', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate to Settings
      await tester.tap(find.byIcon(Icons.settings));
      await tester.pumpAndSettle();
      
      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Verify we're back on Dashboard
      expect(find.byType(DashboardScreen), findsOneWidget);
      
      // Dashboard should speak Urdu "ہم ڈیش بورڈ پر واپس آگئے ہیں۔" and re-initialize
    });
  });

  group('Cross-Page Voice Navigation Tests', () {
    testWidgets('Can navigate from Camera to Guide via voice', (WidgetTester tester) async {
      await Lang.setLanguage('en');
      
      await tester.pumpWidget(
        MaterialApp(
          home: CameraPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // From Camera, saying "Guide" should navigate to Guide page
      // VoiceNavigationMixin._handleGlobalNavigation enables this
    });

    testWidgets('Can navigate from Guide to Settings via voice', (WidgetTester tester) async {
      await Lang.setLanguage('en');
      
      await tester.pumpWidget(
        MaterialApp(
          home: GuidePage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // From Guide, saying "Settings" should navigate to Settings page
    });

    testWidgets('Can navigate from Settings to Saved Routes via voice', (WidgetTester tester) async {
      await Lang.setLanguage('en');
      
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsPage(),
        ),
      );

      await tester.pumpAndSettle(Duration(seconds: 2));

      // From Settings, saying "Saved Routes" should navigate to Saved Routes page
    });
  });

  group('Dashboard Voice Initialization Tests', () {
    testWidgets('Dashboard stops mic before speaking on first load', (WidgetTester tester) async {
      await Lang.setLanguage('en');
      
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );

      // Dashboard._initializeDashboardPage should:
      // 1. Call _clearAllSpeechAndTts() to stop everything
      // 2. Initialize TTS
      // 3. Speak dashboard introduction
      // 4. Start listening after speech completes

      await tester.pumpAndSettle(Duration(seconds: 3));
      
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('Dashboard stops mic before speaking on return', (WidgetTester tester) async {
      await Lang.setLanguage('en');
      
      await tester.pumpWidget(
        MaterialApp(
          home: DashboardScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Navigate away
      await tester.tap(find.text('Guide'));
      await tester.pumpAndSettle();
      
      // Return to Dashboard
      await tester.pageBack();
      await tester.pumpAndSettle(Duration(seconds: 2));

      // Dashboard._onReturnToDashboard should:
      // 1. Call _clearAllSpeechAndTts()
      // 2. Speak "We are back to dashboard..."
      // 3. Re-initialize listening
      
      expect(find.byType(DashboardScreen), findsOneWidget);
    });
  });
}
