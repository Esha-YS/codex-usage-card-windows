param(
    [ValidateSet('install','start','run','status','uninstall')][string]$Action = 'status',
    [string]$NodePath,
    [string]$InstallRoot = (Join-Path $env:USERPROFILE '.codex\usage-card-windows')
)
$ErrorActionPreference = 'Stop'
$owner = 'codex-usage-card-windows-v1'
$InstallRoot = [IO.Path]::GetFullPath($InstallRoot)
$marker = Join-Path $InstallRoot 'installation.json'
$desktop = [Environment]::GetFolderPath('Desktop')
$shortcutPath = Join-Path $desktop 'Codex 额度卡.lnk'
$taskName = 'Codex Usage Card Windows Embedded'
function Task-Arguments { '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "'+(Join-Path $InstallRoot 'manage.ps1')+'" -Action run' }
function Get-OwnedTask {
    $task=Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task -and ($task.Description -ne $owner -or $task.Actions.Count -ne 1 -or $task.Actions[0].Arguments -ne (Task-Arguments))) { throw 'Startup task belongs to another installation.' }
    return $task
}
function Start-OwnedTask {
    for ($attempt=0; $attempt -lt 15; $attempt++) {
        $task=Get-OwnedTask
        if (!$task) { throw 'Startup task missing.' }
        if ([string]$task.State -ne 'Running') { Start-ScheduledTask -TaskName $taskName }
        Start-Sleep -Milliseconds 500
        try {
            $state=Get-Content -LiteralPath (Join-Path $InstallRoot 'supervisor-status.json') -Raw | ConvertFrom-Json
            $monitor=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$state.pid)
            if ($monitor -and $monitor.CommandLine.Contains('"'+(Join-Path $InstallRoot 'manage.ps1')+'"') -and $monitor.CommandLine.Contains('-Action run') -and ([datetime]::UtcNow-[datetime]::Parse($state.updatedAt).ToUniversalTime()).TotalSeconds -lt 10) { return }
        } catch {}
    }
    throw 'Background monitor did not become ready.'
}
function Stop-Supervisor {
    $statusFile=Join-Path $InstallRoot 'supervisor-status.json'
    $supervisor=$null
    if (Test-Path -LiteralPath $statusFile) {
        try {
            $state=Get-Content -LiteralPath $statusFile -Raw | ConvertFrom-Json
            $native=Get-CimInstance Win32_Process -Filter ('ProcessId='+[int]$state.pid)
            if ($native -and $native.Name -eq 'powershell.exe' -and $native.CommandLine.Contains('"'+(Join-Path $InstallRoot 'manage.ps1')+'"') -and $native.CommandLine.Contains('-Action run')) { $supervisor=Get-Process -Id $native.ProcessId }
        } catch {}
    }
    if (Get-OwnedTask) { Stop-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue }
    if ($supervisor -and !$supervisor.WaitForExit(5000)) { throw 'Previous monitor has not stopped; refusing to run a duplicate.' }
}
trap {
    if ($Action -eq 'start') {
        $message = $_.Exception.Message
        try {
            $message | Set-Content -LiteralPath (Join-Path $InstallRoot 'launch-error.log') -Encoding UTF8
            Add-Type -AssemblyName PresentationFramework
            [System.Windows.MessageBox]::Show($message,'Codex Usage Card') | Out-Null
        } catch {}
    }
    Write-Error $_ -ErrorAction Continue
    exit 1
}
function Shortcut-Arguments {
    '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "' + (Join-Path $InstallRoot 'manage.ps1') + '" -Action start'
}
function Read-Installation {
    if (!(Test-Path -LiteralPath $marker)) { throw 'Installation not found.' }
    $info = Get-Content -LiteralPath $marker -Raw | ConvertFrom-Json
    if ($info.owner -ne $owner) { throw 'Installation ownership mismatch.' }
    return $info
}
function Find-Codex {
    $package = Get-AppxPackage -Name 'OpenAI.Codex' | Select-Object -First 1
    if ($package) {
        foreach ($name in @('ChatGPT.exe','Codex.exe')) {
            $candidate = Join-Path $package.InstallLocation "app\$name"
            if (Test-Path -LiteralPath $candidate -PathType Leaf) { return $candidate }
        }
    }
    throw 'Codex desktop app was not found. Install the official Windows app first.'
}
function Get-CodexProcesses($appExe) {
    @(Get-CimInstance Win32_Process -Filter "Name='ChatGPT.exe' OR Name='Codex.exe'" |
        Where-Object { $_.ExecutablePath -and $_.ExecutablePath.Equals($appExe, [StringComparison]::OrdinalIgnoreCase) })
}
function Stop-OwnedAgent {
    $pidFile = Join-Path $InstallRoot 'agent.pid'
    if (!(Test-Path -LiteralPath $pidFile)) { return }
    $agentPid = [int](Get-Content -LiteralPath $pidFile -Raw)
    $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$agentPid"
    $agentPath = Join-Path $InstallRoot 'agent.cjs'
    if ($proc -and $proc.Name -eq 'node.exe' -and $proc.CommandLine.Contains('"' + $agentPath + '"')) {
        $ownedProcess=Get-Process -Id $agentPid
        Stop-Process -Id $agentPid -ErrorAction Stop
        if (!$ownedProcess.WaitForExit(5000)) { throw 'Previous quota reader has not stopped.' }
    } elseif ($proc) { throw 'PID belongs to another process; refusing to stop it.' }
    Remove-Item -LiteralPath $pidFile -Force
}
switch ($Action) {
    install {
        if (Test-Path -LiteralPath $InstallRoot) {
            if (!(Test-Path -LiteralPath $marker)) { throw 'Destination exists without ownership marker.' }
            $null = Read-Installation
            Stop-Supervisor
            Stop-OwnedAgent
        }
        if (!$NodePath) {
            $foundNode = Get-Command node.exe -ErrorAction SilentlyContinue
            if ($foundNode) { $NodePath = $foundNode.Source }
            else { throw 'Node.js 24+ was not found. Install it from https://nodejs.org/ or pass -NodePath with the full path to node.exe.' }
        }
        $NodePath = (Resolve-Path -LiteralPath $NodePath).Path
        $version = & $NodePath --version
        if ([int]($version.TrimStart('v').Split('.')[0]) -lt 24) { throw 'Node.js 24+ required.' }
        $null = Find-Codex
        $shell = New-Object -ComObject WScript.Shell
        if (Test-Path -LiteralPath $shortcutPath) {
            $existing = $shell.CreateShortcut($shortcutPath)
            $legacyArgs = '"' + (Join-Path $env:LOCALAPPDATA 'CodexUsageCard\launch.vbs') + '"'
            if ($existing.Arguments -ne (Shortcut-Arguments) -and $existing.Arguments -ne $legacyArgs) { throw 'Desktop shortcut belongs to another program.' }
        }
        New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
        foreach ($name in @('agent.cjs','manage.ps1','supervisor.ps1','remove-card.cjs','LICENSE','README.md')) {
            $source = Join-Path $PSScriptRoot $name
            if (!(Test-Path -LiteralPath $source -PathType Leaf) -and $name -in @('README.md','LICENSE')) {
                $source = Join-Path (Split-Path $PSScriptRoot -Parent) $name
            }
            $destination = Join-Path $InstallRoot $name
            if ($source -ne $destination) { Copy-Item -LiteralPath $source -Destination $destination -Force }
        }
        $privateNode=Join-Path $InstallRoot 'node.exe'
        if ($NodePath -ne $privateNode) {
            $sameRuntime=(Test-Path -LiteralPath $privateNode) -and ((Get-FileHash -LiteralPath $privateNode).Hash -eq (Get-FileHash -LiteralPath $NodePath).Hash)
            if (!$sameRuntime) { Copy-Item -LiteralPath $NodePath -Destination $privateNode -Force }
        }
        @{owner=$owner;version='0.9.4-windows.3-embedded';node=$privateNode;port=39222;mode='embedded'} | ConvertTo-Json | Set-Content -LiteralPath $marker -Encoding UTF8
        $shortcut = $shell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $shortcut.Arguments = Shortcut-Arguments
        $shortcut.WindowStyle = 7
        $shortcut.WorkingDirectory = $InstallRoot
        $shortcut.IconLocation = (Find-Codex) + ',0'
        $shortcut.Description = 'Launch Codex with the local usage card'
        $shortcut.Save()
        $account=[Security.Principal.WindowsIdentity]::GetCurrent().Name
        $trigger=New-ScheduledTaskTrigger -AtLogOn -User $account
        $taskAction=New-ScheduledTaskAction -Execute (Join-Path $env:WINDIR 'System32\WindowsPowerShell\v1.0\powershell.exe') -Argument (Task-Arguments) -WorkingDirectory $InstallRoot
        $settings=New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([timespan]::Zero) -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -MultipleInstances IgnoreNew -StartWhenAvailable
        $principal=New-ScheduledTaskPrincipal -UserId $account -LogonType Interactive -RunLevel Limited
        $definition=New-ScheduledTask -Action $taskAction -Trigger $trigger -Settings $settings -Principal $principal -Description $owner
        if (!(Get-OwnedTask)) { Register-ScheduledTask -TaskName $taskName -InputObject $definition | Out-Null }
        Start-OwnedTask
        Write-Output 'Installed persistent embedded quota card. Existing visible sessions are preserved.'
    }
    run {
        $null=Read-Installation
        & (Join-Path $InstallRoot 'supervisor.ps1')
    }
    start {
        $info = Read-Installation
        $appExe = Find-Codex
        $running = Get-CodexProcesses $appExe
        $debugReady = $false
        try {
            $targets = Invoke-RestMethod -Uri "http://127.0.0.1:$($info.port)/json/list" -TimeoutSec 2
            $debugReady = @($targets | Where-Object { $_.type -eq 'page' -and $_.url -match '^app://-/index\.html' }).Count -gt 0
        } catch {}
        if ($running.Count -gt 0 -and !$debugReady) {
            Start-OwnedTask
            Write-Output 'Monitor is running. Fully quit the current session once, then reopen Codex normally.'
            break
        }
        if (!$debugReady) {
            $listener = Get-NetTCPConnection -LocalPort $info.port -State Listen -ErrorAction SilentlyContinue
            if ($listener) { throw 'Local port 39222 is occupied; refusing to use another application.' }
            Start-Process -FilePath $appExe -ArgumentList @('--remote-debugging-address=127.0.0.1',"--remote-debugging-port=$($info.port)") | Out-Null
            for ($attempt=0; $attempt -lt 30; $attempt++) {
                Start-Sleep -Seconds 1
                try { $null = Invoke-RestMethod -Uri "http://127.0.0.1:$($info.port)/json/list" -TimeoutSec 1; $debugReady=$true; break } catch {}
            }
            if (!$debugReady) { throw 'Codex did not expose its local debug endpoint; this client may not support the integration.' }
        }
        $unsafe = @(Get-NetTCPConnection -LocalPort $info.port -State Listen -ErrorAction Stop | Where-Object { $_.LocalAddress -notin @('127.0.0.1','::1') })
        if ($unsafe.Count) { throw 'Debug endpoint is not loopback-only; refusing to connect.' }
        Start-OwnedTask
        Write-Output 'Usage card monitor started. Allow up to 15 seconds for the sidebar card.'
    }
    status {
        $info = Read-Installation
        $task=Get-OwnedTask
        $result = [ordered]@{installed=$true;version=$info.version;nodeAvailable=(Test-Path -LiteralPath $info.node);startupTask=if($task){[string]$task.State}else{'Missing'};debugEndpoint=$false;agentRunning=$false}
        try { $null=Invoke-RestMethod -Uri "http://127.0.0.1:$($info.port)/json/list" -TimeoutSec 2; $result.debugEndpoint=$true } catch {}
        $pidFile = Join-Path $InstallRoot 'agent.pid'
        if (Test-Path -LiteralPath $pidFile) {
            $agentPid = [int](Get-Content -LiteralPath $pidFile -Raw)
            $proc = Get-CimInstance Win32_Process -Filter "ProcessId=$agentPid"
            $result.agentRunning = [bool]($proc -and $proc.Name -eq 'node.exe' -and $proc.CommandLine.Contains('"'+(Join-Path $InstallRoot 'agent.cjs')+'"'))
        }
        $result | ConvertTo-Json
    }
    uninstall {
        $null = Read-Installation
        Stop-Supervisor
        Stop-OwnedAgent
        $info=Read-Installation
        & $info.node (Join-Path $InstallRoot 'remove-card.cjs')
        if (Get-OwnedTask) { Unregister-ScheduledTask -TaskName $taskName -Confirm:$false }
        if (Test-Path -LiteralPath $shortcutPath) {
            $shell = New-Object -ComObject WScript.Shell
            if ($shell.CreateShortcut($shortcutPath).Arguments -eq (Shortcut-Arguments)) { Remove-Item -LiteralPath $shortcutPath }
        }
        # Delete only owned files; preserve any unexpected user files in this folder.
        foreach ($name in @('agent.cjs','supervisor.ps1','remove-card.cjs','node.exe','launch.vbs','LICENSE','README.md','README-Windows.md','supervisor.log','supervisor-status.json','agent.log','agent-error.log','launch-error.log','manage.ps1','installation.json')) {
            $target = [IO.Path]::GetFullPath((Join-Path $InstallRoot $name))
            if (!$target.StartsWith($InstallRoot + '\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Invalid uninstall path.' }
            for ($attempt=0; $attempt -lt 10 -and (Test-Path -LiteralPath $target -PathType Leaf); $attempt++) {
                try { Remove-Item -LiteralPath $target -Force } catch { if ($attempt -eq 9) { throw }; Start-Sleep -Milliseconds 200 }
            }
        }
        Write-Output 'Uninstalled. Fully quit and reopen Codex normally to close the local debug endpoint.'
    }
}
