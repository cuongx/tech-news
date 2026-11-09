param([string]$Database='TechNews_Verification_20261025')
$ErrorActionPreference='Stop'
if($Database -notmatch '^TechNews_Verification_'){throw 'Use a dedicated verification database.'}
$repo=Split-Path $PSScriptRoot
$env:ConnectionStrings__BlogDatabase="Server=localhost;Database=$Database;Trusted_Connection=True;TrustServerCertificate=True"
$env:TEST_URL='http://127.0.0.1:5299'
$server=Start-Process dotnet -ArgumentList 'bin/Verification/TechNews.dll --urls http://127.0.0.1:5299' -WorkingDirectory (Join-Path $repo 'TechNews') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $PSScriptRoot 'server.log') -RedirectStandardError (Join-Path $PSScriptRoot 'server-error.log')
try {
 for($attempt=0;$attempt -lt 30;$attempt++) {if($server.HasExited){throw 'Verification server exited.'};try{Invoke-WebRequest "$env:TEST_URL/Admin/Login" -UseBasicParsing -TimeoutSec 2|Out-Null;break}catch{Start-Sleep -Milliseconds 500}}
 foreach($test in @('stability.cjs','features.cjs','accounts-assets.cjs')){node (Join-Path $PSScriptRoot $test);if($LASTEXITCODE -ne 0){throw "$test failed"}}
} finally {if(!$server.HasExited){Stop-Process -Id $server.Id}}
