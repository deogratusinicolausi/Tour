import 'dart:async';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';
import '../services/gesture_service.dart';
import '../services/hand_control_service.dart';
import '../services/hand_cursor_service.dart';
import '../services/air_cursor_controller.dart';
import '../services/air_control_engine.dart';

class HandControlScreen extends StatefulWidget {
  const HandControlScreen({super.key});

  @override
  State<HandControlScreen> createState() => _HandControlScreenState();
}

class _HandControlScreenState extends State<HandControlScreen> {
  CameraController? _cameraController;
  HandLandmarkerPlugin? _handLandmarker;

  StreamSubscription<List<Hand>>? _landmarkSubscription;

  bool _isInitializing = true;
  bool _isProcessingFrame = false;

  int _detectedHands = 0;
  int _detectedLandmarks = 0;
  List<Hand> _hands = [];
  final GestureService _gestureService = GestureService();
  final HandControlService _handControlService = HandControlService.instance;
  final HandCursorService _handCursorService = HandCursorService.instance;
  final AirCursorController _airCursorController = AirCursorController.instance;
  final AirControlEngine _airControlEngine = AirControlEngine.instance;

  HandGesture _currentGesture = HandGesture.none;

  String _status = 'Initializing...';
  bool _isNavigatingBack = false;

  @override
  void initState() {
    super.initState();

    _airCursorController.backRequested.addListener(
      _handleBackRequested,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _status = 'Show your hand to the camera';
      }
      );
    });
  }

  Future<void> _initializeHandControl() async {
    try {
      setState(() {
        _status = 'Finding camera...';
      });

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found on this device.');
      }

      // Prefer the front camera for hand control.
      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      setState(() {
        _status = 'Initializing hand detection...';
      });

      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.5,
        delegate: HandLandmarkerDelegate.gpu,
      );

      _airCursorController.start();

      _landmarkSubscription =
          _handLandmarker!.landmarkStream.listen(_onLandmarksDetected);

      await _cameraController!.startImageStream(_processCameraFrame);

      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _status = 'Show your hand to the camera';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _status = 'Error: $e';
      });
    }
  }

  void _processCameraFrame(CameraImage image) {
    if (_isProcessingFrame) {
      return;
    }

    if (_handLandmarker == null || _cameraController == null) {
      return;
    }

    _isProcessingFrame = true;

    try {
      _handLandmarker!.processFrame(
        image,
        _cameraController!.description.sensorOrientation,
      );
    } catch (e) {
      debugPrint('Hand landmark processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _onLandmarksDetected(List<Hand> hands) {
    if (!mounted) return;

    setState(() {
      _hands = hands;
      _detectedHands = hands.length;

      if (hands.isNotEmpty) {
        final size = MediaQuery.of(context).size;
        _airCursorController.processHands(
          hands,
          screenWidth: size.width,
          screenHeight: size.height,
        );
        debugPrint(
          '🖱️ AIR CURSOR PROCESSING: ${hands.length} hand(s)',
        );

        _handCursorService.updateFromHand(
          hands.first,
          screenWidth: size.width,
          screenHeight: size.height,
        );

        _detectedLandmarks = hands.first.landmarks.length;
        _currentGesture = _gestureService.detectGesture(hands.first);
        final isPinching = _gestureService.isPinching(hands.first);
        debugPrint(
          '🤏 PINCH: $isPinching',
        );
        _handControlService.updateGesture(_currentGesture);

        if (_currentGesture == HandGesture.fist) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop(true);
          }
        }
        _status = _gestureName(_currentGesture);
      } else {
        _detectedLandmarks = 0;
        _handCursorService.hide();
        _status = 'Show your hand to the camera';
      }
    });
  }

  String _gestureName(HandGesture gesture) {
    switch (gesture) {
      case HandGesture.openPalm:
        return '✋ Open Palm';
      case HandGesture.fist:
        return '✊ Fist';
      case HandGesture.pointing:
        return '👆 Pointing';
      case HandGesture.none:
        return 'Hand detected';
    }
  }

  void _handleBackRequested() {
    if (_isNavigatingBack) {
      return;
    }

    if (!_airCursorController.backRequested.value) {
      return;
    }

    _airCursorController.clearBackRequest();

    if (!mounted) {
      return;
    }

    _isNavigatingBack = true;
    debugPrint('✊ FIST → GOING BACK TO HOME');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    _airCursorController.backRequested.removeListener(
      _handleBackRequested,
    );
    _landmarkSubscription?.cancel();

    _cameraController?.stopImageStream();

    _handLandmarker?.dispose();

    _cameraController?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('TURIVA Hand Control'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          _buildCameraPreview(),
          _buildDetectionInfo(),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final cameraController = _airControlEngine.cameraController;

    if (cameraController == null || !cameraController.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _airControlEngine.isRunning
                  ? 'Camera is starting...'
                  : 'Starting Air Control...',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SizedBox.expand(
      child: CameraPreview(cameraController),
    );
  }

  Widget _buildDetectionInfo() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 24,
      child: ValueListenableBuilder<HandGesture>(
        valueListenable: _airCursorController.currentGesture,
        builder: (context, gesture, child) {
          return ValueListenableBuilder<int>(
            valueListenable: _airCursorController.detectedHands,
            builder: (context, hands, child) {
              return ValueListenableBuilder<int>(
                valueListenable: _airCursorController.detectedLandmarks,
                builder: (context, landmarks, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: _airCursorController.pinchDetected,
                    builder: (context, pinching, child) {
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(
                            alpha: 0.75,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _gestureName(gesture),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Hands detected: $hands',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Landmarks: $landmarks / 21',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pinch: ${pinching ? "YES 🤏" : "NO"}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class HandLandmarkPainter extends CustomPainter {
  final List<Hand> hands;

  HandLandmarkPainter({
    required this.hands,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (hands.isEmpty) return;

    final pointPaint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 4;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (final hand in hands) {
      final landmarks = hand.landmarks;

      if (landmarks.length != 21) {
        continue;
      }

      // Draw connections between landmarks.
      final connections = <List<int>>[
        // Thumb
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],

        // Index finger
        [0, 5],
        [5, 6],
        [6, 7],
        [7, 8],

        // Middle finger
        [0, 9],
        [9, 10],
        [10, 11],
        [11, 12],

        // Ring finger
        [0, 13],
        [13, 14],
        [14, 15],
        [15, 16],

        // Pinky
        [0, 17],
        [17, 18],
        [18, 19],
        [19, 20],

        // Palm
        [5, 9],
        [9, 13],
        [13, 17],
      ];

      for (final connection in connections) {
        final start = landmarks[connection[0]];
        final end = landmarks[connection[1]];

        final startOffset = Offset(start.x * size.width, start.y * size.height);
        final endOffset = Offset(end.x * size.width, end.y * size.height);

        canvas.drawLine(startOffset, endOffset, linePaint);
      }

      // Draw the 21 landmarks.
      for (int i = 0; i < landmarks.length; i++) {
        final landmark = landmarks[i];

        final offset = Offset(
          landmark.x * size.width,
          landmark.y * size.height,
        );

        canvas.drawCircle(offset, 6, pointPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandLandmarkPainter oldDelegate) {
    return oldDelegate.hands != hands;
  }
}
