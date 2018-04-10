Import-Module SQLDBATools -DisableNameChecking;
cls;
$servers = 'TUL1DBAPMTDB1','TUL1CIPEDB2';

Write-Host "Testing Get-VolumeInfo through Parameter values";
Get-ServerInfo $servers | ft -AutoSize;
Write-Host "Testing Get-VolumeInfo through pipeline values";
$servers | Get-VolumeInfo | ft -AutoSize;

Write-Host "Testing Get-ServerInfo through Parameter values";
Get-ServerInfo $servers | ft -AutoSize -Wrap;
Write-Host "Testing Get-ServerInfo through pipeline values";
$servers | Get-ServerInfo | ft -AutoSize -Wrap;
