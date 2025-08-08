// lib/pages/lifeService/models/dorm_config.dart

/// 宿舍楼栋配置
class DormConfig {
  static const Map<String, Map<String, int>> dormitories = {
    '橘园': {
      '1舍': 100066,
      '2舍': 100078,
      '3舍': 100079,
      '4舍': 100080,
      '5舍': 100081,
      '6舍': 100082,
      '7舍': 100043,
      '8舍': 100039,
      '9舍': 100038,
      '10舍': 100040,
      '11舍': 100041,
      '12舍': 100042,
      '13舍': 100022,
    },
    '竹园': {
      '1区A栋': 100024,
      '1区B栋': 100025,
      '1区C栋': 100026,
      '1区D栋': 100027,
      '1区E栋': 100028,
      '1区F栋': 100029,
      '2区1舍': 100023,
      '2区2舍': 100030,
      '2区3舍': 100031,
      '2区4舍': 100032,
      '2区5舍': 100033,
      '2区6舍': 100034,
      '2区7舍': 100067,
      '2区8舍': 100068,
      '2区9舍': 100069,
    },
    '杏园': {
      'A栋': 100001,
      'B栋': 100002,
      'C栋': 100003,
      'D栋': 100004,
      'E栋': 100005,
      'F栋': 100006,
    },
    '梅园': {
      '1舍': 100021,
      '2舍': 100054,
      '3舍': 100055,
      '4舍': 100056,
    },
    '桃园': {
      '1舍': 100057,
      '2舍': 100058,
      '3舍': 100059,
      '4舍': 100060,
      '5舍': 100061,
      '6舍': 100063,
    },
    '楠园': {
      '1舍': 100044,
      '2舍': 100045,
      '3舍': 100046,
      '4舍': 100047,
      '5舍': 100048,
      '6舍': 100049,
      '7舍': 100050,
      '8舍': 100062,
      '9舍': 100052,
      '13舍': 100053,
    },
    '李园': {
      '1舍': 100070,
      '2舍': 100071,
      '3舍': 100072,
      '4舍': 100073,
      '5舍': 100074,
      '6舍': 100075,
      '7舍': 100076,
      '8舍': 100077,
    },
    '黄树村': {
      '22栋': 100085,
      '23栋': 100086,
    },
    '文化村': {
      '10舍': 100084,
      '11舍': 100083,
    },
    '博士生公寓': {
      '1号楼': 100087,
      '2号楼': 100088,
    },
  };

  /// 获取所有园区列表
  static List<String> get areas => dormitories.keys.toList();

  /// 根据园区获取楼栋列表
  static List<String> getBuildingsByArea(String area) {
    return dormitories[area]?.keys.toList() ?? [];
  }

  /// 根据园区和楼栋获取ID
  static int? getBuildingId(String area, String building) {
    return dormitories[area]?[building];
  }

  /// 根据ID查找宿舍信息
  static DormInfo? findDormByBuildingId(int buildingId) {
    for (final area in dormitories.entries) {
      for (final building in area.value.entries) {
        if (building.value == buildingId) {
          return DormInfo(
            area: area.key,
            building: building.key,
            buildingId: buildingId,
          );
        }
      }
    }
    return null;
  }

  /// 格式化显示名称
  static String formatDisplayName(String area, String building) {
    return '$area $building';
  }

  /// 验证宿舍配置是否有效
  static bool isValidDorm(String area, String building) {
    return dormitories[area]?.containsKey(building) ?? false;
  }
}

/// 宿舍信息
class DormInfo {
  final String area;
  final String building;
  final int buildingId;

  const DormInfo({
    required this.area,
    required this.building,
    required this.buildingId,
  });

  String get displayName => DormConfig.formatDisplayName(area, building);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DormInfo &&
        other.area == area &&
        other.building == building &&
        other.buildingId == buildingId;
  }

  @override
  int get hashCode => Object.hash(area, building, buildingId);

  @override
  String toString() => displayName;

  Map<String, dynamic> toJson() {
    return {
      'area': area,
      'building': building,
      'buildingId': buildingId,
    };
  }

  factory DormInfo.fromJson(Map<String, dynamic> json) {
    return DormInfo(
      area: json['area'] as String,
      building: json['building'] as String,
      buildingId: json['buildingId'] as int,
    );
  }
}