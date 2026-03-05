# ThePlanner — Gerador do Keystore de Assinatura Release
# Executa: powershell -ExecutionPolicy Bypass -File tool/gen_keystore.ps1

$keytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"

if (-not (Test-Path $keytool)) {
    # Tenta Flutter SDK keytool
    $keytool = "keytool"
    Write-Host "Usando keytool do PATH"
} else {
    Write-Host "Usando keytool do Android Studio JBR"
}

$keystorePath = Join-Path $PSScriptRoot "..\android\theplanner-release.jks"
$keystorePath = [System.IO.Path]::GetFullPath($keystorePath)

if (Test-Path $keystorePath) {
    Write-Host "Keystore ja existe em: $keystorePath" -ForegroundColor Yellow
    Write-Host "Se quiser regenerar, delete o arquivo primeiro." -ForegroundColor Yellow
    exit 0
}

Write-Host "Gerando keystore em: $keystorePath" -ForegroundColor Cyan

& $keytool -genkey -v `
    -keystore $keystorePath `
    -alias theplanner `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -dname "CN=ThePlanner, OU=Dev, O=ThePlannerApp, L=Brazil, S=Brazil, C=BR" `
    -storepass "theplanner2026" `
    -keypass "theplanner2026"

if ($LASTEXITCODE -eq 0) {
    Write-Host "Keystore gerado com sucesso!" -ForegroundColor Green
    Write-Host "IMPORTANTE: Faca backup do arquivo '$keystorePath'" -ForegroundColor Red
    Write-Host "           e das senhas em local seguro!" -ForegroundColor Red
} else {
    Write-Host "Erro ao gerar keystore (codigo: $LASTEXITCODE)" -ForegroundColor Red
    exit 1
}
