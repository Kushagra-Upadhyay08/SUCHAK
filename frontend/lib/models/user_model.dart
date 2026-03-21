class User {
  final String id;
  final String name;
  final String role;
  final String? employeeId;

  User({required this.id, required this.name, required this.role, this.employeeId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      name: json['name'],
      role: json['role'],
      employeeId: json['employeeId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'employeeId': employeeId,
  };
}
