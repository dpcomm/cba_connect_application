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
  final CarpoolStatus status;
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
    required this.status,
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
    final driver = (driverJson is Map<String, dynamic>)
        ? Driver.fromJson(driverJson)
        : Driver(
      id: (json['driverId'] as num).toInt(),
      name: '',
      phone: '',
    );

    final String statusString = json['status'] as String? ?? 'before_departure';
    final CarpoolStatus carpoolStatus = CarpoolStatusExtension.fromApiString(statusString);

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
      status: carpoolStatus,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      driver: driver,
    );
  }

  CarpoolRoom copyWith({
    int? id,
    int? driverId,
    String? carInfo,
    DateTime? departureTime,
    String? origin,
    String? originDetailed,
    String? destination,
    String? destinationDetailed,
    int? seatsTotal,
    int? seatsLeft,
    String? note,
    double? originLat,
    double? originLng,
    double? destLat,
    double? destLng,
    bool? isArrived,
    CarpoolStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Driver? driver,
  }) {
    return CarpoolRoom(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      carInfo: carInfo ?? this.carInfo,
      departureTime: departureTime ?? this.departureTime,
      origin: origin ?? this.origin,
      originDetailed: originDetailed ?? this.originDetailed,
      destination: destination ?? this.destination,
      destinationDetailed: destinationDetailed ?? this.destinationDetailed,
      seatsTotal: seatsTotal ?? this.seatsTotal,
      seatsLeft: seatsLeft ?? this.seatsLeft,
      note: note ?? this.note,
      originLat: originLat ?? this.originLat,
      originLng: originLng ?? this.originLng,
      destLat: destLat ?? this.destLat,
      destLng: destLng ?? this.destLng,
      isArrived: isArrived ?? this.isArrived,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      driver: driver ?? this.driver,
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

enum CarpoolStatus {
  beforeDeparture, 
  inTransit,      
  arrived,        
}

// String <-> CarpoolStatus 변환
extension CarpoolStatusExtension on CarpoolStatus {
  String toApiString() {
    switch (this) {
      case CarpoolStatus.beforeDeparture: return 'before_departure';
      case CarpoolStatus.inTransit: return 'in_transit';
      case CarpoolStatus.arrived: return 'arrived';
    }
  }

  static CarpoolStatus fromApiString(String statusString) {
    switch (statusString) {
      case 'before_departure': return CarpoolStatus.beforeDeparture;
      case 'in_transit': return CarpoolStatus.inTransit;
      case 'arrived': return CarpoolStatus.arrived;
      default:
        print('Warning: Unknown CarpoolStatus string from API: $statusString');
        return CarpoolStatus.beforeDeparture;
    }
  }

  static List<String> get validApiStrings => CarpoolStatus.values.map((e) => e.toApiString()).toList();
}