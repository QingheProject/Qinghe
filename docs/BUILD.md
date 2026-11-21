# 构建说明

## 环境基线

- Flutter stable，推荐使用原生支持 Visual Studio 2026 的 3.38.2 或更高版本。
- Visual Studio 2026，安装“使用 C++ 的桌面开发”工作负载及 Windows SDK。
- Android 构建需要 Android SDK、JDK 17，并接受所需 SDK 许可证。
- Linux 产物必须在 Linux 环境中构建。

运行以下命令检查工具链：

```powershell
flutter doctor -v
```

## Windows

仓库脚本会优先使用当前 Flutter 的原生 VS2026 支持。若检测到旧版 Flutter，它会在本次构建期间临时加入官方的 VS2026 CMake 生成器映射，构建结束后恢复 SDK 文件和工具快照，不修改全局 Git 配置。

```powershell
# 发布构建（默认）
.\tool\build_windows.ps1

# 调试构建
.\tool\build_windows.ps1 -Mode debug

# 性能分析构建
.\tool\build_windows.ps1 -Mode profile
```

产物位于 `build/windows/x64/runner/<模式>/`。脚本失败时返回非零退出码，可直接用于持续集成。

## Android

```powershell
flutter build apk --release
```

首次构建前若 `flutter doctor -v` 提示许可证未接受，执行 `flutter doctor --android-licenses` 并由开发者阅读、确认相应协议。

## Linux

在安装 Flutter Linux 桌面依赖的 Linux 主机上执行：

```bash
flutter build linux --release
```

## 构建前检查

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```
