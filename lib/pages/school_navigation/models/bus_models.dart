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
      BusLine(
        id: '2',
        name: '2号线',
        color: '929296',
        stops: [
          BusStop(name: '教学楼', latitude: 29.81967, longitude: 106.42378),
          BusStop(name: '图书馆', latitude: 29.82067, longitude: 106.42478),
          BusStop(name: '体育馆', latitude: 29.82167, longitude: 106.42578),
        ],
        route: [
          RoutePoint(latitude: 29.81967, longitude: 106.42378),
          RoutePoint(latitude: 29.82067, longitude: 106.42478),
          RoutePoint(latitude: 29.82167, longitude: 106.42578),
        ],
      ),
      BusLine(
        id: '3',
        name: '3号线',
        color: 'f19f39',
        stops: [
          BusStop(name: '南门', latitude: 29.81867, longitude: 106.42278),
          BusStop(name: '中心广场', latitude: 29.82067, longitude: 106.42478),
          BusStop(name: '北门', latitude: 29.82267, longitude: 106.42678),
        ],
        route: [
          RoutePoint(latitude: 29.81867, longitude: 106.42278),
          RoutePoint(latitude: 29.82067, longitude: 106.42478),
          RoutePoint(latitude: 29.82267, longitude: 106.42678),
        ],
      ),
      BusLine(
        id: '4',
        name: '4号线',
        color: 'ff00ff',
        stops: [
          BusStop(name: '食堂', latitude: 29.81967, longitude: 106.42178),
          BusStop(name: '宿舍区', latitude: 29.82167, longitude: 106.42378),
          BusStop(name: '实验楼', latitude: 29.82367, longitude: 106.42578),
        ],
        route: [
          RoutePoint(latitude: 29.81967, longitude: 106.42178),
          RoutePoint(latitude: 29.82167, longitude: 106.42378),
          RoutePoint(latitude: 29.82367, longitude: 106.42578),
        ],
      ),
      BusLine(
        id: '5',
        name: '5号线',
        color: 'ff2323',
        stops: [
          BusStop(name: '行政楼', latitude: 29.81767, longitude: 106.42078),
          BusStop(name: '音乐厅', latitude: 29.82067, longitude: 106.42278),
          BusStop(name: '美术馆', latitude: 29.82367, longitude: 106.42478),
        ],
        route: [
          RoutePoint(latitude: 29.81767, longitude: 106.42078),
          RoutePoint(latitude: 29.82067, longitude: 106.42278),
          RoutePoint(latitude: 29.82367, longitude: 106.42478),
        ],
      ),
      BusLine(
        id: '6',
        name: '6号线',
        color: '00bfff',
        stops: [
          BusStop(name: '医院', latitude: 29.81667, longitude: 106.41978),
          BusStop(name: '超市', latitude: 29.82067, longitude: 106.42178),
          BusStop(name: '银行', latitude: 29.82467, longitude: 106.42378),
        ],
        route: [
          RoutePoint(latitude: 29.81667, longitude: 106.41978),
          RoutePoint(latitude: 29.82067, longitude: 106.42178),
          RoutePoint(latitude: 29.82467, longitude: 106.42378),
        ],
      ),
      BusLine(
        id: '7',
        name: '7号线',
        color: 'ff69b4',
        stops: [
          BusStop(name: '东门', latitude: 29.81967, longitude: 106.41878),
          BusStop(name: '操场', latitude: 29.82167, longitude: 106.42078),
          BusStop(name: '西门', latitude: 29.82367, longitude: 106.42278),
        ],
        route: [
          RoutePoint(latitude: 29.81967, longitude: 106.41878),
          RoutePoint(latitude: 29.82167, longitude: 106.42078),
          RoutePoint(latitude: 29.82367, longitude: 106.42278),
        ],
      ),
      BusLine(
        id: '8',
        name: '8号线',
        color: '6a5acd',
        stops: [
          BusStop(name: '停车场', latitude: 29.81867, longitude: 106.41778),
          BusStop(name: '邮局', latitude: 29.82167, longitude: 106.41978),
          BusStop(name: '招待所', latitude: 29.82467, longitude: 106.42178),
        ],
        route: [
          RoutePoint(latitude: 29.81867, longitude: 106.41778),
          RoutePoint(latitude: 29.82167, longitude: 106.41978),
          RoutePoint(latitude: 29.82467, longitude: 106.42178),
        ],
      ),
      BusLine(
        id: '9',
        name: '经管专线',
        color: '00d499',
        stops: [
          BusStop(name: '经管学院', latitude: 29.81767, longitude: 106.41678),
          BusStop(name: '商学院', latitude: 29.82067, longitude: 106.41878),
          BusStop(name: '经济学院', latitude: 29.82367, longitude: 106.42078),
        ],
        route: [
          RoutePoint(latitude: 29.81767, longitude: 106.41678),
          RoutePoint(latitude: 29.82067, longitude: 106.41878),
          RoutePoint(latitude: 29.82367, longitude: 106.42078),
        ],
      ),
    ];
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

  // 生成模拟数据
  static List<BusData> getMockData() {
    return [
      BusData(
        id: 'bus_001',
        lineId: '1',
        latitude: 29.82067,
        longitude: 106.42478,
        speed: 25.0,
        direction: 45.0,
      ),
      BusData(
        id: 'bus_002',
        lineId: '2',
        latitude: 29.82067,
        longitude: 106.42478,
        speed: 30.0,
        direction: 90.0,
      ),
      BusData(
        id: 'bus_003',
        lineId: '3',
        latitude: 29.82067,
        longitude: 106.42478,
        speed: 20.0,
        direction: 135.0,
      ),
    ];
  }
}
