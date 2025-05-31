import 'dart:typed_data';
import 'package:objectbox/objectbox.dart';
import 'package:visca/features/face_recognition/entities/person.dart';

@Entity()
class FaceEmbedding {
  @Id()
  int id = 0;

  @Property(type: PropertyType.floatVector)
  @HnswIndex(dimensions: 512)
  Float32List embedding;

  final person = ToOne<Person>();

  FaceEmbedding({required List<double> embedding})
    : embedding = Float32List.fromList(embedding);
}
