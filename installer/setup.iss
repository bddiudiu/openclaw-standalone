; OpenClaw Standalone Installer - Inno Setup Script
; Produces a professional guided .exe installer for Windows
; Compile: ISCC.exe /DAppVersion=x.y.z /DSourceDir=...\build\win-x64 /DOutputDir=...\output setup.iss

#ifndef AppVersion
  #define AppVersion "0.0.0"
#endif

#ifndef SourceDir
  #define SourceDir "..\build\win-x64"
#endif

#ifndef OutputDir
  #define OutputDir "..\output"
#endif

[Setup]
AppId={{A7E3F2B1-9C4D-4E5F-B6A8-1D2E3F4A5B6C}
AppName=OpenClaw
AppVersion={#AppVersion}
AppVerName=OpenClaw {#AppVersion}
AppPublisher=晴辰云 (QingChenCloud)
AppPublisherURL=https://github.com/qingchencloud/openclaw-standalone
AppSupportURL=https://github.com/qingchencloud/openclaw-standalone/issues
AppUpdatesURL=https://github.com/qingchencloud/openclaw-standalone/releases
DefaultDirName={autopf}\OpenClaw
DefaultGroupName=OpenClaw
AllowNoIcons=yes
LicenseFile=..\LICENSE
OutputDir={#OutputDir}
OutputBaseFilename=openclaw-{#AppVersion}-win-x64-setup
SetupIconFile=..\assets\openclaw.ico
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
ChangesEnvironment=yes
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\openclaw.cmd
VersionInfoVersion={#AppVersion}
VersionInfoCompany=QingChenCloud
VersionInfoDescription=OpenClaw - AI 智能体引擎
VersionInfoProductName=OpenClaw
MinVersion=10.0

[Languages]
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
chinesesimplified.BeveledLabel=晴辰云 · OpenClaw 安装向导
english.BeveledLabel=QingChenCloud · OpenClaw Setup

[CustomMessages]
chinesesimplified.AddToPath=将 OpenClaw 添加到系统 PATH 环境变量（推荐）
chinesesimplified.CreateDesktopShortcut=创建桌面快捷方式
chinesesimplified.FinishMessage=OpenClaw 已安装完成！%n%n打开终端（PowerShell / CMD）输入 openclaw 即可使用。%n%n如需图形化管理面板，请安装 ClawPanel：%nhttps://github.com/qingchencloud/clawpanel
english.AddToPath=Add OpenClaw to system PATH (recommended)
english.CreateDesktopShortcut=Create desktop shortcut
english.FinishMessage=OpenClaw has been installed!%n%nOpen a terminal (PowerShell / CMD) and type openclaw to get started.%n%nFor a GUI management panel, install ClawPanel:%nhttps://github.com/qingchencloud/clawpanel

[Tasks]
Name: "addtopath"; Description: "{cm:AddToPath}"; GroupDescription: "环境配置:"; Flags: checkedonce

[Files]
Source: "{#SourceDir}\node.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\openclaw.cmd"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\VERSION"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#SourceDir}\node_modules\*"; DestDir: "{app}\node_modules"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\OpenClaw 终端"; Filename: "{cmd}"; Parameters: "/k ""{app}\openclaw.cmd"""; WorkingDir: "{userdocs}"; Comment: "打开 OpenClaw 终端"
Name: "{group}\卸载 OpenClaw"; Filename: "{uninstallexe}"

[Run]
Filename: "{cmd}"; Parameters: "/k echo OpenClaw {#AppVersion} 安装成功！输入 openclaw 开始使用。&& ""{app}\openclaw.cmd"" --version"; Description: "打开终端验证安装"; Flags: nowait postinstall skipifsilent unchecked

[UninstallDelete]
Type: filesandordirs; Name: "{app}\node_modules"
Type: files; Name: "{app}\node.exe"
Type: files; Name: "{app}\openclaw.cmd"
Type: files; Name: "{app}\VERSION"

[Code]
// Add/remove install directory from user PATH
procedure AddToUserPath(Dir: string);
var
  OldPath: string;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER,
    'Environment', 'Path', OldPath) then
    OldPath := '';
  if Pos(Uppercase(Dir), Uppercase(OldPath)) = 0 then
  begin
    if OldPath <> '' then
      OldPath := OldPath + ';';
    OldPath := OldPath + Dir;
    RegWriteStringValue(HKEY_CURRENT_USER,
      'Environment', 'Path', OldPath);
  end;
end;

procedure RemoveFromUserPath(Dir: string);
var
  OldPath, NewPath, Item: string;
  I: Integer;
begin
  if not RegQueryStringValue(HKEY_CURRENT_USER,
    'Environment', 'Path', OldPath) then
    Exit;
  NewPath := '';
  while Length(OldPath) > 0 do
  begin
    I := Pos(';', OldPath);
    if I = 0 then
    begin
      Item := OldPath;
      OldPath := '';
    end else begin
      Item := Copy(OldPath, 1, I - 1);
      OldPath := Copy(OldPath, I + 1, Length(OldPath));
    end;
    Item := Trim(Item);
    if (Length(Item) > 0) and (CompareText(Item, Dir) <> 0) then
    begin
      if NewPath <> '' then
        NewPath := NewPath + ';';
      NewPath := NewPath + Item;
    end;
  end;
  RegWriteStringValue(HKEY_CURRENT_USER,
    'Environment', 'Path', NewPath);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    if IsTaskSelected('addtopath') then
      AddToUserPath(ExpandConstant('{app}'));
  end;
end;

procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then
    RemoveFromUserPath(ExpandConstant('{app}'));
end;

// Notify Windows about PATH change
procedure BroadcastEnvironmentChange;
var
  Dummy: Longint;
begin
  // SendMessage(HWND_BROADCAST, WM_SETTINGCHANGE, 0, 'Environment')
  // Inno Setup doesn't have direct access, but the PATH change takes effect on next terminal open
end;
