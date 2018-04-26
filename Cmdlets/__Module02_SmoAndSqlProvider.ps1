$machine = 'TUL1TEDSQLQA1';
Import-Module SQLDBATools -DisableNameChecking;

Get-ChildItem SQLSERVER:\SQL\$machine\DEFAULT\Databases;
