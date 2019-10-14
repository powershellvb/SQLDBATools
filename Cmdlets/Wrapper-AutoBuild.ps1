<# 
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_variables?view=powershell-6#using-splatting
Install-Module -Name CredentialManagement -Scope AllUsers;
Add-StoredCredentials -Target 'DevSQL' -UserName 'Contso\SQLServices' -Password 'Pa$$w0rd';
Add-StoredCredentials -Target 'SQL_sa' -UserName 'sa' -Password 'Pa$$w0rd';
#>

$ServerName = $env:COMPUTERNAME; # INPUT 01
$SQLServiceAccount = 'Corporate\DevSQL'; # INPUT 02
$SetupFolder = 'E:\Softwares\SQLServer2016' # INPUT 03

$ssn = New-PSSession -ComputerName $ServerName;
$SQLServiceAccountPassword = (Get-StoredCredentials -Target ($SQLServiceAccount.Split('\')[1]) | Select-Object -ExpandProperty Password) | Show-Password;
$SAPassword = ((Get-StoredCredentials -Target 'SQL_sa').Password | Show-Password);
$Params = @{
            InstanceName = "MSSQLSERVER";
            SQLServiceAccount = $SQLServiceAccount;
            SQLServiceAccountPassword = $SQLServiceAccountPassword;
            SAPassword = $SAPassword;
            Administrators = "Corporate\SQL Admins";
}
$ScriptBlock = {
    Set-Location -Path $Using:SqlSetupPath;
    #runas /user:administrator "C:\Users\TechSpot\Desktop\file.exe"
    .\AutoBuild.ps1 @Using:Params
}
Invoke-Command -Session $ssn -ScriptBlock $ScriptBlock;

$InstanceName = "SQL2016";
$configFile = 'E:\Softwares\SQLServer2016\ConfigurationFile.ini';
$configFileContent = Get-Content $configFile;

$configFileContent.Replace("MSSQLSERVER",$InstanceName)
