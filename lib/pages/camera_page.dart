import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:nav_aif_fyp/config/yolo_config.dart';
import 'package:nav_aif_fyp/utils/lang.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;
import '../utils/yolo_tracker.dart';

class ObjectDetectionPage extends StatefulWidget {
  const ObjectDetectionPage({Key? key}) : super(key: key);

  @override
  State<ObjectDetectionPage> createState() => _ObjectDetectionPageState();
}

class _ObjectDetectionPageState extends State<ObjectDetectionPage>
    with WidgetsBindingObserver {
  late CameraController controller;
  late FlutterVision vision;
  late ObjectDetector _objectDetector;
  late List<Map<String, dynamic>> yoloResults;
  CameraImage? cameraImage;
  bool isLoaded = false;
  bool isDetecting = false;
  String? errorMessage;
  bool _isCameraInitialized = false;
  List<Rect> mlKitResults = [];
  bool _isProcessingFrame = false;
  
  final YOLOTracker _tracker = YOLOTracker();
  int _frameCount = 0;
  double _fps = 0;
  DateTime? _lastFpsUpdate;

  final FlutterTts flutterTts = FlutterTts();
  final Map<String, int> _lastAnnouncementTime = {};
  static const int _announcementCooldown = 3000;
  String _currentLanguage = 'en-US';

  static const int _modelInputSize = 640;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    init();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!isDetecting && mounted) {
        startDetection();
      }
    }
  }

  Future<void> init() async {
    if (Platform.isIOS) return; // Native Swift handles iOS
    try {
      final cameraStatus = await Permission.camera.request();
      if (!cameraStatus.isGranted) {
        if (mounted) {
          setState(() {
            errorMessage =
                "Camera permission not granted. Please enable camera access in settings.";
          });
        }
        return;
      }

      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            errorMessage = "No cameras found on this device.";
          });
        }
        return;
      }

      vision = FlutterVision();

      controller = CameraController(
        cameras[0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await controller.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
          errorMessage = null;
        });
      }

      await loadYoloModel();
      _initMLKitDetector();
      await _initTTS();

      if (mounted) {
        setState(() {
          isLoaded = true;
          yoloResults = [];
        });
      }

      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 500));
        await startDetection();
      }

      print("✅ App initialized successfully");
    } catch (e) {
      print("❌ Initialization error: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Failed to initialize: $e";
        });
      }
    }
  }

  Future<void> _initTTS() async {
    try {
      _currentLanguage = Lang.isUrdu ? 'ur-PK' : 'en-US';
      await flutterTts.setLanguage(_currentLanguage);
      await flutterTts.setSpeechRate(0.5);
      await flutterTts.setVolume(1.0);
      await flutterTts.setPitch(1.0);
      await flutterTts.awaitSpeakCompletion(true);
      print("✅ TTS initialized with language: $_currentLanguage");
    } catch (e) {
      print("❌ TTS initialization error: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!Platform.isIOS) {
      stopDetection();
      if (controller.value.isInitialized) {
        controller.dispose();
      }
      vision.closeYoloModel();
      _objectDetector.close();
    }
    flutterTts.stop();
    super.dispose();
  }

  Future<void> loadYoloModel() async {
    try {
      print("🚀 Loading indoor_objects_model.tflite...");

      try {
        final modelData = await rootBundle.load(YoloConfig.modelPath);
        print("✅ Model file found: ${modelData.lengthInBytes ~/ 1024} KB");
      } catch (e) {
        throw Exception("Model file not found at ${YoloConfig.modelPath}");
      }

      try {
        String labelsData = await rootBundle.loadString(YoloConfig.labelsPath);
        final labelCount = labelsData
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .length;
        print("✅ Labels file loaded: $labelCount classes");
      } catch (e) {
        throw Exception("Labels file not found at ${YoloConfig.labelsPath}");
      }

      await vision.loadYoloModel(
        modelPath: YoloConfig.modelPath,
        labels: YoloConfig.labelsPath,
        modelVersion: "yolov11",
        quantization: true,
        numThreads: 2,
        useGpu: false,
      );

      print("✅ YOLO model loaded successfully");
      print("📏 Model expects ${_modelInputSize}x${_modelInputSize} input");
    } catch (e) {
      print("❌ Model loading failed: $e");
      setState(() {
        errorMessage = "Failed to load model: $e";
      });
      rethrow;
    }
  }

  Future<void> startDetection() async {
    if (!isLoaded || !_isCameraInitialized) {
      print("⚠️ Cannot start detection - not ready");
      return;
    }

    if (isDetecting) {
      print("⚠️ Detection already running");
      return;
    }

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
        await Future.delayed(const Duration(milliseconds: 100));
      }

      setState(() {
        isDetecting = true;
        yoloResults.clear();
      });

      print("🚀 Starting detection stream...");

      await controller.startImageStream((image) {
        if (isDetecting && mounted && !_isProcessingFrame) {
          cameraImage = image;
          yoloOnFrame(image);
        }
      });

      print("✅ Detection started successfully");
      await flutterTts.speak(Lang.t("detection_started"));
    } catch (e) {
      print("❌ Error starting detection: $e");
      setState(() {
        isDetecting = false;
      });
    }
  }

  Future<void> stopDetection() async {
    try {
      setState(() {
        isDetecting = false;
        yoloResults.clear();
      });

      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      await flutterTts.stop();
      print("✅ Detection stopped");
    } catch (e) {
      print("❌ Error stopping detection: $e");
    }
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    if (!isDetecting || !mounted || _isProcessingFrame) return;

    _isProcessingFrame = true;
    try {
      img.Image? convertedImage = _convertYUV420ToImage(cameraImage);
      if (convertedImage == null) return;

      img.Image resizedImage = img.copyResize(
        convertedImage,
        width: _modelInputSize,
        height: _modelInputSize,
      );

      List<int> imageBytes = img.encodeJpg(resizedImage);

      // OpenCV Enhancements
      try {
        final mat = cv.imdecode(Uint8List.fromList(imageBytes), cv.IMREAD_COLOR);
        if (!mat.isEmpty) {
          // Contrast Adjustment
          final contrast = cv.convertScaleAbs(mat, alpha: 1.2, beta: 5.0);

          // Sharpening via Unsharp Mask
          final blurred = cv.gaussianBlur(contrast, (3, 3), 1.0, sigmaY: 1.0);
          final sharpened = cv.addWeighted(contrast, 1.5, blurred, -0.5, 0.0);

          final (success, enhancedBytes) = cv.imencode('.jpg', sharpened);
          
          mat.dispose();
          contrast.dispose();
          blurred.dispose();
          sharpened.dispose();

          if (success) {
            imageBytes = enhancedBytes.toList();
            print("✨ Frame enhanced with OpenCV");
          }
        }
      } catch (e) {
        print("❌ OpenCV Enhancement Error: $e");
      }

      final result = await vision.yoloOnFrame(
        bytesList: [Uint8List.fromList(imageBytes)],
        imageHeight: _modelInputSize,
        imageWidth: _modelInputSize,
        iouThreshold: 0.8, // Handled by tracker
        confThreshold: 0.1, // Feed low-conf detections to tracker
        classThreshold: 0.1,
      );

      if (result.isNotEmpty && mounted) {
        final double cw = cameraImage.width.toDouble();
        final double ch = cameraImage.height.toDouble();

        // Convert results for tracker
        final trackerInput = result.map((r) {
          final box = r['box'];
          return {
            "box": [
              box[0] * cw / _modelInputSize,
              box[1] * ch / _modelInputSize,
              box[2] * cw / _modelInputSize,
              box[3] * ch / _modelInputSize,
              box[4]
            ],
            "tag": r['tag']
          };
        }).toList();

        final trackedResults = _tracker.processDetections(trackerInput, YoloConfig.confidenceThreshold, 'all');

        if (trackedResults.isNotEmpty) {
          print("🎯 Detected: ${trackedResults.length} objects");
          setState(() {
            yoloResults = trackedResults;
          });

          _processDetectionsForVoice(trackedResults);
        } else {
          if (yoloResults.isNotEmpty) {
            setState(() {
              yoloResults = [];
            });
          }
        }
      }
      
      if (mounted) {
        _runMLKitBounding(cameraImage, convertedImage);
      }
    } catch (e) {
      print("❌ YOLO Detection Error: $e");
    } finally {
      if (mounted) {
        _frameCount++;
        final now = DateTime.now();
        if (_lastFpsUpdate == null || now.difference(_lastFpsUpdate!).inSeconds >= 1) {
          setState(() {
            _fps = _frameCount / (now.difference(_lastFpsUpdate ?? now.subtract(const Duration(seconds: 1))).inMilliseconds / 1000.0);
            _frameCount = 0;
            _lastFpsUpdate = now;
          });
        }
      }
      _isProcessingFrame = false;
    }
  }

  void _initMLKitDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: false,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _runMLKitBounding(CameraImage image, img.Image? fullImage) async {
    try {
      int totalLen = 0;
      for (final plane in image.planes) {
        totalLen += plane.bytes.length;
      }
      final bytes = Uint8List(totalLen);
      int offset = 0;
      for (final plane in image.planes) {
        bytes.setRange(offset, offset + plane.bytes.length, plane.bytes);
        offset += plane.bytes.length;
      }

      final Size imageSize = Size(image.width.toDouble(), image.height.toDouble());
      final InputImageRotation imageRotation =
          InputImageRotationValue.fromRawValue(controller.description.sensorOrientation) ??
              InputImageRotation.rotation0deg;
      final InputImageFormat inputImageFormat =
          InputImageFormatValue.fromRawValue(image.format.raw) ?? InputImageFormat.nv21;

      final inputImage = InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: imageSize,
          rotation: imageRotation,
          format: inputImageFormat,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
      final objects = await _objectDetector.processImage(inputImage);

      List<Rect> newResults = [];
      for (final object in objects) {
        newResults.add(object.boundingBox);
      }

      if (mounted) {
        setState(() {
          mlKitResults = newResults;
        });

        if (newResults.isNotEmpty && fullImage != null) {
          newResults.sort((a, b) => (b.width * b.height).compareTo(a.width * a.height));
          final topBoxes = newResults.take(3).toList();

          List<Map<String, dynamic>> roiDetections = [];
          for (final box in topBoxes) {
            final res = await _classifyRoi(fullImage, box);
            if (res != null) {
              roiDetections.add(res);
            }
          }

          if (mounted && roiDetections.isNotEmpty) {
            setState(() {
              yoloResults = [...yoloResults, ...roiDetections];
            });
          }
        }
      }
    } catch (e) {
      print("❌ ML Kit Error: $e");
    }
  }

  Future<Map<String, dynamic>?> _classifyRoi(img.Image fullImage, Rect box) async {
    try {
      final cropped = img.copyCrop(
        fullImage,
        x: box.left.toInt(),
        y: box.top.toInt(),
        width: box.width.toInt(),
        height: box.height.toInt(),
      );

      final resizedCrop = img.copyResize(cropped, width: _modelInputSize, height: _modelInputSize);
      final cropBytes = img.encodeJpg(resizedCrop);

      final result = await vision.yoloOnFrame(
        bytesList: [Uint8List.fromList(cropBytes)],
        imageHeight: _modelInputSize,
        imageWidth: _modelInputSize,
        iouThreshold: YoloConfig.iouThreshold,
        confThreshold: YoloConfig.confidenceThreshold,
        classThreshold: YoloConfig.confidenceThreshold,
      );

      if (result.isNotEmpty && mounted) {
        final detection = result.first;
        final confidence = detection['box'][4];

        if (confidence > 0.65) {
          print("🎯 ROI Classified: ${detection['tag']} (${(confidence * 100).toStringAsFixed(1)}%)");
          _processDetectionsForVoice([Map<String, dynamic>.from(detection)]);

          final innerBox = detection['box'];
          
          double rx1 = innerBox[0] * box.width / _modelInputSize;
          double ry1 = innerBox[1] * box.height / _modelInputSize;
          double rx2 = innerBox[2] * box.width / _modelInputSize;
          double ry2 = innerBox[3] * box.height / _modelInputSize;
          
          double globalX1 = box.left + rx1;
          double globalY1 = box.top + ry1;
          double globalX2 = box.left + rx2;
          double globalY2 = box.top + ry2;

          return {
            "box": [globalX1, globalY1, globalX2, globalY2, confidence],
            "tag": detection['tag']
          };
        }
      }
    } catch (e) {
      print("❌ ROI Classification Error: $e");
    }
    return null;
  }

  img.Image? _convertYUV420ToImage(CameraImage image) {
    try {
      final int width = image.width;
      final int height = image.height;

      final yPlane = image.planes[0];
      final uPlane = image.planes[1];
      final vPlane = image.planes[2];

      final yBytes = yPlane.bytes;
      final uBytes = uPlane.bytes;
      final vBytes = vPlane.bytes;

      final int yRowStride = yPlane.bytesPerRow;
      final int uvRowStride = uPlane.bytesPerRow;
      final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

      final img.Image output = img.Image(width: width, height: height);

      for (int h = 0; h < height; h++) {
        final int uvRow = h ~/ 2;
        final int uvRowOffset = uvRow * uvRowStride;

        for (int w = 0; w < width; w++) {
          final int uvCol = w ~/ 2;
          final int uvOffset = uvRowOffset + uvCol * uvPixelStride;

          final int yIdx = (h * yRowStride) + w;
          final int uvIdx = uvOffset;

          final int y = yBytes[yIdx].toInt();
          final int u = uBytes[uvIdx].toInt() - 128;
          final int v = vBytes[uvIdx].toInt() - 128;

          int r = (y + (1.402 * v)).round();
          int g = (y - (0.344 * u) - (0.714 * v)).round();
          int b = (y + (1.772 * u)).round();

          r = r.clamp(0, 255);
          g = g.clamp(0, 255);
          b = b.clamp(0, 255);

          output.setPixelRgb(w, h, r, g, b);
        }
      }

      return output;
    } catch (e) {
      print("❌ Image conversion error: $e");
      return null;
    }
  }

  void _processDetectionsForVoice(List<Map<String, dynamic>> results) async {
    if (!mounted || cameraImage == null || results.isEmpty) return;

    try {
      results.sort(
          (a, b) => (b['box'][4] as double).compareTo(a['box'][4] as double));

      var topResult = results.first;
      String tag = topResult['tag'];
      double confidence = topResult['box'][4];
      List<dynamic> box = topResult['box'];

      if (confidence >= YoloConfig.confidenceThreshold) {
        int currentTime = DateTime.now().millisecondsSinceEpoch;
        int lastTime = _lastAnnouncementTime[tag] ?? 0;

        if (currentTime - lastTime > _announcementCooldown) {
          _lastAnnouncementTime[tag] = currentTime;

          String localizedName = Lang.t(tag);

          double imageWidth = cameraImage!.height.toDouble();
          double imageHeight = cameraImage!.width.toDouble();

          double centerX = (box[0] + box[2]) / 2;
          double objectHeight = box[3] - box[1];

          String position = _getPosition(centerX, imageWidth);
          String distance = _getDistance(objectHeight, imageHeight);

          String announcement = "$localizedName, $position, $distance";

          print("🔊 TTS: $announcement");
          await flutterTts.speak(announcement);
        }
      }
    } catch (e) {
      print("❌ Voice processing error: $e");
    }
  }

  String _getPosition(double centerX, double imageWidth) {
    if (centerX < imageWidth * 0.33) {
      return Lang.t("left");
    } else if (centerX > imageWidth * 0.66) {
      return Lang.t("right");
    } else {
      return Lang.t("center");
    }
  }

  String _getDistance(double objectHeight, double imageHeight) {
    double heightRatio = objectHeight / imageHeight;
    if (heightRatio > 0.4) {
      return Lang.t("near");
    } else if (heightRatio < 0.1) {
      return Lang.t("very_far");
    } else {
      return Lang.t("far");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: UiKitView(
          viewType: 'native_object_detection_view',
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                Text(errorMessage!,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      errorMessage = null;
                      isLoaded = false;
                    });
                    init();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!isLoaded || !_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 24),
              Text('Loading indoor object detection model...',
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );
    }

    final Size screen = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller.value.isInitialized)
            SizedBox(
              width: screen.width,
              height: screen.height,
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: screen.width,
                  height: screen.height,
                  child: CameraPreview(controller),
                ),
              ),
            ),
          if (isDetecting)
            Positioned(
              top: 40,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "LIVE",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ...displayBoxesAroundRecognizedObjects(screen),
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "FPS: ${_fps.toStringAsFixed(1)}",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "Objects: ${yoloResults.length}",
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (isDetecting) {
                    stopDetection();
                  } else {
                    startDetection();
                  }
                },
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDetecting ? Colors.red : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: (isDetecting ? Colors.red : Colors.white)
                            .withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    isDetecting ? Icons.stop : Icons.play_arrow,
                    color: isDetecting ? Colors.white : Colors.black,
                    size: 45,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty || cameraImage == null) return [];
    if (!controller.value.isInitialized) return [];

    try {
      // Get raw camera image dimensions
      final double cameraWidth = cameraImage!.width.toDouble();
      final double cameraHeight = cameraImage!.height.toDouble();
      
      // Get screen dimensions
      final double screenWidth = screen.width;
      final double screenHeight = screen.height;
      
      // Calculate scaling factors for portrait mode
      // The camera image is in landscape orientation (width > height)
      // For portrait display, we rotate 90 degrees clockwise
      final double scaleX = screenWidth / cameraHeight;
      final double scaleY = screenHeight / cameraWidth;
      
      final List<Widget> widgets = [];

      widgets.addAll(yoloResults.map((result) {
        try {
          final box = result["box"];
          final tag = result["tag"] ?? "unknown";
          final double confidence = box[4] ?? 0.0;
          final localizedTag = Lang.t(tag);

          // Get bounding box coordinates in camera image space
          // box[0] = x1, box[1] = y1, box[2] = x2, box[3] = y2
          double x1 = box[0].toDouble();
          double y1 = box[1].toDouble();
          double x2 = box[2].toDouble();
          double y2 = box[3].toDouble();
          
          // Validate coordinates
          x1 = x1.clamp(0, cameraWidth);
          y1 = y1.clamp(0, cameraHeight);
          x2 = x2.clamp(0, cameraWidth);
          y2 = y2.clamp(0, cameraHeight);
          
          // Ensure x1 <= x2 and y1 <= y2
          if (x1 > x2) {
            double temp = x1;
            x1 = x2;
            x2 = temp;
          }
          if (y1 > y2) {
            double temp = y1;
            y1 = y2;
            y2 = temp;
          }
          
          // For portrait mode, we need to rotate the coordinates
          // After 90-degree clockwise rotation:
          // New X = original Y
          // New Y = cameraWidth - original X
          double screenLeft = y1 * scaleX;
          double screenTop = (cameraWidth - x2) * scaleY;
          double screenRight = y2 * scaleX;
          double screenBottom = (cameraWidth - x1) * scaleY;
          
          // Calculate dimensions
          double screenBoxWidth = screenRight - screenLeft;
          double screenBoxHeight = screenBottom - screenTop;
          
          // Validate box dimensions
          if (screenBoxWidth <= 0 || screenBoxHeight <= 0) {
            return const SizedBox.shrink();
          }
          
          // Determine box color based on confidence
          Color boxColor;
          if (confidence > 0.7) {
            boxColor = Colors.greenAccent;
          } else if (confidence > 0.55) {
            boxColor = Colors.orangeAccent;
          } else {
            boxColor = Colors.yellowAccent;
          }
          
          return Positioned(
            left: screenLeft,
            top: screenTop,
            width: screenBoxWidth,
            height: screenBoxHeight,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: boxColor,
                  width: 3.0,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: boxColor.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: -2,
                    left: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: boxColor.withOpacity(0.9),
                        borderRadius: const BorderRadius.only(
                          bottomRight: Radius.circular(10),
                          topLeft: Radius.circular(10),
                        ),
                        border: Border.all(
                          color: Colors.white,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            localizedTag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black54,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "${(confidence * 100).toStringAsFixed(0)}%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        } catch (e) {
          print("❌ Error drawing box: $e");
          return const SizedBox.shrink();
        }
      }).toList());

      return widgets;
    } catch (e) {
      print("❌ Error in displayBoxesAroundRecognizedObjects: $e");
      return [];
    }
  }
}