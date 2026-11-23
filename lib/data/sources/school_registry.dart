import 'package:qinghe_app/data/sources/school_source.dart';
import 'package:qinghe_app/data/sources/swust_source.dart';

/// 已适配学校的登记表。未登记的学校不提供教务导入。
abstract final class SchoolRegistry {
  static final List<SchoolSource> sources = [swustSource];

  static SchoolSource? forSchool(String school) {
    final name = school.trim();
    if (name.isEmpty) return null;
    for (final source in sources) {
      if (source.school == name) return source;
    }
    return null;
  }

  /// 当前平台、当前学校是否可以使用教务导入。
  static bool isAvailable(String school) =>
      forSchool(school)?.isAvailable ?? false;
}
