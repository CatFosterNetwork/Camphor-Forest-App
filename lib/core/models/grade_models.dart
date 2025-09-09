// lib/core/models/grade_models.dart

/// 成绩详情模型
class GradeDetail {
  final String date;
  final String dateDigit;
  final String dateDigitSeparator;
  final String day;
  final String jgpxzd;
  final String jxbId;
  final String jxbmc;
  final String kch;
  final String kchId;
  final String kcmc;
  final String kkbmId;
  final String kkbmmc;
  final String listnav;
  final String localeKey;
  final String month;
  final int pageTotal;
  final bool pageable;
  final Map<String, dynamic> queryModel;
  final String queryTime;
  final bool rangeable;
  final String rowId;
  final String totalResult;
  final Map<String, dynamic> userModel;
  final String xf;
  final String xhId;
  final String xmblmc;
  final String xmcj;
  final String xnm;
  final String xnmmc;
  final String xqm;
  final String xqmmc;
  final String? ksxz;

  const GradeDetail({
    required this.date,
    required this.dateDigit,
    required this.dateDigitSeparator,
    required this.day,
    required this.jgpxzd,
    required this.jxbId,
    required this.jxbmc,
    required this.kch,
    required this.kchId,
    required this.kcmc,
    required this.kkbmId,
    required this.kkbmmc,
    required this.listnav,
    required this.localeKey,
    required this.month,
    required this.pageTotal,
    required this.pageable,
    required this.queryModel,
    required this.queryTime,
    required this.rangeable,
    required this.rowId,
    required this.totalResult,
    required this.userModel,
    required this.xf,
    required this.xhId,
    required this.xmblmc,
    required this.xmcj,
    required this.xnm,
    required this.xnmmc,
    required this.xqm,
    required this.xqmmc,
    this.ksxz,
  });

  factory GradeDetail.fromJson(Map<String, dynamic> json) {
    return GradeDetail(
      date: json['date']?.toString() ?? '',
      dateDigit: json['dateDigit']?.toString() ?? '',
      dateDigitSeparator: json['dateDigitSeparator']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      jgpxzd: json['jgpxzd']?.toString() ?? '',
      jxbId: json['jxb_id']?.toString() ?? '',
      jxbmc: json['jxbmc']?.toString() ?? '',
      kch: json['kch']?.toString() ?? '',
      kchId: json['kch_id']?.toString() ?? '',
      kcmc: json['kcmc']?.toString() ?? '',
      kkbmId: json['kkbm_id']?.toString() ?? '',
      kkbmmc: json['kkbmmc']?.toString() ?? '',
      listnav: json['listnav']?.toString() ?? '',
      localeKey: json['localeKey']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      pageTotal: int.tryParse(json['pageTotal']?.toString() ?? '0') ?? 0,
      pageable: json['pageable'] == true || json['pageable'] == 'true',
      queryModel: json['queryModel'] ?? {},
      queryTime: json['queryTime']?.toString() ?? '',
      rangeable: json['rangeable'] == true || json['rangeable'] == 'true',
      rowId: json['row_id']?.toString() ?? '',
      totalResult: json['totalResult']?.toString() ?? '',
      userModel: json['userModel'] ?? {},
      xf: json['xf']?.toString() ?? '',
      xhId: json['xh_id']?.toString() ?? '',
      xmblmc: json['xmblmc']?.toString() ?? '',
      xmcj: json['xmcj']?.toString() ?? '',
      xnm: json['xnm']?.toString() ?? '',
      xnmmc: json['xnmmc']?.toString() ?? '',
      xqm: json['xqm']?.toString() ?? '',
      xqmmc: json['xqmmc']?.toString() ?? '',
      ksxz: json['ksxz']?.toString(),
    );
  }
}

