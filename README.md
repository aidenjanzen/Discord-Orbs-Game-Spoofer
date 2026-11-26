# Discord Orbs Game Spoofer

A Windows PowerShell utility that copies a small C# console application into selected folders, renames it to a listed executable filename, and launches it.

The console application displays its running executable name, application folder, and elapsed runtime. **It does not install or run the actual games.**

> [!IMPORTANT]
> You will need to accept the quests first to claim playtime. You CAN accept multiple and have them all run at the same time!

## Features

- Browse a numbered list or search by name.
- Select multiple entries with comma-separated numbers.
- Choose an executable path when an entry has several.
- Create missing destination folders automatically.
- Copy and rename `orbs.exe` when the destination is missing.
- Launch an existing destination executable without overwriting it.
- Keep the selector open for additional selections.

## Requirements

- Windows.
- Windows PowerShell 5.1 or newer, or PowerShell 7 on Windows.
- The .NET SDK to compile the C# application using the steps below.

The build below produces a self-contained executable for Windows x64. The target computer does not need a separate .NET runtime installation. Use `win-arm64` instead of `win-x64` when targeting Windows ARM64.

## Repository layout

```text
Orbs/
├── Select-Game.ps1
├── games.txt
├── orbs.cs
├── README.md
├── orbs.exe          # Created by the build steps
└── GameCopies/       # Created when selections are processed
```

`orbs.cs` is the C# source containing the `Program` class and `Main` method. Keep it in the repository root alongside `Select-Game.ps1` and `games.txt`.

## Compile the executable

Open PowerShell in the repository folder. Install the .NET SDK if necessary, then confirm it is available:

```powershell
dotnet --version
```
To compile your own .EXE for security:

Navigate to the project dir.

```powershell
C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe orbs.cs
```

Replacing the created root `orbs.exe` does **not** update copies already present in `GameCopies`. To refresh a generated copy, close that instance, remove only that generated executable, and select the entry again.

## Run the selector

From PowerShell in the repository folder:

```powershell
.\Select-Game.ps1
```

No command-line parameters are required. The script uses paths relative to its own location:

- Source executable: `orbs.exe`
- Entry list: `games.txt`
- Destination root: `GameCopies`

### Menu controls

- `1` — select one displayed entry.
- `1,3,5` — select several displayed entries.
- `apex` — search by part of a name, ignoring case.
- `*` — show the full list again.
- `Q` — quit the selector.
  
<img width="759" height="288" alt="image" src="https://github.com/user-attachments/assets/dcd8ca36-9461-429a-a836-5b67f14d1fd5" />

Numbers refer to the currently displayed list. If an entry has several executable paths, select a path number or enter `S` to skip that entry.

Each selected executable starts without waiting for previous instances to close. You can run multiple instances. Press `Ctrl+C` in an application's console window to stop that instance. Quitting the selector does not automatically close launched applications.

## List format

Each entry consists of a name followed by one or more relative executable paths, with blank lines between entries:

```text
Apex Legends
..\Apex Legends\r5apex.exe

Call of Duty: Ghosts
..\Call of Duty Ghosts\iw6sp64_ship.exe
..\Call of Duty Ghosts\iw6mp64_ship.exe
```
All games grabbed from https://www.reddit.com/r/DiscordQuests/wiki/game-index/

The script interprets the initial `..\` as relative to `GameCopies`, not as a request to navigate to its parent folder. For example:

```text
..\Apex Legends\r5apex.exe
```

becomes:

```text
GameCopies\Apex Legends\r5apex.exe
```

Paths without a filename extension receive `.exe`. Placeholder directory names such as `version-xxxxxxxx` are used literally; the script does not discover installed game locations.

## Troubleshooting

### Running scripts is disabled

> [!IMPORTANT]
> If your organization's policy permits it, allow local scripts for the current PowerShell session:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\Select-Game.ps1
```

The setting expires when that PowerShell window closes. It does not override organizational policy.

> [!IMPORTANT]
> If a downloaded script is blocked, inspect it first, then unblock that specific file:

```powershell
Unblock-File -LiteralPath .\Select-Game.ps1
```

### The script window closes immediately

Run the script from an already-open PowerShell window rather than double-clicking it. Any error will remain visible.

## Safety

Only run executables you trust. The script launches existing destination executables without checking whether they match the current source. Keep `GameCopies` under your control, and do not point the destination at real game installation folders. Renaming an executable does not make it the actual listed game.

> [!CAUTION]
> **Discord Orbs & Quest Manipulation Warning:** Spoofing game activity to earn Quest rewards or Orbs may violate Discord’s [Paid Services Terms](https://discord.com/terms/paid-services-terms), which prohibit manipulating the Orbs system, gaining unfair advantages, and fraud or misrepresentation. Violations may result in account restrictions or suspension. Using an alternate account does not permit prohibited activity.
