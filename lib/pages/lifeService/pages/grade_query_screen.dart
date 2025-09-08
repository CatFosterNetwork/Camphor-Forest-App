// lib/pages/lifeService/pages/grade_query_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/providers/grade_provider.dart';
import '../../../core/widgets/theme_aware_scaffold.dart';
import '../widgets/grade_normal_tab.dart';
import '../widgets/grade_transcript_tab.dart';
import '../widgets/grade_voucher_tab.dart';

/// 成绩查询页面
class GradeQueryScreen extends ConsumerStatefulWidget {
  const GradeQueryScreen({super.key});

  @override
  ConsumerState<GradeQueryScreen> createState() => _GradeQueryScreenState();
}

class _GradeQueryScreenState extends ConsumerState<GradeQueryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final gradeState = ref.watch(gradeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme?.colorList.isNotEmpty == true
        ? currentTheme!.colorList[0]
        : Colors.blue;

    return ThemeAwareScaffold(
      pageType: PageType.other,
      appBar: AppBar(
        title: Text(
          '成绩查询',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
        toolbarHeight: 56, // 增加AppBar高度
        actions: [
          if (_currentTabIndex == 0) // 只在普通成绩页显示刷新按钮
            IconButton(
              icon: gradeState.isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: gradeState.isLoading
                  ? null
                  : () => ref.read(gradeProvider.notifier).refreshGrades(),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70), // 增加Tab区域高度
          child: Container(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            // 移除boxShadow
            child: TabBar(
              controller: _tabController,
              indicatorColor: themeColor,
              indicatorWeight: 3,
              labelColor: themeColor,
              unselectedLabelColor: isDarkMode
                  ? Colors.white70
                  : Colors.black54,
              labelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(vertical: 4), // 增加Tab内边距
              tabs: const [
                Tab(icon: Icon(Icons.school, size: 20), text: '成绩查询'),
                Tab(icon: Icon(Icons.description, size: 20), text: '成绩单'),
                Tab(icon: Icon(Icons.verified, size: 20), text: '电子凭证'),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isDarkMode ? Colors.grey.shade900 : Colors.grey.shade50,
              isDarkMode ? Colors.black : Colors.white,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: const [
            GradeNormalTab(),
            GradeTranscriptTab(),
            GradeVoucherTab(),
          ],
        ),
      ),
    );
  }
}
