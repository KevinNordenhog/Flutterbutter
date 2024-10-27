class Person {
  final int? id;
  final String name;
  final List<int> groupIds;

  Person({
    this.id,
    required this.name,
    required this.groupIds,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'groupIds': groupIds.join(','),
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
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
}
