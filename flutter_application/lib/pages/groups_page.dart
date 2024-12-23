import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/models/person.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_application/pages/group_menu_page.dart';

class Group {
  final int? id;
  final String name;
  final int? parentId;

  Group({this.id, required this.name, this.parentId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'parentId': parentId,
    };
  }

  static Group fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      parentId: map['parentId'],
    );
  }
}

class GroupStats {
  final int totalPeople;
  final int peopleInGroups;
  final int peopleWithoutGroups;
  final Map<String, int> peoplePerGroup;

  GroupStats({
    required this.totalPeople,
    required this.peopleInGroups,
    required this.peopleWithoutGroups,
    required this.peoplePerGroup,
  });
}

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  _GroupsPageState createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  late Database _database;
  List<Group> _groups = [];
  GroupStats? _stats;
  bool _isStatsExpanded = false;

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await DatabaseHelper.initializeDatabase();
    await _loadGroups();
    await _loadStats();
  }

  Future<void> _loadStats() async {
    final List<Map<String, dynamic>> peopleMaps =
        await _database.query('people');
    final List<Person> people = List.generate(
      peopleMaps.length,
      (i) => Person.fromMap(peopleMaps[i]),
    );

    final Map<String, int> peoplePerGroup = {};
    for (var group in _groups) {
      peoplePerGroup[group.name] =
          people.where((person) => person.groupIds.contains(group.id)).length;
    }

    setState(() {
      _stats = GroupStats(
        totalPeople: people.length,
        peopleInGroups: people.where((p) => p.groupIds.isNotEmpty).length,
        peopleWithoutGroups: people.where((p) => p.groupIds.isEmpty).length,
        peoplePerGroup: peoplePerGroup,
      );
    });
  }

  Widget _buildStatsCard() {
    if (_stats == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isStatsExpanded = !_isStatsExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Group Statistics',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(
                    _isStatsExpanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ],
              ),
            ),
          ),
          if (_isStatsExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total People',
                        _stats!.totalPeople.toString(),
                        Icons.people,
                      ),
                      _buildStatItem(
                        'In Groups',
                        _stats!.peopleInGroups.toString(),
                        Icons.group,
                      ),
                      _buildStatItem(
                        'Without Groups',
                        _stats!.peopleWithoutGroups.toString(),
                        Icons.person_outline,
                      ),
                    ],
                  ),
                  if (_stats!.peoplePerGroup.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'People per Group',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      children: _stats!.peoplePerGroup.entries.map((entry) {
                        final percentage = _stats!.totalPeople > 0
                            ? (entry.value / _stats!.totalPeople * 100)
                                .toStringAsFixed(1)
                            : '0';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${entry.key} (${entry.value} people, $percentage%)'),
                              const SizedBox(height: 4),
                              LinearProgressIndicator(
                                value: _stats!.totalPeople > 0
                                    ? entry.value / _stats!.totalPeople
                                    : 0,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _loadGroups() async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'groups',
      where: 'parentId IS NULL',
    );
    setState(() {
      _groups = List.generate(maps.length, (i) {
        return Group(
          id: maps[i]['id'],
          name: maps[i]['name'],
          parentId: maps[i]['parentId'],
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
    await _loadGroups();
    await _loadStats();
  }

  Future<void> _deleteGroup(int id) async {
    await _database.delete(
      'groups',
      where: 'id = ?',
      whereArgs: [id],
    );
    await _loadGroups();
    await _loadStats();
  }

  void _showDeleteConfirmation(Group group) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Group'),
          content: Text(
              'Are you sure you want to delete ${group.name}? This will remove all sub-groups and remove people from this group.'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
              onPressed: () {
                _deleteGroup(group.id!);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
      body: Column(
        children: [
          _buildStatsCard(),
          Expanded(
            child: _groups.isEmpty
                ? const Center(child: Text('No groups yet. Create one!'))
                : ListView.builder(
                    itemCount: _groups.length,
                    itemBuilder: (context, index) {
                      final group = _groups[index];
                      return ListTile(
                        title: Text(group.name),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => _showDeleteConfirmation(group),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GroupMenuPage(group: group),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGroupDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
