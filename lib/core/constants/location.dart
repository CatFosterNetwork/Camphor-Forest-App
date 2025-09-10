// lib/core/constants/location.dart

class LocationPoint {
  final int id;
  final double latitude;
  final double longitude;
  final String content;

  const LocationPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.content,
  });

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      id: json['id'] as int,
      latitude: json['latitude'] as double,
      longitude: json['longitude'] as double,
      content: json['callout']['content'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'callout': {'content': content},
    };
  }
}

/// 餐厅位置
const List<LocationPoint> restaurantLocations = [
  LocationPoint(
    id: 90500,
    latitude: 29.81612,
    longitude: 106.41573,
    content: "竹园食堂",
  ),
  LocationPoint(
    id: 90501,
    latitude: 29.817746,
    longitude: 106.419312,
    content: "楠园一食堂",
  ),
  LocationPoint(
    id: 90502,
    latitude: 29.81664,
    longitude: 106.4204,
    content: "楠园二食堂",
  ),
  LocationPoint(
    id: 90503,
    latitude: 29.824389,
    longitude: 106.423332,
    content: "梅园食堂",
  ),
  LocationPoint(
    id: 90504,
    latitude: 29.820427,
    longitude: 106.426484,
    content: "李园食堂",
  ),
  LocationPoint(
    id: 90505,
    latitude: 29.82509,
    longitude: 106.426305,
    content: "杏园食堂",
  ),
  LocationPoint(
    id: 90506,
    latitude: 29.8278,
    longitude: 106.42731,
    content: "桃园食堂",
  ),
  LocationPoint(
    id: 90507,
    latitude: 29.826618,
    longitude: 106.42598,
    content: "橘园食堂",
  ),
  LocationPoint(
    id: 90508,
    latitude: 29.819989,
    longitude: 106.426335,
    content: "李园小吃街",
  ),
  LocationPoint(
    id: 90509,
    latitude: 29.817797,
    longitude: 106.419517,
    content: "楠园美食城",
  ),
];

