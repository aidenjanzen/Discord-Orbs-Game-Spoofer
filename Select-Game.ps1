# Requires Windows PowerShell 5.1 or newer.
# Copies and launches orbs.exe under selected filenames.
# This does not install or launch the actual games.

# Paths are always relative to this script.
$SourceExe = Join-Path $PSScriptRoot 'orbs.exe'
$ListPath = Join-Path $PSScriptRoot 'games.txt'
$DestinationRoot = Join-Path $PSScriptRoot 'GameCopies'
$RootPrefix = [System.IO.Path]::GetFullPath($DestinationRoot).TrimEnd('\') + '\'

foreach ($file in @($SourceExe, $ListPath)) {
    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
        throw "Required file not found: $file"
    }
}

# Read game names and their executable paths.
$games = [System.Collections.Generic.List[object]]::new()
$currentGame = $null

foreach ($line in Get-Content -LiteralPath $ListPath -Encoding UTF8) {
    $text = $line.Trim()

    if (-not $text) {
        continue
    }

    if ($text -match '^\.\.[\\/]') {
        if ($null -eq $currentGame) {
            throw "Path found before a game name: $text"
        }

        # Handles multiple paths on the same line.
        foreach ($match in [regex]::Matches(
            $text,
            '\.\.[\\/].*?(?=\s+\.\.[\\/]|$)'
        )) {
            $currentGame.Paths += $match.Value.Trim()
        }
    }
    else {
        $currentGame = [pscustomobject]@{
            Name  = $text
            Paths = @()
        }

        $games.Add($currentGame)
    }
}

if ($games.Count -eq 0) {
    throw 'No games found in games.txt.'
}

function Select-ExecutablePath {
    param([object]$Game)

    $paths = @($Game.Paths)

    if ($paths.Count -eq 0) {
        Write-Host "No executable paths for $($Game.Name)." -ForegroundColor Yellow
        return
    }

    if ($paths.Count -eq 1) {
        return $paths[0]
    }

    Write-Host "`nChoose a path for $($Game.Name):" -ForegroundColor Cyan

    for ($i = 0; $i -lt $paths.Count; $i++) {
        Write-Host ('{0}. {1}' -f ($i + 1), $paths[$i])
    }

    while ($true) {
        $answer = (Read-Host 'Path number, or S to skip').Trim()

        if ($answer -ieq 's') {
            return
        }

        $number = 0

        if (
            [int]::TryParse($answer, [ref]$number) -and
            $number -ge 1 -and
            $number -le $paths.Count
        ) {
            return $paths[$number - 1]
        }

        Write-Host 'Invalid path number.' -ForegroundColor Yellow
    }
}

$visibleGames = @($games)
$search = ''

while ($true) {
    Write-Host "`n=== Game Selector ===" -ForegroundColor Cyan

    if ($search) {
        Write-Host "Search: $search"
    }

    if ($visibleGames.Count -eq 0) {
        Write-Host 'No matches.'
    }

    for ($i = 0; $i -lt $visibleGames.Count; $i++) {
        Write-Host ('{0,3}. {1}' -f ($i + 1), $visibleGames[$i].Name)
    }

    Write-Host "`nNumbers: 1,3,5 | Text: search | *: show all | Q: quit"
    $answer = (Read-Host 'Choose').Trim()

    if ($answer -ieq 'q') {
        break
    }

    if (-not $answer) {
        continue
    }

    if ($answer -eq '*') {
        $search = ''
        $visibleGames = @($games)
        continue
    }

    if ($answer -notmatch '^\d+(\s*,\s*\d+)*$') {
        $search = $answer

        $visibleGames = @(
            $games | Where-Object {
                $_.Name.IndexOf(
                    $search,
                    [System.StringComparison]::OrdinalIgnoreCase
                ) -ge 0
            }
        )

        continue
    }

    # Validate all numbers before doing anything.
    $numbers = [System.Collections.Generic.List[int]]::new()
    $valid = $true

    foreach ($token in ($answer -split ',')) {
        $number = 0

        if (
            -not [int]::TryParse($token.Trim(), [ref]$number) -or
            $number -lt 1 -or
            $number -gt $visibleGames.Count
        ) {
            $valid = $false
            break
        }

        if (-not $numbers.Contains($number)) {
            $numbers.Add($number)
        }
    }

    if (-not $valid) {
        Write-Host 'Invalid selection. Use numbers from the displayed list.' `
            -ForegroundColor Yellow
        continue
    }

    foreach ($number in $numbers) {
        $game = $visibleGames[$number - 1]
        $chosenPath = Select-ExecutablePath -Game $game

        if (-not $chosenPath) {
            continue
        }

        try {
            # Interpret the initial "..\" as relative to GameCopies.
            $relativePath = $chosenPath.Replace('/', '\')
            $relativePath = $relativePath -replace '^\.\.\\', ''

            if (
                [System.IO.Path]::IsPathRooted($relativePath) -or
                ($relativePath.Split('\') -contains '..') -or
                $relativePath.Contains(':')
            ) {
                throw "Unsafe path: $chosenPath"
            }

            $extension = [System.IO.Path]::GetExtension($relativePath)

            if (-not $extension) {
                $relativePath += '.exe'
            }
            elseif ($extension -ine '.exe') {
                throw "Not an executable path: $chosenPath"
            }

            $destination = [System.IO.Path]::GetFullPath(
                (Join-Path $DestinationRoot $relativePath)
            )

            if (-not $destination.StartsWith(
                $RootPrefix,
                [System.StringComparison]::OrdinalIgnoreCase
            )) {
                throw 'Destination is outside GameCopies.'
            }

            $folder = Split-Path -Path $destination -Parent

            [System.IO.Directory]::CreateDirectory($folder) | Out-Null

	    if (Test-Path -LiteralPath $destination -PathType Leaf) {
            	Write-Host "`nUsing existing: $destination" -ForegroundColor Cyan
	    }
	    else {
    		# Copy only when the destination does not exist.
    		[System.IO.File]::Copy($SourceExe, $destination, $false)

    		Write-Host "`nCopied: $destination" -ForegroundColor Green
	    }

        }
        catch {
            Write-Host "Copy failed for $($game.Name): $($_.Exception.Message)" `
                -ForegroundColor Red
            continue
        }

        try {
            $process = Start-Process `
                -FilePath $destination `
                -WorkingDirectory $folder `
                -PassThru `
                -ErrorAction Stop

            Write-Host "Started: $($game.Name) (PID: $($process.Id))" `
                -ForegroundColor Green
        }
        catch {
            Write-Host "Launch failed for $($game.Name): $($_.Exception.Message)" `
                -ForegroundColor Red

            Write-Host "The copy remains at: $destination" `
                -ForegroundColor Yellow
        }
    }
}
