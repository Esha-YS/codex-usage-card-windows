param([switch]$Check)
$ErrorActionPreference='Stop'
function Can-RestartFreshApp($ageSeconds,$hasWindow,$alreadyManaged,$preexisting,$portBusy) {
    return $ageSeconds -ge 0 -and $ageSeconds -lt 5 -and !$hasWindow -and !$alreadyManaged -and !$preexisting -and !$portBusy
}
if ($Check) {
    if (!(Can-RestartFreshApp 1 $false $false $false $false)) { throw 'Fresh startup rejected' }
    if (Can-RestartFreshApp 10 $false $false $false $false) { throw 'Old session must never be restarted' }
    if (Can-RestartFreshApp 1 $true $false $false $false) { throw 'Visible session must never be restarted' }
    if (Can-RestartFreshApp 1 $false $true $false $false) { throw 'Managed launch must not restart' }
    if (Can-RestartFreshApp 1 $false $false $true $false) { throw 'Existing session must not restart' }
    if (Can-RestartFreshApp 1 $false $false $false $true) { throw 'Occupied port must not be reused' }
    'Supervisor startup safety checks passed.'; exit
}
$mutex=New-Object Threading.Mutex($false,'Local\CodexUsageCardWindowsEmbeddedV3')
if (!$mutex.WaitOne(0)) { exit }
$root=$PSScriptRoot
$info=Get-Content -LiteralPath (Join-Path $root 'installation.json') -Raw | ConvertFrom-Json
if ($info.owner -ne 'codex-usage-card-windows-v1') { throw 'Invalid installation owner' }
$seen=New-Object 'System.Collections.Generic.HashSet[string]'
$agent=$null; $lastRestart=[datetime]::MinValue; $lastStatus=[datetime]::MinValue
$firstScan=$true
function Log-Supervisor($message) {
    $file=Join-Path $root 'supervisor.log'
    if ((Test-Path -LiteralPath $file) -and (Get-Item -LiteralPath $file).Length -gt 1000000) { [IO.File]::WriteAllText($file,'') }
    [IO.File]::AppendAllText($file,([datetime]::UtcNow.ToString('o')+' '+$message+[Environment]::NewLine))
}
try {
    Log-Supervisor 'Embedded quota supervisor started; existing sessions will not be restarted.'
    while (Test-Path -LiteralPath (Join-Path $root 'installation.json')) {
        try {
            if (!$agent -or $agent.HasExited) {
                $agentArgs='"'+(Join-Path $root 'agent.cjs')+'" --port '+$info.port
                $agent=Start-Process -FilePath $info.node -ArgumentList $agentArgs -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $root 'agent.log') -RedirectStandardError (Join-Path $root 'agent-error.log')
                $agent.Id | Set-Content -LiteralPath (Join-Path $root 'agent.pid')
            }
            $processes=@(Get-Process -Name ChatGPT,Codex -ErrorAction SilentlyContinue | Where-Object { $_.Path -match '\\OpenAI\.Codex[^\\]*\\app\\(ChatGPT|Codex)\.exe$' } | Sort-Object StartTime)
            foreach ($process in $processes) {
                $key=[string]$process.Id+':'+$process.StartTime.Ticks
                if ($seen.Contains($key)) { continue }
                $null=$seen.Add($key)
                if ($firstScan) { continue }
                $native=Get-CimInstance Win32_Process -Filter ('ProcessId='+$process.Id)
                if (!$native -or !$native.CommandLine -or $native.CommandLine -match ' --type=') { continue }
                $age=([datetime]::Now-$process.StartTime).TotalSeconds
                $preexisting=@($processes | Where-Object {$_.Id -ne $process.Id -and $_.StartTime -lt $process.StartTime}).Count -gt 0
                $hasWindow=@($processes | Where-Object {$_.MainWindowHandle -ne 0}).Count -gt 0
                $managed=$native.CommandLine -match '--remote-debugging-port='
                $busy=@([Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners() | Where-Object {$_.Port -eq $info.port}).Count -gt 0
                if (([datetime]::UtcNow-$lastRestart).TotalSeconds -lt 60) { $preexisting=$true }
                if (Can-RestartFreshApp $age $hasWindow $managed $preexisting $busy) {
                    # Recheck immediately before touching this newly created, still invisible process.
                    $process.Refresh()
                    if ($process.HasExited -or $process.MainWindowHandle -ne 0 -or ([datetime]::Now-$process.StartTime).TotalSeconds -ge 5) { continue }
                    $exe=$process.Path
                    $prefix='^\s*"?'+[regex]::Escape($exe)+'"?\s*'
                    $match=[regex]::Match($native.CommandLine,$prefix,[Text.RegularExpressions.RegexOptions]::IgnoreCase)
                    if (!$match.Success) { continue }
                    $originalArgs=$native.CommandLine.Substring($match.Length)
                    $lastRestart=[datetime]::UtcNow
                    & "$env:WINDIR\System32\taskkill.exe" /PID $process.Id /T /F 2>&1 | Out-Null
                    $process.WaitForExit(3000) | Out-Null
                    $arguments='--remote-debugging-address=127.0.0.1 --remote-debugging-port='+$info.port+' '+$originalArgs
                    Start-Process -FilePath $exe -ArgumentList $arguments | Out-Null
                    Log-Supervisor 'Enabled embedded card on fresh, invisible startup; one relaunch only.'
                    break
                }
                if (!$managed) { Log-Supervisor 'Skipped automatic relaunch: startup was already visible, old, or another session/port was active.' }
            }
            $firstScan=$false
            if (([datetime]::UtcNow-$lastStatus).TotalSeconds -ge 5) {
                $lastStatus=[datetime]::UtcNow
                @{owner=$info.owner;pid=$PID;agentPid=$agent.Id;agentRunning=(!$agent.HasExited);appRunning=($processes.Count -gt 0);updatedAt=[datetime]::UtcNow.ToString('o')} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $root 'supervisor-status.json') -Encoding UTF8
            }
        } catch { Log-Supervisor ('Retrying after '+$_.Exception.GetType().Name) }
        Start-Sleep -Milliseconds 250
    }
} finally {
    if ($agent -and !$agent.HasExited) { Stop-Process -Id $agent.Id -ErrorAction SilentlyContinue }
    $mutex.ReleaseMutex();$mutex.Dispose()
}