/// 宿舍位置
const List<LocationPoint> dormitoryLocations = [
  // 竹园1区
  LocationPoint(
    id: 90600,
    latitude: 29.816139,
    longitude: 106.416843,
    content: "竹园1区A栋",
  ),
  LocationPoint(
    id: 90601,
    latitude: 29.816378,
    longitude: 106.416761,
    content: "竹园1区B栋",
  ),
  LocationPoint(
    id: 90602,
    latitude: 29.81674,
    longitude: 106.417,
    content: "竹园1区C栋",
  ),
  LocationPoint(
    id: 90603,
    latitude: 29.81693,
    longitude: 106.41721,
    content: "竹园1区D栋",
  ),
  LocationPoint(
    id: 90604,
    latitude: 29.817047,
    longitude: 106.417859,
    content: "竹园1区E栋",
  ),
  LocationPoint(
    id: 90605,
    latitude: 29.8168,
    longitude: 106.4179,
    content: "竹园1区F栋",
  ),

  // 竹园2区
  LocationPoint(
    id: 90606,
    latitude: 29.815913,
    longitude: 106.41477,
    content: "竹园2区一舍",
  ),
  LocationPoint(
    id: 90607,
    latitude: 29.81673,
    longitude: 106.41428,
    content: "竹园2区二舍",
  ),
  LocationPoint(
    id: 90608,
    latitude: 29.81599,
    longitude: 106.4143,
    content: "竹园2区三舍",
  ),
  LocationPoint(
    id: 90609,
    latitude: 29.81637,
    longitude: 106.41411,
    content: "竹园2区四舍",
  ),
  LocationPoint(
    id: 90610,
    latitude: 29.815745,
    longitude: 106.413817,
    content: "竹园2区五舍",
  ),
  LocationPoint(
    id: 90611,
    latitude: 29.816098,
    longitude: 106.413526,
    content: "竹园2区六舍",
  ),
  LocationPoint(
    id: 90612,
    latitude: 29.816603,
    longitude: 106.415968,
    content: "竹园2区七舍",
  ),
  LocationPoint(
    id: 90613,
    latitude: 29.817157,
    longitude: 106.41636,
    content: "竹园2区八舍",
  ),

  // 楠园
  LocationPoint(
    id: 90614,
    latitude: 29.816641,
    longitude: 106.419275,
    content: "楠园一舍",
  ),
  LocationPoint(
    id: 90615,
    latitude: 29.81838,
    longitude: 106.4192,
    content: "楠园二舍",
  ),
  LocationPoint(
    id: 90616,
    latitude: 29.816151,
    longitude: 106.419942,
    content: "楠园三舍",
  ),
  LocationPoint(
    id: 90617,
    latitude: 29.816757,
    longitude: 106.418684,
    content: "楠园四舍",
  ),
  LocationPoint(
    id: 90618,
    latitude: 29.81768,
    longitude: 106.418919,
    content: "楠园五舍",
  ),
  LocationPoint(
    id: 90619,
    latitude: 29.817215,
    longitude: 106.41973,
    content: "楠园六舍",
  ),
  LocationPoint(
    id: 90620,
    latitude: 29.81755,
    longitude: 106.419695,
    content: "楠园七舍",
  ),
  LocationPoint(
    id: 90621,
    latitude: 29.817382,
    longitude: 106.418656,
    content: "楠园八舍",
  ),
  LocationPoint(
    id: 90622,
    latitude: 29.817205,
    longitude: 106.420512,
    content: "楠园九舍",
  ),

  // 李园
  LocationPoint(
    id: 90623,
    latitude: 29.821339,
    longitude: 106.426148,
    content: "李园一舍",
  ),
  LocationPoint(
    id: 90624,
    latitude: 29.82149,
    longitude: 106.42588,
    content: "李园二舍",
  ),
  LocationPoint(
    id: 90625,
    latitude: 29.82183,
    longitude: 106.4257,
    content: "李园三舍",
  ),
  LocationPoint(
    id: 90626,
    latitude: 29.82155,
    longitude: 106.425004,
    content: "李园四舍",
  ),
  LocationPoint(
    id: 90627,
    latitude: 29.821289,
    longitude: 106.425152,
    content: "李园五舍",
  ),
  LocationPoint(
    id: 90628,
    latitude: 29.820943,
    longitude: 106.425561,
    content: "李园六舍",
  ),
  LocationPoint(
    id: 90629,
    latitude: 29.820637,
    longitude: 106.425833,
    content: "李园七舍",
  ),
  LocationPoint(
    id: 90630,
    latitude: 29.820916,
    longitude: 106.426335,
    content: "李园八舍",
  ),

  // 橘园
  LocationPoint(
    id: 90631,
    latitude: 29.825258,
    longitude: 106.42645,
    content: "橘园一舍",
  ),
  LocationPoint(
    id: 90632,
    latitude: 29.825502,
    longitude: 106.426342,
    content: "橘园二舍",
  ),
  LocationPoint(
    id: 90633,
    latitude: 29.82582,
    longitude: 106.42571,
    content: "橘园三舍",
  ),
  LocationPoint(
    id: 90634,
    latitude: 29.826011,
    longitude: 106.425549,
    content: "橘园四舍",
  ),
  LocationPoint(
    id: 90635,
    latitude: 29.826267,
    longitude: 106.42522,
    content: "橘园五舍",
  ),
  LocationPoint(
    id: 90636,
    latitude: 29.8266,
    longitude: 106.42522,
    content: "橘园六舍",
  ),
  LocationPoint(
    id: 90637,
    latitude: 29.82645,
    longitude: 106.424929,
    content: "橘园七舍",
  ),
  LocationPoint(
    id: 90638,
    latitude: 29.825866,
    longitude: 106.424578,
    content: "橘园八舍",
  ),
  LocationPoint(
    id: 90639,
    latitude: 29.825645,
    longitude: 106.424766,
    content: "橘园九舍",
  ),
  LocationPoint(
    id: 90640,
    latitude: 29.825482,
    longitude: 106.424999,
    content: "橘园十舍",
  ),
  LocationPoint(
    id: 90641,
    latitude: 29.82516,
    longitude: 106.42404,
    content: "橘园十一舍",
  ),
  LocationPoint(
    id: 90642,
    latitude: 29.825498,
    longitude: 106.42388,
    content: "橘园十二舍",
  ),
  LocationPoint(
    id: 90643,
    latitude: 29.82564,
    longitude: 106.423353,
    content: "橘园十三舍",
  ),

  // 杏园
  LocationPoint(
    id: 90644,
    latitude: 29.82487,
    longitude: 106.42667,
    content: "杏园A栋",
  ),
  LocationPoint(
    id: 90645,
    latitude: 29.82471,
    longitude: 106.42673,
    content: "杏园B栋",
  ),
  LocationPoint(
    id: 90646,
    latitude: 29.82471,
    longitude: 106.42616,
    content: "杏园C栋",
  ),
  LocationPoint(
    id: 90647,
    latitude: 29.82444,
    longitude: 106.4263,
    content: "杏园D栋",
  ),
  LocationPoint(
    id: 90648,
    latitude: 29.824308,
    longitude: 106.426482,
    content: "杏园E栋",
  ),
  LocationPoint(
    id: 90649,
    latitude: 29.82414,
    longitude: 106.42543,
    content: "杏园F栋",
  ),
  LocationPoint(
    id: 90650,
    latitude: 29.82401,
    longitude: 106.42551,
    content: "杏园博士后公寓",
  ),

  // 梅园
  LocationPoint(
    id: 90651,
    latitude: 29.823968,
    longitude: 106.422735,
    content: "梅园一舍",
  ),
  LocationPoint(
    id: 90652,
    latitude: 29.823995,
    longitude: 106.42216,
    content: "梅园二舍",
  ),
  LocationPoint(
    id: 90653,
    latitude: 29.823776,
    longitude: 106.422229,
    content: "梅园三舍",
  ),
  LocationPoint(
    id: 90654,
    latitude: 29.823526,
    longitude: 106.42146,
    content: "梅园四舍",
  ),

  // 桃园
  LocationPoint(
    id: 90655,
    latitude: 29.827042,
    longitude: 106.427498,
    content: "桃园一舍",
  ),
  LocationPoint(
    id: 90656,
    latitude: 29.827348,
    longitude: 106.427196,
    content: "桃园二舍",
  ),
  LocationPoint(
    id: 90657,
    latitude: 29.82752,
    longitude: 106.427039,
    content: "桃园三舍",
  ),
  LocationPoint(
    id: 90658,
    latitude: 29.827498,
    longitude: 106.428048,
    content: "桃园四舍",
  ),
  LocationPoint(
    id: 90659,
    latitude: 29.827861,
    longitude: 106.428055,
    content: "桃园五舍",
  ),
  LocationPoint(
    id: 90660,
    latitude: 29.827866,
    longitude: 106.42836,
    content: "桃园六舍",
  ),
];