/// 成绩汇总模型
class GradeSummary {
  final String bfzcj;
  final String bh;
  final String bhId;
  final String bj;
  final String cj;
  final String cjsfzf;
  final String date;
  final String dateDigit;
  final String dateDigitSeparator;
  final String day;
  final String jd;
  final String jgId;
  final String jgmc;
  final String jgpxzd;
  final String jsxm;
  final String jxbId;
  final String jxbmc;
  final String kcbj;
  final String kch;
  final String kchId;
  final String kclbmc;
  final String kcmc;
  final String kcxzdm;
  final String kcxzmc;
  final String key;
  final String kkbmmc;
  final String kklxdm;
  final String ksxz;
  final String ksxzdm;
  final String listnav;
  final String localeKey;
  final String month;
  final String njdmId;
  final String njmc;
  final int pageTotal;
  final bool pageable;
  final Map<String, dynamic> queryModel;
  final String queryTime;
  final bool rangeable;
  final String rowId;
  final String rwzxs;
  final String sfdkbcx;
  final String sfkj;
  final String sfpk;
  final String sfxwkc;
  final String sfzh;
  final String sfzx;
  final String tjrxm;
  final String tjsj;
  final String totalResult;
  final Map<String, dynamic> userModel;
  final String xb;
  final String xbm;
  final String xf;
  final String xfjd;
  final String xh;
  final String xhId;
  final String xm;
  final String xnm;
  final String xnmmc;
  final String xqm;
  final String xqmmc;
  final String xsbjmc;
  final String xslb;
  final String xz;
  final String year;
  final String zsxymc;
  final String zxs;
  final String zyhId;
  final String zymc;

  /// 新增：成绩获取日期
  final String? fetchDate;

  const GradeSummary({
    required this.bfzcj,
    required this.bh,
    required this.bhId,
    required this.bj,
    required this.cj,
    required this.cjsfzf,
    required this.date,
    required this.dateDigit,
    required this.dateDigitSeparator,
    required this.day,
    required this.jd,
    required this.jgId,
    required this.jgmc,
    required this.jgpxzd,
    required this.jsxm,
    required this.jxbId,
    required this.jxbmc,
    required this.kcbj,
    required this.kch,
    required this.kchId,
    required this.kclbmc,
    required this.kcmc,
    required this.kcxzdm,
    required this.kcxzmc,
    required this.key,
    required this.kkbmmc,
    required this.kklxdm,
    required this.ksxz,
    required this.ksxzdm,
    required this.listnav,
    required this.localeKey,
    required this.month,
    required this.njdmId,
    required this.njmc,
    required this.pageTotal,
    required this.pageable,
    required this.queryModel,
    required this.queryTime,
    required this.rangeable,
    required this.rowId,
    required this.rwzxs,
    required this.sfdkbcx,
    required this.sfkj,
    required this.sfpk,
    required this.sfxwkc,
    required this.sfzh,
    required this.sfzx,
    required this.tjrxm,
    required this.tjsj,
    required this.totalResult,
    required this.userModel,
    required this.xb,
    required this.xbm,
    required this.xf,
    required this.xfjd,
    required this.xh,
    required this.xhId,
    required this.xm,
    required this.xnm,
    required this.xnmmc,
    required this.xqm,
    required this.xqmmc,
    required this.xsbjmc,
    required this.xslb,
    required this.xz,
    required this.year,
    required this.zsxymc,
    required this.zxs,
    required this.zyhId,
    required this.zymc,
    this.fetchDate,
  });

