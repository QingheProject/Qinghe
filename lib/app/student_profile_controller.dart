import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StudentProfileController extends GetxService {
  static const _key = 'student_profile_v1';
  static const _avatarKey = 'student_profile_avatar_v1';
  final _profile = const (school: '', nickname: '').obs;
  final _avatar = const (icon: 0, color: 0).obs;

  String get school => _profile.value.school;
  String get nickname => _profile.value.nickname;

  /// 头像图形索引，对应 `AppIcons.avatarChoices`。
  int get avatarIcon => _avatar.value.icon;

  /// 头像底色索引，对应课程色板。
  int get avatarColor => _avatar.value.color;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final fields = preferences.getStringList(_key);
    if (fields != null && fields.length == 2) {
      _profile.value = (school: fields[0], nickname: fields[1]);
    }
    final avatar = preferences.getStringList(_avatarKey);
    if (avatar != null && avatar.length == 2) {
      final icon = int.tryParse(avatar[0]);
      final color = int.tryParse(avatar[1]);
      if (icon != null && color != null && icon >= 0 && color >= 0) {
        _avatar.value = (icon: icon, color: color);
      }
    }
  }

  Future<void> save({required String school, required String nickname}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(_key, [school, nickname]);
    if (!saved) throw const FormatException('个人信息保存失败，请重试。');
    _profile.value = (school: school, nickname: nickname);
  }

  Future<void> saveAvatar({required int icon, required int color}) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setStringList(_avatarKey, [
      '$icon',
      '$color',
    ]);
    if (!saved) throw const FormatException('头像保存失败，请重试。');
    _avatar.value = (icon: icon, color: color);
  }
}
