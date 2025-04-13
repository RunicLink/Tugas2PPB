**1. Install Database ObjectBox**
Install database menggunakan command dibawah dan masukkan ke dalam terminal
```
flutter pub add objectbox objectbox_flutter_libs:any
flutter pub add --dev build_runner objectbox_generator:any
```

**2. Membuat Model dan Build Database**
Membuat model database dan data dummy pada ```\lib\model.dart```. Dan membuat fungsi untuk menambah task baru dan owner baru dan menyimpannya di dalam database.
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
Dan kemudian build databasenya dengan mengetikkan command berikut pada terminal
```dart run build_runner build```

**3. Membuat Task Card untuk Menampilkan Task-Task yang ada di Database**
Task Card ini menjadi component yang akan dipanggil oleh main nantinya. Dimana Task Card ini memiliki fungsi untuk menampilkan task-task dan ownernya, checkbox untuk menyatakan apakah task sudah selesai dikerjakan atau belum, dan pop up untuk menghapus task tersebut.
```
import 'package:flutter/material.dart';
import '../main.dart';
import '../model.dart';

class TaskCard extends StatefulWidget {
  final Task task;
  const TaskCard({Key? key, required this.task}) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  late bool taskStatus;

  void toggleCheckBox() {
    bool newStatus = widget.task.setFinished();
    objectbox.taskBox.put(widget.task);
    setState(() {
      taskStatus = newStatus;
    });
  }

  @override
  void initState() {
    super.initState();
    taskStatus = widget.task.status;
  }

  @override
  Widget build(BuildContext context) {
    // Always get the latest owner relation
    final Owner? currentOwner = widget.task.owner.target;

    return Container(
      height: 90,
      margin: const EdgeInsets.all(5),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 243, 243, 243),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromARGB(255, 168, 168, 168),
            blurRadius: 5,
            offset: Offset(1, 2),
          )
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: 1.3,
            child: Checkbox(
              shape: const CircleBorder(),
              value: taskStatus,
              onChanged: (bool? value) {
                toggleCheckBox();
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: taskStatus
                      ? const TextStyle(
                    fontSize: 20.0,
                    height: 1.0,
                    color: Color.fromARGB(255, 73, 73, 73),
                    decoration: TextDecoration.lineThrough,
                  )
                      : const TextStyle(
                    fontSize: 20.0,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Assigned to: ${currentOwner?.name ?? 'Unknown'}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: taskStatus
                      ? const TextStyle(
                    fontSize: 15.0,
                    height: 1.0,
                    color: Color.fromARGB(255, 106, 106, 106),
                    decoration: TextDecoration.lineThrough,
                  )
                      : const TextStyle(
                    fontSize: 15.0,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<MenuElement>(
            onSelected: (item) => onSelected(context, widget.task),
            itemBuilder: (BuildContext context) =>
            [...MenuItems.itemsFirst.map(buildItem).toList()],
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(color: Colors.grey, Icons.more_horiz),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<MenuElement> buildItem(MenuElement item) =>
      PopupMenuItem<MenuElement>(value: item, child: Text(item.text!));

  void onSelected(BuildContext context, Task task) {
    objectbox.taskBox.remove(task.id);
    debugPrint("Task Deleted");
  }
}

class MenuElement {
  final String? text;
  const MenuElement({required this.text});
}

class MenuItems {
  static const List<MenuElement> itemsFirst = [itemDelete];
  static const itemDelete = MenuElement(text: 'Delete');
}
```

**4. Membuat Task List View untuk Menampilkan Task-Task yang Ada**
Task List View merupakan komponen untuk menampilkan daftar tugas atau task-task menggunakan Task Card sebagai item. Dimana data daftar tugas diambil dari database berdasarkan data dar snapshot. Apabila database kosong maka akan menampilkan tulisan untuk menambahkan data baru.
```
import 'package:flutter/material.dart';
import '../main.dart';
import '../model.dart';
import 'task_card.dart';

class TaskList extends StatefulWidget {
  const TaskList({Key? key}) : super(key: key);

  @override
  State<TaskList> createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  TaskCard Function(BuildContext, int) _itemBuilder(List<Task> tasks) {
    return (BuildContext context, int index) => TaskCard(task: tasks[index]);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Task>>(
      key: UniqueKey(),
      stream: objectbox.getTasks(),
      builder: (context, snapshot) {
        if (snapshot.data?.isNotEmpty ?? false) {
          return ListView.builder(
            shrinkWrap: true,
            itemCount: snapshot.hasData ? snapshot.data!.length : 0,
            itemBuilder: _itemBuilder(snapshot.data ?? []));
        } else {
          return const Center(child: Text("Press the + icon to add tasks"));
        }
      }
    );
  }
}
```

