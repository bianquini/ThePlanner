# Captura screenshot rapido do emulador
param([string]$name = "screen")

$adb    = "C:\Users\iagob\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$outDir = "C:\Users\iagob\ThePlanner\docs\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$path = Join-Path $outDir "$name.png"
& $adb shell screencap -p /sdcard/tmp_sc.png
& $adb pull /sdcard/tmp_sc.png $path
& $adb shell rm /sdcard/tmp_sc.png
Write-Host "Salvo: $path"
