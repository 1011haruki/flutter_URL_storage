import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabaseConnection();
  runApp(MyApp(database));
}

class MyApp extends StatelessWidget {
  final Database db;
  MyApp(this.db);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: DogListPage(db: db));
  }
}

class DogListPage extends StatefulWidget {
  final Database db;
  DogListPage({required this.db});

  @override
  State<DogListPage> createState() => _DogListPageState();
}

class _DogListPageState extends State<DogListPage> {
  List<Dog> dogs = [];

  @override
  void initState() {
    super.initState();
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    final data = await getDogs(widget.db);
    setState(() {
      dogs = data;
    });
  }

  Future<void> _addDog() async {
    final newDog = Dog(name: 'Pochi', age: 1 + dogs.length);
    await insertDog(widget.db, newDog);
    _loadDogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dog List')),
      body: ListView.builder(
        itemCount: dogs.length,
        itemBuilder: (context, index) {
          final dog = dogs[index];
          return ListTile(
            title: Text('${dog.name} (${dog.age}歳)'),
            subtitle: Text('ID: ${dog.id ?? '未登録'}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addDog,
        child: Icon(Icons.add),
      ),
    );
  }
}

// --- 以下はDB操作・モデル定義部分 ---
class Dog {
  final int? id;
  final String name;
  final int age;

  Dog({this.id, required this.name, required this.age});

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'age': age};

  factory Dog.fromMap(Map<String, dynamic> map) =>
      Dog(id: map['id'], name: map['name'], age: map['age']);
}

Future<Database> openDatabaseConnection() async {
  final path = join(await getDatabasesPath(), 'dog_database.db');
  return openDatabase(
    path,
    version: 1,
    onCreate: (db, version) {
      return db.execute(
        'CREATE TABLE dogs(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, age INTEGER)',
      );
    },
  );
}

Future<void> insertDog(Database db, Dog dog) async {
  await db.insert(
    'dogs',
    dog.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<Dog>> getDogs(Database db) async {
  final List<Map<String, dynamic>> maps = await db.query('dogs');
  return List.generate(maps.length, (i) => Dog.fromMap(maps[i]));
}
