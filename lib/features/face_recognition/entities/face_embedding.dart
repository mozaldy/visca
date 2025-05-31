import 'dart:typed_data'; // Required for Float32List
import 'package:objectbox/objectbox.dart';
import 'package:visca/features/face_recognition/entities/person.dart'; // Assuming this path is correct

@Entity()
class FaceEmbedding {
  @Id()
  int id = 0;

  @Property(type: PropertyType.floatVector)
  @HnswIndex(dimensions: 512)
  Float32List embedding; // Changed from List<double>

  final person = ToOne<Person>();

  FaceEmbedding({required List<double> embedding})
    : embedding = Float32List.fromList(embedding); // Constructor updated

  // If you need to get it back as List<double> elsewhere, you can add a getter:
  // List<double> get embeddingAsList => embedding.toList();
}
