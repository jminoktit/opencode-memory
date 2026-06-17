param([switch]$Refresh)

$dir = Split-Path $PSCommandPath -Parent
$port = 8080

Write-Host "🚀 OpenCode Session Viewer" -ForegroundColor Cyan
Write-Host "══════════════════════════" -ForegroundColor Cyan

if ($Refresh -or !(Test-Path "$dir\sessions-data.json")) {
  Write-Host "📦 Exporting sessions from opencode.db..." -ForegroundColor Yellow
  & "$dir\export.ps1"
  Write-Host "" -ForegroundColor Yellow
}

Write-Host "🌐 Server: http://localhost:$port" -ForegroundColor Green
Write-Host "📂 Folder: $dir" -ForegroundColor Gray
Write-Host "Press Ctrl+C to stop`n" -ForegroundColor Gray

npx http-server $dir -p $port -c-1 --silent
