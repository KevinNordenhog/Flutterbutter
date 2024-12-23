import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/pages/groups_page.dart';
import 'package:sqflite/sqflite.dart';

class GroupHistory {
  final int id;
  final int groupId;
  final String configuration;
  final DateTime timestamp;

  GroupHistory({
    required this.id,
    required this.groupId,
    required this.configuration,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'configuration': configuration,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  static GroupHistory fromMap(Map<String, dynamic> map) {
    return GroupHistory(
      id: map['id'],
      groupId: map['groupId'],
      configuration: map['configuration'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class GroupHistoryPage extends StatefulWidget {
  final Group group;

  const GroupHistoryPage({Key? key, required this.group}) : super(key: key);

  @override
  _GroupHistoryPageState createState() => _GroupHistoryPageState();
}

class _GroupHistoryPageState extends State<GroupHistoryPage> {
  late Database _database;
  List<GroupHistory> _history = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await DatabaseHelper.initializeDatabase();
    await _loadHistory();
  }

  Future<void> _loadHistory() async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'group_history',
      where: 'groupId = ?',
      whereArgs: [widget.group.id],
      orderBy: 'timestamp DESC',
    );
    setState(() {
      _history =
          List.generate(maps.length, (i) => GroupHistory.fromMap(maps[i]));
    });
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildHistoryItem(GroupHistory history) {
    print('Raw configuration: ${history.configuration}');

    // First try to parse as a regular action
    try {
      String configStr = history.configuration;

      // Check if it's a regular action by looking for specific keys
      if (configStr.contains('Added new person') ||
          configStr.contains('Added existing person') ||
          configStr.contains('Added existing people') ||
          configStr.contains('Removed person') ||
          configStr.contains('Removed people')) {
        // Parse the action type and value
        String actionType = '';
        String value = '';

        if (configStr.contains('Added new person')) {
          actionType = 'Added new person';
          value = configStr
              .split('Added new person: ')[1]
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('}', '')
              .replaceAll('"', '')
              .trim();
        } else if (configStr.contains('Added existing person')) {
          actionType = 'Added existing person';
          value = configStr
              .split('Added existing person: ')[1]
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('}', '')
              .replaceAll('"', '')
              .trim();
        } else if (configStr.contains('Added existing people')) {
          actionType = 'Added multiple people';
          value = configStr
              .split('Added existing people: ')[1]
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('}', '')
              .replaceAll('"', '')
              .trim();
        } else if (configStr.contains('Removed person')) {
          actionType = 'Removed person';
          value = configStr
              .split('Removed person: ')[1]
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('}', '')
              .replaceAll('"', '')
              .trim();
        } else if (configStr.contains('Removed people')) {
          actionType = 'Removed multiple people';
          value = configStr
              .split('Removed people: ')[1]
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('}', '')
              .replaceAll('"', '')
              .trim();
        }

        print('Action type: $actionType');
        print('Value: $value');

        // Create the appropriate widget based on action type
        Widget content;
        if (actionType == 'Added multiple people' ||
            actionType == 'Removed multiple people') {
          List<String> people = value.split(',').map((e) => e.trim()).toList();
          content = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: people
                  .map((person) => Row(
                        children: [
                          Icon(
                            actionType.startsWith('Added')
                                ? Icons.person_add
                                : Icons.person_remove,
                            color: actionType.startsWith('Added')
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(person),
                        ],
                      ))
                  .toList(),
            ),
          );
        } else {
          content = Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  actionType.startsWith('Added')
                      ? Icons.person_add
                      : Icons.person_remove,
                  color: actionType.startsWith('Added')
                      ? Colors.green
                      : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(value),
              ],
            ),
          );
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ExpansionTile(
            title: Text('$actionType on ${_formatDateTime(history.timestamp)}'),
            children: [content],
          ),
        );
      }

      // Try to parse as randomization
      if (configStr.contains('Random Group')) {
        Map<String, List<String>> groupConfig = {};
        print('Trying to parse as randomization: $configStr');

        // Extract group names and their members using a simpler approach
        configStr = configStr.replaceAll('{', '').replaceAll('}', '');
        List<String> groups = configStr.split(', Random Group');
        for (var group in groups) {
          if (!group.startsWith('Random Group')) {
            group = 'Random Group$group';
          }
          var parts = group.split(': [');
          if (parts.length == 2) {
            String groupName = parts[0].trim();
            String membersStr = parts[1].replaceAll(']', '');
            List<String> members = membersStr
                .split(',')
                .map((e) => e.trim().replaceAll('"', ''))
                .where((e) => e.isNotEmpty)
                .toList();
            groupConfig[groupName] = members;
          }
        }

        if (groupConfig.isNotEmpty) {
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ExpansionTile(
              title: Text(
                  'Randomization on ${_formatDateTime(history.timestamp)}'),
              subtitle: Text('${groupConfig.length} sub-groups'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: groupConfig.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding:
                                const EdgeInsets.only(left: 16.0, bottom: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: entry.value.map((member) {
                                return Row(
                                  children: [
                                    const Icon(Icons.person, size: 16),
                                    const SizedBox(width: 8),
                                    Text(member),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      print('Error parsing history: $e');
    }

    // If we get here, we couldn't parse the configuration
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ExpansionTile(
        title: Text('Unknown action on ${_formatDateTime(history.timestamp)}'),
        children: const [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Could not parse history entry'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('History - ${widget.group.name}'),
      ),
      body: _history.isEmpty
          ? const Center(
              child: Text('No history available for this group.'),
            )
          : ListView.builder(
              itemCount: _history.length,
              itemBuilder: (context, index) {
                return _buildHistoryItem(_history[index]);
              },
            ),
    );
  }
}
