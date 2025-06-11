class CarpoolRoom {
  final int id;
  final int driverId;
  final String carInfo;
  final String origin;
  final String originDetailed;
  final String destination;
  final int seatsTotal;
  final int seatsLeft;
  final String note;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final bool isArrived;

  CarpoolRoom({
    required this.id,
    required this.driverId,
    required this.carInfo,
    required this.origin,
    required this.originDetailed,
    required this.destination,
    required this.seatsTotal,
    required this.seatsLeft,
    required this.note,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.isArrived,
  });

  factory CarpoolRoom.fromJson(Map<String, dynamic> json) {
    double _toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num)    return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return CarpoolRoom(
      id: (json['id'] as num).toInt(),
      driverId: (json['driverId'] as num).toInt(),
      carInfo: json['carInfo'] as String? ?? '',
      origin: json['origin'] as String,
      originDetailed: json['originDetailed'] as String,
      destination: json['destination'] as String,
      seatsTotal: (json['seatsTotal'] as num).toInt(),
      seatsLeft: (json['seatsLeft'] as num).toInt(),
      note: json['note'] as String,
      originLat: _toDouble(json['originLat']),
      originLng: _toDouble(json['originLng']),
      destLat:   _toDouble(json['destLat']),
      destLng:   _toDouble(json['destLng']),
      isArrived: json['isArrived'] as bool,
    );
  }
}