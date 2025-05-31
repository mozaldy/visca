import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:image/image.dart' as img;

class FaceProcessor {
  static final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: false,
      enableLandmarks: false,
      enableClassification: false,
      enableTracking: false,
      minFaceSize: 0.1, // Match the recognition settings
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  /// Extract faces from a File (used in AddPersonView)
  static Future<List<img.Image>> extractFacesFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    print("Face detection starting for file");

    // For file-based images, we need to handle them differently
    return await extractFacesFromInputImageWithFile(inputImage, imageFile);
  }

  /// Extract faces from InputImage (used in FaceRecognitionService - camera frames)
  static Future<List<img.Image>> extractFacesFromInputImage(
    InputImage inputImage,
  ) async {
    final faces = await _faceDetector.processImage(inputImage);
    print("Face detection from camera: ${faces.length} faces found");

    if (faces.isEmpty) {
      return [];
    }

    // Convert InputImage to img.Image (for camera frames)
    final image = await _inputImageToImgImage(inputImage);
    if (image == null) {
      print("Failed to convert camera InputImage to img.Image");
      return [];
    }

    return _cropFacesFromImage(image, faces);
  }

  /// Extract faces from InputImage with File fallback (used for file-based images)
  static Future<List<img.Image>> extractFacesFromInputImageWithFile(
    InputImage inputImage,
    File imageFile,
  ) async {
    final faces = await _faceDetector.processImage(inputImage);
    print("Face detection from file: ${faces.length} faces found");

    if (faces.isEmpty) {
      return [];
    }

    // For file-based images, read the file directly
    final image = await _fileToImgImage(imageFile);
    if (image == null) {
      print("Failed to convert file to img.Image");
      return [];
    }

    return _cropFacesFromImage(image, faces);
  }

  /// Get detected faces with their bounding boxes (used in FaceRecognitionService)
  static Future<List<Face>> detectFaces(InputImage inputImage) async {
    return await _faceDetector.processImage(inputImage);
  }

  /// Crop faces from image using detected face bounding boxes
  static List<img.Image> _cropFacesFromImage(
    img.Image image,
    List<Face> faces,
  ) {
    final List<img.Image> faceImages = [];

    for (final face in faces) {
      final croppedFace = _cropSingleFace(image, face);
      if (croppedFace != null) {
        faceImages.add(croppedFace);
      }
    }

    return faceImages;
  }

  /// Crop a single face from image
  static img.Image? _cropSingleFace(img.Image image, Face face) {
    try {
      final boundingBox = face.boundingBox;

      // Add some padding around the face (can be adjusted)
      final padding = 0.0; // No padding for now, but can be increased
      final width = boundingBox.width;
      final height = boundingBox.height;
      final paddingX = (width * padding).round();
      final paddingY = (height * padding).round();

      final x = (boundingBox.left - paddingX).clamp(0, image.width - 1).round();
      final y = (boundingBox.top - paddingY).clamp(0, image.height - 1).round();
      final cropWidth =
          (width + 2 * paddingX).clamp(1, image.width - x).round();
      final cropHeight =
          (height + 2 * paddingY).clamp(1, image.height - y).round();

      // Validate crop dimensions
      if (cropWidth <= 0 || cropHeight <= 0) {
        print('Invalid crop dimensions: ${cropWidth}x$cropHeight');
        return null;
      }

      // Crop the face
      final faceImage = img.copyCrop(
        image,
        x: x,
        y: y,
        width: cropWidth,
        height: cropHeight,
      );

      return faceImage;
    } catch (e) {
      print('Error cropping face: $e');
      return null;
    }
  }

  /// Convert File to img.Image - for file-based images (AddPersonView)
  static Future<img.Image?> _fileToImgImage(File imageFile) async {
    try {
      print('Reading file: ${imageFile.path}');

      // Read file bytes directly
      final bytes = await imageFile.readAsBytes();
      print('File size: ${bytes.length} bytes');

      // Decode the image
      final image = img.decodeImage(bytes);
      if (image == null) {
        print('Failed to decode image from file');
        return null;
      }

      print('Successfully decoded image: ${image.width}x${image.height}');
      return image;
    } catch (e) {
      print('Error reading file: $e');
      return null;
    }
  }

  /// Convert InputImage to img.Image - for camera frames (FaceRecognitionService)
  static Future<img.Image?> _inputImageToImgImage(InputImage inputImage) async {
    try {
      print('Converting InputImage to img.Image');

      if (inputImage.bytes == null) {
        print(
          'InputImage bytes is null - this is normal for file-based images',
        );
        return null;
      }

      print('InputImage bytes length: ${inputImage.bytes!.length}');
      img.Image? image;

      // Handle different image formats (mainly for camera frames)
      if (inputImage.metadata?.format == InputImageFormat.yuv420) {
        print('Converting YUV420 format');
        image = _convertYuv420ToImage(inputImage);
      } else if (inputImage.metadata?.format == InputImageFormat.nv21) {
        print('Converting NV21 format');
        image = _convertNv21ToImage(inputImage);
      } else {
        print('Decoding standard image format');
        // Try to decode as standard image format (JPEG, PNG, etc.)
        image = img.decodeImage(inputImage.bytes!);
      }

      if (image == null) {
        print('Failed to decode InputImage');
        return null;
      }

      // Handle rotation based on metadata
      final rotation = inputImage.metadata?.rotation;
      if (rotation != null) {
        print('Applying rotation: $rotation');
        switch (rotation) {
          case InputImageRotation.rotation90deg:
            image = img.copyRotate(image, angle: 90);
            break;
          case InputImageRotation.rotation180deg:
            image = img.copyRotate(image, angle: 180);
            break;
          case InputImageRotation.rotation270deg:
            image = img.copyRotate(image, angle: 270);
            break;
          case InputImageRotation.rotation0deg:
            break;
        }
      }

      print(
        'Successfully converted InputImage: ${image.width}x${image.height}',
      );
      return image;
    } catch (e) {
      print('Error converting InputImage: $e');
      return null;
    }
  }

  /// Convert YUV420 to RGB - for camera frames
  static img.Image? _convertYuv420ToImage(InputImage inputImage) {
    try {
      final metadata = inputImage.metadata!;
      final width = metadata.size.width.toInt();
      final height = metadata.size.height.toInt();
      final bytes = inputImage.bytes!;

      print('Converting YUV420: ${width}x$height');

      final image = img.Image(width: width, height: height);

      final uvPixelStride = metadata.bytesPerRow ~/ width;
      final uvRowStride = metadata.bytesPerRow;

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * width + x;
          final uvIndex = uvRowStride * (y ~/ 2) + uvPixelStride * (x ~/ 2);

          if (yIndex >= bytes.length || uvIndex + 1 >= bytes.length) continue;

          final yValue = bytes[yIndex];
          final uValue = bytes[uvIndex];
          final vValue = bytes[uvIndex + 1];

          // Convert YUV to RGB
          final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
          final g =
              (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                  .clamp(0, 255)
                  .toInt();
          final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return image;
    } catch (e) {
      print('Error converting YUV420: $e');
      return null;
    }
  }

  /// Convert NV21 to RGB - for camera frames
  static img.Image? _convertNv21ToImage(InputImage inputImage) {
    try {
      print('Converting NV21 format');
      final metadata = inputImage.metadata!;
      final width = metadata.size.width.toInt();
      final height = metadata.size.height.toInt();
      final bytes = inputImage.bytes!;

      print('NV21 dimensions: ${width}x$height');

      final image = img.Image(width: width, height: height);

      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final yIndex = y * width + x;
          final uvIndex = width * height + (y ~/ 2) * width + (x & ~1);

          if (yIndex >= bytes.length || uvIndex + 1 >= bytes.length) continue;

          final yValue = bytes[yIndex];
          final vValue = bytes[uvIndex];
          final uValue = bytes[uvIndex + 1];

          // Convert YUV to RGB
          final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
          final g =
              (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
                  .clamp(0, 255)
                  .toInt();
          final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

          image.setPixelRgba(x, y, r, g, b, 255);
        }
      }

      return image;
    } catch (e) {
      print('Error converting NV21: $e');
      return null;
    }
  }

  static void dispose() {
    _faceDetector.close();
  }
}
