import 'package:qinghe_app/data/sources/school_source.dart';

/// 西南科技大学：正方 ZFTAL「本科教学教务管理系统」。
///
/// 站点 `https://jwxt.swust.edu.cn` 会把未登录访问重定向到学校统一身份认证，
/// 因此应用只负责打开入口，登录与跳转都交给官方页面。
///
/// 课表取自学生课表页与移动端课表接口：接口参数 `kblx=1` 只返回所选周次，
/// 因此固定使用按学期查询。考试取自「学生考试信息」查询接口，与课表使用
/// 同一份学年与学期编码。
///
/// 桌面端只开放 Windows：Linux 没有可用的 WebView，保持 JSON 入口。
final swustSource = SchoolSource(
  school: '西南科技大学',
  initial: 'X',
  status: SchoolSourceStatus.verified,
  platforms: const {'android', 'windows'},
  entry: Uri.parse('https://jwxt.swust.edu.cn/'),
  timetablePagePath: '/kbcx/xskbcxZccx_cxXskbcxIndex.html',
  timetableDataPath: '/kbcx/xskbcxMobile_cxXsKb.html',
  timetablePageQuery: const {
    'gnmkdm': 'N2154',
    'layout': 'default',
    'hasHeader': 'true',
  },
  examDataPath: '/kwgl/kscx_cxXsksxxIndex.html',
  examDataQuery: const {'doType': 'query', 'gnmkdm': 'N358105'},
);
