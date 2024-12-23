import 'package:flutter/material.dart';
import 'package:flutter_application/models/person.dart';
import 'package:flutter_application/pages/groups_page.dart';
import 'package:flutter_application/services/group_service.dart';

class GroupVisualizationPage extends StatefulWidget {
  const GroupVisualizationPage({Key? key}) : super(key: key);

  @override
  _GroupVisualizationPageState createState() => _GroupVisualizationPageState();
}

class GroupNode {
  final Group group;
  final List<Person> members;
  final List<GroupNode> subGroups;

  GroupNode({
    required this.group,
    required this.members,
    required this.subGroups,
  });
}

class _GroupVisualizationPageState extends State<GroupVisualizationPage> {
  late GroupService _groupService;
  List<GroupNode> _groupNodes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _groupService = await GroupService.getInstance();
    await _loadGroupHierarchy();
    setState(() {
      _isLoading = false;
    });
  }

  Future<GroupNode> _buildGroupNode(Group group) async {
    final members = await _groupService.getPersonsInGroup(group.id!);
    final subGroups = await _groupService.getGroups(parentId: group.id);
    final subNodes = await Future.wait(
      subGroups.map((subGroup) => _buildGroupNode(subGroup)),
    );
    return GroupNode(
      group: group,
      members: members,
      subGroups: subNodes,
    );
  }

  Future<void> _loadGroupHierarchy() async {
    final rootGroups = await _groupService.getGroups();
    final nodes = await Future.wait(
      rootGroups.map((group) => _buildGroupNode(group)),
    );
    setState(() {
      _groupNodes = nodes;
    });
  }

  Widget _buildGroupCard(GroupNode node, {double indent = 0}) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: ExpansionTile(
          initiallyExpanded: indent == 0,
          title: Text(
            node.group.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${node.members.length} members'),
          children: [
            if (node.members.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Members:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: node.members.map((person) {
                        return Chip(
                          avatar: const Icon(Icons.person, size: 16),
                          label: Text(person.name),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.1),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            if (node.subGroups.isNotEmpty) ...[
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Sub-groups:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ...node.subGroups.map((subNode) => _buildGroupCard(
                    subNode,
                    indent: indent + 16,
                  )),
            ],
          ],
        ),
      ),
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
        title: const Text('Group Visualization'),
      ),
      body: _groupNodes.isEmpty
          ? const Center(child: Text('No groups to visualize'))
          : ListView(
              children:
                  _groupNodes.map((node) => _buildGroupCard(node)).toList(),
            ),
    );
  }
}
