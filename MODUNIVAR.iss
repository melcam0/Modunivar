#define MyAppName "MODUNIVAR"
#define MyAppVersion "2.6"
#define MyAppExeName "MODUNIVAR.vbs"
#define MyAppPublisher ""
#define MyAppURL ""

[Setup]
AppName = {#MyAppName}
AppId={{3630AF4C-E10A-4A62-A219-0E4CEF9746E8}
DefaultDirName = {sd}\{#MyAppName}
DefaultGroupName = {#MyAppName}
OutputDir = SetUp
OutputBaseFilename = setup_{#MyAppName}
SetupIconFile = MODUNIVAR.ico
AppVersion = {#MyAppVersion}
AppPublisher = {#MyAppPublisher}
AppPublisherURL = {#MyAppURL}
AppSupportURL = {#MyAppURL}
AppUpdatesURL = {#MyAppURL}
PrivilegesRequired = none
InfoBeforeFile = infobefore.txt
InfoAfterFile = infoafter.txt
Compression = lzma
SolidCompression = yes
LicenseFile = gpl_3.0.txt

[Languages]
Name: "italian"; MessagesFile: "compiler:Languages\Italian.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\MODUNIVAR.ico"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{commonprograms}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; IconFilename: "{app}\MODUNIVAR.ico"
Name: "{commondesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; IconFilename: "{app}\MODUNIVAR.ico"

[Files]

Source: "C:\Users\Camillo\GitHub\Modunivar\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; NOTE: Don't use "Flags: ignoreversion" on any shared system files





