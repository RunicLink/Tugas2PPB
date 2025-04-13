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