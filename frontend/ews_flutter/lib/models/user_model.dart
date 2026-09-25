enum UserRole { field, command }

class UserModel {
  final String id;
  final String name;
  final String designation;
  final String range;
  final String phone;
  final UserRole role;

  const UserModel({
    required this.id,
    required this.name,
    required this.designation,
    required this.range,
    required this.phone,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'designation': designation,
        'range': range,
        'phone': phone,
        'role': role.name,
      };

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        id: '${j['id']}',
        name: j['name'] as String? ?? '',
        designation: j['designation'] as String? ?? '',
        range: j['range'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        role: UserRole.values.firstWhere(
          (r) => r.name == j['role'],
          orElse: () => UserRole.field,
        ),
      );
}
