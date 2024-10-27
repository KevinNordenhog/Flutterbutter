import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/pages/group_page.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as path;

class Group {
  final int? id;
  final String name;

  Group({this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }

  static Group fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
    );
  }
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late Database _database;
  List<Group> _groups = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await DatabaseHelper.initializeDatabase();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    final List<Map<String, dynamic>> maps = await _database.query('groups');
    setState(() {
      _groups = List.generate(maps.length, (i) {
        return Group(
          id: maps[i]['id'],
          name: maps[i]['name'],
        );
      });
    });
  }

  Future<void> _addGroup(Group group) async {
    await _database.insert(
      'groups',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadGroups();
  }

  Future<void> _deleteGroup(int id) async {
    await _database.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    _loadGroups();
  }

  void _showAddGroupDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newGroupName = '';
        return AlertDialog(
          title: const Text('Create New Group'),
          content: TextField(
            onChanged: (value) {
              newGroupName = value;
            },
            decoration: const InputDecoration(hintText: "Enter group name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Create'),
              onPressed: () {
                if (newGroupName.isNotEmpty) {
                  _addGroup(Group(name: newGroupName));
                  Navigator.of(context).pop();
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
      body: _groups.isEmpty
          ? const Center(child: Text('No groups yet. Create one!'))
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (context, index) {
                final group = _groups[index];
                return ListTile(
                  title: Text(group.name),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deleteGroup(group.id!),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GroupPage(group: group),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
