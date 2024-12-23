import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/models/person.dart';
import 'package:flutter_application/pages/assign_groups_page.dart';
import 'package:sqflite/sqflite.dart';

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
    _database = await DatabaseHelper.initializeDatabase();
    _loadPeople();
  }

  Future<void> _loadPeople() async {
    final List<Map<String, dynamic>> maps = await _database.query('people');
    setState(() {
      _people = List.generate(maps.length, (i) => Person.fromMap(maps[i]));
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

  Future<void> _updatePerson(Person person) async {
    await _database.update(
      'people',
      person.toMap(),
      where: 'id = ?',
      whereArgs: [person.id],
    );
    _loadPeople();
  }

  List<Person> _getFilteredPeople() {
    return _people
        .where((person) =>
            person.name.toLowerCase().contains(_filter.toLowerCase()))
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

  Future<void> _deletePerson(int id) async {
    await _database.delete(
      'people',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadPeople();
  }

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
                  onTap: () async {
                    final updatedPerson = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AssignGroupsPage(person: person),
                      ),
                    );
                    if (updatedPerson != null) {
                      setState(() {
                        final index =
                            _people.indexWhere((p) => p.id == updatedPerson.id);
                        if (index != -1) {
                          _people[index] = updatedPerson;
                        }
                      });
                      _loadPeople();
                    }
                  },
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
              return AlertDialog(
                title: const Text('Add Person'),
                content: TextField(
                  onChanged: (value) => name = value,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: const Text('Add'),
                    onPressed: () {
                      if (name.isNotEmpty) {
                        _addPerson(Person(name: name, groupIds: []));
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
