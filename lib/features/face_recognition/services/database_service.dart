import 'dart:math';
import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../entities/person.dart';
import '../entities/face_embedding.dart';
import 'package:visca/objectbox.g.dart';

class DatabaseService {
  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();

  DatabaseService._();

  Store? _store;
  Box<Person>? _personBox;
  Box<FaceEmbedding>? _faceEmbeddingBox;

  Future<void> initialize() async {
    if (_store != null) return;

    final docsDir = await getApplicationDocumentsDirectory();
    _store = await openStore(directory: p.join(docsDir.path, 'objectbox'));
    _personBox = _store!.box<Person>();
    _faceEmbeddingBox = _store!.box<FaceEmbedding>();
  }

  Future<Person> addPerson(String name, String roomId) async {
    await initialize();
    final person = Person(
      name: name, // Name is the identifier
      createdAt: DateTime.now(),
      roomId: roomId,
    );
    person.id = _personBox!.put(person);
    return person;
  }

  // Fetches locally registered faces for recognition in a room
  Future<List<Person>> getLocallyRegisteredPersonsForRoom(String roomId) async {
    await initialize();
    final query = _personBox!.query(Person_.roomId.equals(roomId)).build();
    final persons = query.find();
    query.close();
    return persons;
  }

  // Check if a specific member (by name) already has a local face registration for a room
  Future<Person?> getLocalRegistrationStatus(String name, String roomId) async {
    await initialize();
    final query =
        _personBox!
            .query(
              Person_.name
                  .equals(name) // Query by name
                  .and(Person_.roomId.equals(roomId)),
            )
            .build();
    final result = query.findFirst();
    query.close();
    return result;
  }

  // deletePerson will still work fine if you pass the Person object fetched from ObjectBox
  // as it uses person.id (the ObjectBox internal ID).
  // If you wanted to delete by name + roomId, you'd query first, then remove.
  // Example:
  Future<void> deleteLocalFaceDataForMember(String name, String roomId) async {
    await initialize();
    final existingPerson = await getLocalRegistrationStatus(name, roomId);
    if (existingPerson != null) {
      // First delete all face embeddings for this person
      final embeddings = await getFaceEmbeddingsForPerson(existingPerson);
      if (embeddings.isNotEmpty) {
        _faceEmbeddingBox!.removeMany(embeddings.map((e) => e.id).toList());
      }
      // Then delete the person
      _personBox!.remove(existingPerson.id);
    }
  }

  Future<void> addFaceEmbedding(Person person, List<double> embedding) async {
    await initialize();
    final faceEmbedding = FaceEmbedding(embedding: embedding);
    faceEmbedding.person.target = person;
    _faceEmbeddingBox!.put(faceEmbedding);
  }

  Future<List<Person>> getAllPersons() async {
    await initialize();
    return _personBox!.getAll();
  }

  Future<List<FaceEmbedding>> getFaceEmbeddingsForPerson(Person person) async {
    await initialize();
    final query =
        _faceEmbeddingBox!
            .query(FaceEmbedding_.person.equals(person.id))
            .build();
    final results = query.find();
    query.close();
    return results;
  }

  /// Improved recognition following the Kotlin reference exactly
  /// This matches ImageVectorUseCase.getNearestPersonName() logic
  Future<PersonMatchResult?> getNearestEmbeddingPersonName(
    List<double> queryEmbedding, {
    double threshold = 0.4, // Match Kotlin default threshold
    int maxResultCount = 10,
  }) async {
    await initialize();

    // Convert to Float32List for ObjectBox (matching Kotlin FloatArray)
    final queryVector = Float32List.fromList(
      queryEmbedding.map((e) => e.toDouble()).toList(),
    );

    // Use the same maxResultCount strategy as Kotlin
    final query =
        _faceEmbeddingBox!
            .query(
              FaceEmbedding_.embedding.nearestNeighborsF32(
                queryVector,
                maxResultCount,
              ),
            )
            .build();

    try {
      final results = query.findWithScores();

      if (results.isEmpty) {
        print('No embeddings found in database');
        return null;
      }

      // Get the first (nearest) result - this matches Kotlin's approach
      final nearestResult = results.first;
      final nearestEmbedding = nearestResult.object;

      // Calculate cosine similarity using the EXACT same formula as Kotlin
      final cosineSimilarity = _cosineDistance(
        queryEmbedding,
        nearestEmbedding.embedding,
      );

      if (cosineSimilarity > threshold) {
        final person = nearestEmbedding.person.target;
        if (person != null) {
          return PersonMatchResult(
            person: person,
            similarity: cosineSimilarity,
            distance: nearestResult.score,
            cosineSimilarity: cosineSimilarity,
          );
        }
      } else {
        print(
          'Similarity ${cosineSimilarity.toStringAsFixed(4)} below threshold $threshold',
        );
      }

      return null;
    } finally {
      query.close();
    }
  }

