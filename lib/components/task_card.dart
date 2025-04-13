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
