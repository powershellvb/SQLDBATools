$machine = 'BAN-1ADWIVEDI-L'

Import-Module SQLPS -DisableNameChecking;

Set-Location "SQLSERVER:\SQL\$machine";

$instance = "SQLSERVER:\SQL\$machine\DEFAULT";
