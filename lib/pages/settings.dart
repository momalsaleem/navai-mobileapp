import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/pages/privacy.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/pages/firebase_example.dart';
import 'package:nav_aif_fyp/pages/profile.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/preferences_manager.dart';
import 'package:nav_aif_fyp/utils/voice_navigation_mixin.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> with VoiceNavigationMixin {
  bool _isInitialized = false;

  @override
  String get pageTitle => Lang.isUrdu ? 'ترتیبات' : 'Settings';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await Lang.init();
    setState(() => _isInitialized = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      startVoiceNavigation();
    });
  }

  @override
  Future<bool> onCommand(String command) async {
    final isVoiceModeEnabled = await PreferencesManager.isVoiceModeEnabled();
    if (!isVoiceModeEnabled) return false;

    if (command.contains('account') || command.contains('اکاؤنٹ')) {
      await VoiceManager.safeSpeak(
          flutterTts, '${Lang.t('opening')} ${Lang.t('account')}.');
      await flutterTts.awaitSpeakCompletion(true);

      return true;
    } else if (command.contains('privacy') || command.contains('پرائیویسی')) {
      await VoiceManager.safeSpeak(
          flutterTts, '${Lang.t('opening')} ${Lang.t('privacy')}.');
      await flutterTts.awaitSpeakCompletion(true);
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const PrivacyPage()),
        );
      }
      return true;
    } else if (command.contains('notification') ||
        command.contains('نوٹیفیکیشن')) {
      await VoiceManager.safeSpeak(
          flutterTts, '${Lang.t('opening')} ${Lang.t('notifications')}.');
      await flutterTts.awaitSpeakCompletion(true);

      return true;
    } else if (command.contains('about') || command.contains('مزید معلومات')) {
      await VoiceManager.safeSpeak(
          flutterTts, '${Lang.t('opening')} ${Lang.t('about')}.');
      await flutterTts.awaitSpeakCompletion(true);

      return true;
    }

    return false;
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
        title: Text(Lang.t('settings_title')),
        backgroundColor: const Color(0xFF0d1b2a),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _settingsCard(
                  icon: Icons.person,
                  titleKey: 'account',
                  subtitleKey: 'account_desc',
                  onTap: () async {},
                ),
                _settingsCard(
                  icon: Icons.lock,
                  titleKey: 'privacy',
                  subtitleKey: 'privacy_desc',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const PrivacyPage()),
                    );
                  },
                ),
                _settingsCard(
                  icon: Icons.notifications,
                  titleKey: 'notifications',
                  subtitleKey: 'notifications_desc',
                  onTap: () {},
                ),
                _settingsCard(
                  icon: Icons.info,
                  titleKey: 'about',
                  subtitleKey: 'about_desc',
                  onTap: () {},
                ),
                _settingsCard(
                  icon: Icons.cloud,
                  titleKey: 'Firebase Test',
                  subtitleKey: 'Test Realtime Database Connection',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const FirebaseExamplePage()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String titleKey,
    required String subtitleKey,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.05 * 255).round()),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2563eb).withAlpha((0.25 * 255).round()),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2563eb)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Lang.t(titleKey),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    Lang.t(subtitleKey),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withAlpha((0.6 * 255).round()),
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
}
