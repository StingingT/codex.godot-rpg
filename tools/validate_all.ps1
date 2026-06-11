param(
    [string]$GodotBin = $env:GODOT_BIN,
    [switch]$StrictItemData
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

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

& $GodotBin --headless --import --path $projectRoot
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_architecture.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_content_lifecycle.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($StrictItemData) {
    & $GodotBin --headless --path $projectRoot --script "res://tools/validate_item_data.gd" -- --strict
} else {
    & $GodotBin --headless --path $projectRoot --script "res://tools/validate_item_data.gd"
}
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_inventory_phase_b.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_monster_sprite_delivery.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_scenes.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_ui_layout.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_custom_maps.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

& $GodotBin --headless --path $projectRoot --script "res://tools/validate_custom_route_quest_flow.gd"
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

Write-Host "All Godot validation checks passed."
