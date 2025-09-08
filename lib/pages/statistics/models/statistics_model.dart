// lib/pages/statistics/models/statistics_model.dart

class CourseStatistics {
  final List<CourseStatisticsData> courses;

  CourseStatistics({required this.courses});

  factory CourseStatistics.fromJson(Map<String, dynamic> json) {
    return CourseStatistics(
      courses:
          (json['courses'] as List?)
              ?.map((e) => CourseStatisticsData.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'courses': courses.map((e) => e.toJson()).toList()};
  }
}

class CourseStatisticsData {
  final String courseId;
  final String courseName;
  final double averageGrade;
  final double passRate;
  final double rate60_69;
  final double rate70_79;
  final double rate80_89;
  final double rate90_100;
  final double failRate;
  final Map<int, int> scoreDistribution; // 分数: 人数

  CourseStatisticsData({
    required this.courseId,
    required this.courseName,
    required this.averageGrade,
    required this.passRate,
    required this.rate60_69,
    required this.rate70_79,
    required this.rate80_89,
    required this.rate90_100,
    required this.failRate,
    required this.scoreDistribution,
  });

  factory CourseStatisticsData.fromJson(Map<String, dynamic> json) {
    return CourseStatisticsData(
      courseId: json['courseId'] ?? '',
      courseName: json['courseName'] ?? '',
      averageGrade: (json['averageGrade'] ?? 0).toDouble(),
      passRate: (json['passRate'] ?? 0).toDouble(),
      rate60_69: (json['rate60_69'] ?? 0).toDouble(),
      rate70_79: (json['rate70_79'] ?? 0).toDouble(),
      rate80_89: (json['rate80_89'] ?? 0).toDouble(),
      rate90_100: (json['rate90_100'] ?? 0).toDouble(),
      failRate: (json['failRate'] ?? 0).toDouble(),
      scoreDistribution: Map<int, int>.from(
        (json['scoreDistribution'] as Map?)?.map(
              (key, value) => MapEntry(int.parse(key.toString()), value as int),
            ) ??
            {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'courseName': courseName,
      'averageGrade': averageGrade,
      'passRate': passRate,
      'rate60_69': rate60_69,
      'rate70_79': rate70_79,
      'rate80_89': rate80_89,
      'rate90_100': rate90_100,
      'failRate': failRate,
      'scoreDistribution': scoreDistribution.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    };
  }

  // 从API数据创建的工厂方法
  factory CourseStatisticsData.fromApi({
    required String courseId,
    required String courseName,
    required Map<String, dynamic> apiData,
  }) {
    // 解析API返回的统计数据
    final statistics = apiData['statistics'] as List<dynamic>? ?? [];
    final Map<int, int> scoreDistribution = {};

    // 先对statistics数组按分数排序（参考微信小程序的实现）
    final sortedStatistics = statistics.toList()
      ..sort((a, b) {
        if (a is List && b is List && a.length >= 2 && b.length >= 2) {
          final scoreA = a[0] as int;
          final scoreB = b[0] as int;
          return scoreA.compareTo(scoreB);
        }
        return 0;
      });

    // 将排序后的statistics数组转换为分数分布Map
    for (final item in sortedStatistics) {
      if (item is List && item.length >= 2) {
        final score = item[0] as int;
        final count = item[1] as int;
        scoreDistribution[score] = count;
      }
    }

    // 计算总人数和通过人数
    final totalStudents = scoreDistribution.values.fold(0, (a, b) => a + b);
    final passCount = scoreDistribution.entries
        .where((entry) => entry.key >= 60)
        .fold(0, (sum, entry) => sum + entry.value);

    // 计算各等级段比例
    final rate60_69 = totalStudents > 0
        ? scoreDistribution.entries
                  .where((entry) => entry.key >= 60 && entry.key < 70)
                  .fold(0, (sum, entry) => sum + entry.value) /
              totalStudents
        : 0.0;

    final rate70_79 = totalStudents > 0
        ? scoreDistribution.entries
                  .where((entry) => entry.key >= 70 && entry.key < 80)
                  .fold(0, (sum, entry) => sum + entry.value) /
              totalStudents
        : 0.0;

    final rate80_89 = totalStudents > 0
        ? scoreDistribution.entries
                  .where((entry) => entry.key >= 80 && entry.key < 90)
                  .fold(0, (sum, entry) => sum + entry.value) /
              totalStudents
        : 0.0;

    final rate90_100 = totalStudents > 0
        ? scoreDistribution.entries
                  .where((entry) => entry.key >= 90)
                  .fold(0, (sum, entry) => sum + entry.value) /
              totalStudents
        : 0.0;

    // 计算平均分
    final averageGrade = totalStudents > 0
        ? scoreDistribution.entries.fold(
                0.0,
                (sum, entry) => sum + (entry.key * entry.value),
              ) /
              totalStudents
        : 0.0;

    // 计算通过率和不通过率
    final passRate = totalStudents > 0 ? passCount / totalStudents : 0.0;
    final failRate = 1.0 - passRate;

    return CourseStatisticsData(
      courseId: courseId,
      courseName: courseName,
      averageGrade: averageGrade,
      passRate: passRate,
      rate60_69: rate60_69,
      rate70_79: rate70_79,
      rate80_89: rate80_89,
      rate90_100: rate90_100,
      failRate: failRate,
      scoreDistribution: scoreDistribution,
    );
  }
}
