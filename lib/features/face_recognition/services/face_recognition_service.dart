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
  static const double _recognitionThreshold = 0.7;

  final FaceNetService _faceNetService;
  final DatabaseService _databaseService;
  bool _isInitialized = false;

  // Add room filtering
  String? _currentRoomId;

  FaceRecognitionService({
    FaceNetService? faceNetService,
    DatabaseService? databaseService,
  }) : _faceNetService = faceNetService ?? FaceNetService(),
       _databaseService = databaseService ?? DatabaseService.instance;

  Future<void> initialize({String? roomId}) async {
    if (_isInitialized && _currentRoomId == roomId) return;

    try {
      await _faceNetService.initialize();
      await _databaseService.initialize();

      _currentRoomId = roomId;
      _isInitialized = true;

      if (roomId != null) {
        final registeredCount = await _databaseService
            .getRegisteredFaceCountForRoom(roomId);
        final registeredNames = await _databaseService.getRegisteredNamesInRoom(
          roomId,
        );
        print(
          'Initialized for room: $roomId with $registeredCount face embeddings',
        );
        print('Registered names: ${registeredNames.join(", ")}');
      }
    } catch (e) {
      print('Error initializing FaceRecognitionService: $e');
      throw e;
    }
  }

  /// Main recognition method with room filtering
  Future<List<FaceRecognitionResult>> recognizeFaces(
    InputImage inputImage, {
    String? roomId,
  }) async {
    if (!_isInitialized) {
      throw StateError('Service not initialized');
    }

    // Use provided roomId or the one set during initialization
    final targetRoomId = roomId ?? _currentRoomId;

    if (targetRoomId == null) {
      throw StateError('No room ID specified for recognition');
    }

    try {
      final faces = await FaceProcessor.detectFaces(inputImage);
      if (faces.isEmpty) {
        return [];
      }

      final faceImages = await FaceProcessor.extractFacesFromInputImage(
        inputImage,
      );
      if (faceImages.length != faces.length) {
        print('Warning: Face count mismatch');
      }

      final results = <FaceRecognitionResult>[];

      for (int i = 0; i < faceImages.length && i < faces.length; i++) {
        try {
          final faceImage = faceImages[i];
          final face = faces[i];

          final embedding = await _faceNetService.generateEmbedding(faceImage);

          if (!_faceNetService.validateEmbedding(embedding)) {
            continue;
          }

          // Use room-filtered recognition
          final recognitionResult = await _performRoomFilteredRecognition(
            embedding,
            targetRoomId,
          );

          results.add(
            FaceRecognitionResult(
              personName: recognitionResult?.person.name ?? 'Not recognized',
              isRecognized: recognitionResult != null,
              similarity: recognitionResult?.cosineSimilarity ?? 0.0,
              face: face,
              embedding: embedding,
            ),
          );
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

  /// Perform recognition only within the specified room
  Future<PersonMatchResult?> _performRoomFilteredRecognition(
    List<double> queryEmbedding,
    String roomId,
  ) async {
    try {
      final result = await _databaseService
          .getNearestEmbeddingPersonNameForRoom(
            queryEmbedding,
            roomId,
            threshold: _recognitionThreshold,
            maxResultCount: 10,
          );

      return result;
    } catch (e) {
      print('Error in room-filtered recognition: $e');
      return null;
    }
  }

  // Get room statistics
  Future<Map<String, dynamic>> getRoomStats(String roomId) async {
    await _databaseService.initialize();

    final registeredPersons = await _databaseService
        .getLocallyRegisteredPersonsForRoom(roomId);
    final totalEmbeddings = await _databaseService
        .getRegisteredFaceCountForRoom(roomId);
    final registeredNames = await _databaseService.getRegisteredNamesInRoom(
      roomId,
    );

    return {
      'roomId': roomId,
      'registeredPersons': registeredPersons.length,
      'totalEmbeddings': totalEmbeddings,
      'registeredNames': registeredNames,
    };
  }

  void dispose() {
    _faceNetService.dispose();
    _isInitialized = false;
    _currentRoomId = null;
  }
}
