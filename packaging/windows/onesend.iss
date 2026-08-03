#define MyAppName "OneSend"
#define MyAppPublisher "MakerJackie"
#define MyAppURL "https://onesend.01mvp.com"
#define MyAppExeName "onesend.exe"
#define MyAppVersion GetEnv("ONESEND_WINDOWS_VERSION")
#define MySourceDir GetEnv("ONESEND_WINDOWS_SOURCE_DIR")
#define MyOutputDir GetEnv("ONESEND_WINDOWS_OUTPUT_DIR")

#if MyAppVersion == ""
  #error ONESEND_WINDOWS_VERSION is required
#endif
#if MySourceDir == ""
  #error ONESEND_WINDOWS_SOURCE_DIR is required
#endif
#if MyOutputDir == ""
  #error ONESEND_WINDOWS_OUTPUT_DIR is required
#endif

[Setup]
AppId={{7A7F44D4-64B8-49E4-8BE6-F42D0486A4D1}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}/updates/appcast.xml
DefaultDirName={localappdata}\Programs\{#MyAppName}
DefaultGroupName={#MyAppName}
DisableProgramGroupPage=yes
PrivilegesRequired=lowest
OutputDir={#MyOutputDir}
OutputBaseFilename=onesend-windows-setup
SetupIconFile=..\..\windows\runner\resources\app_icon.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
CloseApplications=force
UninstallDisplayIcon={app}\{#MyAppExeName}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription=OneSend optical file transfer installer
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "chinesesimplified"; MessagesFile: "compiler:Languages\ChineseSimplified.isl"

[Files]
Source: "{#MySourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{autoprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"

[Run]
Filename: "{app}\{#MyAppExeName}"; Flags: nowait skipifdoesntexist; Check: IsUpdaterInstall
Filename: "{app}\{#MyAppExeName}"; Description: "Launch {#MyAppName}"; Flags: nowait postinstall skipifsilent; Check: not IsUpdaterInstall

[Code]
function IsUpdaterInstall(): Boolean;
begin
  Result := ExpandConstant('{param:ONESENDUPDATE|0}') = '1';
end;
