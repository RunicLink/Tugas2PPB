**1. Install Database ObjectBox**
Install database menggunakan command dibawah dan masukkan ke dalam terminal
```
flutter pub add objectbox objectbox_flutter_libs:any
flutter pub add --dev build_runner objectbox_generator:any
```

**2. Membuat Model dan Build Database**
Membuat model database dan data dummy pada ```\lib\model.dart```
```
import 'model.dart';
import 'objectbox.g.dart';
import 'package:flutter/foundation.dart';

class ObjectBox{
  late final Store store;

  late final Box<Owner> ownerBox;
  late final Box<Task> taskBox;

  ObjectBox._create(this.store){
    ownerBox = Box<Owner>(store);
    taskBox = Box<Task>(store);

    if (taskBox.isEmpty()) {
      _putDemoData();
    }
  }

  void _putDemoData() {
    Owner owner1 = Owner("John Cena");
    Owner owner2 = Owner("Tony Stark");

    Task task1 = Task('This is John\'s task');
    task1.owner.target = owner1;

    Task task2 = Task('This is Tony\'s task');
    task2.owner.target = owner2;

    taskBox.putMany([task1, task2]);
  }

  static Future<ObjectBox> create() async {
    final store = await openStore();
    return ObjectBox._create(store);
  }

  void addTask(String taskText, Owner owner){
    Task newTask = Task(taskText);
    newTask.owner.target = owner;

    taskBox.put(newTask);
    debugPrint("Task added ${newTask.text} to ${newTask.owner.target?.name}");
  }

  int addOwner(String newOwner){
    Owner ownerToAdd = Owner(newOwner);
    int newObjectId = ownerBox.put(ownerToAdd);

    return newObjectId;
  }

  Stream<List<Task>> getTasks(){
    final builder = taskBox.query()..order(Task_.id, flags: Order.descending);
    return builder.watch(triggerImmediately: true).map((query) => query.find());
  }


}
```
