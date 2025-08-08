/// 每节课对应的开始与结束时间
class Period {
  final String begin;
  final String end;
  const Period(this.begin, this.end);
}

class PeriodTimes {
  static const Map<int, Period> times = {
    1: Period('08:00', '08:45'),
    2: Period('08:55', '09:40'),
    3: Period('10:00', '10:45'),
    4: Period('10:55', '11:40'),
    5: Period('12:10', '12:55'),
    6: Period('13:05', '13:50'),
    7: Period('14:00', '14:45'),
    8: Period('14:55', '15:40'),
    9: Period('15:50', '16:35'),
    10: Period('16:55', '17:40'),
    11: Period('17:50', '18:35'),
    12: Period('19:20', '20:05'),
    13: Period('20:15', '21:00'),
    14: Period('21:10', '21:55'),
  };
}
