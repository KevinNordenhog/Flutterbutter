import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class Person {
  final int? id;
  final String name;
  final String email;

  Person({this.id, required this.name, required this.email});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class PeoplePage extends StatefulWidget {
  const PeoplePage({Key? key}) : super(key: key);

  @override
  _PeoplePageState createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  late Database _database;
  List<Person> _people = [];
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await openDatabase(
      join(await getDatabasesPath(), 'people_database.db'),
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE people(id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, email TEXT)',
        );
      },
      version: 1,
    );
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final List<Map<String, dynamic>> maps = await _database.query('people');
    setState(() {
      _people = List.generate(maps.length, (i) {
        return Person(
          id: maps[i]['id'],
          name: maps[i]['name'],
          email: maps[i]['email'],
        );
      });
    });
  }

  Future<void> _addPerson(Person person) async {
    await _database.insert(
      'people',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadPeople();
  }

  Future<void> _deletePerson(int id) async {
    await _database.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadPeople();
  }

  List<Person> _getFilteredPeople() {
    return _people
        .where((person) =>
            person.name.toLowerCase().contains(_filter.toLowerCase()) ||
            person.email.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
  }

  // void _showPersonDetails(Person person) {
  //   showDialog(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Text(person.name),
  //         content: Text('Email: ${person.email}'),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Close'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final filteredPeople = _getFilteredPeople();
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('People'),
      // ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _filter = value;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Filter people',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPeople.length,
              itemBuilder: (context, index) {
                final person = filteredPeople[index];
                return ListTile(
                  title: Text(person.name),
                  subtitle: Text(person.email),
                  // onTap: () => _showPersonDetails(person),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deletePerson(person.id!),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              String name = '';
              String email = '';
              return AlertDialog(
                title: const Text('Add Person'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) => name = value,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      onChanged: (value) => email = value,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text('Add'),
                    onPressed: () {
                      if (name.isNotEmpty && email.isNotEmpty) {
                        _addPerson(Person(name: name, email: email));
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
