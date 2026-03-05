# Tenta varias posicoes para abrir o detalhe do mes
$adb = "C:\Users\iagob\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$outDir = "C:\Users\iagob\ThePlanner\docs\screenshots"

function Tap([int]$x, [int]$y) {
    & $adb shell input tap $x $y
    Start-Sleep -Milliseconds 1200
}

function Snap([string]$name) {
    Start-Sleep -Milliseconds 1500
    $path = Join-Path $outDir ($name + ".png")
    & $adb shell screencap -p /sdcard/tmp_sc.png
    & $adb pull /sdcard/tmp_sc.png $path 2>&1 | Out-Null
    & $adb shell rm /sdcard/tmp_sc.png
    Write-Host ("Salvo: " + $name) -ForegroundColor Green
}

# Garante que estamos na aba Planos
Tap 756 2280
Start-Sleep -Seconds 1

# Toca na barra do grafico - testa y=750 (topo da area de barras)
Write-Host "Tentativa: topo das barras (y=750)..."
Tap 155 750
Snap "06_detalhe_mes"
