import 'package:flutter/material.dart';
import 'package:flutter_application/database_helper.dart';
import 'package:flutter_application/models/person.dart';
import 'package:sqflite/sqflite.dart';
import 'groups_page.dart';

class GroupPage extends StatefulWidget {
  final Group group;

  const GroupPage({Key? key, required this.group}) : super(key: key);

  @override
  _GroupPageState createState() => _GroupPageState();
}

class _GroupPageState extends State<GroupPage> {
  late Database _database;
  List<Person> _persons = [];

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  Future<void> _initDatabase() async {
    _database = await DatabaseHelper.initializeDatabase();
    _loadPersons();
  }

  Future<void> _loadPersons() async {
    final List<Map<String, dynamic>> maps = await _database.query('people');
    setState(() {
      _persons = List.generate(maps.length, (i) {
        final person = Person.fromMap(maps[i]);
        if (person.groupIds.contains(widget.group.id)) {
          return person;
        }
        return null;
      }).whereType<Person>().toList();
    });
  }

  Future<void> _addPerson(String name) async {
    final person = Person(
      name: name,
      groupIds: [widget.group.id!],
    );
    await _database.insert(
      'people',
      person.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _loadPersons();
  }

  void _showAddPersonDialog() {
    // Create dialog state outside the builder
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
              final List<Map<String, dynamic>> maps =
                  await _database.query('people');
              setDialogState(() {
                dialogState.availablePeople = maps
                    .map((map) => Person.fromMap(map))
                    .where(
                        (person) => !person.groupIds.contains(widget.group.id))
                    .toList();
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
                      for (var person in dialogState.selectedPeople) {
                        final updatedPerson = person.copyWith(
                          groupIds: [...person.groupIds, widget.group.id!],
                        );
                        await _database.update(
                          'people',
                          updatedPerson.toMap(),
                          where: 'id = ?',
                          whereArgs: [updatedPerson.id],
                        );
                      }
                      _loadPersons();
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
                return ListTile(
                  title: Text(person.name),
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
