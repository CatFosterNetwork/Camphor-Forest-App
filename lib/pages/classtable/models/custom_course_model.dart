/// 自定义课程模型
class CustomCourse {
  final String id;
  final String title; // 课程名称
  final String? teacher; // 教师
  final String? classroom; // 教室
  final int weekday; // 星期几 (1-7)
  final int startTime; // 开始节次
  final int endTime; // 结束节次
  final List<int> weeks; // 上课周次
  final String? description; // 课程描述
  final String courseType; // 课程类型：必修课、选修课、通识课等
  final String xnm; // 学年
  final String xqm; // 学期
  final DateTime createdAt; // 创建时间
  final DateTime updatedAt; // 更新时间

  const CustomCourse({
    required this.id,
    required this.title,
    this.teacher,
    this.classroom,
    required this.weekday,
    required this.startTime,
    required this.endTime,
    required this.weeks,
    this.description,
    this.courseType = '自定义课程',
    required this.xnm,
    required this.xqm,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 从 JSON 创建实例
  factory CustomCourse.fromJson(Map<String, dynamic> json) {
    return CustomCourse(
      id: json['id'] as String,
      title: json['title'] as String,
      teacher: json['teacher'] as String?,
      classroom: json['classroom'] as String?,
      weekday: json['weekday'] as int,
      startTime: json['startTime'] as int,
      endTime: json['endTime'] as int,
      weeks: List<int>.from(json['weeks'] as List),
      description: json['description'] as String?,
      courseType: json['courseType'] as String? ?? '自定义课程',
      xnm: json['xnm'] as String,
      xqm: json['xqm'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  /// 转换为 JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'teacher': teacher,
      'classroom': classroom,
      'weekday': weekday,
      'startTime': startTime,
      'endTime': endTime,
      'weeks': weeks,
      'description': description,
      'courseType': courseType,
      'xnm': xnm,
      'xqm': xqm,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// 复制并修改部分属性
  CustomCourse copyWith({
    String? id,
    String? title,
    String? teacher,
    String? classroom,
    int? weekday,
    int? startTime,
    int? endTime,
    List<int>? weeks,
    String? description,
    String? courseType,
    String? xnm,
    String? xqm,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomCourse(
      id: id ?? this.id,
      title: title ?? this.title,
      teacher: teacher ?? this.teacher,
      classroom: classroom ?? this.classroom,
      weekday: weekday ?? this.weekday,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      weeks: weeks ?? this.weeks,
      description: description ?? this.description,
      courseType: courseType ?? this.courseType,
      xnm: xnm ?? this.xnm,
      xqm: xqm ?? this.xqm,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取时间段描述
  String get timeDescription {
    if (startTime == endTime) {
      return '第$startTime节';
    } else {
      return '第$startTime-$endTime节';
    }
  }

  /// 获取周次描述
  String get weeksDescription {
    if (weeks.isEmpty) return '';
    if (weeks.length == 1) return '第${weeks.first}周';

    final minWeek = weeks.reduce((a, b) => a < b ? a : b);
    final maxWeek = weeks.reduce((a, b) => a > b ? a : b);

    if (maxWeek - minWeek + 1 == weeks.length) {
      // 连续周次
      return '第$minWeek-$maxWeek周';
    } else {
      // 非连续周次
      return '第${weeks.join(',')}周';
    }
  }

  /// 获取星期描述
  String get weekdayDescription {
    const weekdays = ['', '周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    return weekdays[weekday];
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomCourse && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'CustomCourse(id: $id, title: $title, weekday: $weekday, time: $timeDescription)';
  }
}

/// 历史课表信息
class HistoryClassTable {
  final String xnm; // 学年
  final String xqm; // 学期
  final String displayName; // 显示名称

  const HistoryClassTable({
    required this.xnm,
    required this.xqm,
    required this.displayName,
  });

  factory HistoryClassTable.fromJson(Map<String, dynamic> json) {
    return HistoryClassTable(
      xnm: json['xnm'] as String,
      xqm: json['xqm'] as String,
      displayName: json['displayName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'xnm': xnm, 'xqm': xqm, 'displayName': displayName};
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryClassTable && other.xnm == xnm && other.xqm == xqm;
  }

  @override
  int get hashCode => Object.hash(xnm, xqm);
}