  Future<PersonMatchResult?> getNearestEmbeddingPersonNameForRoom(
    List<double> queryEmbedding,
    String roomId, {
    double threshold = 0.4,
    int maxResultCount = 10,
  }) async {
    await initialize();

    // First get all persons registered in this room
    final roomPersons = await getLocallyRegisteredPersonsForRoom(roomId);

    if (roomPersons.isEmpty) {
      print('No persons registered for room: $roomId');
      return null;
    }

    print('Searching among ${roomPersons.length} persons in room: $roomId');

    // Get all face embeddings for persons in this room
    List<FaceEmbedding> roomEmbeddings = [];
    for (final person in roomPersons) {
      final personEmbeddings = await getFaceEmbeddingsForPerson(person);
      roomEmbeddings.addAll(personEmbeddings);
    }

    if (roomEmbeddings.isEmpty) {
      print('No face embeddings found for room: $roomId');
      return null;
    }

    print('Found ${roomEmbeddings.length} face embeddings in room');

    // Find the best match among room embeddings
    PersonMatchResult? bestMatch;
    double bestSimilarity = threshold;

    for (final embedding in roomEmbeddings) {
      final similarity = _cosineDistance(queryEmbedding, embedding.embedding);

      if (similarity > bestSimilarity) {
        final person = embedding.person.target;
        if (person != null) {
          bestMatch = PersonMatchResult(
            person: person,
            similarity: similarity,
            distance: 0.0, // We're not using ObjectBox nearest neighbors here
            cosineSimilarity: similarity,
          );
          bestSimilarity = similarity;
        }
      }
    }

    if (bestMatch != null) {
      print(
        'Best match in room: ${bestMatch.person.name} with similarity: ${bestMatch.similarity.toStringAsFixed(4)}',
      );
    } else {
      print('No match found above threshold $threshold in room: $roomId');
    }

    return bestMatch;
  }

  // Also add a method to get count of registered faces per room
  Future<int> getRegisteredFaceCountForRoom(String roomId) async {
    await initialize();
    final roomPersons = await getLocallyRegisteredPersonsForRoom(roomId);
    int totalEmbeddings = 0;

    for (final person in roomPersons) {
      final embeddings = await getFaceEmbeddingsForPerson(person);
      totalEmbeddings += embeddings.length;
    }

    return totalEmbeddings;
  }

  // Get list of all registered names in a room
  Future<List<String>> getRegisteredNamesInRoom(String roomId) async {
    await initialize();
    final roomPersons = await getLocallyRegisteredPersonsForRoom(roomId);
    return roomPersons.map((person) => person.name).toList();
  }

  /// Calculate cosine distance EXACTLY matching the Kotlin implementation
  /// This is the critical function that must match perfectly
  double _cosineDistance(List<double> x1, List<double> x2) {
    if (x1.length != x2.length) {
      throw ArgumentError(
        'Vectors must have the same length: ${x1.length} vs ${x2.length}',
      );
    }

    // Use the exact same variable names and logic as Kotlin
    double mag1 = 0.0;
    double mag2 = 0.0;
    double product = 0.0;

    // This loop matches the Kotlin implementation exactly
    for (int i = 0; i < x1.length; i++) {
      mag1 += x1[i] * x1[i]; // x1[i].pow(2) in Kotlin
      mag2 += x2[i] * x2[i]; // x2[i].pow(2) in Kotlin
      product += x1[i] * x2[i];
    }

    mag1 = sqrt(mag1);
    mag2 = sqrt(mag2);

    // Handle zero magnitude case
    if (mag1 == 0.0 || mag2 == 0.0) {
      return 0.0;
    }

    return product / (mag1 * mag2);
  }

  /// Verify embedding quality before storing
  bool _isValidEmbedding(List<double> embedding) {
    if (embedding.length != 512) {
      print('Invalid embedding length: ${embedding.length}, expected 512');
      return false;
    }

    // Check for all-zero embeddings
    final nonZeroCount = embedding.where((val) => val.abs() > 1e-10).length;
    if (nonZeroCount < embedding.length * 0.1) {
      print(
        'Warning: Embedding appears to be mostly zeros ($nonZeroCount non-zero values)',
      );
      return false;
    }

    // Check for reasonable value range
    final maxVal = embedding.reduce(max);
    final minVal = embedding.reduce(min);
    if (maxVal.abs() > 100 || minVal.abs() > 100) {
      print(
        'Warning: Embedding values seem unusually large (max: $maxVal, min: $minVal)',
      );
    }

    return true;
  }

  /// Enhanced addFaceEmbedding with validation
  Future<bool> addFaceEmbeddingWithValidation(
    Person person,
    List<double> embedding,
  ) async {
    if (!_isValidEmbedding(embedding)) {
      return false;
    }

    await addFaceEmbedding(person, embedding);
    print('Added embedding for ${person.name}: length=${embedding.length}');
    return true;
  }

  Future<void> deletePerson(Person person) async {
    await initialize();

    // First delete all face embeddings for this person
    final embeddings = await getFaceEmbeddingsForPerson(person);
    for (final embedding in embeddings) {
      _faceEmbeddingBox!.remove(embedding.id);
    }

    // Then delete the person
    _personBox!.remove(person.id);
  }

  Future<void> deleteAllData() async {
    await initialize();
    _faceEmbeddingBox!.removeAll();
    _personBox!.removeAll();
  }

  void close() {
    _store?.close();
    _store = null;
  }
}

/// Updated result class with more debugging information
class PersonMatchResult {
  final Person person;
  final double similarity;
  final double distance; // ObjectBox distance
  final double cosineSimilarity; // Manual cosine similarity

  PersonMatchResult({
    required this.person,
    required this.similarity,
    required this.distance,
    required this.cosineSimilarity,
  });

  @override
  String toString() {
    return 'PersonMatchResult(person: ${person.name}, '
        'cosineSimilarity: ${cosineSimilarity.toStringAsFixed(4)}, '
        'distance: ${distance.toStringAsFixed(4)})';
  }
}
