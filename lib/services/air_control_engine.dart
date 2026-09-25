import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'air_cursor_controller.dart';
class AirControlEngine {
  AirControlEngine._internal();

  static final AirControlEngine instance =
  AirControlEngine._internal();

  CameraController? _cameraController;
  HandLandmarkerPlugin? _handLandmarker;

  StreamSubscription<List<Hand>>? _landmarkSubscription;

  bool _isRunning = false;
  bool _isProcessingFrame = false;

  final AirCursorController _airCursorController =
      AirCursorController.instance;

  bool get isRunning => _isRunning;
  CameraController? get cameraController => _cameraController;

  Future<void> start() async {
    if (_isRunning) {
      return;
    }

    try {
      debugPrint('🟢 AIR CONTROL ENGINE STARTING...');

      final cameras = await availableCameras();

      if (cameras.isEmpty) {
        throw Exception('No camera found on this device.');
      }

      CameraDescription selectedCamera = cameras.first;

      for (final camera in cameras) {
        if (camera.lensDirection == CameraLensDirection.front) {
          selectedCamera = camera;
          break;
        }
      }

      debugPrint(
        '📷 TURIVA CAMERA: '
        '${selectedCamera.lensDirection} | '
        'SENSOR ORIENTATION: '
        '${selectedCamera.sensorOrientation}°',
      );

      _cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      _handLandmarker = HandLandmarkerPlugin.create(
        numHands: 2,
        minHandDetectionConfidence: 0.5,
        delegate: HandLandmarkerDelegate.gpu,
      );

      _airCursorController.start();

      _landmarkSubscription =
          _handLandmarker!.landmarkStream.listen(_onLandmarksDetected);

      await _cameraController!.startImageStream(
        _processCameraFrame,
      );

      _isRunning = true;

      debugPrint('🟢 AIR CONTROL ENGINE RUNNING');
    } catch (e) {
      debugPrint('🔴 AIR CONTROL ENGINE ERROR: $e');
      await stop();
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
      debugPrint(
        'Hand landmark processing error: $e',
      );
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _onLandmarksDetected(List<Hand> hands) {
    final view = PlatformDispatcher.instance.views.first;

    final screenWidth =
        view.physicalSize.width / view.devicePixelRatio;

    final screenHeight =
        view.physicalSize.height / view.devicePixelRatio;

    _airCursorController.processHands(
      hands,
      screenWidth: screenWidth,
      screenHeight: screenHeight,
    );
  }

  Future<void> stop() async {
    if (!_isRunning &&
        _cameraController == null &&
        _handLandmarker == null) {
      return;
    }

    debugPrint('🔴 AIR CONTROL ENGINE STOPPING...');

    await _landmarkSubscription?.cancel();
    _landmarkSubscription = null;

    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}

    _handLandmarker?.dispose();
    _handLandmarker = null;

    await _cameraController?.dispose();
    _cameraController = null;

    _isProcessingFrame = false;
    _isRunning = false;

    _airCursorController.stop();

    debugPrint('🔴 AIR CONTROL ENGINE STOPPED');
  }

  Future<void> dispose() async {
    await stop();
  }
}