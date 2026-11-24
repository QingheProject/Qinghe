import 'dart:io';

/// 教务导入来源的适配状态：只有验证通过的来源才开放入口。
enum SchoolSourceStatus { verified, pending }

/// 一所学校教务系统的取数入口。
///
/// 只描述「去哪里取数」，不包含登录方式与解析规则：登录始终由学校官方页面
/// 完成，解析由 `jwxt` 解析层负责，两者都不需要知道彼此的实现。
class SchoolSource {
  const SchoolSource({
    required this.school,
    required this.initial,
    required this.status,
    required this.platforms,
    required this.entry,
    required this.timetablePagePath,
    required this.timetableDataPath,
    this.timetablePageQuery = const {},
    this.examDataPath = '',
    this.examDataQuery = const {},
  });

  final String school;

  /// 学校名称首字母，用于学校列表的分组与右侧索引。
  final String initial;
  final SchoolSourceStatus status;

  /// 已验证可用的平台，取值与 [Platform.operatingSystem] 一致。
  final Set<String> platforms;

  /// 应用内打开这个地址，由学校页面自行完成登录与跳转。
  final Uri entry;

  /// 学生课表页，用于读取可选的学年与学期。
  final String timetablePagePath;

  /// 课表数据接口，按学年与学期返回课表。
  final String timetableDataPath;

  final Map<String, String> timetablePageQuery;

  /// 考试查询接口；为空表示该校暂不提供考试导入。
  final String examDataPath;

  /// 考试查询接口需要的固定参数。
  final Map<String, String> examDataQuery;

  bool get isVerified => status == SchoolSourceStatus.verified;

  bool get hasExams => examDataPath.isNotEmpty;

  bool get runsOnThisPlatform => platforms.contains(Platform.operatingSystem);

  /// 入口是否可以真正使用：既已验证，也在当前平台开放过。
  bool get isAvailable => isVerified && runsOnThisPlatform;

  /// 地址是否已经离开登录流程，可以开始读取课表。
  bool isSignedIn(Uri uri) =>
      uri.host == entry.host &&
      !uri.path.startsWith('/xtgl/login') &&
      !uri.path.startsWith('/sso/');
}
