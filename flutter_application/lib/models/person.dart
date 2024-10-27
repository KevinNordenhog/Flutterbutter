import 'package:flutter/foundation.dart';

class Person {
  final int? id;
  final String name;
  final List<int> groupIds;

  Person({
    this.id,
    required this.name,
    List<int>? groupIds,
  }) : groupIds = groupIds ?? [];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'groupIds': groupIds.join(','),
    };
  }

  static Person fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      name: map['name'],
      groupIds: (map['groupIds'] as String?)
              ?.split(',')
              .where((e) => e.isNotEmpty)
              .map((e) => int.parse(e))
              .toList() ??
          [],
    );
  }

  Person copyWith({
    int? id,
    String? name,
    List<int>? groupIds,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      groupIds: groupIds ?? List.from(this.groupIds),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person &&
        other.id == id &&
        other.name == name &&
        listEquals(other.groupIds, groupIds);
  }

  @override
  int get hashCode => Object.hash(id, name, Object.hashAll(groupIds));
}
