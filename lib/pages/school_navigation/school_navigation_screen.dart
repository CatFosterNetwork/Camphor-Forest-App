// lib/pages/school_navigation/school_navigation_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/providers/theme_config_provider.dart';
import '../../widgets/app_background.dart';
import 'models/bus_models.dart';
import 'providers/bus_provider.dart';

class SchoolNavigationScreen extends ConsumerStatefulWidget {
  const SchoolNavigationScreen({super.key});

  @override
  ConsumerState<SchoolNavigationScreen> createState() =>
      _SchoolNavigationScreenState();
}

class _SchoolNavigationScreenState
    extends ConsumerState<SchoolNavigationScreen> {
  int? selectedLineIndex;
  bool showStops = true;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final busLinesAsync = ref.watch(busLinesProvider);
    final busDataAsync = ref.watch(realTimeBusDataProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(blur: false),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, isDarkMode),
                Expanded(
                  child: busLinesAsync.when(
                    data: (busLines) => _buildContent(
                      busLines,
                      busDataAsync.value ?? [],
                      isDarkMode,
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (error, stack) =>
                        _buildErrorWidget(error, isDarkMode),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDarkMode) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.black.withOpacity(0.3)
            : Colors.white.withOpacity(0.3),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '校园导航',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    List<BusLine> busLines,
    List<BusData> busData,
    bool isDarkMode,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 地图占位符
          _buildMapPlaceholder(isDarkMode),
          const SizedBox(height: 16),
          // 控制面板
          _buildControlPanel(busData, isDarkMode),
          const SizedBox(height: 16),
          // 线路列表
          Expanded(child: _buildLinesList(busLines, isDarkMode)),
        ],
      ),
    );
  }

  Widget _buildMapPlaceholder(bool isDarkMode) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDarkMode ? Colors.white24 : Colors.black12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map,
              size: 48,
              color: isDarkMode ? Colors.white54 : Colors.black26,
            ),
            const SizedBox(height: 8),
            Text(
              '校园地图',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.white54 : Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '西南大学校园导航',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlPanel(List<BusData> busData, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // 车辆数量
          Column(
            children: [
              Text(
                '${busData.length}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade600,
                ),
              ),
              Text(
                '车辆',
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          // 站点开关
          GestureDetector(
            onTap: () => setState(() => showStops = !showStops),
            child: Column(
              children: [
                Text(
                  '站点',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: showStops ? Colors.green : Colors.grey,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    showStops ? '显示' : '隐藏',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // 包车按钮
          GestureDetector(
            onTap: _makePhoneCall,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone, color: Colors.white, size: 20),
                ),
                const SizedBox(height: 4),
                Text(
                  '包车',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesList(List<BusLine> busLines, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.grey.shade800.withOpacity(0.7)
            : Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '公交线路',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: busLines.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: isDarkMode ? Colors.white12 : Colors.black12,
              ),
              itemBuilder: (context, index) {
                final line = busLines[index];
                final isSelected = selectedLineIndex == index;

                return ListTile(
                  onTap: () => _selectLine(index),
                  leading: Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Color(int.parse('0xFF${line.color}')),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  title: Text(
                    line.name,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  subtitle: Text(
                    '${line.stops.length} 个站点',
                    style: TextStyle(
                      color: isDarkMode ? Colors.white54 : Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Color(int.parse('0xFF${line.color}')),
                        )
                      : null,
                  selected: isSelected,
                  selectedTileColor: Color(
                    int.parse('0xFF${line.color}'),
                  ).withOpacity(0.1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Object error, bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: isDarkMode ? Colors.white54 : Colors.black26,
          ),
          const SizedBox(height: 16),
          Text(
            '加载失败',
            style: TextStyle(
              fontSize: 16,
              color: isDarkMode ? Colors.white54 : Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              ref.invalidate(busLinesProvider);
            },
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  void _selectLine(int index) {
    setState(() {
      if (selectedLineIndex == index) {
        selectedLineIndex = null;
      } else {
        selectedLineIndex = index;
      }
    });
  }

  void _makePhoneCall() async {
    const phoneNumber = 'tel:13983202128';
    if (await canLaunchUrl(Uri.parse(phoneNumber))) {
      await launchUrl(Uri.parse(phoneNumber));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法拨打电话')));
      }
    }
  }
}