/// 校门位置
const List<LocationPoint> gateLocations = [
  LocationPoint(
    id: 90700,
    latitude: 29.821473,
    longitude: 106.428936,
    content: "一号门",
  ),
  LocationPoint(
    id: 90701,
    latitude: 29.81361,
    longitude: 106.4217,
    content: "二号门",
  ),
  LocationPoint(
    id: 90702,
    latitude: 29.818493,
    longitude: 106.425948,
    content: "三号门",
  ),
  LocationPoint(
    id: 90703,
    latitude: 29.828735,
    longitude: 106.43437,
    content: "五号门",
  ),
];

/// 图书馆位置
const List<LocationPoint> libraryLocations = [
  LocationPoint(
    id: 90400,
    latitude: 29.820694,
    longitude: 106.424463,
    content: "中心图书馆",
  ),
  LocationPoint(
    id: 90401,
    latitude: 29.824663,
    longitude: 106.430399,
    content: "弘文图书馆",
  ),
  LocationPoint(
    id: 90402,
    latitude: 29.813321,
    longitude: 106.419087,
    content: "崇实图书馆",
  ),
];

/// 运动场位置
const List<LocationPoint> sportsVenueLocations = [
  LocationPoint(
    id: 90300,
    latitude: 29.8225,
    longitude: 106.429886,
    content: "一运",
  ),
  LocationPoint(
    id: 90301,
    latitude: 29.825287,
    longitude: 106.428425,
    content: "二运",
  ),
  LocationPoint(
    id: 90302,
    latitude: 29.818285,
    longitude: 106.422911,
    content: "三运",
  ),
  LocationPoint(
    id: 90303,
    latitude: 29.816328,
    longitude: 106.421023,
    content: "四运",
  ),
];

/// 景点位置
const List<LocationPoint> scenicSpotLocations = [
  LocationPoint(
    id: 90200,
    latitude: 29.82214,
    longitude: 106.425045,
    content: "崇德湖",
  ),
  LocationPoint(
    id: 90201,
    latitude: 29.814329,
    longitude: 106.418601,
    content: "共青团花园",
  ),
];

