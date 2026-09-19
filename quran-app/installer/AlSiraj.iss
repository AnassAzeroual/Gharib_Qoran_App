; Inno Setup script for AlSiraj (السراج في بيان غريب القرآن)
; Compile: ISCC.exe installer\AlSiraj.iss

#define MyAppName "السراج في بيان غريب القرآن"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "Siraj"
#define MyAppExeName "AlSiraj.exe"
#define MyAppAssocName "AlSiraj"
#define MyAppId "{{4C4540E8-4F30-4C9D-A772-88294AA27218}"

[Setup]
AppId={#MyAppId}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppVerName={#MyAppName} {#MyAppVersion}
AppPublisher={#MyAppPublisher}
DefaultDirName={autopf}\AlSiraj
DisableProgramGroupPage=yes
OutputDir=..\installer
OutputBaseFilename=AlSiraj-Setup
SetupIconFile=..\windows\runner\resources\app_icon.ico
LicenseFile=
UninstallDisplayIcon={app}\{#MyAppExeName}
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=admin
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible

[Languages]
Name: "arabic"; MessagesFile: "compiler:Languages\Arabic.isl"
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Excludes: "*.msix,*.cer,*.pdb"; Flags: recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon

[Run]
Filename: "{app}\{#MyAppExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}}"; Flags: nowait postinstall skipifsilent