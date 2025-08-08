// lib/pages/lifeService/pages/exam_query_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/theme_aware_scaffold.dart';

/// 考试查询页面
class ExamQueryScreen extends ConsumerStatefulWidget {
  const ExamQueryScreen({super.key});

  @override
  ConsumerState<ExamQueryScreen> createState() => _ExamQueryScreenState();
}

class _ExamQueryScreenState extends ConsumerState<ExamQueryScreen> {
  List<dynamic> _exams = [];
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apiService = ref.read(apiServiceProvider);
      final exams = await apiService.getExamInfo();
      
      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    return ThemeAwareScaffold(
      pageType: PageType.other,
      appBar: ThemeAwareAppBar(
        title: '考试查询',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadExams,
          ),
        ],
      ),
      body: _buildBody(isDarkMode),
    );
  }

  Widget _buildBody(bool isDarkMode) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('加载中...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              '加载失败',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadExams,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDarkMode ? Colors.blue.shade300 : Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无考试安排',
              style: TextStyle(
                fontSize: 18,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '当前没有考试信息',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _exams.length,
        itemBuilder: (context, index) {
          final exam = _exams[index] as Map<String, dynamic>;
          return _buildExamCard(exam, isDarkMode);
        },
      ),
    );
  }

  Widget _buildExamCard(Map<String, dynamic> exam, bool isDarkMode) {
    final courseName = exam['courseName'] ?? '未知课程';
    final examTime = exam['examTime'] ?? '';
    final location = exam['location'] ?? '';
    final examType = exam['examType'] ?? '';
    final seatNumber = exam['seatNumber']?.toString() ?? '';
    final duration = exam['duration']?.toString() ?? '';

    return Card(
      color: isDarkMode ? Colors.grey.shade800 : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 课程名称和考试类型
            Row(
              children: [
                Expanded(
                  child: Text(
                    courseName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                if (examType.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getExamTypeColor(examType, isDarkMode).withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      examType,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getExamTypeColor(examType, isDarkMode),
                      ),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // 考试时间
            if (examTime.isNotEmpty)
              _buildInfoRow(
                Icons.access_time,
                '考试时间',
                examTime,
                isDarkMode,
              ),
            
            // 考试地点
            if (location.isNotEmpty)
              _buildInfoRow(
                Icons.location_on,
                '考试地点',
                location,
                isDarkMode,
              ),
            
            // 座位号
            if (seatNumber.isNotEmpty)
              _buildInfoRow(
                Icons.event_seat,
                '座位号',
                seatNumber,
                isDarkMode,
              ),
            
            // 考试时长
            if (duration.isNotEmpty)
              _buildInfoRow(
                Icons.timer,
                '考试时长',
                '$duration分钟',
                isDarkMode,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isDarkMode ? Colors.white54 : Colors.black54,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.white70 : Colors.black54,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getExamTypeColor(String examType, bool isDarkMode) {
    switch (examType) {
      case '期末考试':
      case '期中考试':
        return Colors.red;
      case '补考':
        return Colors.orange;
      case '重修':
        return Colors.amber;
      case '毕业考试':
        return Colors.purple;
      default:
        return isDarkMode ? Colors.blue.shade300 : Colors.blue;
    }
  }
}