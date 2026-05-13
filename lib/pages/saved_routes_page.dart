import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nav_aif_fyp/utils/voice_navigation_mixin.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:nav_aif_fyp/services/voice_manager.dart';
import 'package:nav_aif_fyp/pages/page_four.dart';
import 'package:nav_aif_fyp/services/database_service.dart';
import 'package:nav_aif_fyp/services/microphone_manager.dart';

class SavedRoutesPage extends StatefulWidget {
  const SavedRoutesPage({super.key});

  @override
  State<SavedRoutesPage> createState() => _SavedRoutesPageState();
}

class _SavedRoutesPageState extends State<SavedRoutesPage>
    with VoiceNavigationMixin {
  @override
  String get pageTitle => Lang.isUrdu ? "محفوظ راستے" : "Saved Routes";

  final DatabaseService _dbService = DatabaseService();
 
  List<Map<dynamic, dynamic>> _savedRoutes = [];
  bool _isLoading = true;

  // Recording State
  bool _isRecording = false;
  int _recordedSteps = 0;
  List<String> _recordedInstructions = [];
  String _recordingFrom = '';
  String _recordingTo = '';
  String _recordingFromUr = '';
  String _recordingToUr = '';
  Timer? _stepTimer;

  // Deletion state
  bool _awaitingDeleteConfirmation = false;
  int? _pendingDeleteIndex;

  @override
  void initState() {
    super.initState();
    _loadRoutes();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      startVoiceNavigation();
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRoutes() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final routesMap = await _dbService.getAllRoutes();
      if (routesMap != null) {
        setState(() {
          _savedRoutes = routesMap.entries.map((e) {
            final data = Map<String, dynamic>.from(e.value as Map);
            data['id'] = e.key;
            return data;
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading routes: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getRouteName(int index) {
    if (index < 0 || index >= _savedRoutes.length) return "Unknown";
    final route = _savedRoutes[index];
    return Lang.isUrdu
        ? (route['ur'] ?? route['en'] ?? "نامعلوم راستہ")
        : (route['en'] ?? route['ur'] ?? "Unknown Route");
  }

  String _getAllRoutesForSpeaking() {
    if (_isRecording) {
      return Lang.isUrdu 
          ? "ریکارڈنگ جاری ہے۔ اب تک $_recordedSteps قدم ریکارڈ ہوئے ہیں۔" 
          : "Recording in progress. $_recordedSteps steps recorded so far.";
    }
    
    if (_savedRoutes.isEmpty) {
      return Lang.isUrdu
          ? "کوئی محفوظ راستہ نہیں ہے"
          : "No saved routes available";
    }

    String routes = '';
    if (Lang.isUrdu) {
      routes = 'آپ کے محفوظ راستے: ';
      for (int i = 0; i < _savedRoutes.length; i++) {
        routes += '${i + 1}۔ ${_getRouteName(i)}۔ ';
      }
      routes += 'کسی راستے کو حذف کرنے کے لیے "حذف راستہ" اور نمبر کہیں۔';
    } else {
      routes = 'Your saved routes: ';
      for (int i = 0; i < _savedRoutes.length; i++) {
        routes += '${i + 1}. ${_getRouteName(i)}. ';
      }
      routes += 'To delete, say "Delete route" and the number.';
    }
    return routes;
  }

  @override
  Future<void> speakPageEntry() async {
    if (!mounted) return;
    await stopVoice();
    String intro = _getAllRoutesForSpeaking();
    await _speakConfirmed(intro);
    if (mounted) startListening();
  }

  @override
  Future<bool> onCommand(String command) async {
    if (_isRecording) {
      if (command.contains("stop") || command.contains("save") || command.contains("done") || command.contains("روکیں") || command.contains("ختم")) {
        await _stopAndSaveRecording();
        return true;
      }
      // Treat other voice inputs as "audio instructions" to map along the path
      _addInstructionDuringRecording(command);
      return true;
    }

    if (_awaitingDeleteConfirmation && _pendingDeleteIndex != null) {
      if (command.contains('yes') || command.contains('ہاں') || command.contains('جی')) {
        _awaitingDeleteConfirmation = false;
        final index = _pendingDeleteIndex!;
        _pendingDeleteIndex = null;
        _deleteRoute(index);
        return true;
      } else if (command.contains('no') || command.contains('نہیں') || command.contains('منسوخ')) {
        _awaitingDeleteConfirmation = false;
        _pendingDeleteIndex = null;
        await _speakConfirmed(Lang.isUrdu ? "حذف منسوخ کر دیا گیا۔" : "Deletion cancelled.");
        if (mounted) startListening();
        return true;
      }
      return false;
    }

    if (command.contains('delete') || command.contains('حذف') || command.contains('remove')) {
      int? routeNumber = _extractRouteNumber(command);
      if (routeNumber != null && routeNumber > 0 && routeNumber <= _savedRoutes.length) {
        await _confirmDeleteRouteByVoice(routeNumber - 1);
        return true;
      }
    }

    if (command.contains('add') || command.contains('new') || command.contains('نیا') || command.contains('شامل')) {
      _showAddRouteDialog();
      return true;
    }

    return false;
  }

  int? _extractRouteNumber(String cmd) {
    if (cmd.contains('1') || cmd.contains('one') || cmd.contains('پہلا')) return 1;
    if (cmd.contains('2') || cmd.contains('two') || cmd.contains('دوسرا')) return 2;
    if (cmd.contains('3') || cmd.contains('three') || cmd.contains('تیسرا')) return 3;
    if (cmd.contains('4') || cmd.contains('four') || cmd.contains('چوتھا')) return 4;
    if (cmd.contains('5') || cmd.contains('five') || cmd.contains('پانچواں')) return 5;
    return null;
  }

  Future<void> _confirmDeleteRouteByVoice(int index) async {
    _awaitingDeleteConfirmation = true;
    _pendingDeleteIndex = index;
    String name = _getRouteName(index);
    String msg = Lang.isUrdu 
        ? "کیا آپ واقعی راستہ نمبر ${index+1} $name کو حذف کرنا چاہتے ہیں؟" 
        : "Are you sure you want to delete route number ${index+1}, $name?";
    await _speakConfirmed(msg);
    if (mounted) startListening();
  }

  void _deleteRoute(int index) async {
    final route = _savedRoutes[index];
    final routeId = route['id'];
    final routeName = _getRouteName(index);

    if (routeId != null) {
      try {
        await _dbService.deleteRoute(routeId);
      } catch (e) {
        debugPrint("Error deleting from Firebase: $e");
      }
    }

    setState(() {
      _savedRoutes.removeAt(index);
    });

    String msg = Lang.isUrdu ? '$routeName حذف کر دیا گیا۔' : '$routeName deleted.';
    await _speakConfirmed(msg);
    if (mounted) startListening();
  }

  void _showAddRouteDialog() async {
    final fromControllerEn = TextEditingController();
    final toControllerEn = TextEditingController();
    final fromControllerUr = TextEditingController();
    final toControllerUr = TextEditingController();

    await stopVoice();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2233),
        title: Text(Lang.isUrdu ? "نیا راستہ ریکارڈ کریں" : "Record New Route", style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: fromControllerEn, decoration: const InputDecoration(labelText: "From (English)", labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
              TextField(controller: toControllerEn, decoration: const InputDecoration(labelText: "To (English)", labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
              const Divider(),
              TextField(controller: fromControllerUr, decoration: const InputDecoration(labelText: "کہاں سے (اردو)", labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
              TextField(controller: toControllerUr, decoration: const InputDecoration(labelText: "کہاں تک (اردو)", labelStyle: TextStyle(color: Colors.white70)), style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(Lang.isUrdu ? "منسوخ" : "Cancel", style: const TextStyle(color: Colors.white70))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(Lang.isUrdu ? "ریکارڈ شروع کریں" : "Start Recording")),
        ],
      ),
    );

    if (result == true && mounted) {
      setState(() {
        _isRecording = true;
        _recordedSteps = 0;
        _recordedInstructions = [];
        _recordingFrom = fromControllerEn.text;
        _recordingTo = toControllerEn.text;
        _recordingFromUr = fromControllerUr.text;
        _recordingToUr = toControllerUr.text;
      });
      _startRecordingSession();
    } else {
      if (mounted) startListening();
    }
  }

  void _startRecordingSession() async {
    await stopVoice();
    String msg = Lang.isUrdu
        ? "ریکارڈنگ شروع ہو گئی ہے۔ براہ کرم چلنا شروع کریں اور موڑ آنے پر ہدایات بولیں۔"
        : "Recording started. Please start walking and speak instructions at turns.";
    await _speakConfirmed(msg);

    _stepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (mounted && _isRecording) {
        setState(() {
          _recordedSteps++;
        });
      }
    });

    if (mounted) startListening();
  }

  void _addInstructionDuringRecording(String instruction) {
    if (_isRecording) {
      setState(() {
        _recordedInstructions.add(instruction);
      });
      _speakConfirmed(Lang.isUrdu ? "ہدایت محفوظ ہو گئی۔" : "Instruction saved.");
    }
  }

  Future<void> _stopAndSaveRecording() async {
    if (!_isRecording) return;
    _stepTimer?.cancel();
    setState(() => _isRecording = false);

    final routeId = DateTime.now().millisecondsSinceEpoch.toString();
    final newRoute = {
      'id': routeId,
      'en': '$_recordingFrom to $_recordingTo',
      'ur': '$_recordingFromUr سے $_recordingToUr',
      'steps': _recordedSteps,
      'instructions': _recordedInstructions,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() => _isLoading = true);
    try {
      await _dbService.addRoute(routeId, newRoute);
      await _loadRoutes();
      await _speakConfirmed(Lang.isUrdu ? "راستہ محفوظ ہوگیا۔" : "Route saved to Firebase.");
    } catch (e) {
      debugPrint("Firebase error: $e");
      await _speakConfirmed(Lang.isUrdu ? "محفوظ کرنے میں غلطی ہوئی۔" : "Error saving to Firebase.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
    if (mounted) startListening();
  }

  // FIXED: Removed the reference to undefined '_speech' variable
  Future<void> _speakConfirmed(String text) async {
    if (!mounted) return;
    try {
      await stopVoice();  // Using stopVoice() from VoiceNavigationMixin instead
      await VoiceManager.safeSpeak(flutterTts, text);
      await flutterTts.awaitSpeakCompletion(true);
    } catch (e) {
      debugPrint("Speak Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        title: Text(pageTitle, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0d1b2a),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                if (_isRecording)
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red)),
                    child: Column(
                      children: [
                        const Row(children: [Icon(Icons.fiber_manual_record, color: Colors.red), SizedBox(width: 8), Text("RECORDING ACTIVE", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))]),
                        const SizedBox(height: 8),
                        Text("${Lang.isUrdu ? 'قدم' : 'Steps'}: $_recordedSteps", style: const TextStyle(color: Colors.white, fontSize: 18)),
                        const SizedBox(height: 8),
                        Text("${Lang.isUrdu ? 'ہدایات' : 'Instructions'}: ${_recordedInstructions.length}", style: const TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _savedRoutes.length,
                    itemBuilder: (context, index) => Card(
                      color: const Color(0xFF1a2233),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(_getRouteName(index), style: const TextStyle(color: Colors.white)),
                        subtitle: Text("${_savedRoutes[index]['steps']} steps", style: const TextStyle(color: Colors.white70)),
                        trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteRoute(index)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      floatingActionButton: _buildVoiceIndicator(),
    );
  }

  Widget? _buildVoiceIndicator() {
    if (_isRecording) {
      return FloatingActionButton.extended(
        onPressed: _stopAndSaveRecording,
        backgroundColor: Colors.red,
        icon: const Icon(Icons.stop, color: Colors.white),
        label: Text(Lang.isUrdu ? "محفوظ کریں" : "Stop & Save", style: const TextStyle(color: Colors.white)),
      );
    }
    if (isListening) {
      return FloatingActionButton(onPressed: stopVoice, backgroundColor: Colors.red, child: const Icon(Icons.mic_off, color: Colors.white));
    }
    return FloatingActionButton(onPressed: startListening, backgroundColor: const Color(0xFF2563eb), child: const Icon(Icons.mic, color: Colors.white));
  }
}