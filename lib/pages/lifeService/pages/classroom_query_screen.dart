// lib/pages/lifeService/pages/classroom_query_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/providers/theme_config_provider.dart';
import '../../../core/providers/core_providers.dart';
import '../../../core/widgets/theme_aware_scaffold.dart';
import '../models/region_model.dart';

/// 空教室查询页面
class ClassroomQueryScreen extends ConsumerStatefulWidget {
  const ClassroomQueryScreen({super.key});

  @override
  ConsumerState<ClassroomQueryScreen> createState() =>
      _ClassroomQueryScreenState();
}

class _ClassroomQueryScreenState extends ConsumerState<ClassroomQueryScreen> {
  String _selectedRegion = '南区';
  String _selectedBuilding = '30教';
  List<int> _selectedWeeks = [0]; // 当前周次
  List<int> _selectedWeekdays = [0]; // 周一
  List<int> _selectedPeriods = [0]; // 第1-2节

  List<ClassroomResult> _classrooms = [];
  bool _isLoading = false;
  final List<String> _weekdayLabels = [
    '周一',
    '周二',
    '周三',
    '周四',
    '周五',
    '周六',
    '周日',
  ];
  final List<String> _periodLabels = List.generate(12, (i) => '第${i + 1}节');

  @override
  void initState() {
    super.initState();
    // 初始化默认选择
    _selectedBuilding = RegionConfig.getBuildings(_selectedRegion).first;
  }

  Future<void> _searchClassrooms() async {
    if (!_isFormComplete()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('请填写完整信息')));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = ref.read(apiServiceProvider);

      // 构建查询参数
      final query = ClassroomQuery(
        region: _selectedRegion,
        building: _selectedBuilding,
        weeks: _selectedWeeks,
        weekdays: _selectedWeekdays,
        periods: _selectedPeriods,
      );

      final params = query.toApiParams();
      final result = await apiService.getClassroom(
        xqhId: params['xqhId']!,
        zcd: params['zcd']!,
        xqj: params['xqj']!,
        jcd: params['jcd']!,
        lh: params['lh']!,
      );

