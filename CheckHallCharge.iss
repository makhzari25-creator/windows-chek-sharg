; ============================================================
;  Inno Setup Script - چک شارژ سالن
;  App name: چک شارژ سالن (Check Hall Charge)
;  Output:   installer_output\CheckHallCharge-Setup.exe
;
;  نحوه استفاده:
;    این فایل را با ISCC.exe (Inno Setup Compiler) کامپایل کنید:
;      "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" CheckHallCharge.iss
;
;  یا به‌صورت خودکار با build_installer.bat اجرا می‌شود.
;
;  این فایل را با انکودینگ UTF-8 ذخیره کنید (در همین حالت است).
; ============================================================

#define MyAppName        "چک شارژ سالن"
#define MyAppNameEn      "Check Hall Charge"
#define MyAppVersion     "1.0.0"
#define MyAppPublisher   "CheckHallCharge"
#define MyAppExeName     "check_hall_charge.exe"
#define MyAppSourceDir   "win_project\build\windows\x64\runner\Release"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
AppId={{B7F2C4A9-3D14-4E1F-9B6A-2C8E5D1F7A3B}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL=https://example.local/
AppSupportURL=https://example.local/
AppUpdatesURL=https://example.local/
DefaultDirName={autopf}\{#MyAppNameEn}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
AllowNoIcons=yes
OutputDir=installer_output
OutputBaseFilename=CheckHallCharge-Setup
SetupIconFile=
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
ArchitecturesInstallIn64BitMode=x64compatible
ArchitecturesAllowed=x64compatible
PrivilegesRequired=admin
RightToLeft=yes
ShowLanguageDialog=no
LanguageDetectionMethod=none
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName}
DisableWelcomePage=no
DisableDirPage=no
DisableReadyPage=no
DisableFinishedPage=no
; برنامه کاملاً آفلاین است - هیچ کامپوننت آنلاینی لازم نیست
CloseApplications=force
RestartIfNeededByRun=no

[Languages]
Name: "fa"; MessagesFile: "compiler:Languages\Persian.isl"

[Tasks]
Name: "desktopicon"; Description: "ایجاد شورتکات روی &دسکتاپ"; GroupDescription: "گروه شورتکات‌های اضافی:"; Flags: checkedonce

[Files]
; تمام فایل‌های پوشه‌ی Release شامل exe، DLLها و پوشه‌ی data را کپی می‌کند
Source: "{#MyAppSourceDir}\*"; DestDir: "{app}"; Flags: recursesubdirs createallsubdirs ignoreversion uninsneveruninstall

[Icons]
; شورتکات در Start Menu
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\{#MyAppExeName}"
; شورتکات Uninstall در Start Menu
Name: "{group}\حذف {#MyAppName}"; Filename: "{uninstallexe}"
; شورتکات دسکتاپ (اختیاری)
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\{#MyAppExeName}"

[Run]
; اجرای برنامه بعد از نصب (اختیاری)
Filename: "{app}\{#MyAppExeName}"; Description: "اجرا کردن {#MyAppName}"; Flags: nowait postinstall skipifsilent

[UninstallDelete]
; پاک کردن فایل‌های runtime ساخته‌شده (در صورت وجود)
Type: filesandordirs; Name: "{app}\data"
Type: filesandordirs; Name: "{localappdata}\{#MyAppNameEn}"

[Code]
function InitializeSetup(): Boolean;
begin
  Result := True;
end;
