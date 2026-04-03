@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%node_modules\@qingchencloud\openclaw-zh\openclaw.mjs" (
    "%SCRIPT_DIR%node.exe" "%SCRIPT_DIR%node_modules\@qingchencloud\openclaw-zh\openclaw.mjs" %*
) else if exist "%SCRIPT_DIR%node_modules\openclaw\openclaw.mjs" (
    "%SCRIPT_DIR%node.exe" "%SCRIPT_DIR%node_modules\openclaw\openclaw.mjs" %*
) else (
    echo [ERROR] OpenClaw not found. Please reinstall.
    exit /b 1
)
