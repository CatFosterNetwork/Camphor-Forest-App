// lib/pages/school_navigation/providers/bus_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/bus_models.dart';
import '../../../core/constants/bus_line_constants.dart';

final busLinesProvider = FutureProvider<List<BusLine>>((ref) async {
  // 直接使用已优化的数据格式
  return BusLinesData.getBusLinesData();
});

final realTimeBusDataProvider = StreamProvider<List<BusData>>((ref) async* {
  final channel = WebSocketChannel.connect(
    Uri.parse('wss://youche.jhcampus.net:8914'),
  );

  // 定时上报心跳/订阅消息，参数含义参考小程序：
  // 格式："1,1915111,0,0,<timestamp>,189,0"
  Timer? timer;
  timer = Timer.periodic(const Duration(seconds: 2), (_) {
    final ts = (DateTime.now().millisecondsSinceEpoch / 1000).floor();
    final payload = '1,1915111,0,0,$ts,189,0';
    channel.sink.add(payload);
  });

  ref.onDispose(() {
    timer?.cancel();
    channel.sink.close();
  });

  yield* channel.stream
      .where((event) => event is String && event.contains('|'))
      .map((event) {
        final raw = event as String;
        final parts = raw.split('|');
        if (parts.length < 2) return <BusData>[];
        final dataJson = parts[1];
        try {
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
          return buses;
        } catch (_) {
          return <BusData>[];
        }
      });
});

final selectedBusLineProvider = StateProvider<int?>((ref) => null);

final showStopsProvider = StateProvider<bool>((ref) => true);
