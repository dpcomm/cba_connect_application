class Driver {
  final int id;
  final String name;
  final String phone;

  Driver({
    required this.id,
    required this.name,
    required this.phone,
  });

  factory Driver.fromJson(Map<String,dynamic> json) => Driver(
    id: json['id'] as int,
    name: json['name'] as String,
    phone: (json['phone'] as String?) ?? '',
  );
}
class CarpoolRoom {
  final int id;
  final int driverId;
  final String carInfo;
  final DateTime departureTime;
  final String origin;
  final String originDetailed;
  final String destination;
  final String destinationDetailed;
  final int seatsTotal;
  final int seatsLeft;
  final String note;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final bool isArrived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Driver driver;

  CarpoolRoom({
    required this.id,
    required this.driverId,
    required this.carInfo,
    required this.departureTime,
    required this.origin,
    required this.originDetailed,
    required this.destination,
    required this.destinationDetailed,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.note,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.isArrived,
    required this.createdAt,
    required this.updatedAt,
    required this.driver,
  });

  factory CarpoolRoom.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    final driverJson = json['driver'];
    /// Map이면 파싱, 아니면 driverId만 갖는 최소 정보 객체 생성
    final driver = (driverJson is Map<String, dynamic>)
        ? Driver.fromJson(driverJson)
        : Driver(
      id: (json['driverId'] as num).toInt(),
      name: '',
      phone: '',
    );

    return CarpoolRoom(
      id: (json['id'] as num).toInt(),
      driverId: (json['driverId'] as num).toInt(),
      carInfo: json['carInfo'] as String? ?? '',
      departureTime: DateTime.parse(json['departureTime'] as String),
      origin: json['origin'] as String,
      originDetailed: json['originDetailed'] as String? ?? '',
      destination: json['destination'] as String,
      destinationDetailed: json['destinationDetailed'] as String? ?? '',
      seatsTotal: (json['seatsTotal'] as num).toInt(),
      seatsLeft: (json['seatsLeft'] as num).toInt(),
      note: json['note'] as String? ?? '',
      originLat: _toDouble(json['originLat']),
      originLng: _toDouble(json['originLng']),
      destLat: _toDouble(json['destLat']),
      destLng: _toDouble(json['destLng']),
      isArrived: json['isArrived'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      driver: driver,
    );
  }
}

class CarpoolUserInfo {
  final int userId;
  final String name;
  final String phone;

  CarpoolUserInfo({
    required this.userId,
    required this.name,
    required this.phone,
  });

  factory CarpoolUserInfo.fromJson(Map<String, dynamic> json) {
    return CarpoolUserInfo(
      userId: json['userId'] as int,
      name: json['name'] as String,
      phone: json['phone'] as String? ?? '',
    );
  }
}

class CarpoolRoomDetail {
  final CarpoolRoom room;
  final List<CarpoolUserInfo> members;

  CarpoolRoomDetail({
    required this.room,
    required this.members,
  });

  factory CarpoolRoomDetail.fromJson(Map<String, dynamic> json) {

    final Map<String, dynamic>? roomDataRaw = json['room'] as Map<String, dynamic>?;
    final Map<String, dynamic> carpoolRoomDataForParsing = Map.from(roomDataRaw!);
    final List<dynamic>? rawMembersList = carpoolRoomDataForParsing.remove('members') as List<dynamic>?; // 'members' 추출 후 맵에서 제거

    return CarpoolRoomDetail(
      room: CarpoolRoom.fromJson(carpoolRoomDataForParsing),
      members: rawMembersList != null
          ? rawMembersList
              .whereType<Map<String, dynamic>>()
              .map((e) => CarpoolUserInfo.fromJson(e))
              .toList()
          : [], // members 리스트 파싱
    );
  }
}
