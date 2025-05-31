import 'package:objectbox/objectbox.dart';

@Entity()
class Person {
  @Id()
  int id = 0;

  String name;
  DateTime createdAt;

  Person({required this.name, required this.createdAt});
}
