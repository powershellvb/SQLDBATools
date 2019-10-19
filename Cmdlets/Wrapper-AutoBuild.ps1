<# 
https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_variables?view=powershell-6#using-splatting
Install-Module -Name CredentialManagement -Scope AllUsers;
Add-StoredCredentials -Target 'DevSQL' -UserName 'Contso\SQLServices' -Password 'Pa$$w0rd';
Add-StoredCredentials -Target 'SQL_sa' -UserName 'sa' -Password 'Pa$$w0rd';
#>
cls

$ServerName = 'testvm4'; # INPUT 01
$SQLServiceAccount = 'Corporate\DevSQL'; # INPUT 02
$SetupFolder = 'E:\Developer' # INPUT 03

$StartTime = Get-Date;
$ssn = New-PSSession -ComputerName $ServerName;
$SQLServiceAccountPassword = (Get-StoredCredentials -Target ($SQLServiceAccount.Split('\')[1]) | Select-Object -ExpandProperty Password) | Show-Password;
$SAPassword = ((Get-StoredCredentials -Target 'SQL_sa').Password | Show-Password);
$Params = @{
            InstanceName = "MSSQLSERVER";
            SQLServiceAccount = $SQLServiceAccount;
            SQLServiceAccountPassword = $SQLServiceAccountPassword;
            SAPassword = $SAPassword;
            Administrators = "Corporate\SQL Admins";
            #SqlSetupPath = $SetupFolder
}
$ScriptBlock = {
    Start-Process powershell -Verb runAs;
    $Params = $Using:Params;
    $SetupFolder = $Using:SetupFolder;
    Set-Location -Path $SetupFolder;
    #runas /user:administrator "C:\Users\TechSpot\Desktop\file.exe"
    .\AutoBuild.ps1 @Params
}
# Install SQL Server
$rs = $null;
#$rs = 
Invoke-Command -Session $ssn -ScriptBlock $ScriptBlock
$outputFile = "C:\temp\SQL-Install-on-$ServerName.txt";
$rs | Out-File -FilePath $outputFile -Force;

notepad $outputFile

$EndTime_Install = Get-Date;

Write-Host "Start Time: $StartTime";
Write-Host "Installation finish Time: $EndTime_Install";

Remove-PSSession $ssn
Get-PSSession | Remove-PSSession