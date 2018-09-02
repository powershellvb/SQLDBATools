$ComputerName = 'TUL1CSPVLXDB1';
Test-WSMan -ComputerName $ComputerName
$Services = @('WinRM','Winmgmt');
Get-Service -ComputerName $ComputerName | Where-Object {$Services -contains $_.Name};

Enable-PSRemoting -Force