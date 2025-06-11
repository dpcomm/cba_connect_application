class CreateCarpoolDto {
  final int driverId;
  final String carInfo;
  final String origin;
  final String originDetailed;
  final String destination;
  final int seatsTotal;
  final String note;
  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;

  CreateCarpoolDto({
    required this.driverId,
    required this.carInfo,
    required this.origin,
    required this.originDetailed,
    required this.destination,
    required this.seatsTotal,
    required this.note,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
  });

  Map<String, dynamic> toJson() => {
    'driverId': driverId,
    'carInfo': carInfo,
    'origin': origin,
    'originDetailed': originDetailed,
    'destination': destination,
    'seatsTotal': seatsTotal,
    'seatsLeft': seatsTotal,
    'note': note,
    'originLat': originLat,
    'originLng': originLng,
    'destLat': destLat,
    'destLng': destLng,
    'isArrived': false,
  };
}