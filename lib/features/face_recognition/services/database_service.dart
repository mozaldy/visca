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

  Future<Person> addPerson(String name) async {
    await initialize();
    final person = Person(name: name, createdAt: DateTime.now());
    person.id = _personBox!.put(person);
    return person;
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

      print(
        'Cosine similarity: ${cosineSimilarity.toStringAsFixed(4)}, threshold: $threshold',
      );
      print('ObjectBox distance: ${nearestResult.score.toStringAsFixed(4)}');

      // Match Kotlin logic: if distance > threshold, recognize the person
      // Note: Kotlin uses > 0.4, so we use the same logic
      if (cosineSimilarity > threshold) {
        final person = nearestEmbedding.person.target;
        if (person != null) {
          print(
            'Recognized: ${person.name} with similarity ${cosineSimilarity.toStringAsFixed(4)}',
          );
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

  /// Enhanced method that returns multiple candidates for debugging
  Future<List<PersonMatchResult>> getTopEmbeddingMatches(
    List<double> queryEmbedding, {
    double threshold = 0.3,
    int maxResultCount = 10,
  }) async {
    await initialize();

    final queryVector = Float32List.fromList(
      queryEmbedding.map((e) => e.toDouble()).toList(),
    );

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
      final matches = <PersonMatchResult>[];

      for (final result in results) {
        final embedding = result.object;
        final cosineSimilarity = _cosineDistance(
          queryEmbedding,
          embedding.embedding,
        );

        final person = embedding.person.target;
        if (person != null) {
          matches.add(
            PersonMatchResult(
              person: person,
              similarity: cosineSimilarity,
              distance: result.score,
              cosineSimilarity: cosineSimilarity,
            ),
          );
        }
      }

      // Sort by cosine similarity (highest first)
      matches.sort((a, b) => b.cosineSimilarity.compareTo(a.cosineSimilarity));

      // Filter by threshold
      return matches
          .where((match) => match.cosineSimilarity > threshold)
          .toList();
    } finally {
      query.close();
    }
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

  /// Debug method to compare embeddings
  Future<void> debugEmbeddingComparison(List<double> queryEmbedding) async {
    await initialize();

    final allEmbeddings = _faceEmbeddingBox!.getAll();
    print('=== Embedding Comparison Debug ===');
    print('Query embedding length: ${queryEmbedding.length}');
    print('Query embedding first 5 values: ${queryEmbedding.take(5).toList()}');
    print(
      'Query embedding last 5 values: ${queryEmbedding.skip(queryEmbedding.length - 5).toList()}',
    );
    print('Total embeddings in database: ${allEmbeddings.length}');

    for (int i = 0; i < min(3, allEmbeddings.length); i++) {
      final embedding = allEmbeddings[i];
      final person = embedding.person.target;
      final similarity = _cosineDistance(queryEmbedding, embedding.embedding);

      print('Embedding $i (${person?.name ?? 'Unknown'}):');
      print('  Length: ${embedding.embedding.length}');
      print('  First 5: ${embedding.embedding.take(5).toList()}');
      print(
        '  Last 5: ${embedding.embedding.skip(embedding.embedding.length - 5).toList()}',
      );
      print('  Cosine similarity: ${similarity.toStringAsFixed(6)}');
    }
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
