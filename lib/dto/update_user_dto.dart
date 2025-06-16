class UpdateUserNamelDto {
  final int id;
  final String name;

  UpdateUserNamelDto({
    required this.id,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };
}

class UpdateUserPhoneDto {
  final int id;
  final String phone;

  UpdateUserPhoneDto({
    required this.id,
    required this.phone,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'phone': phone,
  };
}