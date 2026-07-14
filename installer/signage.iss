; Inno Setup script — Digital Signage kiosk app single-file installer
#define MyAppName "Digital Signage"
#define MyAppVersion "1.0.2"
#define MyAppPublisher "Multi Kencana Niagatama"
#define MyAppExeName "signage.exe"

[Setup]
AppId={{8C4A7E52-9B31-4D6F-A2E8-D15F0C93B7A1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
; per-user install: no admin/UAC needed, works on locked-down kiosk PCs
PrivilegesRequired=lowest
DefaultDirName={localappdata}\DigitalSignage
DisableProgramGroupPage=yes
OutputDir=C:\devtools\mds\installer\output
OutputBaseFilename=signage-setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
UninstallDisplayIcon={app}\{#MyAppExeName}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "C:\devtools\mds\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent
