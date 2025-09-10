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

  // 生成模拟数据
  static List<BusLine> getMockData() {
    return [
      BusLine(
        id: '1',
        name: '1号线',
        color: '3983f6',
        stops: [
          BusStop(name: '梅园', latitude: 29.82067, longitude: 106.42478),
          BusStop(name: '桂园', latitude: 29.82167, longitude: 106.42578),
          BusStop(name: '竹园', latitude: 29.82267, longitude: 106.42678),
        ],
        route: [
          RoutePoint(latitude: 29.82067, longitude: 106.42478),
          RoutePoint(latitude: 29.82167, longitude: 106.42578),
          RoutePoint(latitude: 29.82267, longitude: 106.42678),
        ],
      ),
    ];
  }

  // Convert from WeChat busLine.ts structure
  static List<BusLine> fromWeChatConfig(List<dynamic> wechatLines) {
    final result = <BusLine>[];
    for (final line in wechatLines) {
      final id = (line['id'] ?? '').toString();
      final name = (line['name'] ?? '').toString();
      final color = (line['color'] ?? '').toString();
      final List<RoutePoint> route = [];
      final List<BusStop> stops = [];
      final List<dynamic>? busLine = line['bus_line'] as List<dynamic>?;
      final List<dynamic>? busPoint = line['bus_point'] as List<dynamic>?;
      if (busLine != null) {
        for (final p in busLine) {
          final s = p.toString();
          final parts = s.split(',');
          if (parts.length == 2) {
            final lat = double.tryParse(parts[0]) ?? 0;
            final lng = double.tryParse(parts[1]) ?? 0;
            route.add(RoutePoint(latitude: lat, longitude: lng));
          }
        }
      }
      if (busPoint != null) {
        for (final pt in busPoint) {
          final name = (pt['name'] ?? '').toString();
          final lat = double.tryParse((pt['lat'] ?? '0').toString()) ?? 0;
          final lng = double.tryParse((pt['lng'] ?? '0').toString()) ?? 0;
          stops.add(BusStop(name: name, latitude: lat, longitude: lng));
        }
      }
      result.add(
        BusLine(id: id, name: name, color: color, stops: stops, route: route),
      );
    }
    return result;
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
