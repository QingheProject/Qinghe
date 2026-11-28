import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_page.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/brand_mark.dart';

const _repository = 'https://github.com/QingheProject/Qinghe';
const _author = 'TeAnli';
// 发布构建通过 --dart-define 提供公开的作者 QQ。
const _authorQq = String.fromEnvironment('QINGHE_AUTHOR_QQ');

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  static const _copyFeedback = MethodChannel(
    'dev.qinghe.qinghe_app/clipboard_feedback',
  );
  late final _packageInfo = PackageInfo.fromPlatform();

  Future<void> _copy(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _copyFeedback.invokeMethod<void>('showAfterCopy', message);
    } else {
      showAppToast(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('关于青禾')),
      body: SafeArea(
        top: false,
        child: AppPageContent(
          child: ListView(
            padding: AppPageContent.padding,
            children: [
              AppPanel(
                child: Column(
                  children: [
                    const BrandMark(size: 64),
                    const SizedBox(height: AppSpace.sm),
                    Text('青禾', style: text.headlineSmall),
                    Text('离线大学课表', style: text.bodySmall),
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppListGroup(
                children: [
                  FutureBuilder<PackageInfo>(
                    future: _packageInfo,
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '';
                      final build = snapshot.data?.buildNumber ?? '';
                      return AppListRow(
                        icon: AppIcons.info,
                        title: '应用版本',
                        subtitle: version.isEmpty
                            ? (snapshot.connectionState == ConnectionState.done
                                  ? '无法读取版本'
                                  : '正在读取版本')
                            : build.isEmpty
                            ? version
                            : '$version（构建 $build）',
                        trailing: const SizedBox.shrink(),
                      );
                    },
                  ),
                  AppListRow(
                    icon: AppIcons.code,
                    title: 'GitHub 仓库',
                    subtitle: 'QingheProject/Qinghe',
                    onTap: () => _copy(_repository, '已复制 GitHub 仓库链接'),
                    trailing: const Icon(AppIcons.copy, size: 18),
                  ),
                  const AppListRow(
                    icon: AppIcons.user,
                    title: '作者',
                    subtitle: _author,
                    trailing: SizedBox.shrink(),
                  ),
                  AppListRow(
                    icon: AppIcons.user,
                    title: '作者 QQ',
                    subtitle: _authorQq.isEmpty ? '未公开' : _authorQq,
                    onTap: _authorQq.isEmpty
                        ? null
                        : () => _copy(_authorQq, '已复制作者 QQ'),
                    trailing: _authorQq.isEmpty
                        ? const SizedBox.shrink()
                        : const Icon(AppIcons.copy, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
