class CreateCarpoolDto {
  final int driverId;
  final String carInfo;
  final DateTime departureTime;
  final String origin;
  final String? originDetailed;
  final String destination;
  final String? destinationDetailed;
  final int seatsTotal;
  final String note;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  CreateCarpoolDto({
    required this.driverId,
    required this.carInfo,
    required this.departureTime,
    required this.origin,
    this.originDetailed,
    required this.destination,
    this.destinationDetailed,
    required this.seatsTotal,
    required this.note,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  Map<String, dynamic> toJson() => {
    'driverId'           : driverId,
    'carInfo'            : carInfo,
    'departureTime'      : departureTime.toUtc().toIso8601String(),
    'origin'             : origin,
    'originDetailed'     : originDetailed,
    'destination'        : destination,
    'destinationDetailed': destinationDetailed,
    'seatsTotal'         : seatsTotal,
    'seatsLeft'          : seatsTotal,
    'note'               : note,
    'originLat'          : originLat,
    'originLng'          : originLng,
    'destLat'            : destLat,
    'destLng'            : destLng,
  };
}
