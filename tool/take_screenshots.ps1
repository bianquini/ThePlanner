# ThePlanner — Captura screenshots do emulador para o Play Store listing
# Executa: powershell -ExecutionPolicy Bypass -File tool/take_screenshots.ps1

$adb = "C:\Users\iagob\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$outDir = Join-Path $PSScriptRoot "..\docs\screenshots"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

function Take-Screenshot {
    param([string]$name)
    $outPath = Join-Path $outDir "$name.png"
    & $adb exec-out screencap -p | Set-Content -Path $outPath -AsByteStream
    if (Test-Path $outPath) {
        $size = [math]::Round((Get-Item $outPath).Length / 1KB, 1)
        Write-Host "  Salvo: $name.png ($size KB)" -ForegroundColor Green
    } else {
        Write-Host "  ERRO ao salvar $name.png" -ForegroundColor Red
    }
}

Write-Host "=== ThePlanner — Captura de Screenshots ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "Certifique-se de que o app esta aberto no emulador na tela correta."
Write-Host ""

# Verifica dispositivos conectados
$devices = & $adb devices
Write-Host "Dispositivos: $devices"
Write-Host ""

Write-Host "Capturando screenshot atual..."
Take-Screenshot "screenshot_01_atual"

Write-Host ""
Write-Host "Screenshots salvas em: $outDir" -ForegroundColor Cyan
Write-Host ""
Write-Host "PROXIMOS PASSOS:" -ForegroundColor Yellow
Write-Host "  1. Navegue para cada tela do app no emulador"
Write-Host "  2. Execute este script novamente com o nome correto"
Write-Host "  Ou: use 'adb exec-out screencap -p > nome.png' manualmente"
