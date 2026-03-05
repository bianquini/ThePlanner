# ThePlanner — Exibe SHA-256 do keystore release
# Necessario para cadastrar no Firebase Console (Google Sign-In)

$keytool = "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe"
$keystorePath = Join-Path $PSScriptRoot "..\android\theplanner-release.jks"
$keystorePath = [System.IO.Path]::GetFullPath($keystorePath)

Write-Host "Fingerprints do keystore release:" -ForegroundColor Cyan
& $keytool -list -v `
    -keystore $keystorePath `
    -alias theplanner `
    -storepass "theplanner2026" `
    -keypass "theplanner2026" 2>&1 | Select-String -Pattern "SHA|MD5|Alias|Valid"
