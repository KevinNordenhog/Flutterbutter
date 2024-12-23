import 'package:flutter/material.dart';
import 'package:flutter_application/models/person.dart';
import 'package:flutter_application/services/group_service.dart';
import 'groups_page.dart';

class AssignGroupsPage extends StatefulWidget {
  final Person person;

  const AssignGroupsPage({Key? key, required this.person}) : super(key: key);

  @override
  _AssignGroupsPageState createState() => _AssignGroupsPageState();
}

class _AssignGroupsPageState extends State<AssignGroupsPage> {
  late GroupService _groupService;
  List<Group> _groups = [];
  List<int> _selectedGroupIds = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedGroupIds = List.from(widget.person.groupIds);
    _initService();
  }

  Future<void> _initService() async {
    _groupService = await GroupService.getInstance();
    await _loadGroups();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadGroups() async {
    final groups = await _groupService.getGroups();
    setState(() {
      _groups = groups;
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
    await _groupService.updatePersonGroups(widget.person, _selectedGroupIds);
    Navigator.pop(context, widget.person.copyWith(groupIds: _selectedGroupIds));
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
