param(
    [string]$GodotBin = $env:GODOT_BIN,
    [switch]$SkipScreenshots,
    [switch]$StrictItemData
)

$ErrorActionPreference = "Stop"

$toolsRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot = Split-Path -Parent $toolsRoot

if ([string]::IsNullOrWhiteSpace($GodotBin)) {
    $candidates = @(
        "godot",
        "godot4",
        "C:\Users\guyro\Desktop\RPG\Exterior sprites_Winlu\Godot_v4.3-stable_win64_console.exe"
    )
    foreach ($candidate in $candidates) {
        $resolved = Get-Command $candidate -ErrorAction SilentlyContinue
        if ($resolved) {
            $GodotBin = $resolved.Source
            break
        }
        if (Test-Path -LiteralPath $candidate) {
            $GodotBin = $candidate
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($GodotBin) -or -not (Test-Path -LiteralPath $GodotBin)) {
    throw "Godot executable not found. Pass -GodotBin or set GODOT_BIN."
}

Write-Host "Running architect validation..."
& (Join-Path $toolsRoot "validate_all.ps1") -GodotBin $GodotBin -StrictItemData:$StrictItemData
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "Checking UI layout with the normal renderer..."
& $GodotBin --path $projectRoot --script "res://tools/validate_ui_layout.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if (-not $SkipScreenshots) {
    Write-Host "Capturing review screenshots..."
    & $GodotBin --path $projectRoot --script "res://tools/capture_review_screenshots.gd"
    if ($LASTEXITCODE -ne 0) {
        exit $LASTEXITCODE
    }
    Write-Host "Review screenshots written to review_artifacts/screenshots."
}

Write-Host "Architect review checks completed."
