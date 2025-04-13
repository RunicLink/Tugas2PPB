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
