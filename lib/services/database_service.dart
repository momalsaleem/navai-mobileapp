import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  // Explicitly passing the database URL because the project is in the asia-southeast1 region
  final DatabaseReference _dbRef = FirebaseDatabase.instanceFor(
    app: Firebase.app(),
    databaseURL: 'https://nav-ai-122d9-default-rtdb.asia-southeast1.firebasedatabase.app'
  ).ref();

  // Add a new user to "users/"
  Future<void> addUser(String userId, Map<String, dynamic> userData) async {
    try {
      await _dbRef.child('users').child(userId).set(userData);
      print('User added successfully: $userId');
    } catch (e) {
      print('Error adding user: $e');
      rethrow;
    }
  }

  // Add a new route with nested waypoints to "routes/"
  Future<void> addRoute(String routeId, Map<String, dynamic> routeData) async {
    try {
      await _dbRef.child('routes').child(routeId).set(routeData);
      print('Route added successfully: $routeId');
    } catch (e) {
      print('Error adding route: $e');
      rethrow;
    }
  }

  // Delete a route from "routes/"
  Future<void> deleteRoute(String routeId) async {
    try {
      await _dbRef.child('routes').child(routeId).remove();
      print('Route deleted successfully: $routeId');
    } catch (e) {
      print('Error deleting route: $e');
      rethrow;
    }
  }

  // Read all routes from the database
  Future<Map<dynamic, dynamic>?> getAllRoutes() async {
    try {
      final snapshot = await _dbRef.child('routes').get();
      if (snapshot.exists) {
        return snapshot.value as Map<dynamic, dynamic>;
      } else {
        print('No routes available.');
        return null;
      }
    } catch (e) {
      print('Error reading routes: $e');
      rethrow;
    }
  }

  // Listen for real-time updates on routes
  Stream<DatabaseEvent> getRoutesStream() {
    return _dbRef.child('routes').onValue;
  }

  // Save a navigation recording in "recordings/"
  Future<void> saveRecording(String recordingId, Map<String, dynamic> recordingData) async {
    try {
      await _dbRef.child('recordings').child(recordingId).set(recordingData);
      print('Recording saved successfully: $recordingId');
    } catch (e) {
      print('Error saving recording: $e');
      rethrow;
    }
  }
}
