import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../services/face_recognition_service.dart';
import 'coordinates_translator.dart';

class FaceRecognitionPainter extends CustomPainter {
  FaceRecognitionPainter(
    this.recognitionResults,
    this.imageSize,
    this.rotation,
    this.cameraLensDirection,
  );

  final List<FaceRecognitionResult> recognitionResults;
  final Size imageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boundingBoxPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Paint landmarkPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 1.0
          ..color = Colors.green;

    for (final result in recognitionResults) {
      final face = result.face;
      final isKnown = result.isRecognized; // Updated property name

      // Set color based on recognition status
      boundingBoxPaint.color = isKnown ? Colors.green : Colors.red;

      final left = translateX(
        face!.boundingBox.left,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final top = translateY(
        face.boundingBox.top,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final right = translateX(
        face.boundingBox.right,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );
      final bottom = translateY(
        face.boundingBox.bottom,
        size,
        imageSize,
        rotation,
        cameraLensDirection,
      );

      // Draw bounding box
      canvas.drawRect(
        Rect.fromLTRB(left, top, right, bottom),
        boundingBoxPaint,
      );

      // Draw name label
      _drawNameLabel(
        canvas,
        result.personName, // Updated property name
        Offset(left, top - 10),
        isKnown ? Colors.green : Colors.red,
      );

      // Draw confidence if available
      if (result.similarity > 0) {
        // Updated property name
        _drawConfidenceLabel(
          canvas,
          result.similarity, // Updated property name
          Offset(right - 10, top - 10),
          isKnown ? Colors.green : Colors.red,
        );
      }

      // Draw facial landmarks for recognized faces
      if (isKnown) {
        _drawFacialLandmarks(canvas, face, size);
      }
    }
  }

  void _drawNameLabel(
    Canvas canvas,
    String name,
    Offset position,
    Color color,
  ) {
    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 16,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black, offset: Offset(1, 1), blurRadius: 2),
      ],
    );

    final textSpan = TextSpan(text: name, style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background
    final backgroundRect = Rect.fromLTWH(
      position.dx - 4,
      position.dy - textPainter.height - 4,
      textPainter.width + 8,
      textPainter.height + 8,
    );

    final backgroundPaint =
        Paint()
          ..color = color.withOpacity(0.8)
          ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, Radius.circular(4)),
      backgroundPaint,
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(position.dx, position.dy - textPainter.height),
    );
  }

  void _drawConfidenceLabel(
    Canvas canvas,
    double confidence,
    Offset position,
    Color color,
  ) {
    final confidenceText = '${(confidence * 100).toStringAsFixed(0)}%';

    final textStyle = TextStyle(
      color: Colors.white,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    final textSpan = TextSpan(text: confidenceText, style: textStyle);

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    // Draw background
    final backgroundRect = Rect.fromLTWH(
      position.dx - 2,
      position.dy - textPainter.height - 2,
      textPainter.width + 4,
      textPainter.height + 4,
    );

    final backgroundPaint =
        Paint()
          ..color = color.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(backgroundRect, Radius.circular(2)),
      backgroundPaint,
    );

    // Draw text
    textPainter.paint(
      canvas,
      Offset(position.dx, position.dy - textPainter.height),
    );
  }

  void _drawFacialLandmarks(Canvas canvas, Face face, Size size) {
    final Paint landmarkPaint =
        Paint()
          ..style = PaintingStyle.fill
          ..strokeWidth = 1.0
          ..color = Colors.blue;

    void paintLandmark(FaceLandmarkType type) {
      final landmark = face.landmarks[type];
      if (landmark?.position != null) {
        canvas.drawCircle(
          Offset(
            translateX(
              landmark!.position.x.toDouble(),
              size,
              imageSize,
              rotation,
              cameraLensDirection,
            ),
            translateY(
              landmark.position.y.toDouble(),
              size,
              imageSize,
              rotation,
              cameraLensDirection,
            ),
          ),
          2,
          landmarkPaint,
        );
      }
    }

    // Draw key landmarks
    paintLandmark(FaceLandmarkType.leftEye);
    paintLandmark(FaceLandmarkType.rightEye);
    paintLandmark(FaceLandmarkType.noseBase);
    paintLandmark(FaceLandmarkType.leftMouth);
    paintLandmark(FaceLandmarkType.rightMouth);
  }

  @override
  bool shouldRepaint(FaceRecognitionPainter oldDelegate) {
    return oldDelegate.imageSize != imageSize ||
        oldDelegate.recognitionResults != recognitionResults;
  }
}
