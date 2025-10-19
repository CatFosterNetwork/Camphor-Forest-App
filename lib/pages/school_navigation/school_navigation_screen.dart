// lib/pages/school_navigation/school_navigation_screen.dart

import 'dart:io' show Platform;
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../core/utils/app_logger.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:camphor_forest/core/services/toast_service.dart';
import '../../core/services/permission_service.dart';
import '../../core/widgets/theme_aware_dialog.dart';
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

class _AppleScaledIconData {
  _AppleScaledIconData({required this.image, required this.bytes});

  final ui.Image image;
  final Uint8List bytes;
}

class SchoolNavigationScreen extends ConsumerStatefulWidget {
  const SchoolNavigationScreen({super.key});

  @override
  ConsumerState<SchoolNavigationScreen> createState() =>
      _SchoolNavigationScreenState();
}

class _SchoolNavigationScreenState extends ConsumerState<SchoolNavigationScreen>
    with WidgetsBindingObserver {
  int? selectedLineIndex;
  bool showStops = true;

  // 地图控制器
  bmf_map.BMFMapController? _baiduMapController;
  apple.AppleMapController? _appleMapController;

  // 当前显示的覆盖物
  final List<bmf_map.BMFPolyline> _polylines = [];
  final List<bmf_map.BMFMarker> _busStopMarkers = [];
  final List<bmf_map.BMFMarker> _busMarkers = [];
  final Map<String, bmf_map.BMFMarker> _busMarkersMap =
      {}; // 车辆ID -> Marker映射，用于增量更新
  final Map<String, double> _busDirectionMap = {}; // 车辆ID -> 角度映射，用于检测角度变化
  final List<bmf_map.BMFMarker> _locationMarkers = [];
  final List<bmf_map.BMFText> _stationLabels = []; // 存储站点名称标签

  // Apple Maps 覆盖物（iOS平台）
  final List<apple.Polyline> _applePolylines = [];
  final List<apple.Annotation> _appleBusStopAnnotations = [];
  final List<apple.Annotation> _appleBusAnnotations = [];
  final List<apple.Annotation> _appleLocationAnnotations = [];

  // 建筑定位状态
  LocationPoint? _selectedLocation;

  // 位置流监听
  StreamSubscription<Position>? _positionStreamSubscription;
  bool _isLocationStreamActive = false;

  // 磁力计传感器监听（获取设备朝向）
  StreamSubscription<MagnetometerEvent>? _magnetometerSubscription;
  double _currentDeviceHeading = 0.0;
  bool _hasMagnetometerData = false; // 磁力计是否已有有效数据
  int _lastMagnetometerUpdateMs = 0; // 磁力计节流：上次更新时间戳

  // 最后的GPS位置（用于磁力计更新时保持位置）
  Position? _lastGpsPosition;

  // 搜索相关
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // 🚀 缓存建筑数据，避免重复计算
  List<String>? _cachedLocationTypes;
  Map<String, List<LocationPoint>>? _cachedLocationsByType;
  List<LocationPoint>? _cachedAllLocations;
  bool _isBuildingCacheInitialized = false;

  // Marker缩放相关参数
  static const double _initialZoomLevel = 16.0; // 初始缩放级别
  static const double _baseScaleFactor = 1.08; // 缩放因子（每级放大8%，适中变化）
  double _currentZoomLevel = _initialZoomLevel;
  Timer? _zoomDebounceTimer; // 缩放防抖定时器
  double? _pendingZoomLevel; // 待处理的缩放级别

  // Text Label缩放相关参数
  static const double _baseLabelFontSize = 12.0; // 基础字体大小
  static const double _labelZoomFactor = 1.02; // 标签缩放因子（每级放大2%）
  static const double _baseLabelOffset = 0.00015; // 基础偏移距离

  static const double _appleBusHeadingBucketSize = 5.0; // Apple Maps车辆朝向量化步长
  static const double _appleBusIconTargetWidth = 44.0; // Apple Maps车辆图标目标宽度（像素）
  static const double _appleBusIconRotationOffsetDegrees =
      0.0; // Apple Maps车辆图标方向校正角度

  // 缓存自定义图标
  apple.BitmapDescriptor? _appleLocationPinIcon;
  apple.BitmapDescriptor? _appleBusStopIcon;
  final Map<String, _AppleScaledIconData> _appleBusIconAssets = {};
  final Map<String, apple.BitmapDescriptor> _appleBusIconCache = {};
  int _appleBusAnnotationUpdateId = 0;
  Future<void>? _iconsFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 仅在iOS平台预加载图标
    if (Platform.isIOS) {
      _iconsFuture = _loadCustomAppleMapIcons();
    }
    AppLogger.debug('🚀 [页面生命周期] SchoolNavigationScreen 初始化');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 图标加载逻辑已移至 initState
  }

  // 预加载Apple Maps自定义图标
  Future<void> _loadCustomAppleMapIcons() async {
    if (!mounted) return;
    try {
      _appleLocationPinIcon = await _loadAndScaleAppleMapIcon(
        'assets/icons/location_pin.png',
        scale: 2.5,
      );
      _appleBusStopIcon = await _loadAndScaleAppleMapIcon(
        'assets/icons/bus_stop.png',
        scale: 1.6,
      );

      // 预加载所有校车图标 - 使用实际的线路ID
      final supportedLineIds = BusIconUtils.getSupportedLineIds();
      for (final lineIdStr in supportedLineIds) {
        try {
          final iconPath = BusIconUtils.getBusIconPath(lineIdStr);
          final iconData = await _loadAndScaleAppleMapIconData(
            iconPath,
            targetWidth: _appleBusIconTargetWidth,
          );
          _appleBusIconAssets[lineIdStr] = iconData;
          _appleBusIconCache['$lineIdStr|base'] =
              apple.BitmapDescriptor.fromBytes(iconData.bytes);
          AppLogger.debug('🍎 [图标预加载] 线路$lineIdStr: $iconPath');
        } catch (e) {
          AppLogger.debug('🍎 [图标预加载失败] 线路$lineIdStr: $e');
        }
      }
      AppLogger.debug('🍎 [图标加载] Apple Maps 自定义图标加载完成');
    } catch (e) {
      AppLogger.debug('🍎 [图标加载失败] $e');
      // 重新抛出异常，以便 FutureBuilder 可以捕获并显示错误状态
      rethrow;
    }
  }

  Future<apple.BitmapDescriptor> _loadAndScaleAppleMapIcon(
    String assetPath, {
    double scale = 1.0,
    double? targetWidth,
    double? targetHeight,
  }) async {
    final _AppleScaledIconData iconData = await _loadAndScaleAppleMapIconData(
      assetPath,
      scale: scale,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
    );
    return apple.BitmapDescriptor.fromBytes(iconData.bytes);
  }

  Future<_AppleScaledIconData> _loadAndScaleAppleMapIconData(
    String assetPath, {
    double scale = 1.0,
    double? targetWidth,
    double? targetHeight,
  }) async {
    final ByteData data = await rootBundle.load(assetPath);
    final ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
    );
    final ui.FrameInfo fi = await codec.getNextFrame();
    final ui.Image image = fi.image;

    double computedScale = scale;
    if (targetWidth != null && targetWidth > 0) {
      computedScale = targetWidth / image.width;
    } else if (targetHeight != null && targetHeight > 0) {
      computedScale = targetHeight / image.height;
    }

    final int newWidth = math.max(1, (image.width * computedScale).round());
    final int newHeight = math.max(1, (image.height * computedScale).round());

    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..filterQuality = FilterQuality.high;

    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      paint,
    );
    image.dispose();

    final ui.Image newImage = await pictureRecorder.endRecording().toImage(
      newWidth,
      newHeight,
    );
    final ByteData? byteData = await newImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    return _AppleScaledIconData(
      image: newImage,
      bytes: byteData!.buffer.asUint8List(),
    );
  }

  Future<apple.BitmapDescriptor> _createRotatedAppleBusIcon(
    ui.Image baseImage,
    double headingBucket,
  ) async {
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..filterQuality = FilterQuality.high;

    final double width = baseImage.width.toDouble();
    final double height = baseImage.height.toDouble();
    final double diagonal = math.sqrt(width * width + height * height);
    final int canvasSize = diagonal.ceil();
    final double halfCanvas = canvasSize / 2;

    canvas.translate(halfCanvas, halfCanvas);
    final double radians =
        (headingBucket + _appleBusIconRotationOffsetDegrees) * math.pi / 180;
    canvas.rotate(radians);
    canvas.translate(-width / 2, -height / 2);
    canvas.drawImage(baseImage, Offset.zero, paint);

    final ui.Image rotatedImage = await recorder.endRecording().toImage(
      canvasSize,
      canvasSize,
    );
    final ByteData? byteData = await rotatedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    rotatedImage.dispose();

    return apple.BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  Future<apple.BitmapDescriptor> _getAppleBusIcon(
    String lineId,
    double direction,
  ) async {
    final double normalizedDirection = direction.isFinite ? direction : 0.0;
    final double wrappedHeading = (normalizedDirection % 360 + 360) % 360;
    final double step = _appleBusHeadingBucketSize > 0
        ? _appleBusHeadingBucketSize
        : 1.0;
    final int bucketIndex = (wrappedHeading / step).round();
    final double snappedHeading = (bucketIndex * step) % 360;
    final String cacheKey = '$lineId|${snappedHeading.toStringAsFixed(1)}';

    if (_appleBusIconCache.containsKey(cacheKey)) {
      return _appleBusIconCache[cacheKey]!;
    }

    final _AppleScaledIconData? baseIcon = _appleBusIconAssets[lineId];
    if (baseIcon == null) {
      await _loadMissingBusIcon(lineId);
      return _appleBusIconCache['$lineId|base'] ??
          apple.BitmapDescriptor.defaultAnnotation;
    }

    try {
      final apple.BitmapDescriptor descriptor =
          await _createRotatedAppleBusIcon(baseIcon.image, snappedHeading);
      _appleBusIconCache[cacheKey] = descriptor;
      return descriptor;
    } catch (e) {
      AppLogger.debug(
        '🍎 [图标旋转异常] 线路$lineId 角度${snappedHeading.toStringAsFixed(1)}°: $e',
      );
      return _appleBusIconCache['$lineId|base'] ??
          apple.BitmapDescriptor.defaultAnnotation;
    }
  }

  Future<void> _loadMissingBusIcon(String lineId) async {
    if (_appleBusIconAssets.containsKey(lineId)) return;

    try {
      final String iconPath = BusIconUtils.getBusIconPath(lineId);
      final _AppleScaledIconData iconData = await _loadAndScaleAppleMapIconData(
        iconPath,
        targetWidth: _appleBusIconTargetWidth,
      );
      _appleBusIconAssets[lineId] = iconData;
      _appleBusIconCache['$lineId|base'] = apple.BitmapDescriptor.fromBytes(
        iconData.bytes,
      );
      AppLogger.debug('🍎 [图标补载] 成功加载线路$lineId的图标');

      if (mounted) setState(() {});
    } catch (e) {
      AppLogger.debug('🍎 [图标补载失败] 线路$lineId: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    AppLogger.debug('🔄 [应用生命周期] 状态变化: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        AppLogger.debug('🔄 [应用生命周期] 应用恢复到前台，检查WebSocket连接');
        // 触发provider重新评估，这会检查WebSocket管理器状态
        ref.invalidate(realTimeBusDataProvider);
        break;
      case AppLifecycleState.paused:
        AppLogger.debug('🔄 [应用生命周期] 应用进入后台');
        break;
      case AppLifecycleState.detached:
        AppLogger.debug('🔄 [应用生命周期] 应用分离');
        break;
      case AppLifecycleState.inactive:
        AppLogger.debug('🔄 [应用生命周期] 应用不活跃');
        break;
      case AppLifecycleState.hidden:
        AppLogger.debug('🔄 [应用生命周期] 应用隐藏');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(effectiveIsDarkModeProvider);
    final busLinesAsync = ref.watch(busLinesProvider);
    final busDataAsync = ref.watch(realTimeBusDataProvider);

    // 🎨 监听主题变化并重新渲染标签
    ref.listen(effectiveIsDarkModeProvider, (previous, next) {
      if (previous != null && previous != next) {
        AppLogger.debug(
          '🎨 [主题变化] 检测到主题切换: ${previous ? "深色" : "浅色"} → ${next ? "深色" : "浅色"}',
        );

        // 重新渲染所有标签以适配新主题
        if (_stationLabels.isNotEmpty && _busStopMarkers.isNotEmpty) {
          AppLogger.debug('🔄 [重新渲染] 开始重新渲染 ${_stationLabels.length} 个站点标签...');

          // 异步重新渲染标签，避免阻塞UI
          Future.microtask(() async {
            await _renderUniqueStationLabels();
          });
        }
      }
    });

    // 监听实时车辆数据变化并更新地图标注
    ref.listen(realTimeBusDataProvider, (previous, next) {
      AppLogger.debug('🎯 [页面监听] realTimeBusDataProvider 状态变化');
      AppLogger.debug(
        '🎯 [页面监听] previous: ${previous?.hasValue}, next: ${next.hasValue}',
      );

      // 当收到新的校车数据时
      next.whenData((newBusData) {
        // 确保线路数据也已加载完成
        final busLines = busLinesAsync.value;
        if (busLines == null) {
          AppLogger.debug('⚠️ [页面监听] 线路数据尚未加载，无法更新车辆标注');
          return;
        }

        AppLogger.debug('🎯 [页面监听] 收到新的校车数据，准备更新地图: ${newBusData.length}辆车');

        // 根据平台更新地图
        if (Platform.isAndroid && _baiduMapController != null) {
          _updateBusMarkersOnBaiduMap(newBusData, busLines);
        } else if (Platform.isIOS && _appleMapController != null) {
          _updateBusMarkersOnAppleMap(newBusData, busLines);
        }
      });
    });

    // 监听深色模式变化，动态更新地图样式
    ref.listen(effectiveIsDarkModeProvider, (previous, next) {
      if (previous != null && previous != next) {
        AppLogger.debug('🌓 [主题变化] 检测到主题变化: $previous -> $next');
        if (Platform.isAndroid && _baiduMapController != null) {
          AppLogger.debug('📱 [Android] 开始动态更新百度地图样式...');
          _setBaiduMapDarkMode(_baiduMapController!, next);
        } else if (Platform.isAndroid) {
          AppLogger.debug('⚠️ [Android] 地图控制器为空，跳过样式更新');
        } else {
          AppLogger.debug('🍎 [iOS] Apple Maps会自动适配系统主题，无需手动设置');
        }
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 全屏地图背景
          busLinesAsync.when(
            data: (busLines) {
              // 仅针对iOS平台，在图标加载完成前显示加载动画
              if (Platform.isIOS) {
                return FutureBuilder<void>(
                  future: _iconsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasError) {
                        return _buildErrorWidget(
                          snapshot.error ?? '图标加载失败',
                          isDarkMode,
                        );
                      }
                      // 图标加载完成，显示地图
                      return _buildFullScreenMap(
                        busLines,
                        busDataAsync.value ?? [],
                      );
                    } else {
                      // 图标正在加载，显示加载动画
                      return Container(
                        color: isDarkMode
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                );
              } else {
                // 对于Android平台，直接显示地图
                return _buildFullScreenMap(busLines, busDataAsync.value ?? []);
              }
            },
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
              AppLogger.debug('🗺️ [地图加载] 地图加载完成，开始应用样式');
              AppLogger.debug('⏱️ [延迟] 等待500ms确保地图完全初始化...');
              // 延迟一下再设置样式，确保地图完全初始化
              await Future.delayed(const Duration(milliseconds: 500));
              AppLogger.debug(
                '🎨 [样式应用] 开始设置地图样式，当前模式: ${isDarkMode ? "深色" : "浅色"}',
              );
              try {
                await _setBaiduMapDarkMode(controller, isDarkMode);
              } catch (e) {
                AppLogger.debug('💥 [回调异常] 地图样式回调中设置失败: $e');
              }

              // 🎯 地图加载完成，自动启动定位
              AppLogger.debug('🗺️ [地图就绪] 地图加载完成，开始自动定位...');
              await _startAutoLocationOnMapLoad();
            },
          );

          // 设置地图状态改变回调，用于监听缩放级别变化
          controller.setMapStatusDidChangedCallback(
            callback: () async {
              try {
                final zoomLevel = await controller.getZoomLevel();
                if (zoomLevel != null && zoomLevel != _currentZoomLevel) {
                  AppLogger.debug(
                    '🔍 [缩放监听] 缩放级别从 $_currentZoomLevel 变为 $zoomLevel',
                  );
                  _currentZoomLevel = zoomLevel.toDouble();

                  // 使用防抖优化：延迟执行缩放更新，避免连续缩放时重复更新
                  _pendingZoomLevel = _currentZoomLevel;
                  _zoomDebounceTimer?.cancel();
                  _zoomDebounceTimer = Timer(
                    const Duration(milliseconds: 300),
                    () async {
                      if (_pendingZoomLevel != null) {
                        // 动态调整所有marker的尺寸
                        await _updateMarkersScale();

                        // 🏷️ 动态调整所有标签的样式和位置
                        await _updateLabelsScale();

                        _pendingZoomLevel = null;
                      }
                    },
                  );
                }
              } catch (e) {
                AppLogger.debug('💥 [缩放监听异常] $e');
              }
            },
          );

          // 设置marker点击回调，用于显示气泡信息
          controller.setMapClickedMarkerCallback(
            callback: (marker) {
              AppLogger.debug('🎯 [Marker点击] 收到marker点击事件');
              AppLogger.debug('📝 [Marker信息] id: ${marker.id}');
              AppLogger.debug('📝 [Marker信息] identifier: ${marker.identifier}');
              AppLogger.debug('📝 [Marker信息] title: ${marker.title}');
              AppLogger.debug('📝 [Marker信息] subtitle: ${marker.subtitle}');

              // 尝试从本地列表中找到对应的marker (使用id而不是identifier)
              bmf_map.BMFMarker? actualMarker = _findMarkerById(marker);

              if (actualMarker != null) {
                AppLogger.debug('✅ [找到Marker] 在本地列表中找到了对应的marker');
                AppLogger.debug(
                  '📍 [实际信息] title: ${actualMarker.title}, subtitle: ${actualMarker.subtitle}',
                );
                // 🔧 显示marker信息弹窗
                _showMarkerInfoDialog(actualMarker);
              } else {
                AppLogger.debug('❌ [未找到] 无法在本地列表中找到对应的marker');
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
        myLocationEnabled: true, // 启用用户位置显示
        myLocationButtonEnabled: false, // 禁用内置定位按钮，使用自定义按钮
        compassEnabled: true, // 启用指南针
        trafficEnabled: false, // 禁用交通流量图层
        annotations: {
          ..._appleBusStopAnnotations,
          ..._appleBusAnnotations,
          ..._appleLocationAnnotations,
        }.toSet(),
        polylines: _applePolylines.toSet(),
        onMapCreated: (controller) async {
          _appleMapController = controller;
          await _requestLocationPermission();
          await _drawBusLinesOnAppleMap(busLines, isDarkMode);
          _updateBusMarkersOnAppleMap(busData, busLines);
        },
        onTap: (apple.LatLng position) {
          AppLogger.debug(
            '🍎 [地图点击] 点击位置: ${position.latitude}, ${position.longitude}',
          );
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
        ToastService.show('无法拨打电话，已复制电话号码');
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

    // 清除之前的覆盖物
    await _clearAppleMapOverlays();

    // 绘制选中的线路或所有线路
    if (selectedLineIndex != null) {
      // 只绘制选中的线路，并高亮显示
      final selectedLine = busLines[selectedLineIndex!];
      await _drawBusRoutePolylineOnAppleMap(
        selectedLine,
        isDarkMode,
        selectedLineIndex!,
      );

      // 绘制站点标注（如果开启显示站点）
      if (showStops) {
        await _drawBusStopAnnotationsOnAppleMap(selectedLine, isDarkMode);
      }
    } else {
      // 绘制所有线路，都不高亮
      for (int i = 0; i < busLines.length; i++) {
        await _drawBusRoutePolylineOnAppleMap(busLines[i], isDarkMode, i);

        // 绘制站点标注（如果开启显示站点）
        if (showStops) {
          await _drawBusStopAnnotationsOnAppleMap(busLines[i], isDarkMode);
        }
      }
    }

    AppLogger.debug('🍎 [Apple Maps] 已绘制 ${busLines.length} 条公交线路');
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
      AppLogger.debug('🚏 [站点${i + 1}] ${line.name}线 - ${stop.name}');

      final stationName = stop.name.isNotEmpty ? stop.name : '站点${i + 1}';
      final stationSubtitle = '${line.name} • 点击查看详情';
      final stationId = 'bus_stop_${line.id}_$i';

      AppLogger.debug(
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
      AppLogger.debug(
        '✅ [本地保存] Marker已添加到_busStopMarkers列表，当前总数: ${_busStopMarkers.length}',
      );
      AppLogger.debug('   BMFOverlay.id: ${marker.id}'); // 显示自动生成的唯一ID
      AppLogger.debug(
        '   identifier: ${marker.identifier}',
      ); // 显示我们设置的identifier
    }

    // 优化批量添加性能：并行处理而非串行等待
    final List<Future<void>> addMarkerFutures = markers
        .map((marker) => _baiduMapController!.addMarker(marker))
        .toList();

    // 并行执行所有添加操作
    await Future.wait(addMarkerFutures);

    AppLogger.debug('🗺️ [地图添加完成] 已添加 ${markers.length} 个站点marker到地图上');

    // 🎯 添加站点后自动重新渲染站点名称标签
    await _renderUniqueStationLabels();
  }

  // 更新实时公交车辆标注
  void _updateBusMarkersOnBaiduMap(
    List<BusData> busData,
    List<BusLine> busLines,
  ) async {
    if (_baiduMapController == null) return;

    // 🚌 根据选中的线路过滤车辆数据
    List<BusData> filteredBusData;
    if (selectedLineIndex != null) {
      final selectedLine = busLines[selectedLineIndex!];
      filteredBusData = busData
          .where((bus) => bus.lineId == selectedLine.id)
          .toList();
    } else {
      filteredBusData = busData;
    }

    // 🎯 增量更新：计算需要添加、更新、删除的车辆
    final newBusIds = filteredBusData.map((bus) => 'bus_${bus.id}').toSet();
    final existingBusIds = _busMarkersMap.keys.toSet();

    // 1️⃣ 删除不再存在的车辆
    final toRemove = existingBusIds.difference(newBusIds);
    if (toRemove.isNotEmpty) {
      final removeFutures = <Future<void>>[];
      for (final busId in toRemove) {
        final marker = _busMarkersMap[busId];
        if (marker != null) {
          removeFutures.add(_baiduMapController!.removeMarker(marker));
          _busMarkers.remove(marker);
        }
        _busMarkersMap.remove(busId);
        _busDirectionMap.remove(busId); // 同时清除角度记录
      }
      await Future.wait(removeFutures);
      AppLogger.debug('🗑️ [车辆删除] 移除 ${toRemove.length} 辆车');
    }

    // 2️⃣ 更新现有车辆或添加新车辆
    final updateFutures = <Future<void>>[];
    final addFutures = <Future<void>>[];
    final recreateFutures = <Future<void>>[];
    int updateCount = 0;
    int addCount = 0;
    int recreateCount = 0;

    for (final bus in filteredBusData) {
      final busId = 'bus_${bus.id}';
      final existingMarker = _busMarkersMap[busId];
      final coordinate = bmf_base.BMFCoordinate(bus.latitude, bus.longitude);
      final lastDirection = _busDirectionMap[busId];

      if (existingMarker != null) {
        // 检查角度是否有显著变化（超过5度）
        final directionChanged =
            lastDirection == null ||
            ((-bus.direction) - lastDirection).abs() > 5.0;

        if (directionChanged) {
          // 🔄 角度变化较大，需要重新创建marker
          final line = busLines.firstWhere(
            (line) => line.id == bus.lineId,
            orElse: () => busLines.first,
          );
          final iconPath = BusIconUtils.getBusIconPath(bus.lineId);

          recreateFutures.add(
            _baiduMapController!.removeMarker(existingMarker).then((_) async {
              final newMarker = bmf_map.BMFMarker.icon(
                position: coordinate,
                identifier: busId,
                icon: iconPath,
                title: '${line.name} - 车辆${bus.id}',
                subtitle: '速度: ${bus.speed.toStringAsFixed(1)} km/h',
                rotation: -bus.direction,
                centerOffset: bmf_base.BMFPoint(0, -12),
                zIndex: 25,
                isPerspective: false,
                scaleX: 0.4,
                scaleY: 0.4,
                anchorX: 0.5,
                anchorY: 0.5,
                enabled: false,
                canShowCallout: false,
              );
              await _baiduMapController!.addMarker(newMarker);
              _busMarkersMap[busId] = newMarker;
              _busDirectionMap[busId] = -bus.direction;
              final index = _busMarkers.indexOf(existingMarker);
              if (index != -1) {
                _busMarkers[index] = newMarker;
              }
            }),
          );
          recreateCount++;
        } else {
          // ✏️ 只更新位置（角度变化不大）
          updateFutures.add(existingMarker.updatePosition(coordinate));
          updateCount++;
        }
      } else {
        // ➕ 添加新车辆
        final line = busLines.firstWhere(
          (line) => line.id == bus.lineId,
          orElse: () => busLines.first,
        );
        final iconPath = BusIconUtils.getBusIconPath(bus.lineId);

        final marker = bmf_map.BMFMarker.icon(
          position: coordinate,
          identifier: busId,
          icon: iconPath,
          title: '${line.name} - 车辆${bus.id}',
          subtitle: '速度: ${bus.speed.toStringAsFixed(1)} km/h',
          rotation: -bus.direction,
          centerOffset: bmf_base.BMFPoint(0, -12),
          zIndex: 25,
          isPerspective: false,
          scaleX: 0.4,
          scaleY: 0.4,
          anchorX: 0.5,
          anchorY: 0.5,
          enabled: false,
          canShowCallout: false,
        );

        addFutures.add(
          _baiduMapController!.addMarker(marker).then((_) {
            _busMarkers.add(marker);
            _busMarkersMap[busId] = marker;
            _busDirectionMap[busId] = -bus.direction;
          }),
        );
        addCount++;
      }
    }

    // 并行执行所有更新、重建和添加操作
    await Future.wait([...updateFutures, ...recreateFutures, ...addFutures]);

    if (updateCount > 0 ||
        addCount > 0 ||
        recreateCount > 0 ||
        toRemove.isNotEmpty) {
      AppLogger.debug(
        '🚌 [车辆更新] 更新: $updateCount 辆, 重建: $recreateCount 辆, 新增: $addCount 辆, 删除: ${toRemove.length} 辆',
      );
    }
  }

  // Apple地图更新车辆标注
  void _updateBusMarkersOnAppleMap(
    List<BusData> busData,
    List<BusLine> busLines,
  ) async {
    if (_appleMapController == null) return;

    final int requestId = ++_appleBusAnnotationUpdateId;

    try {
      if (busData.isEmpty) {
        if (!mounted || requestId != _appleBusAnnotationUpdateId) return;
        setState(() {
          _appleBusAnnotations.clear();
        });
        return;
      }

      // Filter bus data based on selected line
      List<BusData> filteredBusData;
      if (selectedLineIndex != null) {
        final selectedLine = busLines[selectedLineIndex!];
        filteredBusData = busData
            .where((bus) => bus.lineId == selectedLine.id)
            .toList();
      } else {
        filteredBusData = busData;
      }

      if (filteredBusData.isEmpty) {
        if (!mounted || requestId != _appleBusAnnotationUpdateId) return;
        setState(() {
          _appleBusAnnotations.clear();
        });
        return;
      }

      final List<Future<apple.Annotation>> annotationFutures = filteredBusData
          .map((bus) async {
            final line = busLines.firstWhere(
              (line) => line.id == bus.lineId,
              orElse: () => busLines.first,
            );

            final position = apple.LatLng(bus.latitude, bus.longitude);
            final icon = await _getAppleBusIcon(bus.lineId, bus.direction);

            return apple.Annotation(
              annotationId: apple.AnnotationId('bus_${bus.id}'),
              position: position,
              anchor: const Offset(0.5, 0.5),
              infoWindow: apple.InfoWindow(
                title: '${line.name} - 车辆${bus.id}',
                snippet: '速度: ${bus.speed.toStringAsFixed(1)} km/h • 点击查看详情',
                onTap: () {
                  AppLogger.debug('🍎 [车辆点击] 点击了车辆: ${bus.id}');
                  _showBusInfoDialog(bus, line);
                },
              ),
              icon: icon,
            );
          })
          .toList();

      final List<apple.Annotation> newAnnotations = await Future.wait(
        annotationFutures,
      );

      if (!mounted || requestId != _appleBusAnnotationUpdateId) {
        AppLogger.debug('🍎 [车辆更新] 忽略过期的Apple Maps车辆更新: $requestId');
        return;
      }

      // Trigger a rebuild to display the new annotations
      setState(() {
        _appleBusAnnotations
          ..clear()
          ..addAll(newAnnotations);
      });

      AppLogger.debug(
        '🍎 [车辆完成] 已更新 ${_appleBusAnnotations.length} 个车辆标注到Apple Maps',
      );
    } catch (e) {
      AppLogger.debug('🍎 [车辆异常] Apple Maps车辆标注更新失败: $e');
    }
  }

  // 清除百度地图覆盖物
  Future<void> _clearBaiduMapOverlays() async {
    if (_baiduMapController == null) return;

    try {
      // 创建副本并清空原列表，避免并发修改
      final polylinesToRemove = List<bmf_map.BMFPolyline>.from(_polylines);
      final busStopMarkersToRemove = List<bmf_map.BMFMarker>.from(
        _busStopMarkers,
      );
      final busMarkersToRemove = List<bmf_map.BMFMarker>.from(_busMarkers);
      final locationMarkersToRemove = List<bmf_map.BMFMarker>.from(
        _locationMarkers,
      );
      final stationLabelsToRemove = List<bmf_map.BMFText>.from(_stationLabels);

      _polylines.clear();
      _busStopMarkers.clear();
      _busMarkers.clear();
      _busMarkersMap.clear(); // 清空车辆映射表
      _busDirectionMap.clear(); // 清空角度映射表
      _locationMarkers.clear();
      _stationLabels.clear();

      // ⚡ 优化：并行删除所有覆盖物，提升清理速度
      final removeFutures = <Future<void>>[];

      // 清除折线
      for (final polyline in polylinesToRemove) {
        removeFutures.add(
          _baiduMapController!
              .removeOverlay(polyline.id)
              .then((_) {})
              .catchError((e) {
                AppLogger.debug('移除折线覆盖物失败: ${polyline.id}, 错误: $e');
                return null;
              }),
        );
      }

      // 清除站点标注
      for (final marker in busStopMarkersToRemove) {
        removeFutures.add(
          _baiduMapController!.removeMarker(marker).then((_) {}).catchError((
            e,
          ) {
            AppLogger.debug('移除站点标注失败: 错误: $e');
            return null;
          }),
        );
      }

      // 清除车辆标注
      for (final marker in busMarkersToRemove) {
        removeFutures.add(
          _baiduMapController!.removeMarker(marker).then((_) {}).catchError((
            e,
          ) {
            AppLogger.debug('移除车辆标注失败: 错误: $e');
            return null;
          }),
        );
      }

      // 清除位置标注
      for (final marker in locationMarkersToRemove) {
        removeFutures.add(
          _baiduMapController!.removeMarker(marker).then((_) {}).catchError((
            e,
          ) {
            AppLogger.debug('移除位置标注失败: 错误: $e');
            return null;
          }),
        );
      }

      // 清除站点名称标签
      for (final textLabel in stationLabelsToRemove) {
        removeFutures.add(
          _baiduMapController!
              .removeOverlay(textLabel.id)
              .then((_) {})
              .catchError((e) {
                AppLogger.debug('移除站点标签失败: 错误: $e');
                return null;
              }),
        );
      }

      // 并行执行所有删除操作
      await Future.wait(removeFutures, eagerError: false);
    } catch (e) {
      AppLogger.debug('清理地图覆盖物时出现异常: $e');
      // 即使出现异常，也要清理本地列表
      _polylines.clear();
      _busStopMarkers.clear();
      _busMarkers.clear();
      _busMarkersMap.clear(); // 清空车辆映射表
      _busDirectionMap.clear(); // 清空角度映射表
      _locationMarkers.clear();
      _stationLabels.clear();
    }
  }

  // ===================== Apple Maps 实现 =====================

  // 清除Apple Maps覆盖物
  Future<void> _clearAppleMapOverlays() async {
    setState(() {
      _applePolylines.clear();
      _appleBusStopAnnotations.clear();
      _appleBusAnnotations.clear();
      _appleLocationAnnotations.clear();
    });
    AppLogger.debug('🍎 [清理] Apple Maps覆盖物已清除');
  }

  // Apple Maps绘制公交路线折线
  Future<void> _drawBusRoutePolylineOnAppleMap(
    BusLine line,
    bool isDarkMode,
    int lineIndex,
  ) async {
    if (_appleMapController == null) return;

    try {
      // 转换坐标点为Apple Maps格式
      final coordinates = line.route
          .map((point) => apple.LatLng(point.latitude, point.longitude))
          .toList();

      final lineColor = Color(int.parse('0xFF${line.color}'));

      // 判断当前线路是否被选中
      final isSelected = selectedLineIndex == lineIndex;

      // 为选中线路使用更高亮的样式，考虑深色模式
      Color highlightColor;
      double strokeWidth;

      if (isSelected) {
        // 选中时使用更鲜艳的颜色和更粗的线条
        highlightColor = isDarkMode
            ? lineColor.withOpacity(1.0) // 深色模式下完全不透明
            : lineColor.withOpacity(0.95); // 浅色模式下略微透明
        strokeWidth = 6.0; // 选中线路更粗
      } else {
        // 未选中时使用半透明和细一些的线条
        highlightColor = isDarkMode
            ? lineColor.withOpacity(0.7) // 深色模式下保持可见
            : lineColor.withOpacity(0.5); // 浅色模式下更透明
        strokeWidth = 4.0; // 未选中线路细一些
      }

      // 创建Apple Maps折线
      final polyline = apple.Polyline(
        polylineId: apple.PolylineId('bus_line_${line.id}'),
        points: coordinates,
        color: highlightColor,
        width: strokeWidth.round(),
        patterns: [], // 实线
      );

      _applePolylines.add(polyline);
      setState(() {}); // Trigger rebuild
      AppLogger.debug(
        '🍎 [折线] ${line.name}线折线已添加，选中状态: $isSelected, 坐标点数: ${coordinates.length}',
      );
    } catch (e) {
      AppLogger.debug('🍎 [折线异常] 绘制${line.name}线折线失败: $e');
    }
  }

  // Apple Maps绘制公交站点标注
  Future<void> _drawBusStopAnnotationsOnAppleMap(
    BusLine line,
    bool isDarkMode,
  ) async {
    if (_appleMapController == null) return;

    try {
      List<apple.Annotation> annotations = [];

      for (int i = 0; i < line.stops.length; i++) {
        final stop = line.stops[i];
        final position = apple.LatLng(stop.latitude, stop.longitude);

        final stationName = stop.name.isNotEmpty ? stop.name : '站点${i + 1}';
        final stationSubtitle = '${line.name} • 点击导航';
        final annotationId = 'bus_stop_${line.id}_$i';

        // 创建Apple Maps标注
        final annotation = apple.Annotation(
          annotationId: apple.AnnotationId(annotationId),
          position: position,
          infoWindow: apple.InfoWindow(
            title: stationName,
            snippet: stationSubtitle,
            onTap: () {
              AppLogger.debug('🍎 [站点点击] 点击了站点: $stationName');
              _showStationNavigationDialog(stationName, position);
            },
          ),
          icon: _appleBusStopIcon ?? apple.BitmapDescriptor.defaultAnnotation,
        );

        annotations.add(annotation);
        _appleBusStopAnnotations.add(annotation);

        AppLogger.debug('🍎 [站点] ${line.name}线站点${i + 1}: $stationName 已创建');
      }

      setState(() {}); // Trigger rebuild
      AppLogger.debug('🍎 [站点完成] ${line.name}线已添加 ${annotations.length} 个站点标注');
    } catch (e) {
      AppLogger.debug('🍎 [站点异常] 绘制${line.name}线站点标注失败: $e');
    }
  }

  // Apple Maps启用用户定位
  Future<void> _enableAppleMapUserLocation() async {
    try {
      AppLogger.debug('🍎 [用户定位] 开始启用Apple Maps用户定位...');

      // Apple Maps会自动处理用户定位权限和显示
      // myLocationEnabled: true 已在地图初始化时设置

      AppLogger.debug('✅ [Apple定位] Apple Maps用户定位已启用');
    } catch (e) {
      AppLogger.debug('💥 [Apple定位失败] 启用Apple Maps用户定位失败: $e');
    }
  }

  // 从颜色获取色调值（用于Apple Maps标记）- 暂时不使用
  // double _getHueFromColor(Color color) {
  //   // 将Color转换为HSV，然后获取H（色调）值
  //   final hsl = HSLColor.fromColor(color);
  //   return hsl.hue;
  // }

  // 显示站点导航对话框
  void _showStationNavigationDialog(String stationName, apple.LatLng position) {
    if (!mounted) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          stationName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '公交站点',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '坐标: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '取消',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // 创建LocationPoint对象用于导航
              final locationPoint = LocationPoint(
                id: DateTime.now().millisecondsSinceEpoch,
                content: stationName,
                latitude: position.latitude,
                longitude: position.longitude,
              );
              _navigateToLocationWithMapLauncher(locationPoint);
            },
            icon: const Icon(Icons.navigation, color: Colors.white),
            label: const Text('导航', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // 显示车辆信息对话框
  void _showBusInfoDialog(BusData bus, BusLine line) {
    if (!mounted) return;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.white,
        title: Text(
          '${line.name} - 车辆${bus.id}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('线路', line.name, isDarkMode),
            _buildInfoRow('车辆编号', bus.id.toString(), isDarkMode),
            _buildInfoRow(
              '当前速度',
              '${bus.speed.toStringAsFixed(1)} km/h',
              isDarkMode,
            ),
            _buildInfoRow(
              '行驶方向',
              '${bus.direction.toStringAsFixed(1)}°',
              isDarkMode,
            ),
            _buildInfoRow(
              '位置坐标',
              '${bus.latitude.toStringAsFixed(6)}, ${bus.longitude.toStringAsFixed(6)}',
              isDarkMode,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              '关闭',
              style: TextStyle(
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 构建信息行
  Widget _buildInfoRow(String label, String value, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 安全清理地图覆盖物（用于dispose）
  void _clearBaiduMapOverlaysSafely() {
    try {
      AppLogger.debug('开始安全清理地图覆盖物...');

      // 只清理本地列表，不调用可能已失效的地图API
      final polylineCount = _polylines.length;
      final busStopCount = _busStopMarkers.length;
      final busCount = _busMarkers.length;
      final locationCount = _locationMarkers.length;

      final labelCount = _stationLabels.length;

      _polylines.clear();
      _busStopMarkers.clear();
      _busMarkers.clear();
      _busMarkersMap.clear(); // 清空车辆映射表
      _busDirectionMap.clear(); // 清空角度映射表
      _locationMarkers.clear();
      _stationLabels.clear();

      AppLogger.debug(
        '安全清理完成 - 折线: $polylineCount, 站点: $busStopCount, 车辆: $busCount, 位置: $locationCount, 标签: $labelCount',
      );
    } catch (e) {
      AppLogger.debug('安全清理地图覆盖物时出现异常: $e');
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
    // 🚀 确保缓存已初始化
    _ensureBuildingCacheInitialized();

    if (_searchQuery.isNotEmpty) {
      // 搜索模式：显示搜索结果
      return _buildSearchResults(scrollController);
    } else {
      // 正常模式：使用缓存的分类列表
      final locationTypes = _cachedLocationTypes ?? [];

      if (locationTypes.isEmpty) {
        // 缓存还未准备好，显示加载指示器
        return const Center(child: CircularProgressIndicator());
      }

      return ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        itemCount: locationTypes.length,
        itemBuilder: (context, index) {
          final type = locationTypes[index];
          final locations = _cachedLocationsByType?[type] ?? [];
          return _buildCategorySection(type, locations);
        },
      );
    }
  }

  // 搜索结果列表
  Widget _buildSearchResults(ScrollController scrollController) {
    // 🚀 使用缓存的建筑数据
    final allLocations = _cachedAllLocations ?? [];
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
            directionsMode: DirectionsMode.walking,
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
      AppLogger.debug('启动导航失败: $e');
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
                        directionsMode: DirectionsMode.walking,
                      );
                    } catch (e) {
                      AppLogger.debug('启动 ${map.mapName} 失败: $e');
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

    // 构建不同导航应用的 URL（按优先级排序，优先步行）
    final urls = [
      // Apple 地图（iOS 优先，指定步行模式）
      if (Platform.isIOS)
        'maps://maps.apple.com/?daddr=$latitude,$longitude&dirflg=w',
      // 百度地图（指定步行模式）
      'baidumap://map/direction?destination=latlng:$latitude,$longitude|name:$name&mode=walking&coord_type=gcj02',
      // 高德地图（指定步行模式）
      'amapuri://route/plan/?dlat=$latitude&dlon=$longitude&dname=$name&dev=0&t=2',
      // 腾讯地图（指定步行模式）
      'qqmap://map/routeplan?type=walk&tocoord=$latitude,$longitude&toname=$name',
      // Google 地图（指定步行模式）
      'google.navigation:q=$latitude,$longitude&mode=w',
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
    final markersToRemove = List<bmf_map.BMFMarker>.from(_locationMarkers);
    _locationMarkers.clear();
    for (final marker in markersToRemove) {
      await _baiduMapController!.removeMarker(marker);
    }

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
      ToastService.show('已定位到 ${location.content}');
    }
  }

  // 在 Apple 地图上标记位置
  Future<void> _markLocationOnAppleMap(LocationPoint location) async {
    if (_appleMapController == null) return;

    try {
      // 清除之前的位置标注
      if (_appleLocationAnnotations.isNotEmpty) {
        final locationCount = _appleLocationAnnotations.length;
        _appleLocationAnnotations.clear();
        AppLogger.debug('🍎 [位置清理] 已清除 $locationCount 个位置标注');
      }

      final position = apple.LatLng(location.latitude, location.longitude);

      // 创建位置标注
      final annotation = apple.Annotation(
        annotationId: apple.AnnotationId('location_${location.id}'),
        position: position,
        infoWindow: apple.InfoWindow(
          title: location.content,
          snippet: '校园建筑 • 点击导航',
          onTap: () {
            AppLogger.debug('🍎 [位置点击] 点击了建筑: ${location.content}');
            _navigateToLocationWithMapLauncher(location);
          },
        ),
        // 使用自定义的大头针图标
        icon: _appleLocationPinIcon ?? apple.BitmapDescriptor.defaultAnnotation,
      );

      _appleLocationAnnotations.add(annotation);

      setState(() {}); // Trigger rebuild
      // 移动地图中心到该位置
      await _appleMapController!.animateCamera(
        apple.CameraUpdate.newLatLng(position),
      );

      AppLogger.debug('🍎 [位置标注] 已标记建筑: ${location.content}');

      // 显示信息提示
      if (mounted) {
        ToastService.show('已定位到 ${location.content}');
      }
    } catch (e) {
      AppLogger.debug('🍎 [位置异常] Apple Maps位置标注失败: $e');
    }
  }

  // 请求定位权限
  Future<bool> _requestLocationPermission() async {
    try {
      AppLogger.debug('🔒 [权限检查] 开始检查定位权限...');

      // 使用全局权限管理器请求位置权限
      final result = await PermissionService.requestPermission(
        AppPermissionType.location,
        context: mounted ? context : null,
        showRationale: true,
      );
      AppLogger.debug('📋 [权限状态] 权限请求结果: ${result.isGranted}');

      if (result.isGranted) {
        AppLogger.debug('✅ [权限通过] 用户授予了定位权限');
        _enableUserLocation();
        return true;
      } else {
        AppLogger.debug('❌ [权限拒绝] 权限请求失败: ${result.errorMessage}');
        if (result.isPermanentlyDenied) {
          _showLocationPermissionDialog();
        }
        return false;
      }
    } catch (e) {
      AppLogger.debug('💥 [权限错误] 请求定位权限失败: $e');
      return false;
    }
  }

  // 设置百度地图深色模式
  Future<void> _setBaiduMapDarkMode(
    bmf_map.BMFMapController controller,
    bool isDarkMode,
  ) async {
    try {
      AppLogger.debug('设置地图样式为: ${isDarkMode ? "深色模式" : "标准模式"}');

      if (isDarkMode) {
        AppLogger.debug('🌙 [深色模式] 开始配置深色地图...');

        // 按照官方demo的方式设置.sty样式文件
        try {
          AppLogger.debug('📁 [STY文件] 使用files/路径加载.sty样式文件...');

          // 先设置样式文件（使用.sty格式）
          final result = await controller.setCustomMapStyle(
            'files/dark_map_style.sty',
            0, // 0: 本地文件模式
          );
          AppLogger.debug('📄 [STY文件] setCustomMapStyle返回结果: $result');

          if (result) {
            // 然后启用自定义样式
            final enableResult = await controller.setCustomMapStyleEnable(true);
            AppLogger.debug(
              '🎯 [STY文件] setCustomMapStyleEnable返回结果: $enableResult',
            );
            AppLogger.debug('🎉 [STY成功] 深色模式配置完成！');
            return;
          } else {
            AppLogger.debug('❌ [STY失败] .sty文件设置失败');
          }
        } catch (e) {
          AppLogger.debug('💥 [STY异常] .sty文件设置异常: $e');
        }

        AppLogger.debug('😞 [全部失败] 所有深色模式设置方法都失败了');
      } else {
        // 禁用深色模式：使用标准地图样式
        AppLogger.debug('☀️ [标准模式] 正在禁用自定义样式...');
        final disableResult = await controller.setCustomMapStyleEnable(false);
        AppLogger.debug(
          '🎯 [标准模式] setCustomMapStyleEnable(false)返回结果: $disableResult',
        );
        AppLogger.debug('✅ [标准模式] 标准样式恢复完成');
      }
    } catch (e) {
      AppLogger.debug('设置地图样式失败: $e');
    }
  }

  // 启用用户定位
  void _enableUserLocation() async {
    if (Platform.isAndroid && _baiduMapController != null) {
      try {
        // 🔧 修复：先启用定位图层
        final showResult = await _baiduMapController!.showUserLocation(true);
        AppLogger.debug('🎯 [百度定位图层] 启用结果: $showResult');

        // 🔧 设置定位模式为None，只显示位置不跟随视角
        final trackingResult = await _baiduMapController!.setUserTrackingMode(
          bmf_base.BMFUserTrackingMode.None, // None模式：显示位置但不移动视角
        );
        AppLogger.debug('🎯 [百度跟踪模式] 设置结果: $trackingResult');

        // 🔧 修复：配置定位显示参数
        await _configureLocationDisplay();

        AppLogger.debug('✅ [百度定位] 用户定位功能已启用');
      } catch (e) {
        AppLogger.debug('💥 [百度定位失败] 启用用户定位失败: $e');
      }
    } else if (Platform.isIOS && _appleMapController != null) {
      await _enableAppleMapUserLocation();
    }
  }

  // 🔧 配置定位显示参数并启用定位功能
  Future<void> _configureLocationDisplay() async {
    try {
      AppLogger.debug('🎨 [定位配置] 开始配置定位显示参数...');

      // 🔍 检查地图控制器是否为空
      if (_baiduMapController == null) {
        throw Exception('地图控制器为空');
      }
      AppLogger.debug('✅ [控制器检查] 地图控制器正常');

      // 创建定位显示参数
      AppLogger.debug('🔧 [参数创建] 开始创建定位显示参数...');
      final locationDisplayParam = bmf_map.BMFUserLocationDisplayParam(
        locationViewOffsetX: 0, // X轴偏移
        locationViewOffsetY: 0, // Y轴偏移
        userTrackingMode: bmf_base.BMFUserTrackingMode.None, // 不跟随视角模式
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
      AppLogger.debug('✅ [参数创建] 定位显示参数创建成功');

      // 更新定位显示参数
      AppLogger.debug('🔧 [参数更新] 开始更新定位显示参数...');
      final result = await _baiduMapController!.updateLocationViewWithParam(
        locationDisplayParam,
      );
      AppLogger.debug('🎨 [定位样式] 配置结果: $result');

      if (!result) {
        throw Exception('定位显示参数配置失败');
      }
    } catch (e, stackTrace) {
      AppLogger.debug('💥 [配置失败] 定位显示参数配置失败: $e');
      AppLogger.debug('📍 [堆栈跟踪] $stackTrace');
      rethrow;
    }
  }

  // 🎯 地图加载完成后自动启动定位
  Future<void> _startAutoLocationOnMapLoad() async {
    try {
      AppLogger.debug('🎯 [自动定位] 开始自动定位流程...');

      // 直接检查系统权限状态，而不是依赖本地变量
      final status = await Permission.location.status;
      bool permissionGranted = status.isGranted;

      // 如果权限被拒绝，则尝试请求
      if (status.isDenied) {
        AppLogger.debug('🚫 [自动定位] 定位权限被拒绝，正在请求...');
        permissionGranted = await _requestLocationPermission();
      } else if (status.isPermanentlyDenied) {
        AppLogger.debug('🚫 [自动定位] 定位权限被永久拒绝，跳过自动定位');
        return;
      } else {
        AppLogger.debug('✅ [自动定位] 系统权限已授予，无需重新请求');
      }

      // 如果权限获取成功，启动持续定位
      if (permissionGranted) {
        AppLogger.debug('✅ [自动定位] 权限已获取，启动持续定位...');
        await _startContinuousLocationUpdates();
      } else {
        AppLogger.debug('⚠️ [自动定位] 权限未获取，跳过自动定位');
      }
    } catch (e) {
      AppLogger.debug('💥 [自动定位失败] $e');
    }
  }

  // 🔄 启动持续定位更新
  Future<void> _startContinuousLocationUpdates() async {
    try {
      AppLogger.debug('🔄 [持续定位] 开始启动持续定位更新...');

      if (_isLocationStreamActive) {
        AppLogger.debug('⚠️ [持续定位] 位置流已激活，先停止现有流');
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

      AppLogger.debug('🔄 [位置流] 开始监听位置变化');
      _positionStreamSubscription =
          Geolocator.getPositionStream(
            locationSettings: locationSettings,
          ).listen(
            (Position position) {
              AppLogger.debug('📍 [位置更新] 收到新的位置数据');
              _handleLocationUpdate(position);
            },
            onError: (error) {
              AppLogger.debug('💥 [位置流错误] $error');
            },
            onDone: () {
              AppLogger.debug('🔄 [位置流] 位置流结束');
              _isLocationStreamActive = false;
            },
          );

      _isLocationStreamActive = true;
      AppLogger.debug('✅ [持续定位] 持续定位已启动（每秒更新模式）');
    } catch (e) {
      AppLogger.debug('💥 [持续定位失败] $e');
    }
  }

  // 🔄 停止持续定位更新
  Future<void> _stopContinuousLocationUpdates() async {
    try {
      AppLogger.debug('🛑 [停止定位] 停止持续定位更新...');

      if (_positionStreamSubscription != null) {
        await _positionStreamSubscription!.cancel();
        _positionStreamSubscription = null;
        AppLogger.debug('✅ [停止定位] 位置流已停止');
      }

      // 🧭 停止磁力计传感器监听
      if (_magnetometerSubscription != null) {
        await _magnetometerSubscription!.cancel();
        _magnetometerSubscription = null;
        _hasMagnetometerData = false; // 重置磁力计数据标志
        AppLogger.debug('✅ [停止传感器] 磁力计传感器已停止');
      }

      _isLocationStreamActive = false;
    } catch (e) {
      AppLogger.debug('💥 [停止定位失败] $e');
    }
  }

  // 🧭 启动磁力计传感器监听设备朝向
  void _startMagnetometerListener() {
    try {
      AppLogger.debug('🧭 [磁力计传感器] 开始监听设备朝向...');

      _magnetometerSubscription = magnetometerEventStream().listen(
        (MagnetometerEvent event) {
          // 100ms 更新一次（每秒10次）
          final nowMs = DateTime.now().millisecondsSinceEpoch;
          if (nowMs - _lastMagnetometerUpdateMs < 100) {
            return; // 跳过高频更新
          }
          _lastMagnetometerUpdateMs = nowMs;

          // 计算设备朝向角度（相对于磁北）
          double heading = math.atan2(event.y, event.x) * 180 / math.pi;

          // 确保角度在0-360度范围内
          if (heading < 0) {
            heading += 360;
          }

          // 🧭 朝向校正：逆时针旋转90度
          heading = (heading - 90 + 360) % 360;

          // 🧭 重庆地区磁偏角校正（约-3度）
          // 将磁北转换为真北，与高德地图保持一致
          const double magneticDeclination = -3.0;
          heading = (heading + magneticDeclination + 360) % 360;

          // 平滑处理，避免朝向跳动太频繁
          if ((heading - _currentDeviceHeading).abs() > 1.0) {
            _currentDeviceHeading = heading;
            _hasMagnetometerData = true; // 标记已有有效数据
            AppLogger.debug('🧭 [设备朝向] 磁力计朝向: ${heading.toStringAsFixed(1)}°');

            // 🧭 磁力计更新时也更新地图上的用户位置朝向
            _updateUserLocationHeading();
          }
        },
        onError: (error) {
          AppLogger.debug('💥 [磁力计错误] $error');
        },
      );

      AppLogger.debug('✅ [磁力计传感器] 磁力计监听已启动');
    } catch (e) {
      AppLogger.debug('💥 [磁力计启动失败] $e');
    }
  }

  // 📍 处理位置更新
  Future<void> _handleLocationUpdate(Position position) async {
    try {
      // 保存最后的GPS位置 (WGS-84)
      _lastGpsPosition = position;

      AppLogger.debug(
        '📍 [位置更新] 新位置: 纬度=${position.latitude.toStringAsFixed(6)}, '
        '经度=${position.longitude.toStringAsFixed(6)}, '
        '精度=${position.accuracy.toStringAsFixed(1)}米',
      );

      // 针对不同平台更新位置
      if (Platform.isAndroid && _baiduMapController != null) {
        // 🔄 坐标转换：WGS84 → GCJ02（火星坐标系）
        final gcj02Coordinate = _convertWGS84ToGCJ02(
          position.latitude,
          position.longitude,
        );

        // 🧭 选择朝向：
        // 1. 如果设备在移动（速度>1m/s），优先使用GPS朝向（更准确）
        // 2. 如果设备静止或慢速移动，使用磁力计朝向（静止时GPS朝向无效）
        // 3. 如果磁力计未初始化，使用GPS朝向
        final isMoving = position.speed > 1.0; // 速度大于1m/s算移动
        final useGpsHeading = isMoving || !_hasMagnetometerData;

        final effectiveHeading = useGpsHeading
            ? position.heading
            : _currentDeviceHeading;

        AppLogger.debug(
          '🧭 [朝向选择] GPS朝向=${position.heading.toStringAsFixed(1)}°, '
          '磁力计朝向=${_currentDeviceHeading.toStringAsFixed(1)}°, '
          '速度=${position.speed.toStringAsFixed(2)}m/s, '
          '使用=${useGpsHeading ? "GPS" : "磁力计"}(${effectiveHeading.toStringAsFixed(1)}°)',
        );

        // 创建BMFLocation对象，包含移动方向
        final bmfLocation = bmf_map.BMFLocation(
          coordinate: gcj02Coordinate,
          altitude: position.altitude,
          course: effectiveHeading, // 🧭 使用磁力计朝向
          speed: position.speed,
          timestamp: DateTime.now().millisecondsSinceEpoch.toString(),
        );

        // 创建设备朝向对象（罗盘方向）
        final bmfHeading = bmf_map.BMFHeading(
          trueHeading: effectiveHeading, // 🧭 设备朝向（使用磁力计）
          magneticHeading: effectiveHeading, // 🧭 磁北方向（使用磁力计）
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
          AppLogger.debug('✅ [位置更新] Android位置和朝向数据已更新到地图');
        } else {
          AppLogger.debug('❌ [位置更新] Android位置数据更新失败');
        }
      } else if (Platform.isIOS && _appleMapController != null) {
        // Apple Maps myLocationEnabled 会自动处理位置更新，我们无需手动操作
        AppLogger.debug('🍎 [位置更新] iOS平台接收到新位置，myLocationEnabled会自动处理');
      }
    } catch (e) {
      AppLogger.debug('💥 [位置更新失败] $e');
    }
  }

  // 🧭 仅更新用户位置朝向（磁力计更新时调用）
  Future<void> _updateUserLocationHeading() async {
    if (_baiduMapController == null || _lastGpsPosition == null) {
      return;
    }

    try {
      AppLogger.debug('🧭 [朝向更新] 仅更新朝向，使用最后GPS位置');
      await _handleLocationUpdate(_lastGpsPosition!);
    } catch (e) {
      AppLogger.debug('💥 [朝向更新失败] $e');
    }
  }

  // 🗺️ 移动地图到指定坐标
  Future<void> _moveMapToLocation(bmf_base.BMFCoordinate coordinate) async {
    try {
      AppLogger.debug('🗺️ [地图移动] 移动地图到GPS位置...');

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
        AppLogger.debug('✅ [地图移动] 地图已移动到GPS位置');
      } else {
        AppLogger.debug('⚠️ [地图移动] 地图移动可能失败');
      }
    } catch (e) {
      AppLogger.debug('💥 [地图移动失败] $e');
    }
  }

  // 定位到用户位置
  void _locateUser() async {
    AppLogger.debug('🎯 [定位按钮] 用户点击了定位按钮 - 移动视角到用户中心');

    // 直接检查当前权限状态，而不是依赖 _isLocationEnabled
    final status = await Permission.location.status;
    bool permissionGranted = status.isGranted;

    // 如果权限被拒绝，则尝试请求
    if (status.isDenied) {
      AppLogger.debug('🚫 [定位权限] 定位权限被拒绝，正在请求...');
      permissionGranted = await _requestLocationPermission();
    } else if (status.isPermanentlyDenied) {
      AppLogger.debug('🚫 [定位权限] 定位权限被永久拒绝，显示设置对话框...');
      _showLocationPermissionDialog();
      return;
    }

    // 如果最终权限被授予，则执行定位
    if (permissionGranted) {
      try {
        Position? position;

        // 🚀 优先使用缓存的最后 WGS-84 位置
        if (_lastGpsPosition != null) {
          position = _lastGpsPosition!;
          AppLogger.debug('⚡ [快速定位] 使用缓存WGS-84位置');
        } else {
          AppLogger.debug('📍 [获取位置] 缓存位置不存在，获取当前WGS-84位置...');
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.medium,
            timeLimit: const Duration(seconds: 5),
          );
        }

        AppLogger.debug(
          '✅ [WGS-84坐标] 纬度=${position.latitude.toStringAsFixed(6)}, '
          '经度=${position.longitude.toStringAsFixed(6)}',
        );

        if (Platform.isAndroid && _baiduMapController != null) {
          // 仅在Android平台进行坐标转换 WGS84 → GCJ02
          final gcj02Coordinate = _convertWGS84ToGCJ02(
            position.latitude,
            position.longitude,
          );
          AppLogger.debug(
            '✅ [GCJ-02转换] 纬度=${gcj02Coordinate.latitude.toStringAsFixed(6)}, '
            '经度=${gcj02Coordinate.longitude.toStringAsFixed(6)}',
          );
          await _moveMapToLocation(gcj02Coordinate);
        } else if (Platform.isIOS && _appleMapController != null) {
          // 修正：根据实际测试，iOS平台在中国区同样需要进行坐标转换
          final gcj02Coordinate = _convertWGS84ToGCJ02(
            position.latitude,
            position.longitude,
          );
          AppLogger.debug(
            '🍎 [GCJ-02转换] 纬度=${gcj02Coordinate.latitude.toStringAsFixed(6)}, '
            '经度=${gcj02Coordinate.longitude.toStringAsFixed(6)}',
          );
          final location = apple.LatLng(
            gcj02Coordinate.latitude,
            gcj02Coordinate.longitude,
          );
          await _appleMapController!.animateCamera(
            apple.CameraUpdate.newLatLngZoom(location, 18.0),
          );
          AppLogger.debug('🍎 [定位] Apple Maps已移动到用户GCJ-02位置');
        }
      } catch (e) {
        AppLogger.debug('❌ [定位失败] 错误详情: $e');
      }
    } else {
      AppLogger.debug('🤷 [定位取消] 用户未授予定位权限');
    }
  }

  // 显示定位权限对话框
  void _showLocationPermissionDialog() async {
    if (!mounted) return;

    final shouldOpenSettings = await ThemeAwareDialog.showConfirmDialog(
      context,
      title: '需要定位权限',
      message: '为了在地图上显示您的位置，需要获取定位权限。',
      negativeText: '取消',
      positiveText: '去设置',
    );

    if (shouldOpenSettings) {
      openAppSettings();
    }
  }

  // 动态更新所有marker的缩放比例
  Future<void> _updateMarkersScale() async {
    if (_baiduMapController == null) return;

    try {
      // 计算当前缩放比例因子（相对于初始级别）
      final scaleFactor = _calculateScaleFactor(_currentZoomLevel);

      AppLogger.debug('📏 [缩放更新] 缩放级别: $_currentZoomLevel');
      AppLogger.debug('📏 [缩放更新] 通用缩放因子: ${scaleFactor.toStringAsFixed(3)}');

      // 并行更新所有类型的marker
      final futures = <Future<void>>[];

      // 更新公交站点marker
      for (final marker in _busStopMarkers) {
        futures.add(_updateMarkerScale(marker, scaleFactor * 1.0)); // 站点保持原始比例
      }

      // 🚌 车辆marker不参与动态缩放，保持固定0.4大小
      AppLogger.debug('🚌 [车辆缩放] 车辆保持固定大小0.4，不参与动态缩放');

      // 更新位置标记marker
      for (final marker in _locationMarkers) {
        futures.add(_updateMarkerScale(marker, scaleFactor * 1.3)); // 位置标记最大
      }

      // 等待所有更新完成
      await Future.wait(futures);

      AppLogger.debug(
        '✅ [缩放更新完成] 已更新 ${_busStopMarkers.length + _busMarkers.length + _locationMarkers.length} 个marker',
      );
    } catch (e) {
      AppLogger.debug('💥 [缩放更新失败] $e');
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
      AppLogger.debug('💥 [Marker缩放失败] Marker ${marker.identifier}: $e');
    }
  }

  // 通过ID在本地marker列表中查找对应的marker
  bmf_map.BMFMarker? _findMarkerById(bmf_map.BMFMarker clickedMarker) {
    AppLogger.debug('🔍 [查找Marker] 开始查找，本地marker数量统计:');
    AppLogger.debug('   - 站点markers: ${_busStopMarkers.length}');
    AppLogger.debug('   - 车辆markers: ${_busMarkers.length}');
    AppLogger.debug('   - 位置markers: ${_locationMarkers.length}');

    // 🔧 优先通过唯一的 id 进行查找 (这是BMFOverlay的唯一标识)
    final clickedId = clickedMarker.id;
    AppLogger.debug('🔍 [通过ID查找] 查找id: $clickedId');

    // 在公交站点列表中查找
    for (final marker in _busStopMarkers) {
      if (marker.id == clickedId) {
        AppLogger.debug('✅ [找到匹配] 在站点列表中找到匹配的marker');
        AppLogger.debug(
          '   匹配详情: identifier=${marker.identifier}, title=${marker.title}',
        );
        return marker;
      }
    }

    // 在车辆列表中查找
    for (final marker in _busMarkers) {
      if (marker.id == clickedId) {
        AppLogger.debug('✅ [找到匹配] 在车辆列表中找到匹配的marker');
        AppLogger.debug(
          '   匹配详情: identifier=${marker.identifier}, title=${marker.title}',
        );
        return marker;
      }
    }

    // 在位置标记列表中查找
    for (final marker in _locationMarkers) {
      if (marker.id == clickedId) {
        AppLogger.debug('✅ [找到匹配] 在位置列表中找到匹配的marker');
        AppLogger.debug(
          '   匹配详情: identifier=${marker.identifier}, title=${marker.title}',
        );
        return marker;
      }
    }

    AppLogger.debug('❌ [ID查找失败] 没有找到匹配的id: $clickedId');

    // 🔧 备用方案：通过identifier查找 (如果id查找失败)
    if (clickedMarker.identifier != null) {
      AppLogger.debug(
        '🔄 [备用查找] 尝试通过identifier查找: ${clickedMarker.identifier}',
      );

      for (final marker in [
        ..._busStopMarkers,
        ..._busMarkers,
        ..._locationMarkers,
      ]) {
        if (marker.identifier == clickedMarker.identifier) {
          AppLogger.debug('✅ [备用成功] 通过identifier找到匹配的marker');
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
        AppLogger.debug('🔍 [坐标匹配] 通过坐标找到了marker: ${marker.identifier}');
        return marker;
      }
    }

    return null;
  }

  // 清除所有站点标签
  Future<void> _clearStationLabels() async {
    if (_stationLabels.isNotEmpty) {
      AppLogger.debug('🧹 [清理标签] 清除之前的 ${_stationLabels.length} 个站点标签...');
      final labelsToRemove = List<bmf_map.BMFText>.from(_stationLabels);
      _stationLabels.clear();
      for (final textLabel in labelsToRemove) {
        try {
          await _baiduMapController!.removeOverlay(textLabel.id);
        } catch (e) {
          AppLogger.debug('💥 [清理失败] 移除标签失败: $e');
        }
      }
    }
  }

  // 渲染去重后的站点标签
  Future<void> _renderUniqueStationLabels() async {
    AppLogger.debug('📊 [统计] 开始分析 ${_busStopMarkers.length} 个站点marker...');

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

    AppLogger.debug(
      '🎯 [去重结果] 从 ${_busStopMarkers.length} 个marker中找到 ${uniqueStations.length} 个唯一站点',
    );

    // 🚀 批量创建所有标签（性能优化）
    final List<bmf_map.BMFText> labelsToAdd = [];

    AppLogger.debug('🏗️ [批量创建] 开始批量创建 ${uniqueStations.length} 个标签...');

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
          AppLogger.debug(
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
        AppLogger.debug('💥 [创建异常] $stationName 标签创建失败: $e');
      }
    }

    // 🚀 批量添加到地图（大幅提升性能）
    if (labelsToAdd.isNotEmpty) {
      AppLogger.debug('⚡ [批量添加] 开始批量添加 ${labelsToAdd.length} 个标签到地图...');

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

        AppLogger.debug('✅ [批量完成] 标签批量添加结果:');
        AppLogger.debug('   - 成功: $successCount 个');
        AppLogger.debug('   - 失败: $failCount 个');

        if (successCount > 0) {
          AppLogger.debug('🎉 [完成] 所有站点标签已批量显示在地图上！');
        }
      } catch (e) {
        AppLogger.debug('💥 [批量失败] 批量添加标签失败: $e');
      }
    }
  }

  // 🏷️ 动态调整所有标签的样式和位置（响应缩放变化）
  Future<void> _updateLabelsScale() async {
    if (_stationLabels.isEmpty || _baiduMapController == null) {
      return;
    }

    AppLogger.debug('🏷️ [标签缩放] 开始更新 ${_stationLabels.length} 个标签的缩放样式...');

    try {
      // 重新渲染所有标签以应用新的缩放样式
      await _renderUniqueStationLabels();

      AppLogger.debug('✅ [标签缩放] 标签缩放更新完成');
    } catch (e) {
      AppLogger.debug('💥 [标签缩放失败] $e');
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

  // 🚀 确保建筑缓存已初始化
  void _ensureBuildingCacheInitialized() {
    if (!_isBuildingCacheInitialized) {
      _isBuildingCacheInitialized = true;
      _initializeBuildingCacheSync();
    }
  }

  // 🚀 同步初始化建筑数据缓存（首次访问时）
  void _initializeBuildingCacheSync() {
    try {
      _cachedLocationTypes = CampusLocations.getAllLocationTypes();
      _cachedAllLocations = CampusLocations.getAllLocationPoints();
      _cachedLocationsByType = {};

      for (final type in _cachedLocationTypes!) {
        _cachedLocationsByType![type] = CampusLocations.getLocationsByType(
          type,
        );
      }

      AppLogger.debug(
        '🚀 [建筑缓存] 同步缓存完成: ${_cachedLocationTypes!.length}个分类, ${_cachedAllLocations!.length}个建筑',
      );
    } catch (e) {
      AppLogger.debug('💥 [建筑缓存] 同步初始化失败: $e');
    }
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

    AppLogger.debug('🧭 [开始导航] 导航到: ${locationPoint.content}');

    // 复用现有的导航逻辑
    _navigateToLocationWithMapLauncher(locationPoint);
  }

  @override
  void dispose() {
    // 移除应用生命周期观察者
    WidgetsBinding.instance.removeObserver(this);

    // 安全清理地图覆盖物
    _clearBaiduMapOverlaysSafely();
    _clearAppleMapOverlaysSafely();

    // 🛑 停止位置流监听
    _stopContinuousLocationUpdates();

    // 取消磁力计监听
    _magnetometerSubscription?.cancel();

    // 取消缩放防抖定时器
    _zoomDebounceTimer?.cancel();

    // 清理搜索控制器
    _searchController.dispose();

    // 清理Apple Maps图标缓存
    _clearAppleIconsCache();

    AppLogger.debug('🛑 [页面生命周期] SchoolNavigationScreen 销毁');
    super.dispose();
  }

  // 清理Apple Maps图标缓存
  void _clearAppleIconsCache() {
    try {
      _appleLocationPinIcon = null;
      _appleBusStopIcon = null;
      for (final entry in _appleBusIconAssets.entries) {
        entry.value.image.dispose();
      }
      _appleBusIconAssets.clear();
      _appleBusIconCache.clear();
      AppLogger.debug('🍎 [缓存清理] Apple Maps图标缓存已清理');
    } catch (e) {
      AppLogger.debug('🍎 [缓存清理异常] $e');
    }
  }

  // 安全清理Apple Maps覆盖物（用于dispose）
  void _clearAppleMapOverlaysSafely() {
    try {
      AppLogger.debug('🍎 [安全清理] 开始安全清理Apple Maps覆盖物...');

      // 只清理本地列表，不调用可能已失效的地图API
      final polylineCount = _applePolylines.length;
      final busStopCount = _appleBusStopAnnotations.length;
      final busCount = _appleBusAnnotations.length;
      final locationCount = _appleLocationAnnotations.length;

      _applePolylines.clear();
      _appleBusStopAnnotations.clear();
      _appleBusAnnotations.clear();
      _appleLocationAnnotations.clear();

      AppLogger.debug(
        '🍎 [安全清理完成] 折线: $polylineCount, 站点: $busStopCount, 车辆: $busCount, 位置: $locationCount',
      );
    } catch (e) {
      AppLogger.debug('🍎 [安全清理异常] 安全清理Apple Maps覆盖物时出现异常: $e');
    }
  }
}
