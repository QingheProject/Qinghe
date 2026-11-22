import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileController extends GetxService {
  static const _key = 'student_profile_v1';
  final _profile = const (school: '', nickname: '').obs;

  String get school => _profile.value.school;
  String get nickname => _profile.value.nickname;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final fields = preferences.getStringList(_key);
    if (fields != null && fields.length == 2) {
      _profile.value = (school: fields[0], nickname: fields[1]);
    }
  }

  Future<void> save({required String school, required String nickname}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(_key, [school, nickname]);
    if (!saved) throw const FormatException('个人信息保存失败，请重试。');
    _profile.value = (school: school, nickname: nickname);
  }
}
