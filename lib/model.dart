import 'package:objectbox/objectbox.dart';

@Entity()
class Task {
  @Id()
  int id;

  String text;
  bool status;

  Task(this.text, {this.id = 0, this.status = false});

  final owner = ToOne<Owner>();

  bool setFinished() {
    status = !status;
    return status;
  }
}

@Entity()
class Owner {
  @Id()
  int id;

  String name;

  Owner(this.name, {this.id = 0});

}