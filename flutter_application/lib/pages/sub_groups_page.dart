import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_application/models/person.dart';
import 'package:flutter_application/services/group_service.dart';
import 'package:flutter_application/pages/groups_page.dart';

class SubGroupsPage extends StatefulWidget {
  final Group parentGroup;

  const SubGroupsPage({Key? key, required this.parentGroup}) : super(key: key);

  @override
  _SubGroupsPageState createState() => _SubGroupsPageState();
}

class _SubGroupsPageState extends State<SubGroupsPage> {
  late GroupService _groupService;
  List<Group> _subGroups = [];
  List<Person> _persons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _groupService = await GroupService.getInstance();
    await _loadData();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadSubGroups(),
      _loadPersons(),
    ]);
  }

  Future<void> _loadSubGroups() async {
    final groups =
        await _groupService.getGroups(parentId: widget.parentGroup.id);
    setState(() {
      _subGroups = groups;
    });
  }

  Future<void> _loadPersons() async {
    final persons =
        await _groupService.getPersonsInGroup(widget.parentGroup.id!);
    setState(() {
      _persons = persons;
    });
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
                  onPressed: () async {
                    await _groupService.createRandomSubGroups(
                      widget.parentGroup.id!,
                      _persons,
                      numberOfGroups,
                    );
                    await _loadData();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
