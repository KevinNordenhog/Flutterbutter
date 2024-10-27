import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/models/person.dart';
import 'package:sqflite/sqflite.dart';
import 'groups_page.dart';

class GroupPage extends StatefulWidget {
  final Group group;

  const GroupPage({Key? key, required this.group}) : super(key: key);

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late Database _database;
  List<Person> _persons = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await DatabaseHelper.initializeDatabase();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    final List<Map<String, dynamic>> maps = await _database.query('people');
    setState(() {
      _persons = List.generate(maps.length, (i) {
        final person = Person.fromMap(maps[i]);
        if (person.groupIds.contains(widget.group.id)) {
          return person;
        }
        return null;
      }).whereType<Person>().toList();
    });
  }

  Future<void> _addPerson(String name) async {
    final person = Person(
      name: name,
      groupIds: [widget.group.id!],
    );
    await _database.insert(
      'people',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadPersons();
  }

  void _showAddPersonDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newPersonName = '';
        return AlertDialog(
          title: const Text('Add New Person'),
          content: TextField(
            onChanged: (value) {
              newPersonName = value;
            },
            decoration: const InputDecoration(hintText: "Enter person's name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                if (newPersonName.isNotEmpty) {
                  _addPerson(newPersonName);
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
      ),
      body: _persons.isEmpty
          ? const Center(
              child: Text('No people in this group yet. Add someone!'))
          : ListView.builder(
              itemCount: _persons.length,
              itemBuilder: (context, index) {
                final person = _persons[index];
                return ListTile(
                  title: Text(person.name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPersonDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