      if (result['success'] == true) {
        // 根据实际API响应结构解析数据：res.data.data.items
        final data = result['data'] as Map<String, dynamic>?;
        final items = data?['items'] as List<dynamic>? ?? [];

        final classrooms = items
            .map(
              (item) => ClassroomResult.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        classrooms.sort((a, b) {
          // 获取教室编号的后半部分，去掉数字前缀
          final partsA = a.cdbh.split('-').length > 1
              ? a.cdbh.split('-')[1]
              : a.cdbh.replaceAll(RegExp(r'^\d+'), '');
          final partsB = b.cdbh.split('-').length > 1
              ? b.cdbh.split('-')[1]
              : b.cdbh.replaceAll(RegExp(r'^\d+'), '');

          // 提取楼层和房间号
          final aFloor = int.tryParse(partsA.substring(0, 2)) ?? 0;
          final aRoom = int.tryParse(partsA.substring(2, 4)) ?? 0;
          final bFloor = int.tryParse(partsB.substring(0, 2)) ?? 0;
          final bRoom = int.tryParse(partsB.substring(2, 4)) ?? 0;

          if (aFloor != bFloor) {
            return aFloor.compareTo(bFloor);
          }
          return aRoom.compareTo(bRoom);
        });

        setState(() {
          _classrooms = classrooms;
          _isLoading = false;
        });

        if (_classrooms.isEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('没有查询到空教室')));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('查询成功，找到${_classrooms.length}间空教室')),
          );
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['msg']?.toString() ?? '查询失败')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('查询失败: $e')));
    }
  }

  bool _isFormComplete() {
    return _selectedWeeks.isNotEmpty &&
        _selectedWeekdays.isNotEmpty &&
        _selectedPeriods.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final currentTheme = ref.watch(selectedCustomThemeProvider);
    final themeColor = currentTheme?.colorList.isNotEmpty == true
        ? currentTheme!.colorList[0]
        : Colors.blue;

    return ThemeAwareScaffold(
      pageType: PageType.settings,
      useBackground: false,
      appBar: ThemeAwareAppBar(title: '空教室查询'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchForm(isDarkMode, themeColor),
            const SizedBox(height: 16),
            if (_classrooms.isNotEmpty) _buildResults(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm(bool isDarkMode, Color themeColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 区域与楼栋
            _buildSectionTile(
              title: '区域与楼栋',
              subtitle: '$_selectedRegion $_selectedBuilding',
              onTap: () => _showRegionPicker(isDarkMode, themeColor),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 12),
            _buildDivider(isDarkMode),
            const SizedBox(height: 12),

            // 周次
            _buildSectionTile(
              title: '周次',
              subtitle: _selectedWeeks.isEmpty
                  ? '请选择'
                  : _selectedWeeks.map((i) => '第${i + 1}周').join('、'),
              onTap: () => _showWeeksPicker(isDarkMode, themeColor),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 12),
            _buildDivider(isDarkMode),
            const SizedBox(height: 12),

            // 星期
            _buildSectionTile(
              title: '星期',
              subtitle: _selectedWeekdays.isEmpty
                  ? '请选择'
                  : _selectedWeekdays.map((i) => _weekdayLabels[i]).join('、'),
              onTap: () => _showWeekdaysPicker(isDarkMode, themeColor),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 12),
            _buildDivider(isDarkMode),
            const SizedBox(height: 12),

            // 节数
            _buildSectionTile(
              title: '节数',
              subtitle: _selectedPeriods.isEmpty
                  ? '请选择'
                  : _selectedPeriods.map((i) => _periodLabels[i]).join('、'),
              onTap: () => _showPeriodsPicker(isDarkMode, themeColor),
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: 24),

            // 查询按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchClassrooms,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFormComplete()
                      ? themeColor
                      : (isDarkMode
                            ? Colors.grey.shade600
                            : Colors.grey.shade400),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        '查询',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDarkMode,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                subtitle,
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_right,
              color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDarkMode) {
    return Container(
      height: 1,
      color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
    );
  }

  // 显示校区和楼栋选择器
  void _showRegionPicker(bool isDarkMode, Color themeColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                '选择区域与楼栋',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: RegionConfig.getRegions().length,
                itemBuilder: (context, regionIndex) {
                  final region = RegionConfig.getRegions()[regionIndex];
                  final buildings = RegionConfig.getBuildings(region);

                  return ExpansionTile(
                    title: Text(
                      region,
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    children: buildings.map((building) {
                      return ListTile(
                        title: Text(
                          building,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        trailing:
                            _selectedRegion == region &&
                                _selectedBuilding == building
                            ? Icon(Icons.check, color: themeColor)
                            : null,
                        onTap: () {
                          setState(() {
                            _selectedRegion = region;
                            _selectedBuilding = building;
                          });
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 显示周次选择器
  void _showWeeksPicker(bool isDarkMode, Color themeColor) {
    List<int> tempSelected = List.from(_selectedWeeks);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '选择周次',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedWeeks = tempSelected;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 20,
                  itemBuilder: (context, index) {
                    final isSelected = tempSelected.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            tempSelected.remove(index);
                          } else {
                            tempSelected.add(index);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor
                              : (isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '第${index + 1}周',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? Colors.white : Colors.black),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 显示星期选择器
  void _showWeekdaysPicker(bool isDarkMode, Color themeColor) {
    List<int> tempSelected = List.from(_selectedWeekdays);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '选择星期',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedWeekdays = tempSelected;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final isSelected = tempSelected.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            tempSelected.remove(index);
                          } else {
                            tempSelected.add(index);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor
                              : (isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _weekdayLabels[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? Colors.white : Colors.black),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 显示节次选择器
  void _showPeriodsPicker(bool isDarkMode, Color themeColor) {
    List<int> tempSelected = List.from(_selectedPeriods);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade900 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '选择节次',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedPeriods = tempSelected;
                        });
                        Navigator.pop(context);
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: GridView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    final isSelected = tempSelected.contains(index);
                    return GestureDetector(
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            tempSelected.remove(index);
                          } else {
                            tempSelected.add(index);
                          }
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? themeColor
                              : (isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            _periodLabels[index],
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : (isDarkMode ? Colors.white : Colors.black),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withAlpha(128)
            : Colors.white.withAlpha(204),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '教室名称',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '教室类型',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '教室容量',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._classrooms.map(
              (classroom) => _buildClassroomRow(classroom, isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassroomRow(ClassroomResult classroom, bool isDarkMode) {
    // 处理教室编号显示（移除数字前缀）
    final displayName = classroom.cdbh.replaceAll(RegExp(r'^\d+-'), '');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              classroom.cdlbmc,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              classroom.zws,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white70 : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
