@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

:: OpenClaw 一键安装脚本 (Windows)
:: Usage: 直接双击运行，或在 PowerShell 中执行:
::   irm https://plugins.coocare.com/openclaw/install.cmd | cmd

echo.
echo ╔══════════════════════════════════════╗
echo ║     OpenClaw 一键安装 by Coocare     ║
echo ╚══════════════════════════════════════╝
echo.

set "INSTALL_DIR=%LOCALAPPDATA%\OpenClaw"
set "DOWNLOAD_BASE=https://plugins.coocare.com/openclaw-standalone"
set "PLATFORM=win-x64"

:: --- Get latest version ---
echo [INFO] 获取最新版本...
for /f "delims=" %%v in ('powershell -NoProfile -Command "(Invoke-RestMethod -Uri '%DOWNLOAD_BASE%/latest.json' -TimeoutSec 5).version" 2^>nul') do set "VERSION=%%v"

if "%VERSION%"=="" (
    echo [WARN] 主下载源获取失败，尝试 GitHub...
    for /f "delims=" %%v in ('powershell -NoProfile -Command "(Invoke-RestMethod -Uri 'https://api.github.com/repos/bddiudiu/openclaw-standalone/releases/latest' -TimeoutSec 10).tag_name -replace 'v',''" 2^>nul') do set "VERSION=%%v"
)

if "%VERSION%"=="" (
    echo [ERROR] 无法获取最新版本号。请检查网络连接。
    echo         或手动下载: https://github.com/bddiudiu/openclaw-standalone/releases
    pause
    exit /b 1
)

echo [INFO] 最新版本: %VERSION%

:: --- Download ---
set "ARCHIVE=openclaw-%VERSION%-win-x64.zip"
set "DOWNLOAD_URL=%DOWNLOAD_BASE%/%VERSION%/%ARCHIVE%"
set "TMP_FILE=%TEMP%\%ARCHIVE%"

echo [INFO] 下载安装包...
powershell -NoProfile -Command "try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '%DOWNLOAD_URL%' -OutFile '%TMP_FILE%' -UseBasicParsing } catch { exit 1 }"

if errorlevel 1 (
    echo [WARN] 主下载源下载失败，尝试 GitHub...
    set "DOWNLOAD_URL=https://github.com/bddiudiu/openclaw-standalone/releases/download/v%VERSION%/%ARCHIVE%"
    powershell -NoProfile -Command "try { $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri '!DOWNLOAD_URL!' -OutFile '%TMP_FILE%' -UseBasicParsing } catch { exit 1 }"
)

if errorlevel 1 (
    echo [ERROR] 下载失败。请检查网络连接。
    pause
    exit /b 1
)

echo [OK] 下载完成

:: --- Extract ---
echo [INFO] 解压到 %INSTALL_DIR% ...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
mkdir "%INSTALL_DIR%" 2>nul

powershell -NoProfile -Command "Expand-Archive -Path '%TMP_FILE%' -DestinationPath '%INSTALL_DIR%' -Force"

:: Handle nested 'openclaw' directory from archive
if exist "%INSTALL_DIR%\openclaw\node.exe" (
    powershell -NoProfile -Command "Get-ChildItem '%INSTALL_DIR%\openclaw\*' | Move-Item -Destination '%INSTALL_DIR%' -Force"
    rmdir /s /q "%INSTALL_DIR%\openclaw" 2>nul
)

del "%TMP_FILE%" 2>nul
echo [OK] 解压完成

:: --- Verify ---
if not exist "%INSTALL_DIR%\openclaw.cmd" (
    echo [ERROR] 解压后未找到 openclaw.cmd
    pause
    exit /b 1
)

:: --- Add to PATH ---
echo [INFO] 配置环境变量...
powershell -NoProfile -Command ^
    "$userPath = [Environment]::GetEnvironmentVariable('Path', 'User'); " ^
    "if ($userPath -notlike '*%INSTALL_DIR%*') { " ^
    "  [Environment]::SetEnvironmentVariable('Path', $userPath + ';%INSTALL_DIR%', 'User'); " ^
    "  Write-Host '[OK] 已添加到 PATH' " ^
    "} else { " ^
    "  Write-Host '[INFO] PATH 已包含安装目录' " ^
    "}"

:: Add to current session PATH too
set "PATH=%INSTALL_DIR%;%PATH%"

:: --- Verify version ---
echo.
"%INSTALL_DIR%\openclaw.cmd" --version 2>nul

:: --- Done ---
echo.
echo ╔══════════════════════════════════════╗
echo ║       ✅ OpenClaw 安装成功！         ║
echo ╚══════════════════════════════════════╝
echo.
echo   安装目录: %INSTALL_DIR%
echo.
echo   请重新打开终端（PowerShell / CMD）使 PATH 生效，然后：
echo     openclaw --help        # 查看帮助
echo     openclaw setup         # 初始化配置
echo     openclaw gateway       # 启动 Gateway
echo.
echo   图形管理面板: https://github.com/bddiudiu/clawpanel
echo.
pause
