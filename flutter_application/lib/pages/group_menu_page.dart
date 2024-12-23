import 'package:flutter/material.dart';
import 'package:flutter_application/pages/groups_page.dart';
import 'package:flutter_application/pages/group_page.dart';
import 'package:flutter_application/pages/sub_groups_page.dart';

class GroupMenuPage extends StatelessWidget {
  final Group group;

  const GroupMenuPage({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Persons'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GroupPage(group: group),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_tree),
            title: const Text('Sub-Groups'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SubGroupsPage(parentGroup: group),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
