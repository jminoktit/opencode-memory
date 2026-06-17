$db = "$env:USERPROFILE\.local\share\opencode\opencode.db"
$out = "$PSScriptRoot\sessions-data.json"

Write-Host "Exporting sessions from opencode.db..." -ForegroundColor Cyan

<# Export all sessions #>
$sessions = sqlite3 -json $db @"
SELECT id, title, directory, model, cost, tokens_input, tokens_output,
  datetime(time_created/1000, 'unixepoch') AS date_created,
  (SELECT count(*) FROM message WHERE session_id = s.id) AS msg_count
FROM session s ORDER BY time_created DESC;
"@ | ConvertFrom-Json
Write-Host "  $($sessions.Count) sessions" -ForegroundColor Gray

<# Export all messages #>
$allMessages = sqlite3 -json $db "SELECT id, session_id, data FROM message ORDER BY session_id, time_created ASC;" | ConvertFrom-Json
Write-Host "  $($allMessages.Count) messages" -ForegroundColor Gray

<# Export all parts #>
$allParts = sqlite3 -json $db "SELECT id, message_id, data FROM part ORDER BY message_id, time_created ASC;" | ConvertFrom-Json
Write-Host "  $($allParts.Count) parts" -ForegroundColor Gray

<# Index parts by message_id #>
$partsByMsg = @{}
foreach ($p in $allParts) {
  if (-not $partsByMsg.ContainsKey($p.message_id)) { $partsByMsg[$p.message_id] = @() }
  $partsByMsg[$p.message_id] += $p
}

<# Index messages by session_id #>
$msgsBySession = @{}
foreach ($m in $allMessages) {
  if (-not $msgsBySession.ContainsKey($m.session_id)) { $msgsBySession[$m.session_id] = @() }
  $msgsBySession[$m.session_id] += $m
}

$result = @{ sessions = @() }

foreach ($s in $sessions) {
  <# Parse model #>
  $modelName = $s.model
  if ($s.model) {
    try { $modelObj = $s.model | ConvertFrom-Json; $modelName = $modelObj.id } catch { $modelName = $s.model }
  }

  $msgArr = @()
  $sessionMsgs = $msgsBySession[$s.id]
  if ($sessionMsgs) {
    foreach ($m in $sessionMsgs) {
      <# Get role from message data #>
      $role = "unknown"
      try { $md = $m.data | ConvertFrom-Json; $role = $md.role } catch {}

      <# Get parts for this message #>
      $textParts = @()
      $msgParts = $partsByMsg[$m.id]
      if ($msgParts) {
        foreach ($p in $msgParts) {
          try {
            $d = $p.data | ConvertFrom-Json
            $t = $d.type
            if ($t -eq "text" -and $d.text) { $textParts += $d.text }
            elseif ($t -eq "reasoning" -and $d.text) { $textParts += "[思考] $($d.text)" }
            elseif ($t -eq "tool" -and $d.tool) { $textParts += "[استخدم أداة: $($d.tool)]" }
          } catch {}
        }
      }

      if ($textParts.Count -gt 0) {
        $msgArr += @{ role = $role; text = $textParts -join "`n" }
      }
    }
  }

  $result.sessions += @{
    id = $s.id
    title = $s.title
    directory = $s.directory
    date_created = $s.date_created
    model = $modelName
    cost = [math]::Round([double]$s.cost, 4)
    tokens_input = [int]$s.tokens_input
    tokens_output = [int]$s.tokens_output
    msg_count = [int]$s.msg_count
    messages = $msgArr
  }
}

$json = $result | ConvertTo-Json -Depth 10 -Compress
Set-Content $out -Value $json -Encoding utf8
Write-Host "Done! Exported to $out ($(($json.Length/1MB).ToString('0.0')) MB)" -ForegroundColor Green
