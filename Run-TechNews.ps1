param(
 [string]$Server='localhost',
 [ValidatePattern('^[A-Za-z][A-Za-z0-9_]{0,80}$')][string]$Database='TechNewsDemo',
 [ValidateRange(1024,65535)][int]$Port=5199
)
$ErrorActionPreference='Stop'
$oldConnection=$env:ConnectionStrings__BlogDatabase
$oldEnvironment=$env:ASPNETCORE_ENVIRONMENT
try {
 $builder=New-Object System.Data.SqlClient.SqlConnectionStringBuilder
 $builder['Data Source']=$Server;$builder['Initial Catalog']=$Database;$builder['Integrated Security']=$true;$builder['TrustServerCertificate']=$true
 $connection=New-Object System.Data.SqlClient.SqlConnection($builder.ConnectionString)
 try {$connection.Open();$command=$connection.CreateCommand();$command.CommandText="SELECT CASE WHEN COL_LENGTH('ShopOrders','ProvinceCode') IS NOT NULL AND OBJECT_ID('ShopOrderEvents') IS NOT NULL THEN 1 ELSE 0 END";if($command.ExecuteScalar() -ne 1){throw 'Database schema is incomplete. Run database/Install-Database.ps1 first.'}}finally{$connection.Dispose()}
 $env:ConnectionStrings__BlogDatabase=$builder.ConnectionString
 $env:ASPNETCORE_ENVIRONMENT='Development'
 & dotnet run --project (Join-Path $PSScriptRoot 'TechNews/TechNews.csproj') --no-launch-profile --urls "http://localhost:$Port"
 if($LASTEXITCODE -ne 0){throw 'Application failed to start; inspect output above.'}
} finally {$env:ConnectionStrings__BlogDatabase=$oldConnection;$env:ASPNETCORE_ENVIRONMENT=$oldEnvironment}
