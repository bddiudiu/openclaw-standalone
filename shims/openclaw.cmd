@echo off
setlocal
set "SCRIPT_DIR=%~dp0"
"%SCRIPT_DIR%node.exe" "%SCRIPT_DIR%node_modules\@qingchencloud\openclaw-zh\openclaw.mjs" %*
