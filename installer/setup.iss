[Setup]
AppName=P2P Messenger
AppVersion={#MyAppVersion}
DefaultDirName={autopf}\P2P Messenger
DefaultGroupName=P2P Messenger
OutputDir=Output
OutputBaseFilename=P2PMessenger-Setup
Compression=lzma2
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\P2P Messenger"; Filename: "{app}\p2p_messenger.exe"
Name: "{autodesktop}\P2P Messenger"; Filename: "{app}\p2p_messenger.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "Create desktop shortcut"; GroupDescription: "Additional icons:"

[Run]
Filename: "{app}\p2p_messenger.exe"; Description: "Launch P2P Messenger"; Flags: nowait postinstall skipifsilent
