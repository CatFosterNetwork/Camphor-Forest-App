// lib/pages/school_navigation/utils/bus_icon_utils.dart

class BusIconUtils {
  // 线路ID到图标文件名的映射
  static const Map<String, String> _lineIdToIconMap = {
    '239': 'bus_line_1.png', // 1号线 - 蓝色
    '241': 'bus_line_2.png', // 2号线 - 灰色
    '242': 'bus_line_3.png', // 3号线 - 橙色
    '421': 'bus_line_3b.png', // 3路B线 - 绿色
    '243': 'bus_line_4.png', // 4号线 - 紫红色
    '244': 'bus_line_5.png', // 5号线 - 红色
    '77': 'bus_line_6.png', // 6号线 - 天蓝色
    '78': 'bus_line_7.png', // 7号线 - 粉色
    '79': 'bus_line_8.png', // 8号线 - 紫色
    '293': 'bus_line_economics.png', // 经管专线 - 绿色
  };

  // 线路颜色到图标文件名的映射（备用方案）
  static const Map<String, String> _colorToIconMap = {
    '3983f6': 'bus_line_1.png', // 1号线蓝色
    '929296': 'bus_line_2.png', // 2号线灰色
    'f19f39': 'bus_line_3.png', // 3号线橙色
    '1b751a': 'bus_line_3b.png', // 3路B线绿色
    'ff00ff': 'bus_line_4.png', // 4号线紫红色
    'ff2323': 'bus_line_5.png', // 5号线红色
    '00bfff': 'bus_line_6.png', // 6号线天蓝色
    'ff69b4': 'bus_line_7.png', // 7号线粉色
    '6a5acd': 'bus_line_8.png', // 8号线紫色
    '00d499': 'bus_line_economics.png', // 经管专线绿色
  };

  /// 根据线路ID获取校车图标路径
  /// [lineId] 线路ID
  /// 返回图标的完整资源路径
  static String getBusIconPath(String lineId) {
    final iconFileName = _lineIdToIconMap[lineId];
    if (iconFileName != null) {
      return 'assets/icons/bus/$iconFileName';
    }

    // 如果没有找到对应的线路ID，返回默认图标
    return 'assets/icons/bus/bus_line_1.png';
  }

  /// 根据线路颜色获取校车图标路径（备用方案）
  /// [color] 线路颜色代码（不含#号）
  /// 返回图标的完整资源路径
  static String getBusIconPathByColor(String color) {
    final iconFileName = _colorToIconMap[color.toLowerCase()];
    if (iconFileName != null) {
      return 'assets/icons/bus/$iconFileName';
    }

    // 如果没有找到对应的颜色，返回默认图标
    return 'assets/icons/bus/bus_line_1.png';
  }

  /// 获取线路名称对应的图标路径
  /// [lineName] 线路名称（如"1号线"、"2号线"等）
  /// 返回图标的完整资源路径
  static String getBusIconPathByName(String lineName) {
    switch (lineName) {
      case '1号线':
        return 'assets/icons/bus/bus_line_1.png';
      case '2号线':
        return 'assets/icons/bus/bus_line_2.png';
      case '3号线':
        return 'assets/icons/bus/bus_line_3.png';
      case '3路B线':
        return 'assets/icons/bus/bus_line_3b.png';
      case '4号线':
        return 'assets/icons/bus/bus_line_4.png';
      case '5号线':
        return 'assets/icons/bus/bus_line_5.png';
      case '6号线':
        return 'assets/icons/bus/bus_line_6.png';
      case '7号线':
        return 'assets/icons/bus/bus_line_7.png';
      case '8号线':
        return 'assets/icons/bus/bus_line_8.png';
      case '经管专线':
        return 'assets/icons/bus/bus_line_economics.png';
      default:
        return 'assets/icons/bus/bus_line_1.png';
    }
  }

  /// 检查线路ID是否有对应的图标
  /// [lineId] 线路ID
  /// 返回是否存在对应图标
  static bool hasIconForLineId(String lineId) {
    return _lineIdToIconMap.containsKey(lineId);
  }

  /// 获取所有可用的线路ID列表
  static List<String> getSupportedLineIds() {
    return _lineIdToIconMap.keys.toList();
  }

  /// 获取默认校车图标路径
  static String getDefaultBusIconPath() {
    return 'assets/icons/bus/bus_line_1.png';
  }
}
