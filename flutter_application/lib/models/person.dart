class Person {
  final int? id;
  final String name;
  final String email;
  final List<int> groupIds;

  Person(
      {this.id,
      required this.name,
      required this.email,
      required this.groupIds});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'groupIds':
          groupIds.join(','), // Convert List<int> to comma-separated string
    };
  }

  factory Person.fromMap(Map<String, dynamic> map) {
    return Person(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      groupIds: map['groupIds']
          .split(',')
          .map((e) => int.parse(e))
          .toList(), // Convert string back to List<int>
    );
  }
}
