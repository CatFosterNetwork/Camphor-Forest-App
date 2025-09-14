// lib/pages/school_navigation/school_navigation_screen.dart

import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
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
import 'utils/bus_icon_utils.dart';

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
  final List<bmf_map.BMFText> _stationLabels = []; // 存储站点名称标签

  // 建筑定位状态
  LocationPoint? _selectedLocation;

  // 用户位置状态
  bool _isLocationEnabled = false;

  // 位置流监听
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLocationStreamActive = false;

  // 磁力计传感器监听（获取设备朝向）
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  double _currentDeviceHeading = 0.0;

  // 最后的GPS位置（用于磁力计更新时保持位置）
  Position? _lastGpsPosition;

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Marker缩放相关参数
  static const double _initialZoomLevel = 16.0; // 初始缩放级别
  static const double _baseScaleFactor = 1.08; // 缩放因子（每级放大8%，适中变化）
  double _currentZoomLevel = _initialZoomLevel;

  // Text Label缩放相关参数
  static const double _baseLabelFontSize = 12.0; // 基础字体大小
  static const double _labelZoomFactor = 1.02; // 标签缩放因子（每级放大2%）
  static const double _baseLabelOffset = 0.00015; // 基础偏移距离

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final busLinesAsync = ref.watch(busLinesProvider);
    final busDataAsync = ref.watch(realTimeBusDataProvider);

    // 🎨 监听主题变化并重新渲染标签
    ref.listen(effectiveIsDarkModeProvider, (previous, next) {
      if (previous != null && previous != next) {
        debugPrint(
          '🎨 [主题变化] 检测到主题切换: ${previous ? "深色" : "浅色"} → ${next ? "深色" : "浅色"}',
        );

        // 重新渲染所有标签以适配新主题
        if (_stationLabels.isNotEmpty && _busStopMarkers.isNotEmpty) {
          debugPrint('🔄 [重新渲染] 开始重新渲染 ${_stationLabels.length} 个站点标签...');

          // 异步重新渲染标签，避免阻塞UI
          Future.microtask(() async {
            await _renderUniqueStationLabels();
          });
        }
      }
    });

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

              // 🎯 地图加载完成，自动启动定位
              debugPrint('🗺️ [地图就绪] 地图加载完成，开始自动定位...');
              await _startAutoLocationOnMapLoad();
            },
          );

          // 设置地图状态改变回调，用于监听缩放级别变化
          controller.setMapStatusDidChangedCallback(
            callback: () async {
              try {
                final zoomLevel = await controller.getZoomLevel();
                if (zoomLevel != null && zoomLevel != _currentZoomLevel) {
                  debugPrint(
                    '🔍 [缩放监听] 缩放级别从 $_currentZoomLevel 变为 $zoomLevel',
                  );
                  _currentZoomLevel = zoomLevel.toDouble();

                  // 动态调整所有marker的尺寸
                  await _updateMarkersScale();

                  // 🏷️ 动态调整所有标签的样式和位置
                  await _updateLabelsScale();
                }
              } catch (e) {
                debugPrint('💥 [缩放监听异常] $e');
              }
            },
          );

          // 设置marker点击回调，用于显示气泡信息
          controller.setMapClickedMarkerCallback(
            callback: (marker) {
              debugPrint('🎯 [Marker点击] 收到marker点击事件');
              debugPrint('📝 [Marker信息] id: ${marker.id}');
              debugPrint('📝 [Marker信息] identifier: ${marker.identifier}');
              debugPrint('📝 [Marker信息] title: ${marker.title}');
              debugPrint('📝 [Marker信息] subtitle: ${marker.subtitle}');

              // 尝试从本地列表中找到对应的marker (使用id而不是identifier)
              bmf_map.BMFMarker? actualMarker = _findMarkerById(marker);

              if (actualMarker != null) {
                debugPrint('✅ [找到Marker] 在本地列表中找到了对应的marker');
                debugPrint(
                  '📍 [实际信息] title: ${actualMarker.title}, subtitle: ${actualMarker.subtitle}',
                );
                // 🔧 显示marker信息弹窗
                _showMarkerInfoDialog(actualMarker);
              } else {
                debugPrint('❌ [未找到] 无法在本地列表中找到对应的marker');
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
        mapType: apple.MapType.standard, // 始终使用标准地图，让系统自动适配深色模式
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

    // 🚌 立即更新车辆标注以匹配选中的线路
    final busDataAsync = ref.read(realTimeBusDataProvider);
    busDataAsync.whenData((busData) {
      if (Platform.isAndroid && _baiduMapController != null) {
        _updateBusMarkersOnBaiduMap(busData, busLines);
      } else if (Platform.isIOS && _appleMapController != null) {
        _updateBusMarkersOnAppleMap(busData, busLines);
      }
    });
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
        ).showSnackBar(const SnackBar(content: Text('无法拨打电话，已复制电话号码')));
        await Clipboard.setData(ClipboardData(text: phoneNumber));
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
    if (selectedLineIndex != null) {
      // 只绘制选中的线路，并高亮显示
      final selectedLine = busLines[selectedLineIndex!];
      await _drawBusRoutePolyline(selectedLine, isDarkMode, selectedLineIndex!);

      // 绘制站点标注（如果开启显示站点）
      if (showStops) {
        await _drawBusStopMarkers(selectedLine, isDarkMode);
      }
    } else {
      // 绘制所有线路，都不高亮
      for (int i = 0; i < busLines.length; i++) {
        await _drawBusRoutePolyline(busLines[i], isDarkMode, i);

        // 绘制站点标注（如果开启显示站点）
        if (showStops) {
          await _drawBusStopMarkers(busLines[i], isDarkMode);
        }
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
  Future<void> _drawBusRoutePolyline(
    BusLine line,
    bool isDarkMode,
    int lineIndex,
  ) async {
    if (_baiduMapController == null) return;

    final coordinates = line.route
        .map((point) => bmf_base.BMFCoordinate(point.latitude, point.longitude))
        .toList();

    final lineColor = Color(int.parse('0xFF${line.color}'));

    // 判断当前线路是否被选中
    final isSelected = selectedLineIndex == lineIndex;

    // 为选中线路使用更高亮的样式，考虑深色模式
    Color highlightColor;
    if (isSelected) {
      // 选中时使用更鲜艳的颜色，在深色模式下更亮
      highlightColor = isDarkMode
          ? lineColor.withValues(alpha: 1.0) // 深色模式下完全不透明
          : lineColor.withValues(alpha: 0.95); // 浅色模式下略微透明
    } else {
      // 未选中时使用半透明，在深色模式下稍微更亮
      highlightColor = isDarkMode
          ? lineColor.withValues(alpha: 0.7) // 深色模式下保持可见
          : lineColor.withValues(alpha: 0.5); // 浅色模式下更透明
    }

    final lineWidth = isSelected ? 9 : 7; // 提高对比度

    final polyline = bmf_map.BMFPolyline(
      coordinates: coordinates,
      colors: [highlightColor], // 使用高对比度颜色和透明度
      indexs: [0, coordinates.length - 1], // 颜色索引
      width: lineWidth, // 调整线宽
      dottedLine: false,
      isFocus: isSelected, // 选中时使用发光效果进行高亮
      zIndex: isSelected ? 15 : 5, // 确保选中线路在最上层显示
    );

    _polylines.add(polyline);
    await _baiduMapController!.addPolyline(polyline);
  }

  // 绘制公交站点标注
  Future<void> _drawBusStopMarkers(BusLine line, bool isDarkMode) async {
    if (_baiduMapController == null) return;

    List<bmf_map.BMFMarker> markers = [];

    for (int i = 0; i < line.stops.length; i++) {
      final stop = line.stops[i];
      final coordinate = bmf_base.BMFCoordinate(stop.latitude, stop.longitude);

      // 调试输出站点信息
      debugPrint('🚏 [站点${i + 1}] ${line.name}线 - ${stop.name}');

      final stationName = stop.name.isNotEmpty ? stop.name : '站点${i + 1}';
      final stationSubtitle = '${line.name}线 • 点击查看详情';
      final stationId = 'bus_stop_${line.id}_$i';

      debugPrint(
        '📝 [创建Marker] identifier: $stationId, 标题: $stationName, 副标题: $stationSubtitle',
      );

      // 使用自定义图标创建车站标记点
      final marker = bmf_map.BMFMarker.icon(
        position: coordinate, // 指定标记点的经纬度坐标
        identifier: stationId,
        icon: 'assets/icons/bus_stop.png', // 使用校车站点图标
        title: stationName, // 确保有站点名称
        centerOffset: bmf_base.BMFPoint(0, -12), // 调整标记点位置
        zIndex: 20, // 设置显示层级
        enabled: true, // 启用触摸事件
        canShowCallout: true, // 可以显示信息气泡
        // 缩放相关设置
        isPerspective: true, // 启用透视效果，让标记随地图缩放
        scaleX: 1.0, // 使用默认大小
        scaleY: 1.0, // 使用默认大小
        // 锚点设置：图标中心对准坐标点
        anchorX: 0.5, // 水平居中
        anchorY: 0.5, // 垂直居中
      );

      markers.add(marker);
      _busStopMarkers.add(marker);

      // 验证marker添加到本地列表后的信息
      debugPrint(
        '✅ [本地保存] Marker已添加到_busStopMarkers列表，当前总数: ${_busStopMarkers.length}',
      );
      debugPrint('   BMFOverlay.id: ${marker.id}'); // 显示自动生成的唯一ID
      debugPrint('   identifier: ${marker.identifier}'); // 显示我们设置的identifier
    }

    // 优化批量添加性能：并行处理而非串行等待
    final List<Future<void>> addMarkerFutures = markers
        .map((marker) => _baiduMapController!.addMarker(marker))
        .toList();

    // 并行执行所有添加操作
    await Future.wait(addMarkerFutures);

    debugPrint('🗺️ [地图添加完成] 已添加 ${markers.length} 个站点marker到地图上');

    // 🎯 添加站点后自动重新渲染站点名称标签
    await _renderUniqueStationLabels();
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

    if (busData.isEmpty) return;

    // 🚌 根据选中的线路过滤车辆数据
    List<BusData> filteredBusData;
    if (selectedLineIndex != null) {
      // 只显示选中线路的车辆
      final selectedLine = busLines[selectedLineIndex!];
      filteredBusData = busData
          .where((bus) => bus.lineId == selectedLine.id)
          .toList();
      debugPrint(
        '🚌 [车辆过滤] 选中线路: ${selectedLine.name}, 过滤后车辆数: ${filteredBusData.length}/${busData.length}',
      );
    } else {
      // 显示所有车辆
      filteredBusData = busData;
      debugPrint('🚌 [车辆过滤] 显示所有线路车辆: ${filteredBusData.length}');
    }

    if (filteredBusData.isEmpty) return;

    List<bmf_map.BMFMarker> markers = [];

    // 添加新的车辆标注
    for (final bus in filteredBusData) {
      // 找到对应的线路，用于显示线路信息
      final line = busLines.firstWhere(
        (line) => line.id == bus.lineId,
        orElse: () => busLines.first,
      );

      final coordinate = bmf_base.BMFCoordinate(bus.latitude, bus.longitude);

      // 根据线路ID获取对应的校车图标
      final iconPath = BusIconUtils.getBusIconPath(bus.lineId);

      final marker = bmf_map.BMFMarker.icon(
        position: coordinate, // 指定车辆的经纬度坐标
        identifier: 'bus_${bus.id}',
        icon: iconPath, // 使用线路特定的图标
        title: '${line.name} - 车辆${bus.id}', // 显示线路和车辆信息
        subtitle: '速度: ${bus.speed.toStringAsFixed(1)} km/h', // 添加速度信息
        rotation: bus.direction, // 根据车辆方向旋转图标
        centerOffset: bmf_base.BMFPoint(0, -12), // 调整标记点位置
        zIndex: 25, // 车辆标记层级高于站点
        // 缩放相关设置
        isPerspective: false, // 🚌 禁用透视效果，保持固定大小不随地图缩放
        scaleX: 0.4, // 🚌 车辆图标固定大小
        scaleY: 0.4, // 🚌 车辆图标固定大小
        // 锚点设置：图标中心对准坐标点
        anchorX: 0.5, // 水平居中
        anchorY: 0.5, // 垂直居中
        enabled: false,
        canShowCallout: false,
      );

      markers.add(marker);
      _busMarkers.add(marker);
    }

    // 优化批量添加性能：并行处理而非串行等待
    final List<Future<void>> addMarkerFutures = markers
        .map((marker) => _baiduMapController!.addMarker(marker))
        .toList();

    // 并行执行所有添加操作
    await Future.wait(addMarkerFutures);
  }

  // Apple地图更新车辆标注
  void _updateBusMarkersOnAppleMap(
    List<BusData> busData,
    List<BusLine> busLines,
  ) {
    if (_appleMapController == null) return;

    // TODO: 实现Apple Maps的车辆标注更新
    // Apple Maps API相对简单，可以使用类似的逻辑
    // 1. 清除现有标注
    // 2. 为每辆车创建新的标注，使用对应线路的图标
    // 3. 添加到地图上

    // 🚌 根据选中的线路过滤车辆数据（与百度地图保持一致）
    List<BusData> filteredBusData;
    if (selectedLineIndex != null) {
      // 只显示选中线路的车辆
      final selectedLine = busLines[selectedLineIndex!];
      filteredBusData = busData
          .where((bus) => bus.lineId == selectedLine.id)
          .toList();
      debugPrint(
        '🚌 [Apple地图车辆过滤] 选中线路: ${selectedLine.name}, 过滤后车辆数: ${filteredBusData.length}/${busData.length}',
      );
    } else {
      // 显示所有车辆
      filteredBusData = busData;
      debugPrint('🚌 [Apple地图车辆过滤] 显示所有线路车辆: ${filteredBusData.length}');
    }

    debugPrint('Apple地图校车标记更新: ${filteredBusData.length}辆车');
    for (final bus in filteredBusData) {
      final line = busLines.firstWhere(
        (line) => line.id == bus.lineId,
        orElse: () => busLines.first,
      );
      final iconPath = BusIconUtils.getBusIconPath(bus.lineId);
      debugPrint('车辆${bus.id} 线路${line.name} 图标: $iconPath');
    }
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

      // 清除站点名称标签
      for (final textLabel in _stationLabels) {
        try {
          await _baiduMapController!.removeOverlay(textLabel.id);
        } catch (e) {
          debugPrint('移除站点标签失败: 错误: $e');
        }
      }
      _stationLabels.clear();
    } catch (e) {
      debugPrint('清理地图覆盖物时出现异常: $e');
      // 即使出现异常，也要清理本地列表
      _polylines.clear();
      _busStopMarkers.clear();
      _busMarkers.clear();
      _locationMarkers.clear();
      _stationLabels.clear();
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

      final labelCount = _stationLabels.length;

      _polylines.clear();
      _busStopMarkers.clear();
      _busMarkers.clear();
      _locationMarkers.clear();
      _stationLabels.clear();

      debugPrint(
        '安全清理完成 - 折线: $polylineCount, 站点: $busStopCount, 车辆: $busCount, 位置: $locationCount, 标签: $labelCount',
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
          if (mounted) {
            Navigator.of(context).pop();
          }
          await availableMaps.first.showDirections(
            destination: Coords(location.latitude, location.longitude),
            destinationTitle: location.content,
          );
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
                    // 缓存context引用和scaffold messenger
                    final navigator = Navigator.of(context);
                    if (!mounted) return;

                    navigator.pop(); // 关闭选择弹窗
                    navigator.pop(); // 关闭建筑列表弹窗

                    try {
                      await map.showDirections(
                        destination: Coords(
                          location.latitude,
                          location.longitude,
                        ),
                        destinationTitle: location.content,
                      );
                    } catch (e) {
                      debugPrint('启动 ${map.mapName} 失败: $e');
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
        'geo:$latitude,$longitude?q=$latitude,$longitude($name)',
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
    for (final url in urls) {
      try {
        final uri = Uri.parse(url);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          break;
        }
      } catch (e) {
        continue;
      }
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

    // 使用百度官方标点方法创建位置标记点
    final coordinate = bmf_base.BMFCoordinate(
      location.latitude,
      location.longitude,
    );

    // 使用自定义大头针图标
    final marker = bmf_map.BMFMarker.icon(
      position: coordinate, // 指定建筑的经纬度坐标
      identifier: 'location_${location.id}',
      icon: 'assets/icons/location_pin.png', // 使用大头针图标
      title: location.content, // 建筑名称作为标题
      subtitle: '校园建筑', // 副标题
      centerOffset: bmf_base.BMFPoint(0, -16), // 调整标记点位置
      zIndex: 25, // 最高层级，确保显示在最上层
      enabled: true, // 启用触摸事件
      canShowCallout: true, // 可以显示信息气泡
      selected: true, // 默认选中并弹出气泡
      alpha: 0.9, // 设置透明度
      // 缩放相关设置
      isPerspective: true, // 启用透视效果，让标记随地图缩放
      scaleX: 1.3, // 建筑物标记大一些，突出显示
      scaleY: 1.3, // 建筑物标记大一些，突出显示
      // 锚点设置：大头针底部对准坐标点
      anchorX: 0.5, // 水平居中
      anchorY: 1.0, // 底部对齐
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

  // 请求定位权限
  Future<void> _requestLocationPermission() async {
    try {
      debugPrint('🔒 [权限检查] 开始检查定位权限...');

      // 检查定位权限
      final status = await Permission.location.status;
      debugPrint('📋 [权限状态] 当前权限状态: $status');

      if (status.isDenied) {
        debugPrint('❓ [权限请求] 权限被拒绝，正在请求权限...');
        // 请求权限
        final result = await Permission.location.request();
        debugPrint('📝 [权限结果] 权限请求结果: $result');

        if (result.isGranted) {
          debugPrint('✅ [权限通过] 用户授予了定位权限');
          setState(() {
            _isLocationEnabled = true;
          });
          _enableUserLocation();
        } else {
          debugPrint('❌ [权限拒绝] 用户拒绝了定位权限');
          _showLocationPermissionDialog();
        }
      } else if (status.isGranted) {
        debugPrint('✅ [权限已有] 定位权限已经授予');
        setState(() {
          _isLocationEnabled = true;
        });
        _enableUserLocation();
      } else if (status.isPermanentlyDenied) {
        debugPrint('🚫 [永久拒绝] 定位权限被永久拒绝');
        _showLocationPermissionDialog();
      } else {
        debugPrint('⚠️ [未知状态] 未知的权限状态: $status');
      }
    } catch (e) {
      debugPrint('💥 [权限错误] 请求定位权限失败: $e');
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
        // 🔧 修复：先启用定位图层
        final showResult = await _baiduMapController!.showUserLocation(true);
        debugPrint('🎯 [定位图层] 启用结果: $showResult');

        // 🔧 修复：设置定位模式为Normal（而不是None）
        final trackingResult = await _baiduMapController!.setUserTrackingMode(
          bmf_base.BMFUserTrackingMode.Follow, // 改为Follow模式以显示位置
        );
        debugPrint('🎯 [跟踪模式] 设置结果: $trackingResult');

        // 🔧 修复：配置定位显示参数
        await _configureLocationDisplay();

        debugPrint('✅ [定位启用] 用户定位功能已启用');
      } catch (e) {
        debugPrint('💥 [定位失败] 启用用户定位失败: $e');
      }
    }
  }

  // 🔧 配置定位显示参数并启用定位功能
  Future<void> _configureLocationDisplay() async {
    try {
      debugPrint('🎨 [定位配置] 开始配置定位显示参数...');

      // 🔍 检查地图控制器是否为空
      if (_baiduMapController == null) {
        throw Exception('地图控制器为空');
      }
      debugPrint('✅ [控制器检查] 地图控制器正常');

      // 创建定位显示参数
      debugPrint('🔧 [参数创建] 开始创建定位显示参数...');
      final locationDisplayParam = bmf_map.BMFUserLocationDisplayParam(
        locationViewOffsetX: 0, // X轴偏移
        locationViewOffsetY: 0, // Y轴偏移
        userTrackingMode: bmf_base.BMFUserTrackingMode.Follow, // 跟随模式
        enableDirection: true, // 🧭 启用方向显示（Android独有）
        isAccuracyCircleShow: true, // 显示精度圈
        accuracyCircleFillColor: Colors.blue.withValues(alpha: 0.2), // 精度圈填充色
        accuracyCircleStrokeColor: Colors.blue, // 精度圈边框色
        canShowCallOut: false, // 不显示气泡（避免干扰）
        locationViewHierarchy: bmf_map
            .BMFLocationViewHierarchy
            .LOCATION_VIEW_HIERARCHY_TOP, // 🔧 修复：设置定位图标层级
        // 🧭 启用箭头样式自定义，更好地显示朝向
        isLocationArrowStyleCustom: true,
        breatheEffectOpenForArrowsStyle: true, // 箭头呼吸效果
      );
      debugPrint('✅ [参数创建] 定位显示参数创建成功');

      // 更新定位显示参数
      debugPrint('🔧 [参数更新] 开始更新定位显示参数...');
      final result = await _baiduMapController!.updateLocationViewWithParam(
        locationDisplayParam,
      );
      debugPrint('🎨 [定位样式] 配置结果: $result');

      if (!result) {
        throw Exception('定位显示参数配置失败');
      }
    } catch (e, stackTrace) {
      debugPrint('💥 [配置失败] 定位显示参数配置失败: $e');
      debugPrint('📍 [堆栈跟踪] $stackTrace');
      rethrow;
    }
  }

  // 🎯 地图加载完成后自动启动定位
  Future<void> _startAutoLocationOnMapLoad() async {
    try {
      debugPrint('🎯 [自动定位] 开始自动定位流程...');

      // 自动请求定位权限
      await _requestLocationPermission();

      // 如果权限获取成功，启动持续定位
      if (_isLocationEnabled) {
        debugPrint('✅ [自动定位] 权限已获取，启动持续定位...');
        await _startContinuousLocationUpdates();
      } else {
        debugPrint('⚠️ [自动定位] 权限未获取，跳过自动定位');
      }
    } catch (e) {
      debugPrint('💥 [自动定位失败] $e');
    }
  }

  // 🔄 启动持续定位更新
  Future<void> _startContinuousLocationUpdates() async {
    try {
      debugPrint('🔄 [持续定位] 开始启动持续定位更新...');

      if (_isLocationStreamActive) {
        debugPrint('⚠️ [持续定位] 位置流已激活，先停止现有流');
        await _stopContinuousLocationUpdates();
      }

      // 配置百度地图定位显示
      _enableUserLocation();

      // 🧭 启动磁力计传感器监听设备朝向
      _startMagnetometerListener();

      // 启动位置流监听 - 改为每秒更新而不是移动距离更新
      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high, // 高精度定位
        distanceFilter: 0, // 🔄 设置为0，不根据移动距离过滤
        timeLimit: Duration(seconds: 30), // 30秒超时
      );

      debugPrint('🔄 [位置流] 开始监听位置变化（每秒更新）...');
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              debugPrint('📍 [位置更新] 收到新的位置数据');
              _handleLocationUpdate(position);
            },
            onError: (error) {
              debugPrint('💥 [位置流错误] $error');
            },
            onDone: () {
              debugPrint('🔄 [位置流] 位置流结束');
              _isLocationStreamActive = false;
            },
          );

      _isLocationStreamActive = true;
      debugPrint('✅ [持续定位] 持续定位已启动（每秒更新模式）');
    } catch (e) {
      debugPrint('💥 [持续定位失败] $e');
    }
  }

  // 🔄 停止持续定位更新
  Future<void> _stopContinuousLocationUpdates() async {
    try {
      debugPrint('🛑 [停止定位] 停止持续定位更新...');

      if (_positionStreamSubscription != null) {
        await _positionStreamSubscription!.cancel();
        _positionStreamSubscription = null;
        debugPrint('✅ [停止定位] 位置流已停止');
      }

      // 🧭 停止磁力计传感器监听
      if (_magnetometerSubscription != null) {
        await _magnetometerSubscription!.cancel();
        _magnetometerSubscription = null;
        debugPrint('✅ [停止传感器] 磁力计传感器已停止');
      }

      _isLocationStreamActive = false;
    } catch (e) {
      debugPrint('💥 [停止定位失败] $e');
    }
  }

  // 🧭 启动磁力计传感器监听设备朝向
  void _startMagnetometerListener() {
    try {
      debugPrint('🧭 [磁力计传感器] 开始监听设备朝向...');

      _magnetometerSubscription = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          // 计算设备朝向角度（相对于磁北）
          // atan2(y, x) 返回弧度，需要转换为角度
          double heading = math.atan2(event.y, event.x) * 180 / math.pi;

          // 确保角度在0-360度范围内
          if (heading < 0) {
            heading += 360;
          }

          // 平滑处理，避免朝向跳动太频繁
          if ((heading - _currentDeviceHeading).abs() > 2.0) {
            _currentDeviceHeading = heading;
            debugPrint('🧭 [设备朝向] 磁力计朝向: ${heading.toStringAsFixed(1)}°');

            // 🧭 磁力计更新时也更新地图上的用户位置朝向
            _updateUserLocationHeading();
          }
        },
        onError: (error) {
          debugPrint('💥 [磁力计错误] $error');
        },
      );

      debugPrint('✅ [磁力计传感器] 磁力计监听已启动');
    } catch (e) {
      debugPrint('💥 [磁力计启动失败] $e');
    }
  }

  // 📍 处理位置更新
  Future<void> _handleLocationUpdate(Position position) async {
    try {
      // 保存最后的GPS位置
      _lastGpsPosition = position;

      debugPrint(
        '📍 [位置更新] 新位置: 纬度=${position.latitude.toStringAsFixed(6)}, '
        '经度=${position.longitude.toStringAsFixed(6)}, '
        '精度=${position.accuracy.toStringAsFixed(1)}米, '
        '移动方向=${position.heading.toStringAsFixed(1)}°',
      );

      // 更新用户位置到地图
      await _updateUserLocationToMap(position);
    } catch (e) {
      debugPrint('💥 [位置更新失败] $e');
    }
  }

  // 🔄 更新用户位置到地图（通用方法）
  Future<void> _updateUserLocationToMap(Position position) async {
    try {
      // 🧭 处理朝向数据：优先使用磁力计朝向，GPS朝向作为备用
      double deviceHeading = _currentDeviceHeading; // 磁力计获取的设备朝向
      double gpsHeading = position.heading; // GPS移动方向

      // 选择最佳朝向：优先使用磁力计朝向
      double validHeading;
      String headingSource;

      if (deviceHeading != 0.0) {
        // 使用磁力计朝向（设备实际朝向）
        validHeading = deviceHeading;
        headingSource = "磁力计";
      } else if (gpsHeading > 0 && !gpsHeading.isNaN) {
        // 磁力计无效时使用GPS移动方向
        validHeading = gpsHeading;
        headingSource = "GPS移动";
      } else {
        // 都无效时使用默认朝向
        validHeading = 0.0;
        headingSource = "默认";
      }

      debugPrint('🧭 [朝向处理] 朝向来源: $headingSource');
      debugPrint(
        '🧭 [朝向处理] GPS朝向: ${gpsHeading.toStringAsFixed(1)}°, 磁力计朝向: ${deviceHeading.toStringAsFixed(1)}°',
      );
      debugPrint('🧭 [朝向处理] 最终朝向: ${validHeading.toStringAsFixed(1)}°');

      // 🔄 坐标转换：WGS84 → GCJ02（火星坐标系）
      final gcj02Coordinate = _convertWGS84ToGCJ02(
        position.latitude,
        position.longitude,
      );

      // 创建BMFLocation对象，包含移动方向
      final bmfLocation = bmf_map.BMFLocation(
        coordinate: gcj02Coordinate,
        altitude: position.altitude,
        course: validHeading, // 🧭 使用处理后的有效朝向
        speed: position.speed,
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // 创建设备朝向对象（罗盘方向）
      final bmfHeading = bmf_map.BMFHeading(
        trueHeading: validHeading, // 🧭 设备朝向（真北方向）
        magneticHeading: validHeading, // 磁北方向（简化处理）
        headingAccuracy: 5.0, // 朝向精度
        timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // 创建用户位置对象，同时包含位置和朝向信息
      final userLocation = bmf_map.BMFUserLocation(
        location: bmfLocation,
        heading: bmfHeading, // 🧭 传递设备朝向信息
        updating: true,
      );

      // 更新位置数据到地图
      final result = await _baiduMapController!.updateLocationData(
        userLocation,
      );

      if (result) {
        debugPrint(
          '✅ [位置更新] 位置和朝向数据已更新到地图\n'
          '   GPS朝向: ${gpsHeading.toStringAsFixed(1)}°\n'
          '   磁力计朝向: ${deviceHeading.toStringAsFixed(1)}°\n'
          '   朝向来源: $headingSource\n'
          '   最终朝向: ${validHeading.toStringAsFixed(1)}°',
        );
      } else {
        debugPrint('❌ [位置更新] 位置数据更新失败');
      }
    } catch (e) {
      debugPrint('💥 [位置更新到地图失败] $e');
    }
  }

  // 🧭 仅更新用户位置朝向（磁力计更新时调用）
  Future<void> _updateUserLocationHeading() async {
    if (_baiduMapController == null || _lastGpsPosition == null) {
      return;
    }

    try {
      debugPrint('🧭 [朝向更新] 仅更新朝向，使用最后GPS位置');
      await _updateUserLocationToMap(_lastGpsPosition!);
    } catch (e) {
      debugPrint('💥 [朝向更新失败] $e');
    }
  }

  // 🗺️ 移动地图到指定坐标
  Future<void> _moveMapToLocation(bmf_base.BMFCoordinate coordinate) async {
    try {
      debugPrint('🗺️ [地图移动] 移动地图到GPS位置...');

      // 创建地图状态，移动到指定坐标
      final mapStatus = bmf_map.BMFMapStatus(
        targetGeoPt: coordinate,
        fLevel: 18.0, // 设置合适的缩放级别
      );

      // 动画移动到GPS位置
      final result = await _baiduMapController!.setNewMapStatus(
        mapStatus: mapStatus,
        animateDurationMs: 1500, // 1.5秒动画
      );

      if (result) {
        debugPrint('✅ [地图移动] 地图已移动到GPS位置');
      } else {
        debugPrint('⚠️ [地图移动] 地图移动可能失败');
      }
    } catch (e) {
      debugPrint('💥 [地图移动失败] $e');
    }
  }

  // 定位到用户位置
  void _locateUser() async {
    debugPrint('🎯 [定位按钮] 用户点击了定位按钮 - 移动视角到用户中心');

    if (!_isLocationEnabled) {
      debugPrint('🚫 [定位权限] 定位权限未启用，请求权限...');
      await _requestLocationPermission();
      return;
    }

    if (_baiduMapController == null) {
      debugPrint('❌ [地图控制器] 地图控制器为空');
      return;
    }

    try {
      debugPrint('📍 [获取位置] 获取当前位置以移动视角...');

      // 获取当前位置
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      debugPrint(
        '✅ [位置获取] 当前位置: 纬度=${position.latitude.toStringAsFixed(6)}, '
        '经度=${position.longitude.toStringAsFixed(6)}',
      );

      // 坐标转换：WGS84 → GCJ02
      final gcj02Coordinate = _convertWGS84ToGCJ02(
        position.latitude,
        position.longitude,
      );

      // 移动地图视角到用户位置
      await _moveMapToLocation(gcj02Coordinate);
    } catch (e) {
      debugPrint('❌ [定位失败] 错误详情: $e');
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

  // 动态更新所有marker的缩放比例
  Future<void> _updateMarkersScale() async {
    if (_baiduMapController == null) return;

    try {
      // 计算当前缩放比例因子（相对于初始级别）
      final scaleFactor = _calculateScaleFactor(_currentZoomLevel);

      debugPrint('📏 [缩放更新] 缩放级别: $_currentZoomLevel');
      debugPrint('📏 [缩放更新] 通用缩放因子: ${scaleFactor.toStringAsFixed(3)}');

      // 并行更新所有类型的marker
      final futures = <Future<void>>[];

      // 更新公交站点marker
      for (final marker in _busStopMarkers) {
        futures.add(_updateMarkerScale(marker, scaleFactor * 1.0)); // 站点保持原始比例
      }

      // 🚌 车辆marker不参与动态缩放，保持固定0.4大小
      debugPrint('🚌 [车辆缩放] 车辆保持固定大小0.4，不参与动态缩放');

      // 更新位置标记marker
      for (final marker in _locationMarkers) {
        futures.add(_updateMarkerScale(marker, scaleFactor * 1.3)); // 位置标记最大
      }

      // 等待所有更新完成
      await Future.wait(futures);

      debugPrint(
        '✅ [缩放更新完成] 已更新 ${_busStopMarkers.length + _busMarkers.length + _locationMarkers.length} 个marker',
      );
    } catch (e) {
      debugPrint('💥 [缩放更新失败] $e');
    }
  }

  // 计算缩放因子
  double _calculateScaleFactor(double currentZoomLevel) {
    // 使用指数函数计算缩放因子，确保平滑过渡
    // pow(_baseScaleFactor, zoomLevel - _initialZoomLevel)
    final zoomDiff = currentZoomLevel - _initialZoomLevel;
    final scaleFactor = math.pow(_baseScaleFactor, zoomDiff).toDouble();

    // 限制缩放范围，避免marker过大或过小
    return scaleFactor.clamp(0.3, 3.0);
  }

  // 更新单个marker的缩放比例
  Future<void> _updateMarkerScale(
    bmf_map.BMFMarker marker,
    double scale,
  ) async {
    try {
      // 同时更新X和Y方向的缩放
      await Future.wait([
        marker.updateScaleX(scale),
        marker.updateScaleY(scale),
      ]);
    } catch (e) {
      debugPrint('💥 [Marker缩放失败] Marker ${marker.identifier}: $e');
    }
  }

  // 通过ID在本地marker列表中查找对应的marker
  bmf_map.BMFMarker? _findMarkerById(bmf_map.BMFMarker clickedMarker) {
    debugPrint('🔍 [查找Marker] 开始查找，本地marker数量统计:');
    debugPrint('   - 站点markers: ${_busStopMarkers.length}');
    debugPrint('   - 车辆markers: ${_busMarkers.length}');
    debugPrint('   - 位置markers: ${_locationMarkers.length}');

    // 🔧 优先通过唯一的 id 进行查找 (这是BMFOverlay的唯一标识)
    final clickedId = clickedMarker.id;
    debugPrint('🔍 [通过ID查找] 查找id: $clickedId');

    // 在公交站点列表中查找
    for (final marker in _busStopMarkers) {
      if (marker.id == clickedId) {
        debugPrint('✅ [找到匹配] 在站点列表中找到匹配的marker');
        debugPrint(
          '   匹配详情: identifier=${marker.identifier}, title=${marker.title}',
        );
        return marker;
      }
    }

    // 在车辆列表中查找
    for (final marker in _busMarkers) {
      if (marker.id == clickedId) {
        debugPrint('✅ [找到匹配] 在车辆列表中找到匹配的marker');
        debugPrint(
          '   匹配详情: identifier=${marker.identifier}, title=${marker.title}',
        );
        return marker;
      }
    }

    // 在位置标记列表中查找
    for (final marker in _locationMarkers) {
      if (marker.id == clickedId) {
        debugPrint('✅ [找到匹配] 在位置列表中找到匹配的marker');
        debugPrint(
          '   匹配详情: identifier=${marker.identifier}, title=${marker.title}',
        );
        return marker;
      }
    }

    debugPrint('❌ [ID查找失败] 没有找到匹配的id: $clickedId');

    // 🔧 备用方案：通过identifier查找 (如果id查找失败)
    if (clickedMarker.identifier != null) {
      debugPrint('🔄 [备用查找] 尝试通过identifier查找: ${clickedMarker.identifier}');

      for (final marker in [
        ..._busStopMarkers,
        ..._busMarkers,
        ..._locationMarkers,
      ]) {
        if (marker.identifier == clickedMarker.identifier) {
          debugPrint('✅ [备用成功] 通过identifier找到匹配的marker');
          return marker;
        }
      }
    }

    // 如果identifier为空，尝试通过坐标位置查找
    final clickedPos = clickedMarker.position;
    const tolerance = 0.0001; // 坐标容差

    for (final marker in [
      ..._busStopMarkers,
      ..._busMarkers,
      ..._locationMarkers,
    ]) {
      final pos = marker.position;
      if ((pos.latitude - clickedPos.latitude).abs() < tolerance &&
          (pos.longitude - clickedPos.longitude).abs() < tolerance) {
        debugPrint('🔍 [坐标匹配] 通过坐标找到了marker: ${marker.identifier}');
        return marker;
      }
    }

    return null;
  }

  // 清除所有站点标签
  Future<void> _clearStationLabels() async {
    if (_stationLabels.isNotEmpty) {
      debugPrint('🧹 [清理标签] 清除之前的 ${_stationLabels.length} 个站点标签...');
      for (final textLabel in _stationLabels) {
        try {
          await _baiduMapController!.removeOverlay(textLabel.id);
        } catch (e) {
          debugPrint('💥 [清理失败] 移除标签失败: $e');
        }
      }
      _stationLabels.clear();
    }
  }

  // 渲染去重后的站点标签
  Future<void> _renderUniqueStationLabels() async {
    debugPrint('📊 [统计] 开始分析 ${_busStopMarkers.length} 个站点marker...');

    // 先清除之前的标签
    await _clearStationLabels();

    // 使用Map来去重，key为站点名称，value为该站点的第一个marker
    final Map<String, bmf_map.BMFMarker> uniqueStations = {};

    for (final marker in _busStopMarkers) {
      final stationName = marker.title?.trim();
      if (stationName != null && stationName.isNotEmpty) {
        // 如果站点名称还没有记录，则记录这个marker
        if (!uniqueStations.containsKey(stationName)) {
          uniqueStations[stationName] = marker;
        }
      }
    }

    debugPrint(
      '🎯 [去重结果] 从 ${_busStopMarkers.length} 个marker中找到 ${uniqueStations.length} 个唯一站点',
    );

    // 🚀 批量创建所有标签（性能优化）
    final List<bmf_map.BMFText> labelsToAdd = [];

    debugPrint('🏗️ [批量创建] 开始批量创建 ${uniqueStations.length} 个标签...');

    for (final entry in uniqueStations.entries) {
      final stationName = entry.key;
      final marker = entry.value;

      try {
        // 🎨 获取当前主题模式
        final isDarkMode = ref.read(effectiveIsDarkModeProvider);

        // 📏 根据当前缩放级别计算动态样式
        final dynamicFontSize = _calculateLabelFontSize();
        final dynamicOffset = _calculateLabelOffset();

        // 调试信息（仅在第一个标签时输出，避免日志过多）
        if (entry.key == uniqueStations.keys.first) {
          debugPrint(
            '📏 [动态样式] 缩放级别: $_currentZoomLevel, 字体大小: ${dynamicFontSize.toStringAsFixed(1)}, 偏移: ${(dynamicOffset * 100000).toStringAsFixed(1)}米',
          );
        }

        // 创建优化的文本覆盖物 - 显示在站点图标上方
        final labelPosition = bmf_base.BMFCoordinate(
          marker.position.latitude + dynamicOffset, // 🔄 使用动态偏移距离
          marker.position.longitude,
        );

        final textLabel = bmf_map.BMFText(
          text: ' $stationName ', // 添加前后空格增加内边距效果
          position: labelPosition,
          fontSize: dynamicFontSize.round(), // 🔄 使用动态字体大小
          fontColor: _getOptimizedLabelTextColor(isDarkMode), // 🎨 高对比度文字色
          bgColor: _getOptimizedLabelBackground(isDarkMode), // 🎨 优化的背景色
          rotate: 0,
          alignX: bmf_map.BMFHorizontalAlign.ALIGN_CENTER_HORIZONTAL,
          alignY: bmf_map.BMFVerticalAlign.ALIGN_BOTTOM,
          // 增加文字样式优化
          typeFace: bmf_map.BMFTypeFace(
            familyName: bmf_map.BMFFamilyName.sDefault,
            textStype: bmf_map.BMFTextStyle.BOLD,
          ),
          // iOS专用的行间距设置（模拟内边距）
          lineSpacing: (dynamicFontSize * 0.5).round(), // 🔄 动态行间距
          // 🔝 提高z-index确保显示在最上层
          zIndex: 1000, // 设置很高的z-index
        );

        labelsToAdd.add(textLabel);
      } catch (e) {
        debugPrint('💥 [创建异常] $stationName 标签创建失败: $e');
      }
    }

    // 🚀 批量添加到地图（大幅提升性能）
    if (labelsToAdd.isNotEmpty) {
      debugPrint('⚡ [批量添加] 开始批量添加 ${labelsToAdd.length} 个标签到地图...');

      try {
        // 使用批量添加API（如果支持）或并行添加
        final addFutures = labelsToAdd
            .map(
              (label) => _baiduMapController!.addText(label).then((success) {
                if (success) {
                  _stationLabels.add(label);
                  return true;
                }
                return false;
              }),
            )
            .toList();

        // 并行执行所有添加操作
        final results = await Future.wait(addFutures);
        final successCount = results.where((success) => success).length;
        final failCount = results.length - successCount;

        debugPrint('✅ [批量完成] 标签批量添加结果:');
        debugPrint('   - 成功: $successCount 个');
        debugPrint('   - 失败: $failCount 个');

        if (successCount > 0) {
          debugPrint('🎉 [完成] 所有站点标签已批量显示在地图上！');
        }
      } catch (e) {
        debugPrint('💥 [批量失败] 批量添加标签失败: $e');
      }
    }
  }

  // 🏷️ 动态调整所有标签的样式和位置（响应缩放变化）
  Future<void> _updateLabelsScale() async {
    if (_stationLabels.isEmpty || _baiduMapController == null) {
      return;
    }

    debugPrint('🏷️ [标签缩放] 开始更新 ${_stationLabels.length} 个标签的缩放样式...');

    try {
      // 重新渲染所有标签以应用新的缩放样式
      await _renderUniqueStationLabels();

      debugPrint('✅ [标签缩放] 标签缩放更新完成');
    } catch (e) {
      debugPrint('💥 [标签缩放失败] $e');
    }
  }

  // 📏 根据当前缩放级别计算标签字体大小
  double _calculateLabelFontSize() {
    final zoomDifference = _currentZoomLevel - _initialZoomLevel;
    final scaleFactor = math.pow(_labelZoomFactor, zoomDifference).toDouble();
    final fontSize = _baseLabelFontSize * scaleFactor;

    // 限制字体大小范围，避免过小或过大
    return math.max(10.0, math.min(18.0, fontSize));
  }

  // 📏 根据当前缩放级别计算标签偏移距离
  double _calculateLabelOffset() {
    // 缩放级别越高，偏移距离应该越小（因为地图显示的范围更小）
    final zoomDifference = _currentZoomLevel - _initialZoomLevel;
    final scaleFactor = math.pow(0.85, zoomDifference).toDouble(); // 缩放时偏移减小
    final offset = _baseLabelOffset * scaleFactor;

    // 限制偏移范围，确保标签不会离得太远或太近
    return math.max(0.00008, math.min(0.0003, offset));
  }

  // 🔄 坐标转换方法：WGS84 → GCJ02（火星坐标系）
  bmf_base.BMFCoordinate _convertWGS84ToGCJ02(double wgsLat, double wgsLon) {
    // 中国境外直接返回原坐标
    if (_isOutOfChina(wgsLat, wgsLon)) {
      return bmf_base.BMFCoordinate(wgsLat, wgsLon);
    }

    double dLat = _transformLat(wgsLon - 105.0, wgsLat - 35.0);
    double dLon = _transformLon(wgsLon - 105.0, wgsLat - 35.0);
    double radLat = wgsLat / 180.0 * math.pi;
    double magic = math.sin(radLat);
    magic = 1 - 0.00669342162296594323 * magic * magic;
    double sqrtMagic = math.sqrt(magic);
    dLat =
        (dLat * 180.0) /
        ((6378245.0 * (1 - 0.00669342162296594323)) /
            (magic * sqrtMagic) *
            math.pi);
    dLon =
        (dLon * 180.0) / (6378245.0 / sqrtMagic * math.cos(radLat) * math.pi);

    double mgLat = wgsLat + dLat;
    double mgLon = wgsLon + dLon;

    return bmf_base.BMFCoordinate(mgLat, mgLon);
  }

  // 🔄 辅助方法：判断是否在中国境外
  bool _isOutOfChina(double lat, double lon) {
    return lon < 72.004 || lon > 137.8347 || lat < 0.8293 || lat > 55.8271;
  }

  // 🔄 辅助方法：纬度转换
  double _transformLat(double lon, double lat) {
    double ret =
        -100.0 +
        2.0 * lon +
        3.0 * lat +
        0.2 * lat * lat +
        0.1 * lon * lat +
        0.2 * math.sqrt(lat.abs());
    ret +=
        (20.0 * math.sin(6.0 * lon * math.pi) +
            20.0 * math.sin(2.0 * lon * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (20.0 * math.sin(lat * math.pi) +
            40.0 * math.sin(lat / 3.0 * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (160.0 * math.sin(lat / 12.0 * math.pi) +
            320 * math.sin(lat * math.pi / 30.0)) *
        2.0 /
        3.0;
    return ret;
  }

  // 🔄 辅助方法：经度转换
  double _transformLon(double lon, double lat) {
    double ret =
        300.0 +
        lon +
        2.0 * lat +
        0.1 * lon * lon +
        0.1 * lon * lat +
        0.1 * math.sqrt(lon.abs());
    ret +=
        (20.0 * math.sin(6.0 * lon * math.pi) +
            20.0 * math.sin(2.0 * lon * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (20.0 * math.sin(lon * math.pi) +
            40.0 * math.sin(lon / 3.0 * math.pi)) *
        2.0 /
        3.0;
    ret +=
        (150.0 * math.sin(lon / 12.0 * math.pi) +
            300.0 * math.sin(lon / 30.0 * math.pi)) *
        2.0 /
        3.0;
    return ret;
  }

  // 🎨 获取优化的标签背景色（适配深色模式）
  Color _getOptimizedLabelBackground(bool isDarkMode) {
    if (isDarkMode) {
      // 深色模式：深蓝灰色背景，更现代的外观
      return const Color(0xFF1E1E2E).withValues(alpha: 0.92);
    } else {
      // 浅色模式：纯白背景，带阴影效果的透明度
      return const Color(0xFFFFFFFF).withValues(alpha: 0.95);
    }
  }

  // 🎨 获取优化的标签文字颜色（确保高对比度）
  Color _getOptimizedLabelTextColor(bool isDarkMode) {
    if (isDarkMode) {
      // 深色模式：亮白色文字
      return const Color(0xFFF8F8F2);
    } else {
      // 浅色模式：深色文字
      return const Color(0xFF2E3440);
    }
  }

  // 🔧 显示marker信息弹窗
  void _showMarkerInfoDialog(bmf_map.BMFMarker marker) {
    if (!mounted) return;

    // 解析marker类型和信息
    final markerInfo = _parseMarkerInfo(marker);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          markerInfo['title'] ?? '未知位置',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (markerInfo['subtitle'] != null)
              Text(
                markerInfo['subtitle']!,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            const SizedBox(height: 8),
            if (markerInfo['type'] != null)
              Text(
                '类型: ${markerInfo['type']}',
                style: const TextStyle(fontSize: 14),
              ),
            if (markerInfo['coordinates'] != null)
              Text(
                '坐标: ${markerInfo['coordinates']}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToMarker(marker);
            },
            icon: const Icon(Icons.navigation),
            label: const Text('到这去'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 🔧 解析marker信息
  Map<String, String?> _parseMarkerInfo(bmf_map.BMFMarker marker) {
    String? type;
    String? coordinates;

    // 根据identifier判断marker类型
    if (marker.identifier?.startsWith('bus_stop_') == true) {
      type = '公交站点';
    } else if (marker.identifier?.startsWith('bus_') == true) {
      type = '校车';
    } else if (marker.identifier?.startsWith('location_') == true) {
      type = '建筑位置';
    } else {
      type = '未知';
    }

    // 格式化坐标
    coordinates =
        '${marker.position.latitude.toStringAsFixed(6)}, ${marker.position.longitude.toStringAsFixed(6)}';

    return {
      'title': marker.title,
      'subtitle': marker.subtitle,
      'type': type,
      'coordinates': coordinates,
    };
  }

  // 🔧 导航到marker位置
  void _navigateToMarker(bmf_map.BMFMarker marker) async {
    // 创建LocationPoint对象，复用现有的导航逻辑
    final locationPoint = LocationPoint(
      id: DateTime.now().millisecondsSinceEpoch, // 使用时间戳作为临时ID
      content: marker.title ?? '未知位置',
      latitude: marker.position.latitude,
      longitude: marker.position.longitude,
    );

    debugPrint('🧭 [开始导航] 导航到: ${locationPoint.content}');

    // 复用现有的导航逻辑
    _navigateToLocationWithMapLauncher(locationPoint);
  }

  @override
  void dispose() {
    // 安全清理地图覆盖物
    _clearBaiduMapOverlaysSafely();

    // 🛑 停止位置流监听
    _stopContinuousLocationUpdates();

    _searchController.dispose();
    super.dispose();
  }
}
