import 'dart:math';

class TrackedDetection {
  final String id;
  int lastSeen;
  double confidence;
  List<double> box;
  final String className;

  TrackedDetection({
    required this.id,
    required this.lastSeen,
    required this.confidence,
    required this.box,
    required this.className,
  });
}

class YOLOTracker {
  List<TrackedDetection> activeDetections = [];
  int frameCount = 0;

  // Confidence thresholds mapping
  final Map<String, double> priorityHouseholdItems = {
    'Chair': 0.35, 'Table': 0.35, 'Bed': 0.40, 'Sofa': 0.35,
    'Door': 0.35, 'Window': 0.40, 'Stairs': 0.30, 'Person': 0.45,
    'Laptop': 0.40, 'Computer keyboard': 0.40, 'Mobile phone': 0.35,
    'Mug': 0.30, 'Cup': 0.30, 'Bottle': 0.30, 'Book': 0.35,
    'Television': 0.40, 'Refrigerator': 0.40, 'Oven': 0.40,
    'Microwave oven': 0.40, 'Sink': 0.40, 'Toilet': 0.40
  };

  final Map<String, List<String>> contextPairs = {
    'Computer keyboard': ['Computer monitor', 'Laptop', 'Mouse'],
    'Computer monitor': ['Computer keyboard', 'Mouse'],
    'Mouse': ['Computer keyboard', 'Computer monitor', 'Laptop'],
    'Dining table': ['Chair', 'Plate', 'Bowl', 'Cup'],
    'Bed': ['Pillow', 'Blanket', 'Nightstand'],
    'Sink': ['Tap', 'Soap dispenser', 'Toothbrush'],
    'Desk': ['Laptop', 'Book', 'Pen']
  };

  final Map<String, List<String>> conflictingClasses = {
    'Chair': ['Sofa', 'Bench'],
    'Table': ['Desk', 'Dining table'],
    'Computer monitor': ['Television'],
    'Mug': ['Cup'],
    'Mobile phone': ['Tablet computer'],
  };

  final Set<String> indoorClasses = {
    'Chair', 'Table', 'Bed', 'Sofa', 'Television', 'Refrigerator', 'Oven',
    'Microwave oven', 'Sink', 'Toilet', 'Laptop', 'Computer keyboard',
    'Computer monitor', 'Mouse', 'Dining table', 'Desk', 'Pillow', 'Blanket',
    'Nightstand', 'Tap', 'Soap dispenser', 'Toothbrush', 'Mug', 'Cup',
    'Plate', 'Bowl', 'Door', 'Window', 'Stairs', 'Book', 'Pen', 'Mobile phone'
  };

  final Set<String> outdoorClasses = {
    'Car', 'Bus', 'Truck', 'Motorcycle', 'Bicycle', 'Traffic light',
    'Stop sign', 'Fire hydrant', 'Parking meter', 'Bench', 'Bird',
    'Cat', 'Dog', 'Horse', 'Sheep', 'Cow', 'Elephant', 'Bear', 'Zebra',
    'Giraffe', 'Backpack', 'Umbrella', 'Handbag', 'Tie', 'Suitcase',
    'Frisbee', 'Skis', 'Snowboard', 'Sports ball', 'Kite', 'Baseball bat',
    'Baseball glove', 'Skateboard', 'Surfboard', 'Tennis racket',
    'Airplane', 'Train', 'Boat'
  };

  final Set<String> bothClasses = {'Person', 'Potted plant'};

