// lib/pages/lifeService/models/region_model.dart

/// 校区和教学楼配置
class RegionConfig {
  static const Map<String, Map<String, dynamic>> _regions = {
    '南区': {
      '30教': 30,
      '31教': 31,
      '32教': 32,
      '33教': 33,
      '35教': 35,
      '36教': 36,
      '37教': 37,
      '38教': 38,
      '39教': 39,
      '40教': 40,
      '45教': 45,
      '46教': 46,
      '48教': 48,
      '96教': 96,
      '97教': 97,
      '98教': 98,
      'Online Learning': 1001,
      '工科大楼B座': 'GKL-B',
      '无楼号': 'wlh',
      '学生活动中心': 'HDZX',
    },
    '北区': {
      '01教': '01',
      '02教': '02',
      '03教': '03',
      '04教': '04',
      '05教': '05',
      '06教': '06',
      '07教': '07',
      '08教': '08',
      '09教': '09',
      '10教': '10',
      '11教': '11',
      '13教': '13',
      '14教': '14',
      '15教': '15',
      '16教': '16',
      '17教': '17',
      '19教': '19',
      '21教': '21',
      '23教': '23',
      '24教': '24',
      '25教': '25',
      '26教': '26',
      '27教': '27',
      '28教': '28',
      '29教': '29',
      '93教': '93',
      '95教': '95',
      '99教': '99',
      'Online Learning': 1002,
      '传媒实验实训大楼': 'CMSYSX',
      '化学与药学大楼': 'HY01',
      '数学大楼': 'SXDL',
      '新出版楼': 'XCBL',
      '无楼号': 'wlh',
    },
    '荣昌校区': {
      '第零教楼': 'RC00',
      '第一教学楼': 'RC01',
      '第二教学楼': 'RC02',
      '第三教学楼': 'RC03',
      '第四教学楼': 'RC04',
      '第五教学楼': 'RC05',
      '第七教学楼': 'RC7B',
      '第九教学楼': 'RC09',
      'Online Learning': 1003,
      'rc-无楼号': 'rwlh',
      '无楼号': 'wlh',
    },
    '西塔学院': {'无楼号': 'wlh'},
  };

  /// 获取所有校区
  static List<String> getRegions() {
    return _regions.keys.toList();
  }

  /// 获取指定校区的所有教学楼
  static List<String> getBuildings(String region) {
    return _regions[region]?.keys.toList() ?? [];
  }

  /// 获取教学楼ID
  static dynamic getBuildingId(String region, String building) {
    return _regions[region]?[building];
  }

  /// 获取校区ID（用于API调用）
  static int getRegionId(String region) {
    final regions = getRegions();
    return regions.indexOf(region) + 1;
  }
}

/// 空教室查询模型
class ClassroomQuery {
  final String region;
  final String building;
  final List<int> weeks;
  final List<int> weekdays;
  final List<int> periods;

  const ClassroomQuery({
    required this.region,
    required this.building,
    required this.weeks,
    required this.weekdays,
    required this.periods,
  });

  /// 转换为API参数
  Map<String, String> toApiParams() {
    // 计算周次位掩码
    int weekMask = 0;
    for (int week in weeks) {
      weekMask += 1 << week;
    }

    // 计算节次位掩码
    int periodMask = 0;
    for (int period in periods) {
      periodMask += 1 << period;
    }

    return {
      'xqhId': RegionConfig.getRegionId(region).toString(),
      'zcd': weekMask.toString(),
      'xqj': weekdays.map((w) => w + 1).join(','),
      'jcd': periodMask.toString(),
      'lh': RegionConfig.getBuildingId(region, building).toString(),
    };
  }
}

/// 空教室结果模型
class ClassroomResult {
  final String cdId; // 教室ID
  final String cdbh; // 教室编号
  final String cdlbmc; // 教室类别名称
  final String cdmc; // 教室名称
  final String cdjylx; // 教室用途类型
  final String zws; // 总座位数
  final String kszws1; // 考试座位数
  final String xqmc; // 校区名称
  final String jxlmc; // 教学楼名称
  final String lh; // 楼号
  final String lch; // 楼层号
  final String dateDigit; // 日期
  final String date; // 中文日期
  final String year; // 年份
  final String month; // 月份
  final String day; // 日期

  const ClassroomResult({
    required this.cdId,
    required this.cdbh,
    required this.cdlbmc,
    required this.cdmc,
    required this.cdjylx,
    required this.zws,
    required this.kszws1,
    required this.xqmc,
    required this.jxlmc,
    required this.lh,
    required this.lch,
    required this.dateDigit,
    required this.date,
    required this.year,
    required this.month,
    required this.day,
  });

  factory ClassroomResult.fromJson(Map<String, dynamic> json) {
    return ClassroomResult(
      cdId: json['cd_id']?.toString() ?? '',
      cdbh: json['cdbh']?.toString() ?? '',
      cdlbmc: json['cdlbmc']?.toString() ?? '',
      cdmc: json['cdmc']?.toString() ?? '',
      cdjylx: json['cdjylx']?.toString() ?? '',
      zws: json['zws']?.toString() ?? '0',
      kszws1: json['kszws1']?.toString() ?? '0',
      xqmc: json['xqmc']?.toString() ?? '',
      jxlmc: json['jxlmc']?.toString() ?? '',
      lh: json['lh']?.toString() ?? '',
      lch: json['lch']?.toString() ?? '',
      dateDigit: json['dateDigit']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cd_id': cdId,
      'cdbh': cdbh,
      'cdlbmc': cdlbmc,
      'cdmc': cdmc,
      'cdjylx': cdjylx,
      'zws': zws,
      'kszws1': kszws1,
      'xqmc': xqmc,
      'jxlmc': jxlmc,
      'lh': lh,
      'lch': lch,
      'dateDigit': dateDigit,
      'date': date,
      'year': year,
      'month': month,
      'day': day,
    };
  }

  /// 获取数字座位数
  int get seatCount => int.tryParse(zws) ?? 0;

  /// 获取考试座位数
  int get examSeatCount => int.tryParse(kszws1) ?? 0;
}
