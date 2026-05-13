import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/settings.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:nav_aif_fyp/utils/voice_navigation_mixin.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with VoiceNavigationMixin {
  final TextEditingController _nameController =
      TextEditingController(text: "Alex Doe");
  String _voiceId = "Female";
  String _language = "English";
  String _navMode = "Both";
  bool _isInitialized = false;
  final List<String> savedLocations = ["Home", "Work", "Grocery", "Doctor"];

  @override
  String get pageTitle => Lang.isUrdu ? 'پروفائل' : 'Profile';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();

    final savedLang = await PreferencesManager.getLanguage();
    setState(() {
      _language = savedLang == 'ur' ? "Urdu" : "English";
      _isInitialized = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startVoiceNavigation();
    });
  }

  @override
  Future<bool> onCommand(String command) async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (!isVoiceModeEnabled) return false;

    if (command.contains('settings') || command.contains('سیٹنگز')) {
      await VoiceManager.safeSpeak(
          flutterTts, '${Lang.t('opening')} ${Lang.t('settings')}.');
      await flutterTts.awaitSpeakCompletion(true);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
      }
      return true;
    }

    return false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: const Color(0xFF0d1b2a),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        title: Text(Lang.t('profile_title')),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(Lang.t('user_info')),
          _card(
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: Lang.t('name'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2563eb)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _voiceId,
                  dropdownColor: const Color(0xFF1a2233),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: Lang.t('voice_id'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2563eb)),
                    ),
                  ),
                  items: ["Male", "Female", "System"]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _voiceId = v!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(Lang.t('preferences')),
          _card(
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: _language,
                  dropdownColor: const Color(0xFF1a2233),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: Lang.t('preferred_language'),
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: const UnderlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF2563eb)),
                    ),
                  ),
                  items: ["English", "Urdu"]
                      .map((v) => DropdownMenuItem(
                            value: v,
                            child: Text(v,
                                style: const TextStyle(color: Colors.white)),
                          ))
                      .toList(),
                  onChanged: (v) async {
                    setState(() => _language = v!);
                    if (v == "Urdu") {
                      await Lang.setLanguage('ur');
                      await PreferencesManager.setLanguage('ur');
                    } else {
                      await Lang.setLanguage('en');
                      await PreferencesManager.setLanguage('en');
                    }
                  },
                ),
                const SizedBox(height: 20),
                Text(Lang.t('preferred_nav_mode'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    )),
                const SizedBox(height: 8),
                ToggleButtons(
                  isSelected: ["Voice-only", "Haptic-only", "Both"]
                      .map((m) => _navMode == m)
                      .toList(),
                  onPressed: (index) {
                    setState(() {
                      _navMode = ["Voice-only", "Haptic-only", "Both"][index];
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  selectedColor: Colors.white,
                  fillColor: const Color(0xFF2563eb),
                  color: Colors.white60,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        Lang.t('voice_only_mode'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        Lang.t('haptic_only_mode'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        Lang.t('both_mode'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(Lang.t('saved_locations')),
          _card(
            child: Column(
              children: [
                for (var loc in savedLocations)
                  ListTile(
                    title:
                        Text(loc, style: const TextStyle(color: Colors.white)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.white60),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.white60),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  const Color(0xFF2563eb).withAlpha((0.2 * 255).round()),
              foregroundColor: const Color(0xFF2563eb),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                    color:
                        const Color(0xFF2563eb).withAlpha((0.5 * 255).round())),
              ),
            ),
            onPressed: () {},
            child: Text(Lang.t('add_location')),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Card(
      color: const Color(0xFF1a2233),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
