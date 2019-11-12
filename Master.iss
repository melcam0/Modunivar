  #define MyAppName "Master"
#define MyAppVersion "1.0"
#define MyAppExeName "Master.vbs"
#define MyAppPublisher ""
#define MyAppURL ""

[Setup]
AppName = {#MyAppName}
AppId={{3630AF4C-E10A-4A62-A219-0E4CEF9746E8}
DefaultDirName = {sd}\{#MyAppName}
DefaultGroupName = {#MyAppName}
OutputDir = SetUp
OutputBaseFilename = setup_{#MyAppName}
SetupIconFile = master.ico
AppVersion = {#MyAppVersion}
AppPublisher = {#MyAppPublisher}
AppPublisherURL = {#MyAppURL}
AppSupportURL = {#MyAppURL}
AppUpdatesURL = {#MyAppURL}
PrivilegesRequired = none
InfoBeforeFile = infobefore.txt
InfoAfterFile = infoafter.txt
Compression = lzma2/ultra64
SolidCompression = yes
ArchitecturesInstallIn64BitMode = x64
LicenseFile = gpl_3.0.txt

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\master.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\master.ico"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\master.ico"

[Files]

Source: "C:\Users\Camillo\GitHub\Master\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; NOTE: Don't use "Flags: ignoreversion" on any shared system files





