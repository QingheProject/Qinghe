# 仓库贡献指南

## 项目状态与功能范围

QingheApp 是计划基于 Flutter + GetX 开发的大学课表应用，面向 Windows、Linux 和安卓。目前目录中尚无应用工程或 Git 历史；以下目录结构与命令适用于后续工程初始化。

## 项目结构与模块组织

- `lib/main.dart`：应用入口。
- `lib/features/`：功能页面、GetX 控制器及依赖绑定。
- `lib/data/`：数据模型、数据仓库和本地持久化。
- `lib/services/`：通知、小组件和桌面端集成。
- `test/`：测试代码，目录结构与源代码对应。
- `assets/`：随应用打包的资源，需在 `pubspec.yaml` 中声明。

持久化和导入解析逻辑应独立于界面组件及控制器。

## 构建、测试与开发命令

创建 `pubspec.yaml` 后，在项目根目录执行：

- `flutter pub get`：安装依赖。
- `dart format lib test`：格式化 Dart 源代码。
- `flutter analyze`：执行静态分析。
- `flutter test`：运行自动化测试。
- `flutter devices`：列出可用设备。
- `flutter run -d <设备标识>`：在指定设备上启动应用。
- `flutter build windows`、`flutter build linux` 或 `flutter build apk`：构建对应平台的产物；桌面端构建需在对应操作系统上执行。

## 代码风格与命名规范

使用 Dart 格式化工具，采用两空格缩进。文件使用 `snake_case.dart`，类型使用 `UpperCamelCase`，成员使用 `lowerCamelCase`。命名应表达实际含义，控制器职责应集中。配置静态分析规则后，遵循项目规则。修改仅限任务所需，避免投机性抽象和无关清理。

## 测试规范

使用 `flutter_test` 编写单元测试和组件测试，文件命名为 `*_test.dart`。优先验证教学周计算、单次调课、CSV 校验和导入冲突处理。目前未设定覆盖率门槛。涉及平台集成时，记录受影响平台的手动验证结果，并明确尚未测试的平台。

## 提交与合并请求规范

提交应按功能的开发时间与依赖顺序组织，每个提交只包含一个可说明的改动。提交信息必须保持单行，并使用 `type(scope): subject` 格式，例如 `feat(schedule): add weekly timetable view`。常用类型包括 `feat`、`fix`、`docs`、`test`、`refactor`、`build` 和 `chore`；`scope` 使用实际模块或功能名称，`subject` 简洁描述行为变化。

执行每个提交前，必须先向用户列出该提交包含的全部文件及拟用的一行提交信息，并询问是否合适；只有获得确认后才能提交。合并请求应说明行为变化、关联相关问题并报告验证结果；界面或动画变更需附截图或录屏。

## 安全与隐私

源码、日志、测试样例和文档中不得包含凭证、令牌、个人信息或机器专属路径。示例使用占位符或虚构数据。发现疑似敏感信息时，停止相关操作并提示用户，不得复制或传播。
