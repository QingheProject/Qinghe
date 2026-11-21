import 'package:flutter/widgets.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/services/desktop_window.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DesktopWindow.initialize();
  runApp(const QingheApp());
}
