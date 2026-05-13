
enum DashboardAction {
  objectDetection,
  navigation,
  savedRoutes,
  guide,
  none
}

class VoiceCommandParser {
  
  /// Parses voice input for Dashboard options
  /// Returns [DashboardAction] corresponding to the command
  static DashboardAction parseDashboardCommand(String input) {
    String normalized = input.toLowerCase().trim();
    
    // OBJECT DETECTION
    if (normalized.contains('object') || 
        normalized.contains('آبجیکٹ') ||
        normalized.contains('camera') ||
        normalized.contains('کیمرہ') ||
        normalized.contains('detect') ||
        normalized.contains('بیٹین')) {
      return DashboardAction.objectDetection;
    }
    
    // NAVIGATION
    if (normalized.contains('navigation') || 
        normalized.contains('نیویگیشن') ||
        normalized.contains('navigate') ||
        normalized.contains('map') ||
        normalized.contains('direction') ||
        normalized.contains('راستہ')) {
      return DashboardAction.navigation;
    }
    
    // SAVED ROUTES
    if (normalized.contains('saved') || 
        normalized.contains('محفوظ') ||
        normalized.contains('route') ||
        normalized.contains('راستہ') ||
        normalized.contains('path') ||
        normalized.contains('history')) {
      return DashboardAction.savedRoutes;
    }
    
    // GUIDE
    if (normalized.contains('guide') || 
        normalized.contains('گائیڈ') ||
        normalized.contains('help') ||
        normalized.contains('instruction') ||
        normalized.contains('مدد')) {
      return DashboardAction.guide;
    }
    
    return DashboardAction.none;
  }

  /// Checks if the input is a "Back" command in English or Urdu
  static bool isBackCommand(String input) {
    String normalized = input.toLowerCase().trim();
    
    final backCommands = [
      // English
      'back', 'home', 'dashboard', 'return', 'main menu', 'exit', 'go back',
      // Urdu
      'واپس', 'بیک', 'گھر', 'ہوم', 'ڈیش بورڈ', 'منیو', 'جاو', 'peeche', 'wapas',
      // Phonetic matches for "Wapas" (when heard by English STT)
      'what pass', 'war pass', 'warp us', 'office', 'what us', 'wa pass', 'wapos', 'vapors', 'wipers', 
      'purpose', 'walrus', 'walkers',
      // Phonetic matches for "Back"
      'bag', 'pack', 'beck', 'bike'
    ];
    
    return backCommands.any((cmd) => normalized.contains(cmd));
  }
}