  factory GradeSummary.fromJson(Map<String, dynamic> json) {
    return GradeSummary(
      bfzcj: json['bfzcj']?.toString() ?? '',
      bh: json['bh']?.toString() ?? '',
      bhId: json['bh_id']?.toString() ?? '',
      bj: json['bj']?.toString() ?? '',
      cj: json['cj']?.toString() ?? '',
      cjsfzf: json['cjsfzf']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      dateDigit: json['dateDigit']?.toString() ?? '',
      dateDigitSeparator: json['dateDigitSeparator']?.toString() ?? '',
      day: json['day']?.toString() ?? '',
      jd: json['jd']?.toString() ?? '',
      jgId: json['jg_id']?.toString() ?? '',
      jgmc: json['jgmc']?.toString() ?? '',
      jgpxzd: json['jgpxzd']?.toString() ?? '',
      jsxm: json['jsxm']?.toString() ?? '',
      jxbId: json['jxb_id']?.toString() ?? '',
      jxbmc: json['jxbmc']?.toString() ?? '',
      kcbj: json['kcbj']?.toString() ?? '',
      kch: json['kch']?.toString() ?? '',
      kchId: json['kch_id']?.toString() ?? '',
      kclbmc: json['kclbmc']?.toString() ?? '',
      kcmc: json['kcmc']?.toString() ?? '',
      kcxzdm: json['kcxzdm']?.toString() ?? '',
      kcxzmc: json['kcxzmc']?.toString() ?? '',
      key: json['key']?.toString() ?? '',
      kkbmmc: json['kkbmmc']?.toString() ?? '',
      kklxdm: json['kklxdm']?.toString() ?? '',
      ksxz: json['ksxz']?.toString() ?? '',
      ksxzdm: json['ksxzdm']?.toString() ?? '',
      listnav: json['listnav']?.toString() ?? '',
      localeKey: json['localeKey']?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      njdmId: json['njdm_id']?.toString() ?? '',
      njmc: json['njmc']?.toString() ?? '',
      pageTotal: int.tryParse(json['pageTotal']?.toString() ?? '0') ?? 0,
      pageable: json['pageable'] == true || json['pageable'] == 'true',
      queryModel: json['queryModel'] ?? {},
      queryTime: json['queryTime']?.toString() ?? '',
      rangeable: json['rangeable'] == true || json['rangeable'] == 'true',
      rowId: json['row_id']?.toString() ?? '',
      rwzxs: json['rwzxs']?.toString() ?? '',
      sfdkbcx: json['sfdkbcx']?.toString() ?? '',
      sfkj: json['sfkj']?.toString() ?? '',
      sfpk: json['sfpk']?.toString() ?? '',
      sfxwkc: json['sfxwkc']?.toString() ?? '',
      sfzh: json['sfzh']?.toString() ?? '',
      sfzx: json['sfzx']?.toString() ?? '',
      tjrxm: json['tjrxm']?.toString() ?? '',
      tjsj: json['tjsj']?.toString() ?? '',
      totalResult: json['totalResult']?.toString() ?? '',
      userModel: json['userModel'] ?? {},
      xb: json['xb']?.toString() ?? '',
      xbm: json['xbm']?.toString() ?? '',
      xf: json['xf']?.toString() ?? '',
      xfjd: json['xfjd']?.toString() ?? '',
      xh: json['xh']?.toString() ?? '',
      xhId: json['xh_id']?.toString() ?? '',
      xm: json['xm']?.toString() ?? '',
      xnm: json['xnm']?.toString() ?? '',
      xnmmc: json['xnmmc']?.toString() ?? '',
      xqm: json['xqm']?.toString() ?? '',
      xqmmc: json['xqmmc']?.toString() ?? '',
      xsbjmc: json['xsbjmc']?.toString() ?? '',
      xslb: json['xslb']?.toString() ?? '',
      xz: json['xz']?.toString() ?? '',
      year: json['year']?.toString() ?? '',
      zsxymc: json['zsxymc']?.toString() ?? '',
      zxs: json['zxs']?.toString() ?? '',
      zyhId: json['zyh_id']?.toString() ?? '',
      zymc: json['zymc']?.toString() ?? '',
      fetchDate: json['fetchDate']?.toString(),
    );
  }