/// 教室位置
const List<LocationPoint> classroomLocations = [
  LocationPoint(
    id: 90100,
    latitude: 29.82571,
    longitude: 106.42885,
    content: "1教文学院",
  ),
  LocationPoint(
    id: 90101,
    latitude: 29.822676,
    longitude: 106.421018,
    content: "2教化学化工学院药学院",
  ),
  LocationPoint(
    id: 90102,
    latitude: 29.82661,
    longitude: 106.42801,
    content: "3教国治院马克思主义学院",
  ),
  LocationPoint(
    id: 90103,
    latitude: 29.82289,
    longitude: 106.42673,
    content: "4教新传院",
  ),
  LocationPoint(
    id: 90104,
    latitude: 29.821401,
    longitude: 106.421189,
    content: "5教外院",
  ),
  LocationPoint(
    id: 90106,
    latitude: 29.82625,
    longitude: 106.429297,
    content: "9教历院",
  ),
  LocationPoint(
    id: 90107,
    latitude: 29.824437,
    longitude: 106.428815,
    content: "11教教育学部教师教育学院",
  ),
  LocationPoint(
    id: 90108,
    latitude: 29.823043,
    longitude: 106.425548,
    content: "13教物院",
  ),
  LocationPoint(
    id: 90109,
    latitude: 29.822278,
    longitude: 106.427322,
    content: "14教生科院",
  ),
  LocationPoint(
    id: 90110,
    latitude: 29.822252,
    longitude: 106.42984,
    content: "15教美院",
  ),
  LocationPoint(
    id: 90111,
    latitude: 29.820663,
    longitude: 106.427272,
    content: "19教音乐学院",
  ),
  LocationPoint(
    id: 90112,
    latitude: 29.819419,
    longitude: 106.422602,
    content: "21教材料与能源学院",
  ),
  LocationPoint(
    id: 90113,
    latitude: 29.82074,
    longitude: 106.42194,
    content: "23教心理学部",
  ),
  LocationPoint(
    id: 90114,
    latitude: 29.821756,
    longitude: 106.423194,
    content: "24教地科院",
  ),
  LocationPoint(
    id: 90115,
    latitude: 29.822521,
    longitude: 106.42414,
    content: "25教计信院",
  ),
  LocationPoint(
    id: 90116,
    latitude: 29.82292,
    longitude: 106.42176,
    content: "26教含弘学院",
  ),
  LocationPoint(
    id: 90117,
    latitude: 29.813442,
    longitude: 106.417943,
    content: "33教蚕桑院园艺园林学院",
  ),
  LocationPoint(
    id: 90118,
    latitude: 29.81229,
    longitude: 106.41798,
    content: "34教植保院",
  ),
  LocationPoint(
    id: 90119,
    latitude: 29.811579,
    longitude: 106.415938,
    content: "35教资环院",
  ),
  LocationPoint(
    id: 90120,
    latitude: 29.814252,
    longitude: 106.417564,
    content: "36教工院",
  ),
  LocationPoint(
    id: 90121,
    latitude: 29.81304,
    longitude: 106.41679,
    content: "37教农生院",
  ),
  LocationPoint(
    id: 90122,
    latitude: 29.81502,
    longitude: 106.41889,
    content: "38教法学院",
  ),
  LocationPoint(
    id: 90123,
    latitude: 29.811776,
    longitude: 106.416899,
    content: "40教食科院",
  ),
  LocationPoint(
    id: 90124,
    latitude: 29.811696,
    longitude: 106.413392,
    content: "46教经管院",
  ),
];

/// 所有位置信息的汇总
class CampusLocations {
  static const Map<String, List<LocationPoint>> allLocations = {
    '餐厅位置': restaurantLocations,
    '宿舍位置': dormitoryLocations,
    '北碚校门': gateLocations,
    '图书馆位置': libraryLocations,
    '运动场位置': sportsVenueLocations,
    '景点': scenicSpotLocations,
    '教室位置': classroomLocations,
  };

  /// 根据类型获取位置列表
  static List<LocationPoint> getLocationsByType(String type) {
    return allLocations[type] ?? [];
  }

  /// 获取所有位置类型
  static List<String> getAllLocationTypes() {
    return allLocations.keys.toList();
  }

  /// 获取所有位置点
  static List<LocationPoint> getAllLocationPoints() {
    return allLocations.values.expand((locations) => locations).toList();
  }

  /// 根据 ID 查找位置点
  static LocationPoint? findLocationById(int id) {
    for (final locations in allLocations.values) {
      for (final location in locations) {
        if (location.id == id) {
          return location;
        }
      }
    }
    return null;
  }

  /// 根据名称搜索位置点
  static List<LocationPoint> searchLocationsByName(String name) {
    final results = <LocationPoint>[];
    for (final locations in allLocations.values) {
      for (final location in locations) {
        if (location.content.contains(name)) {
          results.add(location);
        }
      }
    }
    return results;
  }
}
