# Navega para Planos, toca na barra do grafico e captura detalhe do mes
$adb = "C:\Users\iagob\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$outDir = "C:\Users\iagob\ThePlanner\docs\screenshots"

function Tap([int]$x, [int]$y) {
    & $adb shell input tap $x $y
    Start-Sleep -Milliseconds 900
}

function Snap([string]$name) {
    Start-Sleep -Milliseconds 1800
    $path = Join-Path $outDir ($name + ".png")
    & $adb shell screencap -p /sdcard/tmp_sc.png
    & $adb pull /sdcard/tmp_sc.png $path 2>&1 | Out-Null
    & $adb shell rm /sdcard/tmp_sc.png
    Write-Host ("Salvo: " + $name + ".png") -ForegroundColor Green
}

# Va para aba Planos (4a aba - x=756)
Write-Host "Navegando para Planos..."
Tap 756 2280
Start-Sleep -Seconds 1

# Toca na primeira barra do grafico (mar.)
# No screenshot 04_planos.png: o grafico fica entre y~840 e y~1250
# Primeira barra (mar.) fica em x~155, centro do grafico y~1000
Write-Host "Tocando na barra 'mar.' do grafico..."
Tap 155 1000
Start-Sleep -Seconds 2
Snap "06_detalhe_mes"
