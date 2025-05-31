import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:visca/features/face_recognition/camera_view.dart';
import 'package:visca/features/face_recognition/painters/face_recognition_painter.dart';
import 'package:visca/features/face_recognition/services/face_recognition_service.dart';
import 'package:visca/features/face_recognition/services/facenet_service.dart';

class FaceDetectorView extends StatefulWidget {
  @override
  State<FaceDetectorView> createState() => _FaceDetectorViewState();
}

class _FaceDetectorViewState extends State<FaceDetectorView> {
  final FaceNetService _faceNetService = FaceNetService();
  late final FaceRecognitionService _recognitionService;

  bool _canProcess = true;
  bool _isBusy = false;
  bool _isInitialized = false;
  var _cameraLensDirection = CameraLensDirection.front;
  List<FaceRecognitionResult> _results = [];

  // Add these variables for the custom painter
  Size _imageSize = Size.zero;
  InputImageRotation _rotation = InputImageRotation.rotation0deg;
  CustomPaint? _customPaint;

  @override
  void initState() {
    super.initState();
    _recognitionService = FaceRecognitionService(
      faceNetService: _faceNetService,
    );
    _initializeService();
  }

  Future<void> _initializeService() async {
    try {
      await _recognitionService.initialize();
      setState(() {
        _isInitialized = true;
      });
      print('Face recognition service initialized');
    } catch (e) {
      print('Error initializing service: $e');
    }
  }

  @override
  void dispose() {
    _canProcess = false;
    _recognitionService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraView(
            customPaint: _customPaint, // Now using the custom paint
            onImage: _processImage,
            initialCameraLensDirection: _cameraLensDirection,
            onCameraLensDirectionChanged: (value) {
              _cameraLensDirection = value;
              _updateCustomPaint(); // Update paint when camera direction changes
            },
          ),

          // Results overlay (keep your existing overlay)
          Positioned(
            left: 16,
            right: 16,
            bottom: 80,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isInitialized
                            ? Icons.check_circle
                            : Icons.hourglass_empty,
                        color: _isInitialized ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isInitialized
                            ? 'Recognition Active'
                            : 'Initializing...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Faces: ${_results.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  if (_results.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._results.asMap().entries.map((entry) {
                      final index = entry.key;
                      final result = entry.value;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          'Face ${index + 1}: ${result.personName} '
                          '(${result.similarity.toStringAsFixed(3)})',
                          style: TextStyle(
                            color:
                                result.isRecognized ? Colors.green : Colors.red,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processImage(InputImage inputImage) async {
    if (!_canProcess || _isBusy || !_isInitialized) return;

    _isBusy = true;

    try {
      final results = await _recognitionService.recognizeFaces(inputImage);

      // Update image metadata for the painter
      _imageSize = Size(
        inputImage.metadata?.size.width.toDouble() ?? 0,
        inputImage.metadata?.size.height.toDouble() ?? 0,
      );
      _rotation =
          inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;

      setState(() {
        _results = results;
        _updateCustomPaint();
      });

      print('Frame processed: ${results.length} faces detected');
      for (final result in results) {
        print(result.toString());
      }
    } catch (e) {
      print('Error processing frame: $e');
    } finally {
      _isBusy = false;
    }
  }

  void _updateCustomPaint() {
    if (_results.isNotEmpty && _imageSize != Size.zero) {
      _customPaint = _buildCustomPaint();
    } else {
      _customPaint = null;
    }
  }

  CustomPaint _buildCustomPaint() {
    return CustomPaint(
      painter: FaceRecognitionPainter(
        _results,
        _imageSize,
        _rotation,
        _cameraLensDirection,
      ),
    );
  }
}
