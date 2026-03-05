# ThePlanner — Instala APK debug no emulador e captura screenshots
# Executa: powershell -ExecutionPolicy Bypass -File tool/install_and_screenshot.ps1

$adb    = "C:\Users\iagob\AppData\Local\Android\Sdk\platform-tools\adb.exe"
$flutter = "flutter"
$root   = Join-Path $PSScriptRoot ".."
$root   = [System.IO.Path]::GetFullPath($root)
$outDir = Join-Path $root "docs\screenshots"
$apk    = Join-Path $root "build\app\outputs\flutter-apk\app-debug.apk"

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# ── Verifica emulador ─────────────────────────────────────────────────────────
$devices = (& $adb devices) -join "`n"
if ($devices -notmatch "emulator") {
    Write-Host "ERRO: Nenhum emulador conectado." -ForegroundColor Red
    Write-Host "Inicie um emulador via Android Studio antes de continuar." -ForegroundColor Yellow
    exit 1
}
Write-Host "Emulador detectado." -ForegroundColor Green

# ── Build APK debug se nao existir ───────────────────────────────────────────
if (-not (Test-Path $apk)) {
    Write-Host "Gerando APK debug..." -ForegroundColor Cyan
    Push-Location $root
    & $flutter build apk --debug
    Pop-Location
}

if (-not (Test-Path $apk)) {
    Write-Host "ERRO: APK debug nao encontrado em $apk" -ForegroundColor Red
    exit 1
}

Write-Host "APK: $apk" -ForegroundColor Cyan

# ── Instala no emulador ───────────────────────────────────────────────────────
Write-Host "Instalando APK no emulador..." -ForegroundColor Cyan
& $adb install -r $apk
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO na instalacao" -ForegroundColor Red
    exit 1
}
Write-Host "App instalado com sucesso!" -ForegroundColor Green

# ── Lanca o app ──────────────────────────────────────────────────────────────
Write-Host "Lancando ThePlanner no emulador..." -ForegroundColor Cyan
& $adb shell am start -n "com.theplanner.the_planner/.MainActivity"
Start-Sleep -Seconds 4

# ── Funcao de screenshot ─────────────────────────────────────────────────────
function Take-Screenshot {
    param([string]$filename)
    $path = Join-Path $outDir "$filename"
    $tmpDevice = "/sdcard/tmp_screenshot.png"
    & $adb shell screencap -p $tmpDevice
    & $adb pull $tmpDevice $path
    & $adb shell rm $tmpDevice
    if (Test-Path $path) {
        $size = [math]::Round((Get-Item $path).Length / 1KB, 1)
        Write-Host "  [OK] $filename ($size KB)" -ForegroundColor Green
    } else {
        Write-Host "  [ERRO] Falha ao capturar $filename" -ForegroundColor Red
    }
}

# ── Tela de Login ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== SCREENSHOT 1: Tela de Login ===" -ForegroundColor Yellow
Start-Sleep -Seconds 2
Take-Screenshot "01_login.png"

Write-Host ""
Write-Host "App aberto no emulador!" -ForegroundColor Green
Write-Host ""
Write-Host "Para as proximas screenshots, faca login no app e navegue para cada tela." -ForegroundColor Yellow
Write-Host "Depois execute os comandos abaixo para cada tela:" -ForegroundColor Yellow
Write-Host ""
Write-Host "  # Dashboard"
Write-Host "  & '$adb' shell screencap -p /sdcard/sc.png; & '$adb' pull /sdcard/sc.png '$outDir\02_dashboard.png'"
Write-Host ""
Write-Host "  # Gastos"
Write-Host "  & '$adb' shell screencap -p /sdcard/sc.png; & '$adb' pull /sdcard/sc.png '$outDir\03_gastos.png'"
Write-Host ""
Write-Host "  # Planejamento"
Write-Host "  & '$adb' shell screencap -p /sdcard/sc.png; & '$adb' pull /sdcard/sc.png '$outDir\04_planejamento.png'"
Write-Host ""
Write-Host "  # Detalhe do mes"
Write-Host "  & '$adb' shell screencap -p /sdcard/sc.png; & '$adb' pull /sdcard/sc.png '$outDir\05_detalhe_mes.png'"
Write-Host ""
Write-Host "Screenshots salvas em: $outDir" -ForegroundColor Cyan
