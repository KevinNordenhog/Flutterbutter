import 'package:sqflite/sqflite.dart';
import 'package:flutter_application/models/person.dart';
import 'package:flutter_application/pages/groups_page.dart';
import 'package:flutter_application/services/history_service.dart';
import 'package:flutter_application/database_helper.dart';

class GroupService {
  static GroupService? _instance;
  late Database _database;
  late HistoryService _historyService;

  // Private constructor
  GroupService._();

  static Future<GroupService> getInstance() async {
    if (_instance == null) {
      _instance = GroupService._();
      await _instance!._init();
    }
    return _instance!;
  }

  Future<void> _init() async {
    _database = await DatabaseHelper.initializeDatabase();
    _historyService = HistoryService(_database);
  }

  Future<List<Group>> getGroups({int? parentId}) async {
    final List<Map<String, dynamic>> maps = await _database.query(
      'groups',
      where: parentId == null ? 'parentId IS NULL' : 'parentId = ?',
      whereArgs: parentId == null ? null : [parentId],
    );
    return List.generate(maps.length, (i) => Group.fromMap(maps[i]));
  }

  Future<List<Person>> getPersonsInGroup(int groupId) async {
    final List<Map<String, dynamic>> maps = await _database.query('people');
    return List.generate(maps.length, (i) {
      final person = Person.fromMap(maps[i]);
      if (person.groupIds.contains(groupId)) {
        return person;
      }
      return null;
    }).whereType<Person>().toList();
  }

  Future<List<Person>> getAvailablePeople(int excludeGroupId) async {
    final List<Map<String, dynamic>> maps = await _database.query('people');
    return maps
        .map((map) => Person.fromMap(map))
        .where((person) => !person.groupIds.contains(excludeGroupId))
        .toList();
  }

  Future<void> addPersonToGroup(Person person, int groupId,
      {bool isNewPerson = false}) async {
    if (isNewPerson) {
      await _database.insert(
        'people',
        person.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      final updatedPerson = person.copyWith(
        groupIds: [...person.groupIds, groupId],
      );
      await _database.update(
        'people',
        updatedPerson.toMap(),
        where: 'id = ?',
        whereArgs: [updatedPerson.id],
      );
    }

    await _historyService.addPersonToHistory(
      groupId: groupId,
      personName: person.name,
      isNewPerson: isNewPerson,
    );
  }

  Future<void> addPeopleToGroup(List<Person> people, int groupId) async {
    List<String> names = [];
    for (var person in people) {
      final updatedPerson = person.copyWith(
        groupIds: [...person.groupIds, groupId],
      );
      await _database.update(
        'people',
        updatedPerson.toMap(),
        where: 'id = ?',
        whereArgs: [updatedPerson.id],
      );
      names.add(person.name);
    }

    await _historyService.addPeopleToHistory(
      groupId: groupId,
      peopleNames: names,
    );
  }

  Future<void> createRandomSubGroups(
      int parentGroupId, List<Person> persons, int numberOfGroups) async {
    // Delete existing subgroups
    await _database.delete(
      'groups',
      where: 'parentId = ?',
      whereArgs: [parentGroupId],
    );

    // Remove old subgroup IDs from persons
    for (var person in persons) {
      final updatedPerson = person.copyWith(
        groupIds: person.groupIds.where((id) => id == parentGroupId).toList(),
      );
      await _database.update(
        'people',
        updatedPerson.toMap(),
        where: 'id = ?',
        whereArgs: [updatedPerson.id],
      );
    }

    // Create new random groups
    final shuffledPersons = List<Person>.from(persons)..shuffle();
    final Map<String, List<String>> groupConfiguration = {};

    for (var i = 0; i < numberOfGroups; i++) {
      final group = Group(
        name: 'Random Group ${i + 1}',
        parentId: parentGroupId,
      );

      final groupId = await _database.insert(
        'groups',
        group.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final List<String> groupMembers = [];

      for (var j = i; j < shuffledPersons.length; j += numberOfGroups) {
        final person = shuffledPersons[j];
        final updatedPerson = person.copyWith(
          groupIds: [...person.groupIds, groupId],
        );

        await _database.update(
          'people',
          updatedPerson.toMap(),
          where: 'id = ?',
          whereArgs: [updatedPerson.id],
        );

        groupMembers.add(person.name);
      }

      groupConfiguration[group.name] = groupMembers;
    }

    await _historyService.addRandomizationToHistory(
      groupId: parentGroupId,
      groupConfiguration: groupConfiguration,
    );
  }

  Future<void> updatePersonGroups(Person person, List<int> newGroupIds) async {
    final updatedPerson = person.copyWith(groupIds: newGroupIds);
    await _database.update(
      'people',
      updatedPerson.toMap(),
      where: 'id = ?',
      whereArgs: [updatedPerson.id],
    );

    // Track history for newly added groups
    final addedGroups =
        newGroupIds.where((id) => !person.groupIds.contains(id)).toList();
    for (final groupId in addedGroups) {
      await _historyService.addPersonToHistory(
        groupId: groupId,
        personName: person.name,
        isNewPerson: false,
      );
    }
  }

  Future<void> removePersonFromGroup(Person person, int groupId) async {
    final updatedPerson = person.copyWith(
      groupIds: person.groupIds.where((id) => id != groupId).toList(),
    );
    await _database.update(
      'people',
      updatedPerson.toMap(),
      where: 'id = ?',
      whereArgs: [updatedPerson.id],
    );

    await _historyService.addToHistory(
      groupId: groupId,
      configuration: {
        "Removed person": [person.name]
      },
    );
  }

  Future<void> removePeopleFromGroup(List<Person> people, int groupId) async {
    List<String> names = [];
    for (var person in people) {
      final updatedPerson = person.copyWith(
        groupIds: person.groupIds.where((id) => id != groupId).toList(),
      );
      await _database.update(
        'people',
        updatedPerson.toMap(),
        where: 'id = ?',
        whereArgs: [updatedPerson.id],
      );
      names.add(person.name);
    }

    await _historyService.addToHistory(
      groupId: groupId,
      configuration: {"Removed people": names},
    );
  }
}
