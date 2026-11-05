$ErrorActionPreference='Stop'
foreach ($name in @('manage.ps1','supervisor.ps1','build-release.ps1','check.ps1')) {
    $file=Join-Path $PSScriptRoot $name
    $tokens=$null; $parseErrors=$null
    $null=[Management.Automation.Language.Parser]::ParseFile($file,[ref]$tokens,[ref]$parseErrors)
    if ($parseErrors.Count) { $parseErrors | Format-List; throw "PowerShell syntax failed: $name" }
}
foreach ($name in @('agent.cjs','remove-card.cjs','test.cjs')) {
    & node --check (Join-Path $PSScriptRoot $name)
    if ($LASTEXITCODE -ne 0) { throw "JavaScript syntax failed: $name" }
}
& node --test (Join-Path $PSScriptRoot 'test.cjs')
if ($LASTEXITCODE -ne 0) { throw 'Agent tests failed' }
& (Join-Path $PSScriptRoot 'supervisor.ps1') -Check
if ($LASTEXITCODE -ne 0) { throw 'Supervisor checks failed' }
'Source checks passed. No desktop app or installation was started.'
