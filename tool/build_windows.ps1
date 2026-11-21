[CmdletBinding()]
param(
    [ValidateSet('debug', 'profile', 'release')]
    [string]$Mode = 'release'
)

$ErrorActionPreference = 'Stop'

$flutterCommand = (Get-Command flutter.bat -ErrorAction Stop).Source
$flutterRoot = Split-Path (Split-Path $flutterCommand -Parent) -Parent
$visualStudioSource = Join-Path $flutterRoot 'packages\flutter_tools\lib\src\windows\visual_studio.dart'
$backupPath = "$visualStudioSource.qinghe-backup"
$utf8WithoutBom = [System.Text.UTF8Encoding]::new($false)
$originalToolArguments = $env:FLUTTER_TOOL_ARGS
$patchedLegacySdk = $false
$originalSource = $null

if (-not (Test-Path -LiteralPath $visualStudioSource)) {
    throw '无法定位 Flutter Windows 工具源码。'
}

if (Test-Path -LiteralPath $backupPath) {
    Copy-Item -LiteralPath $backupPath -Destination $visualStudioSource -Force
    Remove-Item -LiteralPath $backupPath -Force
    Write-Warning '已恢复上次中断构建留下的 Flutter SDK 备份。'
}

$source = [System.IO.File]::ReadAllText($visualStudioSource)

if ($source -notmatch "18\s*=>\s*'Visual Studio 18 2026'") {
    $generator2022 = "      17 => 'Visual Studio 17 2022',"
    $generator2026 = "      18 => 'Visual Studio 18 2026',"
    $patchedSource = $source.Replace(
        $generator2022,
        "$generator2026$([Environment]::NewLine)$generator2022"
    )

    if ($patchedSource -eq $source) {
        throw '当前 Flutter SDK 不支持 VS2026，且兼容补丁无法安全应用。请升级 Flutter stable。'
    }

    $originalSource = $source
    [System.IO.File]::WriteAllText($backupPath, $originalSource, $utf8WithoutBom)
    [System.IO.File]::WriteAllText($visualStudioSource, $patchedSource, $utf8WithoutBom)
    $env:FLUTTER_TOOL_ARGS = '--enable-asserts'
    $patchedLegacySdk = $true
    Write-Host '当前 Flutter 较旧，已临时启用官方 VS2026 生成器映射。'
}

$projectRoot = [System.IO.Path]::GetFullPath((Get-Location).Path)
$windowsBuildDirectory = [System.IO.Path]::GetFullPath(
    (Join-Path $projectRoot 'build\windows')
)
$cmakeCache = Get-ChildItem -LiteralPath $windowsBuildDirectory `
    -Filter 'CMakeCache.txt' -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($cmakeCache) {
    $cachedGenerator = Select-String -LiteralPath $cmakeCache.FullName `
        -Pattern '^CMAKE_GENERATOR:INTERNAL=(.+)$' |
        Select-Object -First 1

    if ($cachedGenerator -and $cachedGenerator.Matches[0].Groups[1].Value -ne 'Visual Studio 18 2026') {
        $expectedPrefix = $projectRoot.TrimEnd('\') + '\'
        if (-not $windowsBuildDirectory.StartsWith($expectedPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw 'Windows 构建目录不在项目目录内，拒绝清理。'
        }

        Write-Host '检测到其他 Visual Studio 生成器的缓存，正在清理 build/windows。'
        Remove-Item -LiteralPath $windowsBuildDirectory -Recurse -Force
    }
}

try {
    & $flutterCommand build windows "--$Mode"
    if ($LASTEXITCODE -ne 0) {
        throw "Windows $Mode 构建失败，退出码：$LASTEXITCODE"
    }
}
finally {
    if ($patchedLegacySdk) {
        if (Test-Path -LiteralPath $backupPath) {
            Copy-Item -LiteralPath $backupPath -Destination $visualStudioSource -Force
            Remove-Item -LiteralPath $backupPath -Force
        }
        else {
            [System.IO.File]::WriteAllText($visualStudioSource, $originalSource, $utf8WithoutBom)
        }

        if ($null -eq $originalToolArguments) {
            Remove-Item Env:FLUTTER_TOOL_ARGS -ErrorAction SilentlyContinue
        }
        else {
            $env:FLUTTER_TOOL_ARGS = $originalToolArguments
        }

        & $flutterCommand --version | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Write-Warning 'Flutter SDK 源码已恢复，但工具快照未能自动刷新。'
        }
    }
}
