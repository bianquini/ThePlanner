# ThePlanner — Gerador de Ícone do App
# Executa: powershell -ExecutionPolicy Bypass -File tool/create_icon.ps1
# Requer: Windows com .NET Framework (System.Drawing)

Add-Type -AssemblyName System.Drawing

$size = 1024
$bmp  = New-Object System.Drawing.Bitmap($size, $size)
$g    = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode    = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

# ── Fundo azul #4361EE ──────────────────────────────────────────────────────
$bgColor = [System.Drawing.Color]::FromArgb(255, 67, 97, 238)
$bgBrush = New-Object System.Drawing.SolidBrush($bgColor)
$g.FillRectangle($bgBrush, 0, 0, $size, $size)

# ── Círculo branco centralizado ─────────────────────────────────────────────
$margin      = 160
$circleSize  = $size - 2 * $margin
$circleRect  = New-Object System.Drawing.Rectangle($margin, $margin, $circleSize, $circleSize)
$whiteBrush  = [System.Drawing.Brushes]::White
$g.FillEllipse($whiteBrush, $circleRect)

# ── Texto "TP" em azul sobre o círculo ──────────────────────────────────────
$font      = New-Object System.Drawing.Font("Arial", 310, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
$textColor = [System.Drawing.Color]::FromArgb(255, 67, 97, 238)
$textBrush = New-Object System.Drawing.SolidBrush($textColor)

$sf                = New-Object System.Drawing.StringFormat
$sf.Alignment      = [System.Drawing.StringAlignment]::Center
$sf.LineAlignment  = [System.Drawing.StringAlignment]::Center

$textRect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
$g.DrawString("TP", $font, $textBrush, $textRect, $sf)

# ── Salvar ───────────────────────────────────────────────────────────────────
$g.Dispose()
$outDir = Join-Path $PSScriptRoot "..\assets\icon"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir "app_icon.png"
$bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()

Write-Host "Icone gerado em: $outPath" -ForegroundColor Green
Write-Host "Proximo passo: dart run flutter_launcher_icons" -ForegroundColor Cyan
