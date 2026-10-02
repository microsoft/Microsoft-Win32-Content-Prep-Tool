<#
.SYNOPSIS
    Packages each app folder in .\input into a .intunewin file in .\output.

.DESCRIPTION
    Every subfolder of the input folder is one app. Each one is packaged with
    IntuneWinAppUtil.exe and saved as output\<folder name>.intunewin, replacing
    any earlier package with that name.

    The setup file is picked from the files directly inside the app folder, in
    this order:
      1. A PSAppDeployToolkit launcher: Invoke-AppDeployToolkit.exe or
         Deploy-Application.exe
      2. An install script: install.ps1, install.cmd or install.bat
      3. The only .msi file
      4. The only .exe file
    If none of these applies, name the setup file with -SetupFile, or use
    -PromptForSetupFile to be asked which file it is.

.PARAMETER App
    Names of the app folders to package. By default every folder in the input
    folder is packaged.

.PARAMETER SetupFile
    The setup file to use, relative to the app folder (for example setup.exe or
    Files\setup.exe). Skips the automatic pick.

.PARAMETER PromptForSetupFile
    When the setup file can't be picked automatically, list the installer files
    in the app folder and ask which one to use, instead of skipping the app.
    Start-Packaging.bat turns this on.

.PARAMETER InputFolder
    Folder that holds one subfolder per app. Default: input, next to this script.

.PARAMETER OutputFolder
    Folder the .intunewin files are written to. Default: output, next to this
    script.

.PARAMETER ToolPath
    Path to IntuneWinAppUtil.exe. Default: the copy next to this script.

.EXAMPLE
    .\Build-IntuneWin.ps1

    Packages every app folder, for example input\7-Zip -> output\7-Zip.intunewin.

.EXAMPLE
    .\Build-IntuneWin.ps1 -App 7-Zip -SetupFile 7z2408-x64.msi

    Packages only input\7-Zip, with 7z2408-x64.msi as the setup file.
