import 'package:sqflite/sqflite.dart';

class HistoryService {
  final Database _database;

  HistoryService(this._database);

  Future<void> addToHistory({
    required int groupId,
    required Map<String, dynamic> configuration,
  }) async {
    await _database.insert(
      'group_history',
      {
        'groupId': groupId,
        'configuration': configuration.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  Future<void> addPersonToHistory({
    required int groupId,
    required String personName,
    bool isNewPerson = true,
  }) async {
    final config = isNewPerson
        ? {
            "Added new person": [personName]
          }
        : {
            "Added existing person": [personName]
          };

    await addToHistory(
      groupId: groupId,
      configuration: config,
    );
  }

  Future<void> addPeopleToHistory({
    required int groupId,
    required List<String> peopleNames,
  }) async {
    await addToHistory(
      groupId: groupId,
      configuration: {"Added existing people": peopleNames},
    );
  }

  Future<void> addRandomizationToHistory({
    required int groupId,
    required Map<String, List<String>> groupConfiguration,
  }) async {
    await addToHistory(
      groupId: groupId,
      configuration: groupConfiguration,
    );
  }
}
