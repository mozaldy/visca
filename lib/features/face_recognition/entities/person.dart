// entities/person.dart
import 'package:objectbox/objectbox.dart';

@Entity()
class Person {
  @Id()
  int id = 0; // Local ObjectBox ID

  @Index() // Good to index name if you query by it often for status checks
  String name; // Name of the member (student/attendee) - NOW THE IDENTIFIER
  DateTime createdAt; // Local registration timestamp

  @Index()
  String roomId; // Corresponds to RoomModel.id from Firebase

  Person({required this.name, required this.createdAt, required this.roomId});
}