#>
[CmdletBinding(PositionalBinding = $false)]
param(
    [string[]] $App,
    [string] $SetupFile,
    [switch] $PromptForSetupFile,
    [string] $InputFolder = (Join-Path $PSScriptRoot 'input'),
    [string] $OutputFolder = (Join-Path $PSScriptRoot 'output'),
    [string] $ToolPath = (Join-Path $PSScriptRoot 'IntuneWinAppUtil.exe')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Exit-Script([string] $Message) {
    Write-Host $Message -ForegroundColor Red
    exit 1
}

# Returns the setup file for an app folder, or $null if there's no clear pick.
function Find-SetupFile([System.IO.DirectoryInfo] $Folder) {
    $files = @(Get-ChildItem -LiteralPath $Folder.FullName -File)

    foreach ($name in 'Invoke-AppDeployToolkit.exe', 'Deploy-Application.exe', 'install.ps1', 'install.cmd', 'install.bat') {
        $match = @($files | Where-Object { $_.Name -eq $name })
        if ($match.Count -eq 1) { return $match[0] }
    }
    foreach ($extension in '.msi', '.exe') {
        $match = @($files | Where-Object { $_.Extension -eq $extension })
        if ($match.Count -eq 1) { return $match[0] }
    }
    return $null
}

# Asks which installer file in an app folder is the setup file. Returns $null if
# there are none to choose from.
function Read-SetupFileChoice([System.IO.DirectoryInfo] $Folder) {
    $candidates = @(Get-ChildItem -LiteralPath $Folder.FullName -File |
        Where-Object { $_.Extension -in '.exe', '.msi', '.msp', '.ps1', '.cmd', '.bat' })
    if ($candidates.Count -eq 0) { return $null }

    Write-Host 'Which file is the setup file?'
    for ($i = 0; $i -lt $candidates.Count; $i++) {
        Write-Host "  $($i + 1). $($candidates[$i].Name)"
    }
    while ($true) {
        $answer = Read-Host 'Type its number and press Enter (or just press Enter to skip this app)'
        if (-not $answer) { throw 'No setup file chosen, so this app was skipped.' }
        $number = 0
        if ([int]::TryParse($answer, [ref] $number) -and $number -ge 1 -and $number -le $candidates.Count) {
            return $candidates[$number - 1]
        }
        Write-Host "Enter a number from 1 to $($candidates.Count)."
    }
}

if (-not (Test-Path -LiteralPath $ToolPath -PathType Leaf)) {
    Exit-Script "IntuneWinAppUtil.exe not found: $ToolPath"
}
if (-not (Test-Path -LiteralPath $InputFolder -PathType Container)) {
    Exit-Script "Input folder not found: $InputFolder"
}
$ToolPath = (Get-Item -LiteralPath $ToolPath).FullName
$InputFolder = (Get-Item -LiteralPath $InputFolder).FullName
$OutputFolder = $PSCmdlet.GetUnresolvedProviderPathFromPSPath($OutputFolder)

$allFolders = @(Get-ChildItem -LiteralPath $InputFolder -Directory | Sort-Object Name)
if ($App) {
    $appFolders = @(foreach ($name in $App) {
        $match = @($allFolders | Where-Object { $_.Name -eq $name })
        if ($match.Count -eq 0) {
            Exit-Script "App folder '$name' not found in $InputFolder. Found: $(($allFolders | ForEach-Object { $_.Name }) -join ', ')"
        }
        $match[0]
    })
} else {
    # Files dropped straight into input\ instead of an app folder are a likely mistake.
    $looseFiles = @(Get-ChildItem -LiteralPath $InputFolder -File | Where-Object { $_.Name -ne 'README.md' })
    if ($looseFiles.Count -gt 0) {
        Write-Warning "Skipping files directly in $InputFolder (only app folders are packaged): $(($looseFiles | ForEach-Object { $_.Name }) -join ', ')"
    }
    $appFolders = $allFolders
    if ($appFolders.Count -eq 0) {
        Exit-Script "No app folders in $InputFolder. Put each app's setup files in their own folder, for example input\7-Zip\7z2408-x64.msi"
    }
}

$created = @()
$failed = @()
foreach ($folder in $appFolders) {
    Write-Host ''
    Write-Host "Packaging $($folder.Name)" -ForegroundColor Cyan
    try {
        if ($SetupFile) {
            $setupPath = Join-Path $folder.FullName $SetupFile
            if (-not (Test-Path -LiteralPath $setupPath -PathType Leaf)) {
                throw "Setup file not found: $setupPath"
            }
            $setup = Get-Item -LiteralPath $setupPath
            if (-not $setup.FullName.StartsWith($folder.FullName + [System.IO.Path]::DirectorySeparatorChar, 'OrdinalIgnoreCase')) {
                throw "The setup file has to be inside the app folder: $($setup.FullName)"
            }
        } else {
            $setup = Find-SetupFile $folder
            if (-not $setup -and $PromptForSetupFile) {
                $setup = Read-SetupFileChoice $folder
            }
            if (-not $setup) {
                throw "Couldn't tell which file in $($folder.FullName) is the setup file. Name it with: .\Build-IntuneWin.ps1 -App '$($folder.Name)' -SetupFile <file name>"
            }
        }
        Write-Host "Setup file: $($setup.FullName.Substring($folder.FullName.Length + 1))"

        # The tool names its output after the setup file, so build in a scratch folder
        # and then rename the package after the app folder.
        $staging = Join-Path $OutputFolder ('.staging-' + [guid]::NewGuid().ToString('N'))
        try {
            & $ToolPath -c $folder.FullName -s $setup.FullName -o $staging -q
            # The tool exits with 0 even when it rejects its arguments, so also check for the file.
            $package = Join-Path $staging ($setup.BaseName + '.intunewin')
            if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $package -PathType Leaf)) {
                throw "IntuneWinAppUtil.exe did not create a package (exit code $LASTEXITCODE). See its output above."
            }
            $destination = Join-Path $OutputFolder ($folder.Name + '.intunewin')
            Move-Item -LiteralPath $package -Destination $destination -Force
        } finally {
            if (Test-Path -LiteralPath $staging) {
                Remove-Item -LiteralPath $staging -Recurse -Force
            }
        }
        Write-Host "Created $destination" -ForegroundColor Green
        $created += $destination
    } catch {
        Write-Host "FAILED: $($_.Exception.Message)" -ForegroundColor Red
        $failed += $folder.Name
    }
}

Write-Host ''
if ($created.Count -gt 0) {
    Write-Host "Created $($created.Count) package(s) in $OutputFolder" -ForegroundColor Green
}
if ($failed.Count -gt 0) {
    Exit-Script "Failed: $($failed -join ', ')"
}
