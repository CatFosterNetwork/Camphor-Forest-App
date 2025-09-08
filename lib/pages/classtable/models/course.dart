class Course {
  final String id; // 课程代码 kch
  final String title; // 课程名称 kcmc
  final String classroom; // 教室 cdmc
  final String teacher; // 教师 xm
  final int weekday; // 周几 1~7 xqj

  /// 节次列表 (如 [1,2,3])
  final List<int> periods;

  /// 开始节次 (periods.first) 兼容旧代码
  int get start => periods.isNotEmpty ? periods.first : 1;

  /// 结束节次 (periods.last) 兼容旧代码
  int get end => periods.isNotEmpty ? periods.last : start;

  /// 开课周次列表 zcd
  final List<int> weeks;

  /// 是否为自定义课程
  final bool isCustom;

  /// 课程类型
  final String? courseType;

  /// 课程性质（必修课、选修课等）
  final String? kcxz;

  /// 课程类别
  final String? kclb;

  const Course({
    required this.id,
    required this.title,
    required this.classroom,
    required this.teacher,
    required this.weekday,
    required this.periods,
    required this.weeks,
    this.isCustom = false,
    this.courseType,
    this.kcxz,
    this.kclb,
  });

  /// 从已格式化的JSON数据创建课程对象
  factory Course.fromFormattedJson(Map<String, dynamic> json) {
    List<int> intList(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v
            .map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList();
      }
      return [];
    }

    // 处理周次特殊情况
    List<int> parseWeeks(dynamic v) {
      if (v == null) return [];

      // 如果已经是数字列表
      if (v is List) {
        return v
            .map((e) => int.tryParse('$e') ?? 0)
            .where((e) => e > 0)
            .toList();
      }

      // 如果是字符串，可能包含类似 "1-16" 或 "1,3,5,7" 这样的格式
      if (v is String) {
        final List<int> result = [];

        // 处理多种可能的分隔符
        final parts = v.split(RegExp(r'[,，;；]'));
        for (final part in parts) {
          if (part.contains('-') || part.contains('~')) {
            // 区间格式: "1-16"
            final range = part.split(RegExp(r'[-~]'));
            if (range.length == 2) {
              final start = int.tryParse(range[0].trim()) ?? 0;
              final end = int.tryParse(range[1].trim()) ?? 0;
              if (start > 0 && end >= start) {
                for (int i = start; i <= end; i++) {
                  result.add(i);
                }
              }
            }
          } else {
            // 单个数字
            final week = int.tryParse(part.trim()) ?? 0;
            if (week > 0) {
              result.add(week);
            }
          }
        }

        return result;
      }

      return [];
    }

    // 解析周次数据
    List<int> weekList = parseWeeks(json['zcd']);

    // 如果周次为空，至少添加第一周保证显示
    if (weekList.isEmpty) {
      weekList = [1];
    }

    return Course(
      id: json['kch']?.toString() ?? '',
      title: json['kcmc']?.toString() ?? '',
      classroom: json['cdmc']?.toString() ?? '',
      teacher: json['xm']?.toString() ?? '',
      weekday: int.tryParse(json['xqj']?.toString() ?? '') ?? 0,
      periods: intList(json['jc']),
      weeks: weekList,
      isCustom: json['isCustom'] == true,
      courseType: json['courseType']?.toString(),
      kcxz: json['kcxz']?.toString(),
      kclb: json['kclb']?.toString(),
    );
  }

  /// 从API返回的原始JSON数据创建课程对象
  factory Course.fromRawJson(Map<String, dynamic> json) {
    // 展开周次范围 (如 "1-16(单)" -> [1, 3, 5, ..., 15])
    List<int> expandRanges(String zcdStr) {
      final List<int> result = [];

      if (zcdStr.isEmpty) return result;

      final ranges = zcdStr.replaceAll('周', '').split(',');

      for (final range in ranges) {
        if (range.isEmpty) continue;

        // 检查是否包含单双周标记
        String rangeStr = range;
        bool isOdd = false;
        bool isEven = false;

        if (range.contains('(')) {
          final parts = range.split('(');
          rangeStr = parts[0];
          final parity = parts[1];
          isOdd = parity == '单)';
          isEven = parity == '双)';
        }

        // 处理范围
        if (rangeStr.contains('-')) {
          final limits = rangeStr.split('-');
          if (limits.length == 2) {
            final start = int.tryParse(limits[0]) ?? 0;
            final end = int.tryParse(limits[1]) ?? 0;

            if (start > 0 && end >= start) {
              for (int i = start; i <= end; i++) {
                if (!isOdd && !isEven ||
                    (isOdd && i % 2 == 1) ||
                    (isEven && i % 2 == 0)) {
                  result.add(i);
                }
              }
            }
          }
        } else {
          // 单个数字
          final week = int.tryParse(rangeStr) ?? 0;
          if (week > 0) {
            result.add(week);
          }
        }
      }

      return result;
    }

    // 展开节次范围 (如 "1-3" -> [1, 2, 3])
    List<int> expandSchedule(String jcStr) {
      final List<int> result = [];

      if (jcStr.isEmpty) return result;

      final ranges = jcStr.replaceAll('节', '').split(',');

      for (final range in ranges) {
        if (range.isEmpty) continue;

        if (range.contains('-')) {
          final parts = range.split('-');
          if (parts.length == 2) {
            final start = int.tryParse(parts[0]) ?? 0;
            final end = int.tryParse(parts[1]) ?? 0;

            if (start > 0 && end >= start) {
              for (int i = start; i <= end; i++) {
                result.add(i);
              }
            }
          }
        } else {
          // 单个数字
          final period = int.tryParse(range) ?? 0;
          if (period > 0) {
            result.add(period);
          }
        }
      }

      return result;
    }

    // 获取周次列表
    final List<int> weeks = expandRanges(json['zcd']?.toString() ?? '');
    // 获取节次列表
    final List<int> periods = expandSchedule(json['jc']?.toString() ?? '');

    return Course(
      id: json['kch']?.toString() ?? '',
      title: json['kcmc']?.toString() ?? '',
      classroom: json['cdmc']?.toString() ?? '',
      teacher: json['xm']?.toString() ?? '',
      weekday: int.tryParse(json['xqj']?.toString() ?? '') ?? 0,
      periods: periods,
      weeks: weeks.isEmpty ? [1] : weeks, // 如果周次为空，至少添加第一周保证显示
      isCustom: json['isCustom'] == true,
      courseType: json['courseType']?.toString(),
      kcxz: json['kcxz']?.toString(),
      kclb: json['kclb']?.toString(),
    );
  }

  /// 向后兼容的原始fromJson方法，等同于fromFormattedJson
  factory Course.fromJson(Map<String, dynamic> json) =>
      Course.fromFormattedJson(json);

  Map<String, dynamic> toJson() => {
    'kch': id,
    'kcmc': title,
    'cdmc': classroom,
    'xm': teacher,
    'xqj': weekday,
    'jc': periods,
    'zcd': weeks,
    'isCustom': isCustom,
    'courseType': courseType,
    'kcxz': kcxz,
    'kclb': kclb,
  };

  @override
  String toString() =>
      'Course{id: $id, title: $title, weekday: $weekday, periods: $periods, weeks: $weeks}';
}
