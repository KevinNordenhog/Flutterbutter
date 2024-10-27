import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/models/person.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;
import 'people_page.dart';
import 'groups_page.dart';

class AssignGroupsPage extends StatefulWidget {
  final Person person;

  const AssignGroupsPage({Key? key, required this.person}) : super(key: key);

  @override
  _AssignGroupsPageState createState() => _AssignGroupsPageState();
}

class _AssignGroupsPageState extends State<AssignGroupsPage> {
  late Database _database;
  List<Group> _groups = [];
  List<int> _selectedGroupIds = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
    _selectedGroupIds = List.from(widget.person.groupIds);
  }

  Future<void> _initDatabase() async {
    _database = await DatabaseHelper.initializeDatabase();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final List<Map<String, dynamic>> maps = await _database.query('groups');
    setState(() {
      _groups = List.generate(maps.length, (i) => Group.fromMap(maps[i]));
    });
  }

  void _toggleGroupSelection(int groupId) {
    setState(() {
      if (_selectedGroupIds.contains(groupId)) {
        _selectedGroupIds.remove(groupId);
      } else {
        _selectedGroupIds.add(groupId);
      }
    });
  }

  Future<void> _saveAssignedGroups() async {
    final updatedPerson = Person(
      id: widget.person.id,
      name: widget.person.name,
      groupIds: _selectedGroupIds,
    );

    await _database.update(
      'people',
      updatedPerson.toMap(),
      where: 'id = ?',
      whereArgs: [updatedPerson.id],
    );

    Navigator.pop(context, updatedPerson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Groups to ${widget.person.name}'),
      ),
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (context, index) {
          final group = _groups[index];
          return CheckboxListTile(
            title: Text(group.name),
            value: _selectedGroupIds.contains(group.id),
            onChanged: (bool? value) {
              _toggleGroupSelection(group.id!);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveAssignedGroups,
        child: const Icon(Icons.save),
      ),
    );
  }
}
