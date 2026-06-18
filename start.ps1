param(
  [switch]$Refresh,
  [int]$Port = 8080
)

$dir = Split-Path $PSCommandPath -Parent

Write-Host "🚀 OpenCode Session Viewer" -ForegroundColor Cyan
Write-Host "══════════════════════════" -ForegroundColor Cyan

if ($Refresh -or !(Test-Path "$dir\sessions-data.json")) {
  Write-Host "📦 Exporting sessions from opencode.db..." -ForegroundColor Yellow
  & "$dir\export.ps1"
}

$url = "http://localhost:$Port"
Write-Host ""
Write-Host "🌐 Session Viewer: $url" -ForegroundColor Green
Write-Host "📂 Folder: $dir" -ForegroundColor Gray
Write-Host ""

Start-Process $url

node "$dir\server.js"
