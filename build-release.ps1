$ErrorActionPreference='Stop'
$files=@('agent.cjs','manage.ps1','supervisor.ps1','remove-card.cjs','install.cmd','start.cmd','uninstall.cmd','README.md','LICENSE','NOTICE.md','SECURITY.md','CHANGELOG.md')
$output=Join-Path $PSScriptRoot 'dist'
$archiveName='CodexUsageCard-Windows-0.9.4.3.zip'
$archive=Join-Path $output $archiveName
foreach ($name in $files) {
    if (!(Test-Path -LiteralPath (Join-Path $PSScriptRoot $name) -PathType Leaf)) { throw "Required file missing: $name" }
}
New-Item -ItemType Directory -Path $output -Force | Out-Null
$paths=@($files | ForEach-Object {Join-Path $PSScriptRoot $_})
Compress-Archive -LiteralPath $paths -DestinationPath $archive -Force
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip=[IO.Compression.ZipFile]::OpenRead($archive)
try {
    $entries=@($zip.Entries | ForEach-Object {$_.FullName})
    if (@(Compare-Object ($files | Sort-Object) ($entries | Sort-Object)).Count) { throw 'Archive does not match the public release allowlist.' }
} finally { $zip.Dispose() }
$hash=(Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant()
$checksum=Join-Path $output 'SHA256SUMS.txt'
[IO.File]::WriteAllText($checksum,($hash+'  '+$archiveName+"`n"),(New-Object Text.UTF8Encoding $false))
Write-Output "Built $archiveName ($($files.Count) public source/documentation files)."
Write-Output "$hash  $archiveName"
