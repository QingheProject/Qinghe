import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('资料与头像分别持久化，重新加载后保持', () async {
    SharedPreferences.setMockInitialValues({});
    final controller = StudentProfileController();
    await controller.load();

    expect(controller.school, isEmpty);
    expect(controller.nickname, isEmpty);
    expect(controller.avatarIcon, 0);
    expect(controller.avatarColor, 0);

    await controller.save(school: '示例大学', nickname: '小禾');
    await controller.saveAvatar(icon: 3, color: 4);

    final reloaded = StudentProfileController();
    await reloaded.load();
    expect(reloaded.school, '示例大学');
    expect(reloaded.nickname, '小禾');
    expect(reloaded.avatarIcon, 3);
    expect(reloaded.avatarColor, 4);
  });

  test('旧资料缺少头像字段时使用默认头像', () async {
    SharedPreferences.setMockInitialValues({
      'student_profile_v1': ['示例大学', '小禾'],
    });
    final controller = StudentProfileController();
    await controller.load();

    expect(controller.nickname, '小禾');
    expect(controller.avatarIcon, 0);
    expect(controller.avatarColor, 0);
  });
}
