$convDir = "$PSScriptRoot\conversations"
$files = Get-ChildItem $convDir -Filter *.json

Write-Host "=== Conversation Stats ===" -ForegroundColor Cyan
Write-Host "Total conversations: $($files.Count)"

$totalMsg = 0
foreach ($f in $files) {
  $data = Get-Content $f.FullName -Raw | ConvertFrom-Json
  $count = $data.messages.Count
  $totalMsg += $count
  Write-Host "`n`n$($data.date) - $($data.title)" -ForegroundColor Yellow
  Write-Host "  Directory: $($data.directory)"
  Write-Host "  Messages: $count"
  Write-Host "  File: $($f.Name)"
}

Write-Host "`n==========================="
Write-Host "Total messages: $totalMsg" -ForegroundColor Green
