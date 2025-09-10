class BusLine {
  final String id;
  final String schoolId;
  final String name;
  final String color;
  final List<String> busLine;
  final List<BusPoint> busPoint;

  const BusLine({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.color,
    required this.busLine,
    required this.busPoint,
  });

  factory BusLine.fromJson(Map<String, dynamic> json) {
    return BusLine(
      id: json['id'] as String,
      schoolId: json['school_id'] as String,
      name: json['name'] as String,
      color: json['color'] as String,
      busLine: List<String>.from(json['bus_line'] as List),
      busPoint: (json['bus_point'] as List)
          .map((point) => BusPoint.fromJson(point as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'school_id': schoolId,
      'name': name,
      'color': color,
      'bus_line': busLine,
      'bus_point': busPoint.map((point) => point.toJson()).toList(),
    };
  }
}

class BusPoint {
  final String name;
  final String shortName;
  final String lat;
  final String lng;
  final String adVoice;
  final String voice;
  final String offVoice;
  final String nextVoice;
  final String playNext;
  final String type;
  final String icon;
  final String color;
  final String silent;
  final String length;

  const BusPoint({
    required this.name,
    required this.shortName,
    required this.lat,
    required this.lng,
    required this.adVoice,
    required this.voice,
    required this.offVoice,
    required this.nextVoice,
    required this.playNext,
    required this.type,
    required this.icon,
    required this.color,
    required this.silent,
    required this.length,
  });

  factory BusPoint.fromJson(Map<String, dynamic> json) {
    return BusPoint(
      name: json['name'] as String,
      shortName: json['short_name'] as String,
      lat: json['lat'] as String,
      lng: json['lng'] as String,
      adVoice: json['ad_voice'] as String,
      voice: json['voice'] as String,
      offVoice: json['off_voice'] as String,
      nextVoice: json['next_voice'] as String,
      playNext: json['play_next'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
      silent: json['silent'] as String,
      length: json['length'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'short_name': shortName,
      'lat': lat,
      'lng': lng,
      'ad_voice': adVoice,
      'voice': voice,
      'off_voice': offVoice,
      'next_voice': nextVoice,
      'play_next': playNext,
      'type': type,
      'icon': icon,
      'color': color,
      'silent': silent,
      'length': length,
    };
  }
}
