# QingheApp

[![CI](https://github.com/QingheProject/Qinghe/actions/workflows/ci.yml/badge.svg)](https://github.com/QingheProject/Qinghe/actions/workflows/ci.yml)

青禾是基于 Flutter + GetX 的离线大学课表应用，目标平台为 Android、Windows 和 Linux。当前仓库处于基础工程阶段，包含自有扁平视觉体系与基础组件（`lib/app/theme`、`lib/app/widgets`）、加载页、开始使用引导、基于示例数据的首页，以及响应式导航壳；课表与我的页面仍为占位。

## 开发命令

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run -d <设备标识>
```

产品范围见 `docs/PROJECT.md`，业务与技术设计见 `docs/DESIGN.md`。具体视觉风格由用户另行设计。

三端构建环境与 Windows VS2026 脚本见 `docs/BUILD.md`。

## 持续集成

`.github/workflows/ci.yml` 在推送到 `main` 和提交 PR 时运行：

- **格式、静态分析与测试**：`dart format --set-exit-if-changed`、`flutter analyze`、`flutter test`。
- **构建 Android 安装包**：仅 `main` 分支通过上述检查后触发，产出 `app-release.apk` 并作为构建产物保留 14 天。

CI 固定 Flutter `3.35.3`（stable），与本地开发版本一致；升级时同步修改 workflow 里的 `FLUTTER_VERSION`。