  double calculateIoU(List<double> boxA, List<double> boxB) {
    double xA = max(boxA[0], boxB[0]);
    double yA = max(boxA[1], boxB[1]);
    double xB = min(boxA[2], boxB[2]);
    double yB = min(boxA[3], boxB[3]);

    double interArea = max(0.0, xB - xA) * max(0.0, yB - yA);
    if (interArea == 0.0) return 0.0;

    double boxAArea = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1]);
    double boxBArea = (boxB[2] - boxB[0]) * (boxB[3] - boxB[1]);

    return interArea / (boxAArea + boxBArea - interArea);
  }

  double calculateIoA(List<double> boxA, List<double> boxB) {
    double xA = max(boxA[0], boxB[0]);
    double yA = max(boxA[1], boxB[1]);
    double xB = min(boxA[2], boxB[2]);
    double yB = min(boxA[3], boxB[3]);

    double interArea = max(0.0, xB - xA) * max(0.0, yB - yA);
    if (interArea == 0.0) return 0.0;

    double boxAArea = (boxA[2] - boxA[0]) * (boxA[3] - boxA[1]);
    return interArea / boxAArea;
  }

  List<Map<String, dynamic>> applyNMS(List<Map<String, dynamic>> detections, double iouThreshold) {
    if (detections.isEmpty) return [];

    detections.sort((a, b) => (b['box'][4] as double).compareTo(a['box'][4] as double));
    List<Map<String, dynamic>> selected = [];

    for (var det in detections) {
      bool shouldSelect = true;
      for (var sel in selected) {
        if (calculateIoU(det['box'], sel['box']) > iouThreshold) {
          shouldSelect = false;
          break;
        }
      }
      if (shouldSelect) {
        selected.add(det);
      }
    }
    return selected;
  }

  List<Map<String, dynamic>> removeDuplicates(List<Map<String, dynamic>> detections) {
    List<Map<String, dynamic>> filtered = [];
    
    for (var det in detections) {
      bool isDuplicate = false;
      for (int i = 0; i < filtered.length; i++) {
        var existing = filtered[i];
        
        if (det['tag'] == existing['tag']) {
          if (calculateIoU(det['box'], existing['box']) > 0.85) {
            isDuplicate = true;
            if (det['box'][4] > existing['box'][4]) {
              filtered[i] = det;
            }
            break;
          }
        } else {
          if (calculateIoU(det['box'], existing['box']) > 0.85 ||
              calculateIoA(det['box'], existing['box']) > 0.85 ||
              calculateIoA(existing['box'], det['box']) > 0.85) {
            
            isDuplicate = true;
            if (conflictingClasses[det['tag']]?.contains(existing['tag']) == true ||
                conflictingClasses[existing['tag']]?.contains(det['tag']) == true) {
              
              if (det['box'][4] > existing['box'][4]) {
                filtered[i] = det;
              }
              break;
            }
            
            if (det['box'][4] > existing['box'][4]) {
              filtered[i] = det;
            }
            break;
          }
        }
      }
      if (!isDuplicate) {
        filtered.add(det);
      }
    }
    return filtered;
  }

  List<Map<String, dynamic>> processDetections(List<Map<String, dynamic>> rawDetections, double baseThreshold, String filterMode) {
    frameCount++;

    // Two-pass decoding for context-awareness
    List<String> currentLabels = rawDetections.map((d) => d['tag'] as String).toList();
    
    List<Map<String, dynamic>> filtered = [];
    for (var det in rawDetections) {
      String label = det['tag'];
      double conf = det['box'][4];
      
      double dynamicThreshold = priorityHouseholdItems[label] ?? baseThreshold;
      
      if (contextPairs.containsKey(label)) {
        for (String relatedLabel in contextPairs[label]!) {
          if (currentLabels.contains(relatedLabel)) {
            dynamicThreshold *= 0.8;
            break;
          }
        }
      }

      if (filterMode == "indoor") {
        if (!indoorClasses.contains(label) && !bothClasses.contains(label)) {
          dynamicThreshold = 1.0; // Filter out
        }
      } else if (filterMode == "outdoor") {
        if (!outdoorClasses.contains(label) && !bothClasses.contains(label)) {
          dynamicThreshold = 1.0; // Filter out
        }
      }

      if (conf >= dynamicThreshold) {
        filtered.add(det);
      }
    }

    filtered = removeDuplicates(filtered);
    filtered = applyNMS(filtered, 0.45);

    // Update tracking
    List<TrackedDetection> newActive = [];
    for (var det in filtered) {
      String label = det['tag'];
      List<double> box = List<double>.from(det['box']);
      double conf = box[4];

      bool matched = false;
      for (var active in activeDetections) {
        if (active.className == label && calculateIoU(active.box, box) > 0.4) {
          active.box = [
            active.box[0] * 0.7 + box[0] * 0.3,
            active.box[1] * 0.7 + box[1] * 0.3,
            active.box[2] * 0.7 + box[2] * 0.3,
            active.box[3] * 0.7 + box[3] * 0.3,
            active.confidence * 0.5 + conf * 0.5,
          ];
          active.lastSeen = frameCount;
          active.confidence = active.box[4];
          newActive.add(active);
          matched = true;
          break;
        }
      }

      if (!matched) {
        newActive.add(TrackedDetection(
          id: "\$label-\${DateTime.now().millisecondsSinceEpoch}-\${Random().nextInt(1000)}",
          lastSeen: frameCount,
          confidence: conf,
          box: box,
          className: label,
        ));
      }
    }

    // Keep active detections that were seen recently
    for (var active in activeDetections) {
      if (frameCount - active.lastSeen < 15 && !newActive.contains(active)) {
        newActive.add(active);
      }
    }

    activeDetections = newActive;

    return activeDetections.map((track) => {
      "box": track.box,
      "tag": track.className,
      "id": track.id,
    }).toList();
  }
}