**5. Membuat Task Add untuk Menambahkan Task Baru pada Database**
Task Add digunakan untuk membuat task baru yang kemudian akan diassign sesuai orang yang akan mengerjakan task tersebut. Pada fungsi ini, pengguna dapat membuat task baru, menambahkan orang baru untuk mengerjakan task tersebut, memilih siapa orang yang akan mengerjakan task tersebut, mengupdate orang yang mengerjakan task tersebut, dan menghapus orang yang sudah tidak relevan.
```
import 'package:flutter/material.dart';
import '../main.dart';
import '../model.dart';

class AddTask extends StatefulWidget {
  const AddTask({Key? key}) : super(key: key);

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  final inputController = TextEditingController();
  final ownerInputController = TextEditingController();
  late List<Owner> owners;
  late Owner currentOwner;

  void createOwner(String name) {
    int newOwnerId = objectbox.addOwner(name);
    updateOwners(newOwnerId);
  }

  void updateOwners([int? newOwnerId]) {
    final newOwnersList = objectbox.ownerBox.getAll();
    setState(() {
      owners = newOwnersList;
      if (newOwnerId != null) {
        currentOwner = objectbox.ownerBox.get(newOwnerId)!;
      } else if (owners.isNotEmpty) {
        currentOwner = owners[0];
      }
    });
  }

  void updateOwner(int newOwnerId) {
    Owner? newCurrentOwner = objectbox.ownerBox.get(newOwnerId);
    if (newCurrentOwner != null) {
      setState(() {
        currentOwner = newCurrentOwner;
      });
    }
  }

  void deleteOwner(int ownerId) {
    objectbox.ownerBox.remove(ownerId);
    updateOwners();
  }

  void createTask() {
    if (inputController.text.isNotEmpty) {
      objectbox.addTask(inputController.text, currentOwner);
    }
  }

  @override
  void initState() {
    super.initState();
    owners = objectbox.ownerBox.getAll();
    if (owners.isNotEmpty) {
      currentOwner = owners[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add Task")),
      key: UniqueKey(),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: TextField(
              controller: inputController,
              decoration: const InputDecoration(labelText: "Task Title"),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Row(
              children: [
                const Text("Assign Owner:", style: TextStyle(fontSize: 17)),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: currentOwner.id,
                  items: owners.map((element) {
                    return DropdownMenuItem<int>(
                      value: element.id,
                      child: Text(
                        element.name,
                        style: const TextStyle(
                          fontSize: 15.0,
                          height: 1.0,
                          overflow: TextOverflow.fade,
                        ),
                      ),
                    );
                  }).toList(),
                  underline: Container(
                    height: 1.5,
                    color: Colors.blueAccent,
                  ),
                  onChanged: (value) {
                    if (value != null) updateOwner(value);
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.manage_accounts),
                  tooltip: 'Manage Owners',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Manage Owners"),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: owners.length,
                            itemBuilder: (context, index) {
                              final owner = owners[index];
                              return ListTile(
                                title: Text(owner.name),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    deleteOwner(owner.id);
                                    Navigator.of(context).pop();
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const Spacer(),
          TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('New Owner'),
                  content: TextField(
                    autofocus: true,
                    decoration:
                    const InputDecoration(hintText: 'Enter the owner name'),
                    controller: ownerInputController,
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Submit'),
                      onPressed: () {
                        createOwner(ownerInputController.text);
                        ownerInputController.clear();
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              );
            },
            child: const Text(
              "Add Owner",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: ElevatedButton(
                    child: const Text(
                      "Save",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () {
                      createTask();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

**6. Membuat ```main.dart``` agar Aplikasi Dapat Digunakan**
File Main digunakan untuk memanggil fungsi-fungsi dengan cara memanggil komponen-komponen yang telah dibuat agar pengguna dapat membuat dan menghapus task, membuat dan menghapus list orang, mengupdate status task, mengupdate siapa yang mengerjakan task tersebut, dll.
```
import 'dart:async';

import 'package:flutter/material.dart';
import 'objectbox.dart';
import 'components/task_list_view.dart';
import 'components/task_add.dart';

late ObjectBox objectbox;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectbox = await ObjectBox.create();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ObjectBox Relations Application',
      theme: ThemeData(
          primarySwatch: Colors.deepPurple,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Events", style: TextStyle(fontWeight: FontWeight.bold),),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: TaskList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => AddTask()));
        },
        child: const Icon(Icons.add)
      ),
    );
  }
}
```

