import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import '../services/database_service.dart';
import '../services/facenet_service.dart';
import '../utils/face_processor.dart';

class FaceRecognitionResult {
  final String personName;
  final bool isRecognized;
  final double similarity;
  final Face? face;
  final List<double>? embedding;

  FaceRecognitionResult({
    required this.personName,
    required this.isRecognized,
    required this.similarity,
    this.face,
    this.embedding,
  });

  @override
  String toString() {
    return 'FaceRecognitionResult(name: $personName, recognized: $isRecognized, '
        'similarity: ${similarity.toStringAsFixed(4)})';
  }
}

class FaceRecognitionService {
  static const double _recognitionThreshold = 0.7; // Match Kotlin exactly

  final FaceNetService _faceNetService;
  final DatabaseService _databaseService;
  bool _isInitialized = false;

  // Constructor that takes the existing services
  FaceRecognitionService({
    FaceNetService? faceNetService,
    DatabaseService? databaseService,
  }) : _faceNetService = faceNetService ?? FaceNetService(),
       _databaseService = databaseService ?? DatabaseService.instance;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize the existing services
      await _faceNetService.initialize();
      await _databaseService.initialize();

      _isInitialized = true;
      print('FaceRecognitionService initialized successfully');
    } catch (e) {
      print('Error initializing FaceRecognitionService: $e');
      throw e;
    }
  }

  /// Main recognition method - uses FaceProcessor and FaceNetService
  Future<List<FaceRecognitionResult>> recognizeFaces(
    InputImage inputImage,
  ) async {
    if (!_isInitialized) {
      throw StateError('Service not initialized');
    }

    try {
      // Step 1: Detect faces using FaceProcessor (same as AddPersonView)
      final faces = await FaceProcessor.detectFaces(inputImage);
      if (faces.isEmpty) {
        return [];
      }

      print('Detected ${faces.length} faces');

      // Step 2: Extract face images using FaceProcessor (same as AddPersonView)
      final faceImages = await FaceProcessor.extractFacesFromInputImage(
        inputImage,
      );
      if (faceImages.length != faces.length) {
        print(
          'Warning: Detected ${faces.length} faces but extracted ${faceImages.length} face images',
        );
      }

      final results = <FaceRecognitionResult>[];

      // Step 3: Process each extracted face
      for (int i = 0; i < faceImages.length && i < faces.length; i++) {
        try {
          final faceImage = faceImages[i];
          final face = faces[i];

          // Step 3a: Generate embedding using the existing FaceNetService
          // This ensures exact same preprocessing as AddPersonView
          final embedding = await _faceNetService.generateEmbedding(faceImage);

          // Step 3b: Validate embedding
          if (!_faceNetService.validateEmbedding(embedding)) {
            print('Invalid embedding generated for face $i');
            continue;
          }

          // Step 3c: Perform recognition
          final recognitionResult = await _performRecognition(embedding);

          results.add(
            FaceRecognitionResult(
              personName: recognitionResult?.person.name ?? 'Not recognized',
              isRecognized: recognitionResult != null,
              similarity: recognitionResult?.cosineSimilarity ?? 0.0,
              face: face,
              embedding: embedding,
            ),
          );

          // Debug output
          if (recognitionResult != null) {
            print(
              'Recognized: ${recognitionResult.person.name} with similarity ${recognitionResult.cosineSimilarity.toStringAsFixed(4)}',
            );
          } else {
            print('Face $i not recognized (similarity below threshold)');
          }
        } catch (e) {
          print('Error processing face $i: $e');
          results.add(
            FaceRecognitionResult(
              personName: 'Error',
              isRecognized: false,
              similarity: 0.0,
              face: i < faces.length ? faces[i] : null,
            ),
          );
        }
      }

      return results;
    } catch (e) {
      print('Error in recognizeFaces: $e');
      return [];
    }
  }

  /// Perform recognition using database - matches Kotlin logic exactly
  Future<PersonMatchResult?> _performRecognition(
    List<double> queryEmbedding,
  ) async {
    try {
      // Use the exact same method as Kotlin with same threshold
      final result = await _databaseService.getNearestEmbeddingPersonName(
        queryEmbedding,
        threshold: _recognitionThreshold, // 0.4 - matches Kotlin exactly
        maxResultCount: 10,
      );

      return result;
    } catch (e) {
      print('Error in recognition: $e');
      return null;
    }
  }

  /// Debug method to compare embeddings between training and recognition
  Future<void> debugEmbeddingConsistency(InputImage inputImage) async {
    print('=== Debugging Embedding Consistency ===');

    try {
      final faceImages = await FaceProcessor.extractFacesFromInputImage(
        inputImage,
      );

      for (int i = 0; i < faceImages.length; i++) {
        final faceImage = faceImages[i];

        // Generate embedding using the same service as AddPersonView
        final embedding = await _faceNetService.generateEmbedding(faceImage);

        print('Face $i embedding:');
        print('  Length: ${embedding.length}');
        print(
          '  First 5 values: ${embedding.take(5).map((v) => v.toStringAsFixed(6)).toList()}',
        );
        print(
          '  Last 5 values: ${embedding.skip(embedding.length - 5).map((v) => v.toStringAsFixed(6)).toList()}',
        );

        final magnitude = _faceNetService.cosineSimilarity(
          embedding,
          embedding,
        ); // Should be 1.0
        print(
          '  Self similarity (should be 1.0): ${magnitude.toStringAsFixed(6)}',
        );

        // Compare with database embeddings
        await _databaseService.debugEmbeddingComparison(embedding);
      }
    } catch (e) {
      print('Error in debug: $e');
    }
  }

  void dispose() {
    _faceNetService.dispose();
    _isInitialized = false;
  }
}
