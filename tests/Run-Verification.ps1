param(
 [ValidatePattern('^TechNews_Verification_[A-Za-z0-9_]+$')][string]$Database='TechNews_Verification_20261025',
 [int]$Port=5299,
 [string]$BuildDirectory,
 [string]$ResultsDirectory
)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot
if(!$BuildDirectory){$BuildDirectory=Join-Path $repo 'TechNews/bin/Verification'}
if(!$ResultsDirectory){$ResultsDirectory=Join-Path $repo 'TestResults'}
New-Item -ItemType Directory -Force -Path $ResultsDirectory | Out-Null
$dll=Join-Path $BuildDirectory 'TechNews.dll'
if(!(Test-Path -LiteralPath $dll)){throw 'Build TechNews.csproj into BuildDirectory before verification.'}
if(Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue){throw "Port $Port is already in use."}
$savedConnection=$env:ConnectionStrings__BlogDatabase
$savedUrl=$env:TEST_URL
$savedDatabase=$env:TEST_DATABASE
$env:ConnectionStrings__BlogDatabase="Server=localhost;Database=$Database;Trusted_Connection=True;TrustServerCertificate=True"
$env:TEST_URL="http://127.0.0.1:$Port"
$env:TEST_DATABASE=$Database
$server=$null
$results=@()
try {
 $server=Start-Process dotnet -ArgumentList "`"$dll`" --urls $env:TEST_URL" -WorkingDirectory (Join-Path $repo 'TechNews') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $ResultsDirectory 'server.log') -RedirectStandardError (Join-Path $ResultsDirectory 'server-error.log')
 $ready=$false
 for($attempt=0;$attempt -lt 40;$attempt++) {
  if($server.HasExited){throw 'Verification server exited.'}
  try{Invoke-WebRequest "$env:TEST_URL/Admin/Login" -UseBasicParsing -TimeoutSec 2|Out-Null;$ready=$true;break}catch{Start-Sleep -Milliseconds 500}
 }
 if(!$ready){throw 'Verification server did not become ready.'}
 foreach($test in @('stability','features','accounts-assets','commerce','cart','orders','admin-orders','account-lists','product-assets','shipping-address')) {
  $started=Get-Date
  $log=Join-Path $ResultsDirectory "$test.log"
  # Windows PowerShell can treat native stderr as an error record. Preserve
  # the process exit code and continue recording other suites on assertion failures.
  $ErrorActionPreference='Continue'
  try { & node (Join-Path $PSScriptRoot "$test.cjs") *> $log; $code=$LASTEXITCODE }
  finally { $ErrorActionPreference='Stop' }
  $results += [PSCustomObject]@{suite=$test;exitCode=$code;started=$started.ToString('o');seconds=[Math]::Round(((Get-Date)-$started).TotalSeconds,2);log="$test.log"}
  $results | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ResultsDirectory 'results.json')
  Write-Output "$test : exit $code"
 }
 $results | ConvertTo-Json -Depth 4 | Set-Content -Encoding UTF8 (Join-Path $ResultsDirectory 'results.json')
 if($results | Where-Object {$_.exitCode -ne 0}){throw 'Verification failed; inspect results.json and suite logs.'}
} finally {
 if($server -and !$server.HasExited){Stop-Process -Id $server.Id}
 $env:ConnectionStrings__BlogDatabase=$savedConnection
 $env:TEST_URL=$savedUrl
 $env:TEST_DATABASE=$savedDatabase
}
