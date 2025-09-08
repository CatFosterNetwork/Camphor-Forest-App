/// 学期起止日期配置
/// 根据西南大学校历精确配置每个学期的开始和结束日期
class SemesterConfig {
  /// 所有学期的配置数据
  /// 格式: "年份-学期" -> {"start": "开始日期", "end": "结束日期"}
  /// 其中年份为学年（如2024表示2024-2025学年），学期为3（秋季）或12（春季）
  static const Map<String, Map<String, String>> _semesterData = {
    // 2018-2019学年
    "2018-3": {"start": "2018-09-03", "end": "2019-01-20"},
    "2018-12": {"start": "2019-02-25", "end": "2019-07-07"},

    // 2019-2020学年
    "2019-3": {"start": "2019-09-02", "end": "2020-01-12"},
    "2019-12": {"start": "2020-02-24", "end": "2020-07-12"},

    // 2020-2021学年
    "2020-3": {"start": "2020-09-07", "end": "2021-01-24"},
    "2020-12": {"start": "2021-03-01", "end": "2021-07-11"},

    // 2021-2022学年
    "2021-3": {"start": "2021-09-06", "end": "2022-01-16"},
    "2021-12": {"start": "2022-02-28", "end": "2022-07-10"},

    // 2022-2023学年
    "2022-3": {"start": "2022-09-05", "end": "2023-01-15"},
    "2022-12": {"start": "2023-02-20", "end": "2023-07-09"},

    // 2023-2024学年
    "2023-3": {"start": "2023-09-04", "end": "2024-01-14"},
    "2023-12": {"start": "2024-02-26", "end": "2024-07-14"},

    // 2024-2025学年
    "2024-3": {"start": "2024-09-02", "end": "2025-01-12"},
    "2024-12": {"start": "2025-02-24", "end": "2025-07-13"},

    // 2025-2026学年
    "2025-3": {"start": "2025-09-01", "end": "2026-01-18"},
    "2025-12": {"start": "2026-03-02", "end": "2026-07-12"},
  };

  /// 获取学期开始日期
  static DateTime getSemesterStart(String xnm, String xqm) {
    final key = "$xnm-$xqm";
    final semesterInfo = _semesterData[key];

    if (semesterInfo != null && semesterInfo["start"] != null) {
      return DateTime.parse(semesterInfo["start"]!);
    }

    // 如果配置中没有该学期，使用默认计算逻辑作为后备
    return _getDefaultSemesterStart(xnm, xqm);
  }

  /// 获取学期结束日期
  static DateTime getSemesterEnd(String xnm, String xqm) {
    final key = "$xnm-$xqm";
    final semesterInfo = _semesterData[key];

    if (semesterInfo != null && semesterInfo["end"] != null) {
      return DateTime.parse(semesterInfo["end"]!);
    }

    // 如果配置中没有该学期，使用默认计算逻辑作为后备
    return _getDefaultSemesterEnd(xnm, xqm);
  }

  /// 默认学期开始日期计算（后备方案）
  static DateTime _getDefaultSemesterStart(String xnm, String xqm) {
    final year = int.tryParse(xnm) ?? DateTime.now().year;

    if (xqm == '3') {
      // 秋季学期：9月第一周的星期一
      return DateTime(year, 9, 2);
    } else if (xqm == '12') {
      // 春季学期：次年2月最后一周的星期一
      return DateTime(year + 1, 2, 24);
    } else {
      // 夏季学期或其他
      return DateTime(year + 1, 6, 15);
    }
  }

  /// 默认学期结束日期计算（后备方案）
  static DateTime _getDefaultSemesterEnd(String xnm, String xqm) {
    final year = int.tryParse(xnm) ?? DateTime.now().year;

    if (xqm == '3') {
      // 秋季学期：次年1月中旬
      return DateTime(year + 1, 1, 15);
    } else if (xqm == '12') {
      // 春季学期：当年7月中旬
      return DateTime(year + 1, 7, 15);
    } else {
      // 夏季学期或其他
      return DateTime(year + 1, 8, 31);
    }
  }

  /// 获取当前学期的开始日期（兼容旧代码）
  static DateTime get start {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 计算当前学期
    final currentXnm = currentMonth < 7
        ? (currentYear - 1).toString()
        : currentYear.toString();
    final currentXqm = currentMonth < 7 ? '12' : '3';

    return getSemesterStart(currentXnm, currentXqm);
  }

  /// 获取当前学期的结束日期（兼容旧代码）
  static DateTime get end {
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;

    // 计算当前学期
    final currentXnm = currentMonth < 7
        ? (currentYear - 1).toString()
        : currentYear.toString();
    final currentXqm = currentMonth < 7 ? '12' : '3';

    return getSemesterEnd(currentXnm, currentXqm);
  }

  /// 检查指定学期是否有配置数据
  static bool hasSemesterConfig(String xnm, String xqm) {
    return _semesterData.containsKey("$xnm-$xqm");
  }

  /// 获取所有已配置的学期列表
  static List<String> getAvailableSemesters() {
    return _semesterData.keys.toList()..sort();
  }
}
