import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/models/person.dart';
import 'package:flutter_application/pages/groups_page.dart';
import 'package:sqflite/sqflite.dart';

class SubGroupsPage extends StatefulWidget {
  final Group parentGroup;

  const SubGroupsPage({Key? key, required this.parentGroup}) : super(key: key);

  @override
  _SubGroupsPageState createState() => _SubGroupsPageState();
}

class _SubGroupsPageState extends State<SubGroupsPage> {
  late Database _database;
  List<Group> _subGroups = [];
  List<Person> _persons = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await DatabaseHelper.initializeDatabase();
    _loadSubGroups();
    _loadPersons();
  }

  Future<void> _loadSubGroups() async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'groups',
      where: 'parentId = ?',
      whereArgs: [widget.parentGroup.id],
    );
    setState(() {
      _subGroups = List.generate(maps.length, (i) => Group.fromMap(maps[i]));
    });
  }

  Future<void> _loadPersons() async {
    final List<Map<String, dynamic>> maps = await _database.query('people');
    setState(() {
      _persons = List.generate(maps.length, (i) {
        final person = Person.fromMap(maps[i]);
        if (person.groupIds.contains(widget.parentGroup.id)) {
          return person;
        }
        return null;
      }).whereType<Person>().toList();
    });
  }

  Future<void> _addSubGroup(Group group) async {
    await _database.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadSubGroups();
  }

  void _showAddSubGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newGroupName = '';
        return AlertDialog(
          title: const Text('Create New Sub-Group'),
          content: TextField(
            onChanged: (value) {
              newGroupName = value;
            },
            decoration: const InputDecoration(hintText: "Enter sub-group name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                if (newGroupName.isNotEmpty) {
                  _addSubGroup(Group(
                    name: newGroupName,
                    parentId: widget.parentGroup.id,
                  ));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showRandomizeDialog() {
    if (_persons.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No persons in this group to randomize!')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        int numberOfGroups = 2;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Create Random Sub-Groups'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Number of groups: $numberOfGroups'),
                  Slider(
                    min: 2,
                    max: min(_persons.length.toDouble(), 10),
                    divisions: min(_persons.length - 1, 8),
                    value: numberOfGroups.toDouble(),
                    onChanged: (value) {
                      setState(() {
                        numberOfGroups = value.round();
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Create'),
                  onPressed: () {
                    _createRandomGroups(numberOfGroups);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createRandomGroups(int numberOfGroups) async {
    if (_persons.isEmpty ||
        numberOfGroups <= 0 ||
        numberOfGroups > _persons.length) {
      return;
    }

    // First, delete all existing sub-groups of this parent group
    await _database.delete(
      'groups',
      where: 'parentId = ?',
      whereArgs: [widget.parentGroup.id],
    );

    // Remove the deleted sub-group IDs from all persons
    for (var person in _persons) {
      final updatedPerson = person.copyWith(
        groupIds:
            person.groupIds.where((id) => id == widget.parentGroup.id).toList(),
      );
      await _database.update(
        'people',
        updatedPerson.toMap(),
        where: 'id = ?',
        whereArgs: [updatedPerson.id],
      );
    }

    // Shuffle the persons list
    final shuffledPersons = List<Person>.from(_persons)..shuffle();

    // Create the new groups
    for (var i = 0; i < numberOfGroups; i++) {
      final group = Group(
        name: 'Random Group ${i + 1}',
        parentId: widget.parentGroup.id,
      );

      final groupId = await _database.insert(
        'groups',
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Assign persons to this group
      for (var j = i; j < shuffledPersons.length; j += numberOfGroups) {
        final person = shuffledPersons[j];
        final updatedPerson = person.copyWith(
          groupIds: [...person.groupIds, groupId],
        );

        await _database.update(
          'people',
          updatedPerson.toMap(),
          where: 'id = ?',
          whereArgs: [updatedPerson.id],
        );
      }
    }

    // Reload both sub-groups and persons to update the view
    await _loadSubGroups();
    await _loadPersons();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sub-Groups of ${widget.parentGroup.name}'),
      ),
      body: _subGroups.isEmpty
          ? const Center(
              child: Text(
                  'No sub-groups yet. Use the shuffle button to create random groups!'))
          : ListView.builder(
              itemCount: _subGroups.length,
              itemBuilder: (context, index) {
                final group = _subGroups[index];
                final groupMembers = _persons
                    .where((person) => person.groupIds.contains(group.id))
                    .toList();
                return ExpansionTile(
                  initiallyExpanded: true,
                  title: Text(group.name),
                  children: groupMembers
                      .map((person) => ListTile(
                            leading: const Icon(Icons.person),
                            title: Text(person.name),
                          ))
                      .toList(),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showRandomizeDialog,
        child: const Icon(Icons.shuffle),
      ),
    );
  }
}
