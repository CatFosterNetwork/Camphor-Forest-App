// lib/pages/school_navigation/models/bus_models.dart

class BusLine {
  final String id;
  final String name;
  final String color;
  final List<BusStop> stops;
  final List<RoutePoint> route;

  BusLine({
    required this.id,
    required this.name,
    required this.color,
    required this.stops,
    required this.route,
  });

  factory BusLine.fromJson(Map<String, dynamic> json) {
    return BusLine(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      color: json['color'] ?? '',
      stops:
          (json['stops'] as List?)?.map((e) => BusStop.fromJson(e)).toList() ??
          [],
      route:
          (json['route'] as List?)
              ?.map((e) => RoutePoint.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'stops': stops.map((e) => e.toJson()).toList(),
      'route': route.map((e) => e.toJson()).toList(),
    };
  }

  factory BusLine.empty() {
    return BusLine(id: '', name: '', color: '', stops: [], route: []);
  }

}

class RoutePoint {
  final double latitude;
  final double longitude;

  RoutePoint({required this.latitude, required this.longitude});

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    return RoutePoint(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'latitude': latitude, 'longitude': longitude};
  }
}

class BusStop {
  final String name;
  final double latitude;
  final double longitude;

  BusStop({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  factory BusStop.fromJson(Map<String, dynamic> json) {
    return BusStop(
      name: json['name'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'latitude': latitude, 'longitude': longitude};
  }
}

class BusData {
  final String id;
  final String lineId;
  final double latitude;
  final double longitude;
  final double speed;
  final double direction;

  BusData({
    required this.id,
    required this.lineId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.direction,
  });

  factory BusData.fromJson(Map<String, dynamic> json) {
    return BusData(
      id: json['id'] ?? '',
      lineId: json['lineId'] ?? '',
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      speed: (json['speed'] ?? 0).toDouble(),
      direction: (json['direction'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lineId': lineId,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'direction': direction,
    };
  }
}