  /// 创建带有新获取日期的副本
  GradeSummary copyWith({String? fetchDate}) {
    return GradeSummary(
      bfzcj: bfzcj,
      bh: bh,
      bhId: bhId,
      bj: bj,
      cj: cj,
      cjsfzf: cjsfzf,
      date: date,
      dateDigit: dateDigit,
      dateDigitSeparator: dateDigitSeparator,
      day: day,
      jd: jd,
      jgId: jgId,
      jgmc: jgmc,
      jgpxzd: jgpxzd,
      jsxm: jsxm,
      jxbId: jxbId,
      jxbmc: jxbmc,
      kcbj: kcbj,
      kch: kch,
      kchId: kchId,
      kclbmc: kclbmc,
      kcmc: kcmc,
      kcxzdm: kcxzdm,
      kcxzmc: kcxzmc,
      key: key,
      kkbmmc: kkbmmc,
      kklxdm: kklxdm,
      ksxz: ksxz,
      ksxzdm: ksxzdm,
      listnav: listnav,
      localeKey: localeKey,
      month: month,
      njdmId: njdmId,
      njmc: njmc,
      pageTotal: pageTotal,
      pageable: pageable,
      queryModel: queryModel,
      queryTime: queryTime,
      rangeable: rangeable,
      rowId: rowId,
      rwzxs: rwzxs,
      sfdkbcx: sfdkbcx,
      sfkj: sfkj,
      sfpk: sfpk,
      sfxwkc: sfxwkc,
      sfzh: sfzh,
      sfzx: sfzx,
      tjrxm: tjrxm,
      tjsj: tjsj,
      totalResult: totalResult,
      userModel: userModel,
      xb: xb,
      xbm: xbm,
      xf: xf,
      xfjd: xfjd,
      xh: xh,
      xhId: xhId,
      xm: xm,
      xnm: xnm,
      xnmmc: xnmmc,
      xqm: xqm,
      xqmmc: xqmmc,
      xsbjmc: xsbjmc,
      xslb: xslb,
      xz: xz,
      year: year,
      zsxymc: zsxymc,
      zxs: zxs,
      zyhId: zyhId,
      zymc: zymc,
      fetchDate: fetchDate ?? this.fetchDate,
    );
  }
}

/// 计算的成绩信息
class CalculatedGrade {
  final String kcmc;
  final String kch;
  final String kchId;
  final String xf;
  final dynamic zcj; // 可能是数字或字符串（如"优"）
  final String jd;
  final String? teacher;
  final String? kcxzmc;
  final String? kclbmc;
  final String? ksxz;

  const CalculatedGrade({
    required this.kcmc,
    required this.kch,
    required this.kchId,
    required this.xf,
    required this.zcj,
    required this.jd,
    this.teacher,
    this.kcxzmc,
    this.kclbmc,
    this.ksxz,
  });
}

/// 学期信息
class SemesterInfo {
  final String xnm;
  final String xqm;
  final String displayName;

  const SemesterInfo({
    required this.xnm,
    required this.xqm,
    required this.displayName,
  });
}

/// 成绩统计信息
class GradeStatistics {
  final double compulsoryAverage;
  final double totalAverage;
  final double compulsoryGpa;
  final double totalGpa;
  final int totalCredits;
  final int compulsoryCredits;

  const GradeStatistics({
    required this.compulsoryAverage,
    required this.totalAverage,
    required this.compulsoryGpa,
    required this.totalGpa,
    required this.totalCredits,
    required this.compulsoryCredits,
  });
}

/// 成绩排序方式
enum GradeSortBy {
  course, // 按课程名称
  credit, // 按学分
  score, // 按成绩
  gpa, // 按绩点
}

/// 成绩单类型
class TranscriptType {
  final String name;
  final String fileProperty;

  const TranscriptType({required this.name, required this.fileProperty});
}

/// 电子凭证类型
class VoucherType {
  final String name;
  final String fileProperty;

  const VoucherType({required this.name, required this.fileProperty});
}

/// 成绩发送选项
class GradeSendOptions {
  final String email;
  final TranscriptType? transcriptType;
  final VoucherType? voucherType;
  final String? jdType; // 绩点类型：0-不显示，1-全科平均绩点，2-授予学位学科平均绩点
  final String? pmType; // 排名类型：0-不显示，1-所有必修课排名，2-授予学位学科排名
  final String? pjfType; // 平均分类型：0-不显示，1-所有必修课正考成绩加权平均分，2-授予学位学科成绩加权平均分

  const GradeSendOptions({
    required this.email,
    this.transcriptType,
    this.voucherType,
    this.jdType,
    this.pmType,
    this.pjfType,
  });
}
