import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceNetService {
  static const int embeddingDim = 512;
  static const int inputImageSize = 160;

  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Match Kotlin interpreter options exactly
      final options =
          InterpreterOptions()
            ..threads = 4
            ..useNnApiForAndroid = true;

      _interpreter = await Interpreter.fromAsset(
        'assets/facenet_512.tflite',
        options: options,
      );

      _isInitialized = true;
      print('FaceNet model loaded successfully');
      print('Input shape: ${_interpreter!.getInputTensor(0).shape}');
      print('Output shape: ${_interpreter!.getOutputTensor(0).shape}');
    } catch (e) {
      print('Error loading FaceNet model: $e');
      throw e;
    }
  }

  Future<List<double>> generateEmbedding(img.Image faceImage) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Resize image using bilinear interpolation (matches Kotlin ResizeOp.BILINEAR)
    final resizedImage = img.copyResize(
      faceImage,
      width: inputImageSize,
      height: inputImageSize,
      interpolation: img.Interpolation.linear, // This matches BILINEAR
    );

    // Convert to the exact format expected by TensorFlow Lite
    final inputBuffer = _convertImageToByteBuffer(resizedImage);

    // Run inference
    final output = [List.filled(embeddingDim, 0.0)];
    _interpreter!.run(inputBuffer, output);

    return output[0].cast<double>();
  }

  /// Converts img.Image to ByteBuffer exactly matching Kotlin preprocessing
  ByteBuffer _convertImageToByteBuffer(img.Image image) {
    // Create ByteBuffer with exact size: 1 * height * width * 3 * 4 bytes per float
    final byteData = ByteData(1 * inputImageSize * inputImageSize * 3 * 4);

    // Extract pixel values in row-major order exactly like Kotlin
    final pixelValues = <double>[];

    // Process pixels in row-major order (y, x) - this is critical
    for (int y = 0; y < inputImageSize; y++) {
      for (int x = 0; x < inputImageSize; x++) {
        final pixel = image.getPixel(x, y);
        // Extract RGB values in 0-255 range
        pixelValues.add(pixel.r.toDouble());
        pixelValues.add(pixel.g.toDouble());
        pixelValues.add(pixel.b.toDouble());
      }
    }

    // Apply standardization exactly like Kotlin StandardizeOp
    final standardizedPixels = _standardizePixels(pixelValues);

    // Write standardized values to ByteBuffer
    for (int i = 0; i < standardizedPixels.length; i++) {
      byteData.setFloat32(i * 4, standardizedPixels[i], Endian.little);
    }

    return byteData.buffer.asByteData().buffer;
  }

  /// Standardization matching the Kotlin StandardizeOp exactly
  /// x' = (x - mean) / std_dev
  List<double> _standardizePixels(List<double> pixels) {
    // Calculate mean
    final mean = pixels.reduce((a, b) => a + b) / pixels.length;

    // Calculate variance and standard deviation
    final variance =
        pixels.map((pixel) => pow(pixel - mean, 2)).reduce((a, b) => a + b) /
        pixels.length;

    var stdDev = sqrt(variance);

    // Apply the same minimum std_dev constraint as Kotlin
    // std = max(std, 1f / sqrt(pixels.size.toFloat()))
    final minStdDev = 1.0 / sqrt(pixels.length.toDouble());
    stdDev = max(stdDev, minStdDev);

    // Apply standardization: (pixel - mean) / stdDev
    return pixels.map((pixel) => (pixel - mean) / stdDev).toList();
  }

  /// Alternative method using Float32List (simpler approach)
  Float32List _convertImageToFloat32List(img.Image image) {
    // Create buffer matching TensorFlow Lite expected format: [1, height, width, 3]
    final buffer = Float32List(1 * inputImageSize * inputImageSize * 3);

    // Extract pixel values in the correct order
    final pixelValues = <double>[];

    // Process pixels in row-major order (y, x)
    for (int y = 0; y < inputImageSize; y++) {
      for (int x = 0; x < inputImageSize; x++) {
        final pixel = image.getPixel(x, y);
        // Extract RGB values (0-255 range)
        pixelValues.add(pixel.r.toDouble());
        pixelValues.add(pixel.g.toDouble());
        pixelValues.add(pixel.b.toDouble());
      }
    }

    // Apply standardization exactly like Kotlin StandardizeOp
    final standardizedPixels = _standardizePixels(pixelValues);

    // Fill the buffer
    for (int i = 0; i < standardizedPixels.length; i++) {
      buffer[i] = standardizedPixels[i];
    }

    return buffer;
  }

  /// Debug method to verify preprocessing matches Kotlin
  void debugPreprocessing(img.Image image) {
    print('=== Debug Preprocessing ===');
    print('Original image size: ${image.width}x${image.height}');

    final resized = img.copyResize(
      image,
      width: inputImageSize,
      height: inputImageSize,
      interpolation: img.Interpolation.linear,
    );
    print('Resized image size: ${resized.width}x${resized.height}');

    // Sample a few pixels to verify values
    print('Sample pixels from resized image:');
    for (int i = 0; i < min(5, resized.width); i++) {
      final pixel = resized.getPixel(i, 0);
      print('Pixel ($i,0): R=${pixel.r}, G=${pixel.g}, B=${pixel.b}');
    }

    // Test pixel extraction order
    final pixelValues = <double>[];
    for (int y = 0; y < min(3, resized.height); y++) {
      for (int x = 0; x < min(3, resized.width); x++) {
        final pixel = resized.getPixel(x, y);
        pixelValues.addAll([
          pixel.r.toDouble(),
          pixel.g.toDouble(),
          pixel.b.toDouble(),
        ]);
      }
    }
    print('First 9 pixel values (RGB): ${pixelValues.take(9).toList()}');

    // Test standardization
    final standardized = _standardizePixels([255.0, 128.0, 0.0, 64.0, 192.0]);
    print(
      'Standardization test: ${standardized.map((v) => v.toStringAsFixed(3)).toList()}',
    );

    // Test the full preprocessing pipeline
    final buffer = _convertImageToByteBuffer(resized);
    final float32View = buffer.asFloat32List();
    print('Buffer size: ${float32View.length}');
    print(
      'First 10 values: ${float32View.take(10).map((v) => v.toStringAsFixed(3)).toList()}',
    );
    print(
      'Last 10 values: ${float32View.skip(float32View.length - 10).map((v) => v.toStringAsFixed(3)).toList()}',
    );

    // Calculate stats
    final mean = float32View.reduce((a, b) => a + b) / float32View.length;
    final variance =
        float32View.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
        float32View.length;
    print(
      'Processed data - Mean: ${mean.toStringAsFixed(6)}, Std: ${sqrt(variance).toStringAsFixed(6)}',
    );
  }

  /// Get model input/output information for debugging
  void printModelInfo() {
    if (_interpreter == null) return;

    print('=== Model Information ===');
    print('Input tensors: ${_interpreter!.getInputTensors().length}');
    print('Output tensors: ${_interpreter!.getOutputTensors().length}');

    final inputTensor = _interpreter!.getInputTensor(0);
    print('Input tensor shape: ${inputTensor.shape}');
    print('Input tensor type: ${inputTensor.type}');

    final outputTensor = _interpreter!.getOutputTensor(0);
    print('Output tensor shape: ${outputTensor.shape}');
    print('Output tensor type: ${outputTensor.type}');
  }

  /// Compare two embeddings using cosine similarity (matches Kotlin logic)
  double cosineSimilarity(List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw ArgumentError('Embeddings must have the same length');
    }

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (int i = 0; i < embedding1.length; i++) {
      dotProduct += embedding1[i] * embedding2[i];
      norm1 += embedding1[i] * embedding1[i];
      norm2 += embedding2[i] * embedding2[i];
    }

    norm1 = sqrt(norm1);
    norm2 = sqrt(norm2);

    if (norm1 == 0.0 || norm2 == 0.0) {
      return 0.0;
    }

    return dotProduct / (norm1 * norm2);
  }

  /// Validate that an embedding looks reasonable
  bool validateEmbedding(List<double> embedding) {
    if (embedding.length != embeddingDim) {
      print(
        'Invalid embedding length: ${embedding.length}, expected: $embeddingDim',
      );
      return false;
    }

    // Check for NaN or infinite values
    for (int i = 0; i < embedding.length; i++) {
      if (embedding[i].isNaN || embedding[i].isInfinite) {
        print('Invalid embedding value at index $i: ${embedding[i]}');
        return false;
      }
    }

    // Check embedding magnitude (should be reasonable)
    final magnitude = sqrt(embedding.map((v) => v * v).reduce((a, b) => a + b));
    if (magnitude < 0.1 || magnitude > 100.0) {
      print('Unusual embedding magnitude: $magnitude');
      return false;
    }

    return true;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
