class UpdateCarpoolInfoDto {
  final int carpoolId;
  final String carInfo;
  final DateTime departureTime;
  final String? originDetailed;
  final String? destinationDetailed;
  final String note;

  UpdateCarpoolInfoDto({
    required this.carpoolId,
    // required this.driverId,
    required this.carInfo,
    required this.departureTime,
    // required this.origin,
    this.originDetailed,
    // required this.destination,
    this.destinationDetailed,
    // required this.seatsTotal,
    required this.note,
    // required this.originLat,
    // required this.originLng,
    // required this.destLat,
    // required this.destLng,
  });

  Map<String, dynamic> toJson() => {
    'carpoolId'          : carpoolId,
    // 'driverId'           : driverId,
    'carInfo'            : carInfo,
    'departureTime'      : departureTime.toUtc().toIso8601String(),
    // 'origin'             : origin,
    'originDetailed'     : originDetailed,
    // 'destination'        : destination,
    'destinationDetailed': destinationDetailed,
    // 'seatsTotal'         : seatsTotal,
    // 'seatsLeft'          : seatsTotal,
    'note'               : note,
    // 'originLat'          : originLat,
    // 'originLng'          : originLng,
    // 'destLat'            : destLat,
    // 'destLng'            : destLng,
  };
}
