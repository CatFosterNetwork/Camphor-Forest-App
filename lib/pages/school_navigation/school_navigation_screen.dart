// lib/pages/school_navigation/school_navigation_screen.dart

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter_baidu_mapapi_map/flutter_baidu_mapapi_map.dart'
    as bmf_map;
import 'package:flutter_baidu_mapapi_base/flutter_baidu_mapapi_base.dart'
    as bmf_base;
import 'package:apple_maps_flutter/apple_maps_flutter.dart' as apple;

import '../../core/config/providers/theme_config_provider.dart';
import '../../core/constants/location.dart';
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

  // 地图控制器
  bmf_map.BMFMapController? _baiduMapController;
  apple.AppleMapController? _appleMapController;

  // 当前显示的覆盖物
  final List<bmf_map.BMFPolyline> _polylines = [];
  final List<bmf_map.BMFMarker> _busStopMarkers = [];
  final List<bmf_map.BMFMarker> _busMarkers = [];
  final List<bmf_map.BMFMarker> _locationMarkers = [];

  // 建筑定位状态
  LocationPoint? _selectedLocation;

  // 用户位置状态
  bool _isLocationEnabled = false;

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 页面不再自行申请定位权限，交由全局权限管理器统一处理

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final busLinesAsync = ref.watch(busLinesProvider);
    final busDataAsync = ref.watch(realTimeBusDataProvider);

    // 监听实时车辆数据变化并更新地图标注
    ref.listen(realTimeBusDataProvider, (previous, next) {
      if (_baiduMapController != null) {
        next.whenData((newBusData) {
          busLinesAsync.whenData((busLines) {
            _updateBusMarkersOnBaiduMap(newBusData, busLines);
          });
        });
      }
      if (_appleMapController != null) {
        next.whenData((newBusData) {
          busLinesAsync.whenData((busLines) {
            _updateBusMarkersOnAppleMap(newBusData, busLines);
          });
        });
      }
    });

    // 监听深色模式变化，动态更新地图样式
    ref.listen(effectiveIsDarkModeProvider, (previous, next) {
      if (previous != null && previous != next) {
        debugPrint('🌓 [主题变化] 检测到主题变化: $previous -> $next');
        if (Platform.isAndroid && _baiduMapController != null) {
          debugPrint('📱 [Android] 开始动态更新百度地图样式...');
          _setBaiduMapDarkMode(_baiduMapController!, next);
        } else if (Platform.isAndroid) {
          debugPrint('⚠️ [Android] 地图控制器为空，跳过样式更新');
        } else {
          debugPrint('🍎 [iOS] Apple Maps会自动适配系统主题，无需手动设置');
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 全屏地图背景
          busLinesAsync.when(
            data: (busLines) =>
                _buildFullScreenMap(busLines, busDataAsync.value ?? []),
            loading: () => Container(
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => Container(
              color: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
              child: _buildErrorWidget(error, isDarkMode),
            ),
          ),

          // 浮动 UI 层
          SafeArea(
            child: Stack(
              children: [
                // 顶部导航栏
                _buildFloatingAppBar(context, isDarkMode),

                // 左侧控制面板
                busLinesAsync.when(
                  data: (busLines) => _buildLeftControlPanel(
                    busDataAsync.value ?? [],
                    isDarkMode,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

                // 左侧线路选择器
                busLinesAsync.when(
                  data: (busLines) =>
                      _buildLeftLineSelector(busLines, isDarkMode),
                  loading: () => const SizedBox.shrink(),
                  error: (error, stack) => const SizedBox.shrink(),
                ),

                // 建筑定位按钮（在线路选择下方）
                _buildBuildingLocationButton(isDarkMode),

                // 用户定位按钮
                _buildUserLocationButton(isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 全屏地图组件
  Widget _buildFullScreenMap(List<BusLine> busLines, List<BusData> busData) {
    final centerLat = 29.82067;
    final centerLng = 106.42478;
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);

    if (Platform.isAndroid) {
      // 百度地图（Android）
      final options = bmf_map.BMFMapOptions(
        center: bmf_base.BMFCoordinate(centerLat, centerLng),
        zoomLevel: 16,
        zoomEnabled: true,
        scrollEnabled: true,
        rotateEnabled: false,
        showMapScaleBar: true,
        // 使用标准地图类型，深色模式通过自定义样式实现
        mapType: bmf_base.BMFMapType.Standard,
      );
      return bmf_map.BMFMapWidget(
        mapOptions: options,
        onBMFMapCreated: (controller) async {
          _baiduMapController = controller;
          await _requestLocationPermission();

          // 设置地图加载完成回调，在地图完全加载后再应用样式
          controller.setMapDidLoadCallback(
            callback: () async {
              debugPrint('🗺️ [地图加载] 地图加载完成，开始应用样式');
              debugPrint('⏱️ [延迟] 等待500ms确保地图完全初始化...');
              // 延迟一下再设置样式，确保地图完全初始化
              await Future.delayed(const Duration(milliseconds: 500));
              debugPrint(
                '🎨 [样式应用] 开始设置地图样式，当前模式: ${isDarkMode ? "深色" : "浅色"}',
              );
              try {
                await _setBaiduMapDarkMode(controller, isDarkMode);
              } catch (e) {
                debugPrint('💥 [回调异常] 地图样式回调中设置失败: $e');
              }
            },
          );

          await _drawBusLinesOnBaiduMap(busLines, isDarkMode);
          _updateBusMarkersOnBaiduMap(busData, busLines);
        },
      );
    }

    if (Platform.isIOS) {
      // Apple 地图（iOS）
      return apple.AppleMap(
        initialCameraPosition: apple.CameraPosition(
          target: apple.LatLng(centerLat, centerLng),
          zoom: 16,
        ),
        mapType: isDarkMode ? apple.MapType.satellite : apple.MapType.standard,
        onMapCreated: (controller) async {
          _appleMapController = controller;
          await _drawBusLinesOnAppleMap(busLines, isDarkMode);
          _updateBusMarkersOnAppleMap(busData, busLines);
        },
      );
    }

    // 其他平台显示占位
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Text('当前平台不支持地图'),
    );
  }

  // 浮动导航栏
  Widget _buildFloatingAppBar(BuildContext context, bool isDarkMode) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 56,
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.grey.shade900.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(
                Icons.arrow_back,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '校园导航',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 左侧控制面板
  Widget _buildLeftControlPanel(List<BusData> busData, bool isDarkMode) {
    return Positioned(
      left: 0,
      top: 80,
      child: Container(
        width: 48,
        height: 120,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // 车辆数量
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${busData.length}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  Text(
                    '车辆',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            // 分割线 1
            Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            // 站点开关
            Expanded(
              child: GestureDetector(
                onTap: () => _toggleStopsVisibility(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '站点',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      showStops ? '开' : '关',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: showStops
                            ? Colors.green.shade400
                            : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 分割线 2
            Container(
              height: 1.5,
              margin: const EdgeInsets.symmetric(horizontal: 8),
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            // 包车按钮
            Expanded(
              child: GestureDetector(
                onTap: _makePhoneCall,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '包车',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 左侧线路选择器
  Widget _buildLeftLineSelector(List<BusLine> busLines, bool isDarkMode) {
    return Positioned(
      left: 0,
      top: 220,
      child: Container(
        width: 48,
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(8),
            bottomRight: Radius.circular(8),
          ),
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(2, 0),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(7), // 略小于外层圆角
            bottomRight: Radius.circular(7),
          ),
          child: ListView.separated(
            itemCount: busLines.length,
            separatorBuilder: (context, index) => Container(
              height: 1,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final line = busLines[index];
              final isSelected = selectedLineIndex == index;
              final lineColor = Color(int.parse('0xFF${line.color}'));
              final isFirst = index == 0;
              final isLast = index == busLines.length - 1;

              return _buildLineItem(
                line,
                isSelected,
                lineColor,
                isFirst,
                isLast,
                index,
                busLines,
                isDarkMode,
              );
            },
          ),
        ),
      ),
    );
  }

  // 构建单个线路项
  Widget _buildLineItem(
    BusLine line,
    bool isSelected,
    Color lineColor,
    bool isFirst,
    bool isLast,
    int index,
    List<BusLine> busLines,
    bool isDarkMode,
  ) {
    return GestureDetector(
      onTap: () => _selectLine(index, busLines),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? lineColor : Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: isFirst ? const Radius.circular(7) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(7) : Radius.zero,
          ),
          border: Border(bottom: BorderSide(color: lineColor, width: 2)),
        ),
        child: Center(
          child: Text(
            line.name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected
                  ? Colors.white
                  : (isDarkMode ? Colors.white70 : Colors.black87),
            ),
            textAlign: TextAlign.center,
          ),
        ),
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

  void _selectLine(int index, List<BusLine> busLines) {
    // 立即更新UI状态
    setState(() {
      if (selectedLineIndex == index) {
        selectedLineIndex = null;
      } else {
        selectedLineIndex = index;
      }
    });

    // 异步重新绘制地图上的线路，不阻塞UI更新
    _updateMapLines(busLines);
  }

  void _updateMapLines(List<BusLine> busLines) async {
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);
    if (Platform.isAndroid && _baiduMapController != null) {
      await _drawBusLinesOnBaiduMap(busLines, isDarkMode);
    } else if (Platform.isIOS && _appleMapController != null) {
      await _drawBusLinesOnAppleMap(busLines, isDarkMode);
    }
  }

  // 切换站点显示/隐藏
  void _toggleStopsVisibility() async {
    setState(() {
      showStops = !showStops;
    });

    // 重新绘制地图（更新站点标注显示状态）
    final busLinesAsync = ref.read(busLinesProvider);
    final isDarkMode = ref.read(effectiveIsDarkModeProvider);

    busLinesAsync.whenData((busLines) async {
      if (Platform.isAndroid && _baiduMapController != null) {
        await _drawBusLinesOnBaiduMap(busLines, isDarkMode);
      } else if (Platform.isIOS && _appleMapController != null) {
        await _drawBusLinesOnAppleMap(busLines, isDarkMode);
      }
    });
  }

  void _makePhoneCall() async {
    const phoneNumber = 'tel:13983202128';
    final uri = Uri.parse(phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('无法拨打电话')));
      }
    }
  }

  // 百度地图绘制公交线路
  Future<void> _drawBusLinesOnBaiduMap(
    List<BusLine> busLines,
    bool isDarkMode,
  ) async {
    if (_baiduMapController == null) return;

    // 清除之前的覆盖物
    await _clearBaiduMapOverlays();

    // 绘制选中的线路或所有线路
    final linesToDraw = selectedLineIndex != null
        ? [busLines[selectedLineIndex!]]
        : busLines;

    for (final busLine in linesToDraw) {
      // 绘制线路折线
      await _drawBusRoutePolyline(busLine, isDarkMode);

      // 绘制站点标注（如果开启显示站点）
      if (showStops) {
        await _drawBusStopMarkers(busLine, isDarkMode);
      }
    }
  }

  // Apple地图绘制公交线路
  Future<void> _drawBusLinesOnAppleMap(
    List<BusLine> busLines,
    bool isDarkMode,
  ) async {
    if (_appleMapController == null) return;

    // Apple Maps 的绘制逻辑（简化版本，因为API限制）
    // 这里主要处理站点标注
    if (showStops) {
      final linesToDraw = selectedLineIndex != null
          ? [busLines[selectedLineIndex!]]
          : busLines;

      for (int i = 0; i < linesToDraw.length; i++) {
        // 在Apple Maps上添加站点标注
        // 注意：Apple Maps的折线绘制需要不同的API
        // TODO: 实现 Apple Maps 的站点标注 for line $i
      }
    }
  }

  // 绘制公交路线折线
  Future<void> _drawBusRoutePolyline(BusLine line, bool isDarkMode) async {
    if (_baiduMapController == null) return;

    final coordinates = line.route
        .map((point) => bmf_base.BMFCoordinate(point.latitude, point.longitude))
        .toList();

    if (coordinates.isEmpty) return;

    // final lineColor = Color(int.parse('0xFF${line.color}')); // 保留供后续使用

    final polyline = bmf_map.BMFPolyline(
      coordinates: coordinates,
      indexs: [0, coordinates.length - 1],
      width: 5,
      // color: lineColor.withOpacity(0.8), // 暂时注释，使用默认颜色
      dottedLine: false,
    );

    _polylines.add(polyline);
    await _baiduMapController!.addPolyline(polyline);
  }

  // 绘制公交站点标注
  Future<void> _drawBusStopMarkers(BusLine line, bool isDarkMode) async {
    if (_baiduMapController == null) return;

    for (int i = 0; i < line.stops.length; i++) {
      final stop = line.stops[i];
      final coordinate = bmf_base.BMFCoordinate(stop.latitude, stop.longitude);

      final marker = bmf_map.BMFMarker.icon(
        position: coordinate,
        identifier: 'bus_stop_${line.id}_$i',
        icon: 'assets/icons/bus_stop.png', // 使用默认图标
      );

      _busStopMarkers.add(marker);
      await _baiduMapController!.addMarker(marker);
    }
  }

  // 更新实时公交车辆标注
  void _updateBusMarkersOnBaiduMap(
    List<BusData> busData,
    List<BusLine> busLines,
  ) async {
    if (_baiduMapController == null) return;

    // 清除之前的车辆标注
    for (final marker in _busMarkers) {
      await _baiduMapController!.removeMarker(marker);
    }
    _busMarkers.clear();

    // 添加新的车辆标注
    for (final bus in busData) {
      // 找到对应的线路（暂时不使用，后续可用于显示线路信息）
      // final line = busLines.firstWhere(
      //   (line) => line.id == bus.lineId,
      //   orElse: () => busLines.first,
      // );

      final coordinate = bmf_base.BMFCoordinate(bus.latitude, bus.longitude);

      final marker = bmf_map.BMFMarker.icon(
        position: coordinate,
        identifier: 'bus_${bus.id}',
        icon: 'assets/icons/bus.png', // 使用默认图标
      );

      _busMarkers.add(marker);
      await _baiduMapController!.addMarker(marker);
    }
  }

  // Apple地图更新车辆标注
  void _updateBusMarkersOnAppleMap(
    List<BusData> busData,
    List<BusLine> busLines,
  ) {
    if (_appleMapController == null) return;

    // Apple Maps 的车辆标注更新逻辑
    // 由于API限制，这里是简化版本
  }

  // 清除百度地图覆盖物
  Future<void> _clearBaiduMapOverlays() async {
    if (_baiduMapController == null) return;

    try {
      // 清除折线
      for (final polyline in _polylines) {
        try {
          await _baiduMapController!.removeOverlay(polyline.id);
        } catch (e) {
          debugPrint('移除折线覆盖物失败: ${polyline.id}, 错误: $e');
        }
      }
      _polylines.clear();

      // 清除站点标注
      for (final marker in _busStopMarkers) {
        try {
          await _baiduMapController!.removeMarker(marker);
        } catch (e) {
          debugPrint('移除站点标注失败: 错误: $e');
        }
      }
      _busStopMarkers.clear();

      // 清除车辆标注
      for (final marker in _busMarkers) {
        try {
          await _baiduMapController!.removeMarker(marker);
        } catch (e) {
          debugPrint('移除车辆标注失败: 错误: $e');
        }
      }
      _busMarkers.clear();

      // 清除位置标注
      for (final marker in _locationMarkers) {
        try {
          await _baiduMapController!.removeMarker(marker);
        } catch (e) {
          debugPrint('移除位置标注失败: 错误: $e');
        }
      }
      _locationMarkers.clear();
    } catch (e) {
      debugPrint('清理地图覆盖物时出现异常: $e');
      // 即使出现异常，也要清理本地列表
      _polylines.clear();
      _busStopMarkers.clear();
      _busMarkers.clear();
      _locationMarkers.clear();
    }
  }

  // 安全清理地图覆盖物（用于dispose）
  void _clearBaiduMapOverlaysSafely() {
    try {
      debugPrint('开始安全清理地图覆盖物...');

      // 只清理本地列表，不调用可能已失效的地图API
      final polylineCount = _polylines.length;
      final busStopCount = _busStopMarkers.length;
      final busCount = _busMarkers.length;
      final locationCount = _locationMarkers.length;

      _polylines.clear();
      _busStopMarkers.clear();
      _busMarkers.clear();
      _locationMarkers.clear();

      debugPrint(
        '安全清理完成 - 折线: $polylineCount, 站点: $busStopCount, 车辆: $busCount, 位置: $locationCount',
      );
    } catch (e) {
      debugPrint('安全清理地图覆盖物时出现异常: $e');
    }
  }

  // 建筑定位按钮
  Widget _buildBuildingLocationButton(bool isDarkMode) {
    return Positioned(
      left: 0, // 贴住左侧边框
      top: 220 + MediaQuery.of(context).size.height * 0.4 + 10, // 放在线路选择下方
      child: GestureDetector(
        onTap: _showAllBuildingsSheet,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.location_city_rounded,
            size: 24,
            color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  // 显示所有建筑的弹窗
  void _showAllBuildingsSheet() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey.shade900 : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDarkMode ? 0.5 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                // 顶部拖拽指示器和标题
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      // 拖拽指示器
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // 标题
                      Row(
                        children: [
                          const SizedBox(width: 20),
                          Icon(
                            Icons.location_city_rounded,
                            color: Colors.blue,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '校园建筑定位',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: Icon(
                              Icons.close,
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 搜索框
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: '搜索建筑...',
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
                              },
                              icon: const Icon(Icons.clear, color: Colors.grey),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: isDarkMode
                              ? Colors.grey.shade600
                              : Colors.grey.shade300,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.blue),
                      ),
                      filled: true,
                      fillColor: isDarkMode
                          ? Colors.grey.shade800
                          : Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),

                // 所有建筑的网格列表
                Expanded(child: _buildAllBuildingsGrid(scrollController)),
              ],
            ),
          );
        },
      ),
    );
  }

  // 所有建筑的分类列表
  Widget _buildAllBuildingsGrid(ScrollController scrollController) {
    if (_searchQuery.isNotEmpty) {
      // 搜索模式：显示搜索结果
      return _buildSearchResults(scrollController);
    } else {
      // 正常模式：显示分类列表
      final locationTypes = CampusLocations.getAllLocationTypes();

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: locationTypes.length,
        itemBuilder: (context, index) {
          final type = locationTypes[index];
          final locations = CampusLocations.getLocationsByType(type);
          return _buildCategorySection(type, locations);
        },
      );
    }
  }

  // 搜索结果列表
  Widget _buildSearchResults(ScrollController scrollController) {
    final allLocations = CampusLocations.getAllLocationPoints();
    final filteredLocations = allLocations
        .where(
          (location) => location.content.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    if (filteredLocations.isEmpty) {
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '未找到相关建筑',
              style: TextStyle(
                fontSize: 16,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '尝试使用其他关键词搜索',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: (filteredLocations.length / 2).ceil(),
      itemBuilder: (context, index) {
        final startIndex = index * 2;
        final endIndex = (startIndex + 1).clamp(0, filteredLocations.length);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              // 左侧建筑
              Expanded(
                child: _buildBuildingGridItem(
                  filteredLocations[startIndex],
                  _getCategoryForLocation(filteredLocations[startIndex]),
                ),
              ),
              const SizedBox(width: 12),
              // 右侧建筑（如果存在）
              Expanded(
                child: endIndex < filteredLocations.length
                    ? _buildBuildingGridItem(
                        filteredLocations[endIndex],
                        _getCategoryForLocation(filteredLocations[endIndex]),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 根据位置获取类别（用于搜索结果）
  String _getCategoryForLocation(LocationPoint location) {
    final types = CampusLocations.getAllLocationTypes();
    for (final type in types) {
      final locations = CampusLocations.getLocationsByType(type);
      if (locations.any((loc) => loc.id == location.id)) {
        return type;
      }
    }
    return '其他';
  }

  // 构建分类区域
  Widget _buildCategorySection(String category, List<LocationPoint> locations) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分类标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _getCategoryIcon(category, size: 24),
              const SizedBox(width: 12),
              Text(
                category,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${locations.length})',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode
                      ? Colors.grey.shade400
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // 该分类下的建筑网格
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 2.8, // 增加高度以显示更多文字
            crossAxisSpacing: 12,
            mainAxisSpacing: 8,
          ),
          itemCount: locations.length,
          itemBuilder: (context, index) {
            final location = locations[index];
            return _buildBuildingGridItem(location, category);
          },
        ),

        const SizedBox(height: 16), // 分类间距
      ],
    );
  }

  // 建筑网格项
  Widget _buildBuildingGridItem(LocationPoint location, String category) {
    final isSelected = _selectedLocation?.id == location.id;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isDarkMode ? Colors.blue.shade900 : Colors.blue.shade50)
            : (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? (isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200)
              : (isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _markLocationOnMap(location),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                // 类型图标
                _getCategoryIcon(category, size: 16),
                const SizedBox(width: 8),
                // 建筑名称
                Expanded(
                  child: Text(
                    location.content,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? (isDarkMode
                                ? Colors.blue.shade200
                                : Colors.blue.shade800)
                          : (isDarkMode ? Colors.white70 : Colors.black87),
                      height: 1.2, // 行高调整
                    ),
                    maxLines: 3, // 允许3行显示
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // 导航按钮
                GestureDetector(
                  onTap: () => _navigateToLocationWithMapLauncher(location),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.navigation,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 获取类别图标
  Widget _getCategoryIcon(String category, {double size = 20}) {
    IconData iconData;
    Color backgroundColor;

    switch (category) {
      case '餐厅位置':
        iconData = Icons.restaurant_rounded;
        backgroundColor = Colors.orange;
        break;
      case '宿舍位置':
        iconData = Icons.home_rounded;
        backgroundColor = Colors.purple;
        break;
      case '北碚校门':
        iconData = Icons.door_front_door_rounded;
        backgroundColor = Colors.brown;
        break;
      case '图书馆位置':
        iconData = Icons.local_library_rounded;
        backgroundColor = Colors.blue;
        break;
      case '运动场位置':
        iconData = Icons.sports_soccer_rounded;
        backgroundColor = Colors.green;
        break;
      case '景点':
        iconData = Icons.landscape_rounded;
        backgroundColor = Colors.teal;
        break;
      case '教室位置':
        iconData = Icons.school_rounded;
        backgroundColor = Colors.red;
        break;
      default:
        iconData = Icons.location_on_rounded;
        backgroundColor = Colors.grey;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(iconData, size: size * 0.6, color: Colors.white),
    );
  }

  // 用户定位按钮
  Widget _buildUserLocationButton(bool isDarkMode) {
    return Positioned(
      left: 0, // 贴住左侧边框
      top: 220 + MediaQuery.of(context).size.height * 0.4 + 70, // 放在建筑定位按钮下方
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey.shade800 : Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(
              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDarkMode ? 0.3 : 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            onTap: _locateUser,
            child: Icon(
              Icons.my_location_rounded,
              size: 24,
              color: isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }

  // 使用 map_launcher 导航到位置
  void _navigateToLocationWithMapLauncher(LocationPoint location) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      if (availableMaps.isNotEmpty) {
        if (availableMaps.length == 1) {
          // 只有一个导航应用，直接使用
          Navigator.of(context).pop();
          await availableMaps.first.showDirections(
            destination: Coords(location.latitude, location.longitude),
            destinationTitle: location.content,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '正在使用 ${availableMaps.first.mapName} 导航到 ${location.content}',
                ),
                duration: const Duration(seconds: 2),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          // 多个导航应用，让用户选择
          _showMapSelectionSheet(location, availableMaps);
        }
      } else {
        // 没有可用的地图应用，使用备用方案
        _navigateToLocationFallback(location);
      }
    } catch (e) {
      debugPrint('启动导航失败: $e');
      _navigateToLocationFallback(location);
    }
  }

  // 显示地图选择弹窗
  void _showMapSelectionSheet(
    LocationPoint location,
    List<AvailableMap> availableMaps,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 拖拽指示器
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? Colors.grey.shade600
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.navigation, color: Colors.blue, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '选择导航应用',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // 导航应用列表
              ...availableMaps.map(
                (map) => ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.grey.shade700
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map, color: Colors.blue),
                  ),
                  title: Text(
                    map.mapName,
                    style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  subtitle: Text(
                    '导航到 ${location.content}',
                    style: TextStyle(
                      color: isDarkMode
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(context).pop(); // 关闭选择弹窗
                    Navigator.of(context).pop(); // 关闭建筑列表弹窗

                    try {
                      await map.showDirections(
                        destination: Coords(
                          location.latitude,
                          location.longitude,
                        ),
                        destinationTitle: location.content,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '正在使用 ${map.mapName} 导航到 ${location.content}',
                            ),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      debugPrint('启动 ${map.mapName} 失败: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('启动 ${map.mapName} 失败'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
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

  // 备用导航方案
  void _navigateToLocationFallback(LocationPoint location) async {
    final latitude = location.latitude;
    final longitude = location.longitude;
    final name = Uri.encodeComponent(location.content);

    // 构建不同导航应用的 URL（按优先级排序）
    final urls = [
      // 百度地图（Android 优先）
      if (Platform.isAndroid)
        'baidumap://map/direction?destination=$latitude,$longitude&destination_name=$name&mode=driving',
      // Apple 地图（iOS 优先）
      if (Platform.isIOS) 'maps://maps.apple.com/?daddr=$latitude,$longitude',
      // 高德地图
      'amapuri://route/plan/?dlat=$latitude&dlon=$longitude&dname=$name&dev=0&t=0',
      // 腾讯地图
      'qqmap://map/routeplan?type=drive&tocoord=$latitude,$longitude&toname=$name',
      // Google 地图
      'google.navigation:q=$latitude,$longitude',
      // 通用地图链接（兜底）
      'geo:$latitude,$longitude?q=$latitude,$longitude($name)',
    ];

    // 尝试打开第一个可用的导航应用
    bool launched = false;
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        continue;
      }
    }

    // 如果都无法打开，显示错误提示
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('未找到可用的导航应用'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: '复制坐标',
            textColor: Colors.white,
            onPressed: () => _copyLocationInfo(location),
          ),
        ),
      );
    }
  }

  // 在地图上标记位置
  void _markLocationOnMap(LocationPoint location) async {
    // 关闭底部弹窗
    Navigator.of(context).pop();

    setState(() {
      _selectedLocation = location;
    });

    if (Platform.isAndroid && _baiduMapController != null) {
      await _markLocationOnBaiduMap(location);
    } else if (Platform.isIOS && _appleMapController != null) {
      await _markLocationOnAppleMap(location);
    }
  }

  // 在百度地图上标记位置
  Future<void> _markLocationOnBaiduMap(LocationPoint location) async {
    if (_baiduMapController == null) return;

    // 清除之前的位置标注
    for (final marker in _locationMarkers) {
      await _baiduMapController!.removeMarker(marker);
    }
    _locationMarkers.clear();

    // 添加新的位置标注
    final coordinate = bmf_base.BMFCoordinate(
      location.latitude,
      location.longitude,
    );
    final marker = bmf_map.BMFMarker.icon(
      position: coordinate,
      identifier: 'location_${location.id}',
      icon: 'assets/icons/location_marker.png',
    );

    _locationMarkers.add(marker);
    await _baiduMapController!.addMarker(marker);

    // 移动地图中心到该位置
    await _baiduMapController!.setCenterCoordinate(coordinate, true);

    // 显示信息提示
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已定位到 ${location.content}')));
    }
  }

  // 在 Apple 地图上标记位置
  Future<void> _markLocationOnAppleMap(LocationPoint location) async {
    if (_appleMapController == null) return;

    // Apple Maps 的位置标注实现
    // 由于 API 限制，这里是简化版本
    // TODO: 实现 Apple Maps 的位置标注功能
  }

  // 复制位置信息
  void _copyLocationInfo(LocationPoint location) async {
    final locationText =
        '${location.content}\n坐标: ${location.latitude}, ${location.longitude}';
    await Clipboard.setData(ClipboardData(text: locationText));

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('已复制 ${location.content} 的坐标')));
    }
  }

  // 请求定位权限
  Future<void> _requestLocationPermission() async {
    try {
      // 检查定位权限
      final status = await Permission.location.status;

      if (status.isDenied) {
        // 请求权限
        final result = await Permission.location.request();
        if (result.isGranted) {
          setState(() {
            _isLocationEnabled = true;
          });
          _enableUserLocation();
        } else {
          _showLocationPermissionDialog();
        }
      } else if (status.isGranted) {
        setState(() {
          _isLocationEnabled = true;
        });
        _enableUserLocation();
      } else if (status.isPermanentlyDenied) {
        _showLocationPermissionDialog();
      }
    } catch (e) {
      debugPrint('请求定位权限失败: $e');
    }
  }

  // 设置百度地图深色模式
  Future<void> _setBaiduMapDarkMode(
    bmf_map.BMFMapController controller,
    bool isDarkMode,
  ) async {
    try {
      debugPrint('设置地图样式为: ${isDarkMode ? "深色模式" : "标准模式"}');

      if (isDarkMode) {
        debugPrint('🌙 [深色模式] 开始配置深色地图...');

        // 按照官方demo的方式设置.sty样式文件
        try {
          debugPrint('📁 [STY文件] 使用files/路径加载.sty样式文件...');

          // 先设置样式文件（使用.sty格式）
          final result = await controller.setCustomMapStyle(
            'files/dark_map_style.sty',
            0, // 0: 本地文件模式
          );
          debugPrint('📄 [STY文件] setCustomMapStyle返回结果: $result');

          if (result) {
            // 然后启用自定义样式
            final enableResult = await controller.setCustomMapStyleEnable(true);
            debugPrint('🎯 [STY文件] setCustomMapStyleEnable返回结果: $enableResult');
            debugPrint('🎉 [STY成功] 深色模式配置完成！');
            return;
          } else {
            debugPrint('❌ [STY失败] .sty文件设置失败');
          }
        } catch (e) {
          debugPrint('💥 [STY异常] .sty文件设置异常: $e');
        }

        debugPrint('😞 [全部失败] 所有深色模式设置方法都失败了');
      } else {
        // 禁用深色模式：使用标准地图样式
        debugPrint('☀️ [标准模式] 正在禁用自定义样式...');
        final disableResult = await controller.setCustomMapStyleEnable(false);
        debugPrint(
          '🎯 [标准模式] setCustomMapStyleEnable(false)返回结果: $disableResult',
        );
        debugPrint('✅ [标准模式] 标准样式恢复完成');
      }
    } catch (e) {
      debugPrint('设置地图样式失败: $e');
    }
  }

  // 启用用户定位
  void _enableUserLocation() async {
    if (_baiduMapController != null) {
      try {
        // 设置显示用户位置
        await _baiduMapController!.showUserLocation(true);
      } catch (e) {
        debugPrint('启用用户定位失败: $e');
      }
    }
  }

  // 定位到用户位置
  void _locateUser() async {
    if (!_isLocationEnabled) {
      await _requestLocationPermission();
      return;
    }

    if (_baiduMapController != null) {
      try {
        // 启用用户位置显示
        await _baiduMapController!.showUserLocation(true);

        // 设置地图跟踪用户位置 (暂时注释，API可能已变化)
        // await _baiduMapController!.setUserTrackingMode(true);

        // 显示成功提示
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('正在定位到您的位置...'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        debugPrint('定位失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('定位失败，请检查位置权限'),
              duration: Duration(seconds: 2),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // 显示定位权限对话框
  void _showLocationPermissionDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('需要定位权限'),
        content: const Text('为了在地图上显示您的位置，需要获取定位权限。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    // 安全清理地图覆盖物
    _clearBaiduMapOverlaysSafely();
    _searchController.dispose();
    super.dispose();
  }
}
