// lib/pages/index/widgets/classroom_brief.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../lifeService/models/region_model.dart';
import '../../lifeService/pages/classroom_query_screen.dart';

/// 空教室简要组件
class ClassroomBrief extends ConsumerStatefulWidget {
  final bool blur;
  final bool darkMode;

  const ClassroomBrief({
    super.key,
    required this.blur,
    required this.darkMode,
  });

  @override
  ConsumerState<ClassroomBrief> createState() => _ClassroomBriefState();
}

class _ClassroomBriefState extends ConsumerState<ClassroomBrief> {
  List<ClassroomResult> _classrooms = [];

  @override
  void initState() {
    super.initState();
    _loadStoredClassrooms();
  }

  void _loadStoredClassrooms() {
    // 这里可以从存储加载上次查询的结果
    // 暂时使用空列表
    setState(() {
      _classrooms = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    // 获取主题色
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme?.colorList.isNotEmpty == true 
        ? currentTheme!.colorList[0] 
        : Colors.blue;
    
    final textColor = widget.darkMode ? Colors.white70 : Colors.black87;
    final subtitleColor = widget.darkMode ? Colors.white54 : Colors.black54;

    Widget child = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToClassroomQuery(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题栏
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: themeColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.meeting_room_outlined,
                          color: themeColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '空教室',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  // 右上角箭头
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _navigateToClassroomQuery(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: themeColor.withAlpha(26),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          color: themeColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
          
              const SizedBox(height: 16),
          
              // 内容区域
              if (_classrooms.isNotEmpty) ...[
                _buildClassroomContent(textColor, subtitleColor),
              ] else ...[
                _buildEmptyState(textColor, subtitleColor),
              ],
            ],
          ),
        ),
      ),
    );

    return _applyContainerStyle(child);
  }

  /// 构建空教室内容
  Widget _buildClassroomContent(Color textColor, Color subtitleColor) {
    final classroom = _classrooms.first;
    final displayName = classroom.cdbh.replaceAll(RegExp(r'^\d+'), '');
    final locationName = '${classroom.xqmc}${classroom.jxlmc}';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 教室信息卡片
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.darkMode
                  ? [Colors.blue.shade800.withAlpha(76), Colors.green.shade800.withAlpha(76)]
                  : [Colors.blue.shade50, Colors.green.shade50],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withAlpha(76),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // 教室名称
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (locationName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        locationName,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // 教室信息
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (classroom.dateDigit.isNotEmpty)
                      Text(
                        classroom.dateDigit,
                        style: TextStyle(
                          color: subtitleColor,
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      '可容纳${classroom.zws}人',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建空状态
  Widget _buildEmptyState(Color textColor, Color subtitleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.meeting_room_outlined,
              color: subtitleColor,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              '点击查询空教室',
              style: TextStyle(
                color: Colors.blue.shade600,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 应用容器样式和模糊效果
  Widget _applyContainerStyle(Widget child) {
    Widget styledChild = Container(
      decoration: BoxDecoration(
        color: widget.darkMode 
            ? Colors.grey.shade900.withAlpha(230) 
            : Colors.white.withAlpha(230),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );

    if (widget.blur) {
      styledChild = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: widget.darkMode 
                  ? const Color(0xFF2A2A2A).withAlpha(217)
                  : Colors.white.withAlpha(128),
              borderRadius: BorderRadius.circular(16),
              border: widget.darkMode ? Border.all(
                color: Colors.white.withAlpha(26),
                width: 1,
              ) : null,
            ),
            child: child,
          ),
        ),
      );
    }

    return styledChild;
  }

  /// 导航到空教室查询页面
  void _navigateToClassroomQuery(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ClassroomQueryScreen(),
      ),
    );
  }
}
