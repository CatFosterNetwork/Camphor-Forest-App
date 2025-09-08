import 'package:flutter/material.dart';
import '../../../core/models/theme_model.dart' as custom_theme_model;

class WeekSelectorTabs extends StatefulWidget {
  final int currentWeek;
  final int maxWeek;
  final Function(int) onWeekChanged;
  final custom_theme_model.Theme? customTheme;
  final bool? darkMode;

  const WeekSelectorTabs({
    super.key,
    required this.currentWeek,
    required this.maxWeek,
    required this.onWeekChanged,
    this.customTheme,
    this.darkMode,
  });

  @override
  State<WeekSelectorTabs> createState() => _WeekSelectorTabsState();
}

class _WeekSelectorTabsState extends State<WeekSelectorTabs> {
  late ScrollController _scrollController;
  late int _currentWeekDisplayed;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _currentWeekDisplayed = widget.currentWeek;
    // 延迟滚动到当前周，确保布局完成
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentWeek();
    });
  }

  @override
  void didUpdateWidget(WeekSelectorTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentWeek != widget.currentWeek) {
      _currentWeekDisplayed = widget.currentWeek;
      _scrollToCurrentWeek();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // 滚动到当前选中的周次
  void _scrollToCurrentWeek() {
    if (!_scrollController.hasClients) return;

    // 计算需要滚动的位置
    final estimatedTabWidth = 66.0; // 预估每个tab的宽度(60 + 12 margin)
    final screenWidth = MediaQuery.of(context).size.width;

    // 确保当前周在有效范围内
    final safeCurrentWeek = _currentWeekDisplayed.clamp(1, widget.maxWeek);
    final offset = (safeCurrentWeek - 1) * estimatedTabWidth;

    // 尝试将当前选中项居中
    final scrollTo = offset - (screenWidth / 2) + (estimatedTabWidth / 2);

    // 限制在有效滚动范围内
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final scrollOffset = scrollTo.clamp(0.0, maxScrollExtent);

    // 平滑滚动
    _scrollController.animateTo(
      scrollOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = widget.darkMode ?? (theme.brightness == Brightness.dark);

    // 获取主题颜色
    final primaryColor = widget.customTheme?.colorList.isNotEmpty == true
        ? widget.customTheme!.colorList.first
        : theme.colorScheme.primary;
    final textColor = isDarkMode
        ? const Color(0xFFBFC2C9)
        : (widget.customTheme?.foregColor ?? Colors.black54);

    // 渲染周次标签
    List<Widget> buildWeekTabs() {
      // 确保最少显示20周
      final totalWeeks = widget.maxWeek > 20 ? widget.maxWeek : 20;

      return List.generate(totalWeeks, (index) {
        final weekNumber = index + 1;
        final isSelected = weekNumber == widget.currentWeek;

        return GestureDetector(
          onTap: () {
            _currentWeekDisplayed = weekNumber;
            widget.onWeekChanged(weekNumber);
          },
          child: Container(
            width: 60, // 增加宽度，防止文字溢出
            margin: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? primaryColor : Colors.transparent,
                  width: 2.0,
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Text(
                      '第$weekNumber周',
                      style: TextStyle(
                        color: isSelected ? primaryColor : textColor,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: isSelected ? 15 : 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      });
    }

    return Container(
      height: 44, // 增加高度，给文字更多的空间
      decoration: const BoxDecoration(color: Colors.transparent),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              theme.scaffoldBackgroundColor.withAlpha(128),
              theme.scaffoldBackgroundColor.withAlpha(0),
              theme.scaffoldBackgroundColor.withAlpha(0),
              theme.scaffoldBackgroundColor.withAlpha(128),
            ],
            stops: const [0.0, 0.05, 0.95, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstOut,
        child: ListView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: buildWeekTabs(),
        ),
      ),
    );
  }
}
