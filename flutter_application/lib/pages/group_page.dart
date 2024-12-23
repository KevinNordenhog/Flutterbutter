import 'package:flutter/material.dart';
import 'package:flutter_application/models/person.dart';
import 'package:flutter_application/services/group_service.dart';
import 'groups_page.dart';

class GroupPage extends StatefulWidget {
  final Group group;

  const GroupPage({Key? key, required this.group}) : super(key: key);

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late GroupService _groupService;
  List<Person> _persons = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initService();
  }

  Future<void> _initService() async {
    _groupService = await GroupService.getInstance();
    await _loadPersons();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadPersons() async {
    final persons = await _groupService.getPersonsInGroup(widget.group.id!);
    setState(() {
      _persons = persons;
    });
  }

  Future<void> _addPerson(String name) async {
    final person = Person(
      name: name,
      groupIds: [widget.group.id!],
    );
    await _groupService.addPersonToGroup(person, widget.group.id!,
        isNewPerson: true);
    _loadPersons();
  }

  Future<void> _addExistingPeople(List<Person> people) async {
    await _groupService.addPeopleToGroup(people, widget.group.id!);
    _loadPersons();
  }

  Future<void> _removePerson(Person person) async {
    await _groupService.removePersonFromGroup(person, widget.group.id!);
    await _loadPersons();
  }

  void _showAddPersonDialog() {
    final dialogState = _DialogState(
      isNewPerson: true,
      newPersonName: '',
      selectedPeople: [],
      availablePeople: [],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            Future<void> loadAvailablePeople() async {
              final people =
                  await _groupService.getAvailablePeople(widget.group.id!);
              setDialogState(() {
                dialogState.availablePeople = people;
              });
            }

            return AlertDialog(
              title: const Text('Add Person to Group'),
              content: FutureBuilder(
                future: loadAvailablePeople(),
                builder: (context, snapshot) {
                  return SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('New Person'),
                                value: true,
                                groupValue: dialogState.isNewPerson,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    dialogState.isNewPerson = value!;
                                    dialogState.selectedPeople = [];
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              child: RadioListTile<bool>(
                                title: const Text('Existing'),
                                value: false,
                                groupValue: dialogState.isNewPerson,
                                onChanged: (bool? value) {
                                  setDialogState(() {
                                    dialogState.isNewPerson = value!;
                                    dialogState.newPersonName = '';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        if (dialogState.isNewPerson)
                          TextField(
                            onChanged: (value) {
                              setDialogState(() {
                                dialogState.newPersonName = value;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: "Enter person's name",
                            ),
                          )
                        else if (dialogState.availablePeople.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text('No available people to add'),
                          )
                        else
                          SizedBox(
                            width: double.maxFinite,
                            height: 200,
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children:
                                    dialogState.availablePeople.map((person) {
                                  return CheckboxListTile(
                                    dense: true,
                                    title: Text(person.name),
                                    value: dialogState.selectedPeople
                                        .contains(person),
                                    onChanged: (bool? value) {
                                      setDialogState(() {
                                        if (value == true) {
                                          dialogState.selectedPeople
                                              .add(person);
                                        } else {
                                          dialogState.selectedPeople
                                              .remove(person);
                                        }
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: const Text('Add'),
                  onPressed: () async {
                    if (dialogState.isNewPerson &&
                        dialogState.newPersonName.isNotEmpty) {
                      await _addPerson(dialogState.newPersonName);
                      Navigator.pop(context);
                    } else if (!dialogState.isNewPerson &&
                        dialogState.selectedPeople.isNotEmpty) {
                      await _addExistingPeople(dialogState.selectedPeople);
                      Navigator.pop(context);
                    }
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
        title: Text(widget.group.name),
      ),
      body: _persons.isEmpty
          ? const Center(
              child: Text('No people in this group yet. Add someone!'))
          : ListView.builder(
              itemCount: _persons.length,
              itemBuilder: (context, index) {
                final person = _persons[index];
                return Dismissible(
                  key: Key(person.id.toString()),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    return await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Removal'),
                          content:
                              Text('Remove ${person.name} from this group?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: const Text('Remove'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  onDismissed: (direction) {
                    _removePerson(person);
                  },
                  child: ListTile(
                    title: Text(person.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Confirm Removal'),
                              content: Text(
                                  'Remove ${person.name} from this group?'),
                              actions: <Widget>[
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            );
                          },
                        );
                        if (confirmed == true) {
                          await _removePerson(person);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddPersonDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Helper class to manage dialog state
class _DialogState {
  bool isNewPerson;
  String newPersonName;
  List<Person> selectedPeople;
  List<Person> availablePeople;

  _DialogState({
    required this.isNewPerson,
    required this.newPersonName,
    required List<Person>? selectedPeople,
    required this.availablePeople,
  }) : selectedPeople = selectedPeople ?? [];
}
