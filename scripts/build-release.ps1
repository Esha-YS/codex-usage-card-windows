$ErrorActionPreference='Stop'
$codeFiles=@('agent.cjs','manage.ps1','supervisor.ps1','remove-card.cjs','install.cmd')
$docFiles=@('README.md','LICENSE','SECURITY.md','CHANGELOG.md')
$files=$codeFiles+$docFiles
$repoRoot=Split-Path $PSScriptRoot -Parent
$output=Join-Path $repoRoot 'dist'
$archiveName='CodexUsageCard-Windows-0.9.4.3.zip'
$archive=Join-Path $output $archiveName
$paths=@($codeFiles | ForEach-Object {Join-Path $PSScriptRoot $_})+@($docFiles | ForEach-Object {Join-Path $repoRoot $_})
foreach ($file in $paths) { if (!(Test-Path -LiteralPath $file -PathType Leaf)) { throw "Required file missing: $file" } }
New-Item -ItemType Directory -Path $output -Force | Out-Null
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
Copy-Item -LiteralPath $checksum -Destination (Join-Path $repoRoot 'SHA256SUMS.txt') -Force
Write-Output "Built $archiveName ($($files.Count) public source/documentation files)."
Write-Output "$hash  $archiveName"

