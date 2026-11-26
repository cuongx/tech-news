param(
 [string]$Server='localhost',
 [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,80}$')][string]$Database='TechNews'
)
$ErrorActionPreference='Stop'
if(!(Get-Command sqlcmd -ErrorAction SilentlyContinue)){throw 'Install SQL Server command-line utilities (sqlcmd), or open database/TechNews.Full.sql in SSMS with SQLCMD Mode enabled.'}
$sql=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'TechNews.Full.sql')).Replace('[TechNews]',('['+$Database+']')).Replace("N'TechNews'",("N'"+$Database+"'"))
$temp=Join-Path ([IO.Path]::GetTempPath()) ('technews-install-'+[Guid]::NewGuid().ToString('N')+'.sql')
try {
 [IO.File]::WriteAllText($temp,$sql,(New-Object Text.UTF8Encoding($true)))
 & sqlcmd -S $Server -E -C -b -f 65001 -i $temp
 if($LASTEXITCODE -ne 0){throw 'Database installation failed. Existing databases are never overwritten. Inspect the SQL error above.'}
 Write-Output "Database ready: $Server / $Database. Demo logins: admin / 12345; customer / 12345."
} finally {if(Test-Path -LiteralPath $temp){Remove-Item -LiteralPath $temp}}
