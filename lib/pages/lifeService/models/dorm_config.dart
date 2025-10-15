// lib/pages/lifeService/models/dorm_config.dart

/// 宿舍楼栋配置
class DormConfig {
  static const Map<String, Map<String, int>> dormitories = {
    '楠园': {
      "1舍": 100121,
      "2舍": 100122,
      "3舍": 100123,
      "4舍": 100124,
      "5舍": 100125,
      "6舍": 100126,
      "7舍": 100127,
      "8舍": 100128,
      "9舍": 100129,
    },
    '梅园': {"1舍": 100049, "2舍": 100050, "3舍": 100051, "4舍": 100052},
    '桃园': {
      "1舍": 100073,
      "2舍": 100074,
      "3舍": 100075,
      "4舍": 100076,
      "5舍": 100077,
      "6舍": 100078,
      "7舍": 100079,
      "8舍": 100080,
      "11舍": 100070,
      "12舍": 100072,
    },
    '竹园': {
      "1舍": 100108,
      "2舍": 100110,
      "3舍": 100111,
      "4舍": 100112,
      "5舍": 100113,
      "6舍": 100114,
      "7舍": 100115,
      "8舍": 100116,
      "9舍": 100117,
    },
    '橘园': {
      "3舍": 100138,
      "4舍": 100139,
      "5舍": 100140,
      "6舍": 100141,
      "7舍": 100142,
      "8舍": 100143,
      "9舍": 100144,
      "10舍": 100134,
      "11舍": 100135,
      "12舍": 100136,
      "13舍": 100137,
    },
    '李园': {
      "1舍": 100040,
      "2舍": 100041,
      "3舍": 100042,
      "4舍": 100043,
      "5舍": 100044,
      "6舍": 100045,
      "7舍": 100046,
      "8舍": 100047,
    },
    '杏园': {
      "1舍": 100093,
      "2舍": 100094,
      "3舍": 100095,
      "4舍": 100096,
      "5舍": 100097,
      "6舍": 100098,
      "7舍": 100099,
      "8舍": 100100,
    },
    '榕园': {"1舍": 100131, "2舍": 100132, "3舍": 100133},
    '茶园': {
      "1舍": 100014,
      "2舍": 100015,
      "3舍": 100016,
      "4舍": 100017,
      "5舍": 100018,
      "6舍": 100019,
    },
    '斑竹村': {
      "146号": 100001,
      "154号": 100002,
      "155号": 100003,
      "156号": 100004,
      "157号": 100005,
      "158号": 100006,
      "19栋144号": 100007,
      "22栋151号": 100008,
    },
    '北区博士后公寓': {"1单元": 100009, "2单元": 100010, "3单元": 100011},
    '学苑小区': {"7号楼": 100102},
    '文化村': {"18栋": 100087},
    '南区博士后公寓': {
      '154': 100054,
      '155': 100055,
      '156': 100056,
      '157': 100057,
      '158': 100058,
    },
    '天生路': {"41号": 100083},
    '石岗村': {'14': 100062},
    '土地沟': {"土地沟": 100086},
    '紫云楼': {"紫云楼": 100120},
    '四新村': {
      "231号": 100063,
      "232号": 100064,
      "233号": 100065,
      "234号": 100066,
      "235号": 100067,
      "236号": 100068,
    },
    '新房子': {"7栋": 100091},
    '垃圾房': {'桃园2舍': 100038},
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
    return {'area': area, 'building': building, 'buildingId': buildingId};
  }

  factory DormInfo.fromJson(Map<String, dynamic> json) {
    return DormInfo(
      area: json['area'] as String,
      building: json['building'] as String,
      buildingId: json['buildingId'] as int,
    );
  }
}
