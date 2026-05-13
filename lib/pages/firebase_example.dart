import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:nav_aif_fyp/services/database_service.dart';

class FirebaseExamplePage extends StatefulWidget {
  const FirebaseExamplePage({Key? key}) : super(key: key);

  @override
  State<FirebaseExamplePage> createState() => _FirebaseExamplePageState();
}

class _FirebaseExamplePageState extends State<FirebaseExamplePage> {
  final DatabaseService _dbService = DatabaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Example'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () async {
                await _dbService.addUser('user123', {
                  'name': 'John Doe',
                  'email': 'johndoe@example.com',
                  'role': 'user',
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User added to database!')),
                  );
                }
              },
              child: const Text('Add User'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _dbService.addRoute('route1', {
                  'name': 'Home to Office',
                  'description': 'Daily commute route',
                  'waypoints': {
                    'wp1': {'lat': 31.5204, 'lng': 74.3587, 'order': 1},
                    'wp2': {'lat': 31.5210, 'lng': 74.3590, 'order': 2},
                  },
                  'createdAt': DateTime.now().toIso8601String(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Route added to database!')),
                  );
                }
              },
              child: const Text('Add Route'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () async {
                await _dbService.saveRecording('rec1', {
                  'routeId': 'route1',
                  'duration': 120, // in seconds
                  'date': DateTime.now().toIso8601String(),
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Recording saved!')),
                  );
                }
              },
              child: const Text('Save Recording'),
            ),
            const SizedBox(height: 20),
            const Text(
              'Real-time Routes Tracker:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _dbService.getRoutesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    // Safe conversion of database nodes into a Map
                    Map mapData = snapshot.data!.snapshot.value as Map;
                    
                    return ListView.builder(
                      itemCount: mapData.length,
                      itemBuilder: (context, index) {
                        String key = mapData.keys.elementAt(index).toString();
                        Map routeData = mapData[key] as Map;
                        int waypointsCount = 0;
                        if (routeData.containsKey('waypoints') && routeData['waypoints'] is Map) {
                          waypointsCount = (routeData['waypoints'] as Map).length;
                        }
                        return Card(
                          child: ListTile(
                            title: Text(routeData['name']?.toString() ?? 'Route ($key)'),
                            subtitle: Text('Waypoints: $waypointsCount'),
                            trailing: const Icon(Icons.route),
                          ),
                        );
                      },
                    );
                  }
                  return const Center(child: Text('No routes found in database'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
