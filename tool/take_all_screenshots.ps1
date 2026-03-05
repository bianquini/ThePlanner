# ThePlanner - Screenshots para Play Store
$adb    = "C:\Users\iagob\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$outDir = "C:\Users\iagob\ThePlanner\docs\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Snap([string]$name) {
    Start-Sleep -Milliseconds 1500
    $path = Join-Path $outDir ($name + ".png")
    & $adb shell screencap -p /sdcard/tmp_sc.png
    & $adb pull /sdcard/tmp_sc.png $path 2>&1 | Out-Null
    & $adb shell rm /sdcard/tmp_sc.png
    Write-Host ("  [OK] " + $name + ".png") -ForegroundColor Green
}

function Tap([int]$x, [int]$y) {
    & $adb shell input tap $x $y
    Start-Sleep -Milliseconds 800
}

Write-Host "=== ThePlanner - Screenshots ===" -ForegroundColor Cyan

Write-Host "1. Dashboard..."
Tap 108 2280
Snap "01_dashboard"

Write-Host "2. Gastos..."
Tap 324 2280
Snap "02_gastos"

Write-Host "3. Rendas..."
Tap 540 2280
Snap "03_rendas"

Write-Host "4. Planos..."
Tap 756 2280
Snap "04_planos"

Write-Host "5. Perfil..."
Tap 972 2280
Snap "05_perfil"

Write-Host "6. Detalhe do mes..."
Tap 108 2280
Start-Sleep -Seconds 1
Tap 540 450
Start-Sleep -Seconds 1
Snap "06_detalhe_mes"

Write-Host ""
Write-Host "Done! Screenshots em: $outDir" -ForegroundColor Cyan
Get-ChildItem $outDir -Filter "*.png" | ForEach-Object { Write-Host ("  " + $_.Name) }
