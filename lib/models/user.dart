class User {
  final int id;
  final String rank;
  final String userId;
  final String name;
  final String group;
  final String phone;
  final DateTime birth;
  final String gender;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.rank,
    required this.userId,
    required this.name,
    required this.group,
    required this.phone,
    required this.birth,
    required this.gender,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      rank: json['rank'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      group: json['group'] as String,
      phone: json['phone'] as String,
      birth: DateTime.parse(json['birth'] as String),
      gender: json['gender'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
  factory User.empty() {
    return User(
      id: 0,
      rank: '',
      userId: '',
      name: '',
      group: '',
      phone: '',
      birth: DateTime.fromMillisecondsSinceEpoch(0),
      gender: '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
  User copyWith({
    int? id,
    String? rank,
    String? userId,
    String? name,
    String? group,
    String? phone,
    DateTime? birth,
    String? gender,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      rank: rank ?? this.rank,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      group: group ?? this.group,
      phone: phone ?? this.phone,
      birth: birth ?? this.birth,
      gender: gender ?? this.gender,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
