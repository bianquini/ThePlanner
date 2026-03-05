# Navega para o detalhe do mes e tira screenshot
$adb = "C:\Users\iagob\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$outDir = "C:\Users\iagob\ThePlanner\docs\screenshots"

function Tap([int]$x, [int]$y) {
    & $adb shell input tap $x $y
    Start-Sleep -Milliseconds 800
}

function Snap([string]$name) {
    Start-Sleep -Milliseconds 1500
    $path = Join-Path $outDir ($name + ".png")
    & $adb shell screencap -p /sdcard/tmp_sc.png
    & $adb pull /sdcard/tmp_sc.png $path 2>&1 | Out-Null
    & $adb shell rm /sdcard/tmp_sc.png
    Write-Host ("Salvo: " + $path) -ForegroundColor Green
}

# Garante que estamos no Inicio
Tap 108 2280
Start-Sleep -Seconds 1

# Toca no badge "marco 2026" no canto superior direito do header
# Coordenadas no device 1080x2400: ~x=460, y=110
Write-Host "Tocando no badge do mes..."
Tap 460 110
Start-Sleep -Seconds 2
Snap "06_detalhe_mes"

Write-Host "Feito!"
