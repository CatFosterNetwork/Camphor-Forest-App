// lib/pages/school_navigation/providers/bus_provider.dart

import 'dart:async';

import '../../../core/utils/app_logger.dart';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bus_models.dart';
import '../../../core/constants/bus_line_constants.dart';

// WebSocket管理器类
class WebSocketManager {
  WebSocketChannel? _channel;
  Timer? _heartbeatTimer;
  StreamController<List<BusData>>? _controller;
  bool _isDisposed = false;

  Stream<List<BusData>> get stream => _controller!.stream;

  WebSocketManager() {
    _controller = StreamController<List<BusData>>.broadcast();
    _connect();
  }

  void _connect() async {
    if (_isDisposed) return;

    try {
      AppLogger.debug('🔄 [WebSocket管理器] 开始连接...');
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://youche.jhcampus.net:8914'),
      );

      AppLogger.debug('✅ [WebSocket管理器] 连接成功，启动心跳');
      _startHeartbeat();
      _listenToStream();
    } catch (e) {
      AppLogger.debug('💥 [WebSocket管理器] 连接失败: $e');
      // 5秒后重试
      if (!_isDisposed) {
        Timer(const Duration(seconds: 5), () => _connect());
      }
    }
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      try {
        if (_channel?.closeCode == null) {
          final ts = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
          final payload = '1,1915111,0,0,$ts,189,0';
          _channel!.sink.add(payload);
          AppLogger.debug('💓 [WebSocket管理器] 心跳发送: $payload');
        } else {
          AppLogger.debug('⚠️ [WebSocket管理器] 连接已关闭，准备重连');
          _reconnect();
        }
      } catch (e) {
        AppLogger.debug('💥 [WebSocket管理器] 心跳失败: $e，准备重连');
        _reconnect();
      }
    });
  }

  void _listenToStream() {
    _channel!.stream.listen(
      (event) {
        if (_isDisposed) return;
        _handleMessage(event);
      },
      onError: (error) {
        AppLogger.debug('💥 [WebSocket管理器] 流错误: $error，准备重连');
        if (!_isDisposed) _reconnect();
      },
      onDone: () {
        AppLogger.debug('🔚 [WebSocket管理器] 流结束，准备重连');
        if (!_isDisposed) _reconnect();
      },
    );
  }

  void _handleMessage(dynamic event) {
    // 增加原始数据打印，用于调试任何类型的传入消息
    AppLogger.debug('📥 [WebSocket管理器] 收到原始事件: $event');
    try {
      if (event is String && event.contains('|')) {
        // 增加长度检查，避免RangeError
        final logMessage = event.length > 100
            ? '${event.substring(0, 100)}...'
            : event;
        AppLogger.debug('📥 [WebSocket管理器] 收到有效数据: $logMessage');
        final parts = event.split('|');
        if (parts.length < 2) return;

        final dataJson = parts[1];
        final List<dynamic> arr = json.decode(dataJson);
        final buses = <BusData>[];

        for (final item in arr) {
          if (item is String) {
            final fields = item.split(',');
            if (fields.length >= 9) {
              // 索引解析：0:id, 1:speed, 2:lng, 3:lat, 6:direction, 8:lineID
              final id = fields[0];
              final speed = double.tryParse(fields[1]) ?? 0;
              final lng = double.tryParse(fields[2]) ?? 0;
              final lat = double.tryParse(fields[3]) ?? 0;
              final direction = double.tryParse(fields[6]) ?? 0;
              final lineId = fields[8];
              buses.add(
                BusData(
                  id: id,
                  lineId: lineId,
                  latitude: lat,
                  longitude: lng,
                  speed: speed,
                  direction: direction,
                ),
              );
            }
          }
        }

        AppLogger.debug('📊 [WebSocket管理器] 解析完成: ${buses.length}辆车');
        if (!_isDisposed) {
          _controller!.add(buses);
        }
      }
    } catch (e) {
      AppLogger.debug('💥 [WebSocket管理器] 消息处理失败: $e');
    }
  }

  void _reconnect() {
    AppLogger.debug('🔄 [WebSocket管理器] 开始重连...');
    _cleanup();
    Timer(const Duration(seconds: 2), () => _connect());
  }

  void _cleanup() {
    _heartbeatTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    AppLogger.debug('🛑 [WebSocket管理器] 销毁连接');
    _isDisposed = true;
    _cleanup();
    _controller?.close();
  }
}

final busLinesProvider = FutureProvider<List<BusLine>>((ref) async {
  // 直接使用已优化的数据格式
  return BusLinesData.getBusLinesData();
});

// 全局WebSocket管理器实例
WebSocketManager? _globalWebSocketManager;

final realTimeBusDataProvider = StreamProvider.autoDispose<List<BusData>>((
  ref,
) async* {
  AppLogger.debug('🔄 [Provider] realTimeBusDataProvider 被创建');

  // 创建或重用WebSocket管理器
  if (_globalWebSocketManager == null || _globalWebSocketManager!._isDisposed) {
    AppLogger.debug('🔄 [Provider] 创建新的WebSocket管理器');
    _globalWebSocketManager = WebSocketManager();
  } else {
    AppLogger.debug('🔄 [Provider] 重用现有WebSocket管理器');
  }

  ref.onDispose(() {
    AppLogger.debug(
      '🛑 [Provider] realTimeBusDataProvider 被销毁，释放 WebSocket 管理器',
    );
    _globalWebSocketManager?.dispose();
    _globalWebSocketManager = null;
  });

  // 返回管理器的数据流
  yield* _globalWebSocketManager!.stream;
});

final selectedBusLineProvider = StateProvider<int?>((ref) => null);

final showStopsProvider = StateProvider<bool>((ref) => true);
