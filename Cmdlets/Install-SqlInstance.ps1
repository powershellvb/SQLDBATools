function Install-SqlInstance {
<#
    .SYNOPSIS
    This function installs and configures SQL Server on computer
    .DESCRIPTION
    This function take ServerName, SQLServiceAccount, InstanceName etc as parameters, and installl SQL Server on Server.
    .PARAMETER ServerName
    Name of the Server where SQL Services will be installed
    .PARAMETER Version
    Select appropriate Sql Server version. Available options are 2014, 2016, 2017 and 2019.
    .PARAMETER Edition
    Select appropriate Sql Edition to install. Available options are Developer, Enterprise, Standard and Express.
    .PARAMETER SQLServiceAccount
    SQL Server Service account to choose out of "Corporate\DevSQL", "Corporate\ProdSQL" and "Corporate\QASQL". By default 'Corporate\DevSQL' is passed.
    .PARAMETER InstanceName
    Name of the Instance. By default assumed to be default installation 'MSSQLSERVER'.
    .PARAMETER SQLServiceAccountPassword
    Password for SQL Service account. By Default will be fetched from SQLDBATools Inventory.
    .PARAMETER SAPassword
    Password for SA account. By Default will be fetched from SQLDBATools Inventory.
    .PARAMETER Administrators
    AD accounts that are to be made SysAdmin in SqlInstance. By default, 'Coprorate\SQL Admins' is added.
    .PARAMETER SetupParentFolderOnTarget
    Path on target Server where the SQL Server setup would be copied from Inventory.
    .PARAMETER ModifyConfigFile
    With this switch, Installation will allow to change the settings like data/log/tempdb/root directories inside ConfigurationFile.ini file before Sql Installation.
    .PARAMETER PerformDBAConfigurations
    With this switch, Post Installation, all the DBA configurations will be applied through function Set-DbaConfigurations.
    .EXAMPLE
    Install-SqlInstance -ServerName 'testvm' -Version 2014 -Edition 'Developer' -PerformDBAConfigurations
    This command will install SQL Server 2014 Developer edition as default instance on server 'testvm' with all other default parameter values.
    Also perform DBA configurations like adding DBA database, optimizing settings of model database etc. To perform this, a call to Set-DbaConfigurations is made.
    .EXAMPLE
    Install-SqlInstance -ServerName 'testvm' -Version 2014 -Edition 'Developer' -SQLServiceAccount 'Corporate\ProdSQL'
    This command will install SQL Server 2014 Developer edition as default instance on server 'testvm' using 'Corporate\ProdSQL' as service account with all other default parameter values.
    .EXAMPLE
    Install-SqlInstance -ServerName 'testvm' -Version 2014 -Edition 'Developer' -ModifyConfigFile -Confirm:$false 
    This command will wait for user to modify 'Configurationfile.ini' from copied target setup before proceeding with default SQL instance installation with SQL Server 2014 Developer edition.
    .LINK
    https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$True, ConfirmImpact='High')]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias('ComputerName')]
        [String]$ServerName,

        [Parameter(Mandatory=$true)]
        [ValidateSet(2014, 2016, 2017, 2019)]
        [String] $Version = 2014,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Developer','Enterprise','Standard','Express')]
        [String] $Edition = 'Developer',

        [Parameter(Mandatory=$false)]
        [ValidateSet("Corporate\DevSQL", "Corporate\ProdSQL", "Corporate\QASQL")]
        [string] $SQLServiceAccount = 'Corporate\DevSQL',

        [Parameter(Mandatory=$false)]
        [string] $InstanceName = 'MSSQLSERVER',

        [Parameter(Mandatory=$false)]
        [string] $SQLServiceAccountPassword,

        [Parameter(Mandatory=$false)]
        [string] $SAPassword,

        [Parameter(Mandatory=$false)]
        [string] $Administrators = 'Corporate\SQL Admins',
        
        [Parameter(Mandatory=$false)]
        [string] $SetupParentFolderOnTarget = 'C:\',

        [Parameter(Mandatory=$false)]
        [switch] $ModifyConfigFile,

        [Parameter(Mandatory=$false)]
        [Alias('PerformPostInstallationSteps')]
        [switch] $PerformDBAConfigurations,

        [Parameter(Mandatory=$false)]
        [switch] $RebootIfRequired
    )

    if($SetupParentFolderOnTarget.EndsWith('\') -eq $false){$SetupParentFolderOnTarget += '\'};

    Write-Verbose "Creating credential for SQLDBATools for PSRemoting";
    $InventoryServerName = $Global:InventoryInstance.Split('\')[0];
    $CurrentHostName = $env:COMPUTERNAME;

    # File Path for Credentials & Key
        # Check if Host & Inventory Server are same
    if($InventoryServerName -eq $CurrentHostName) {
        $SQLDBATools = Get-Module -ListAvailable -Name SQLDBATools | Select-Object -ExpandProperty ModuleBase;
        $AESKeyFilePath = "$SQLDBATools\SQLDBATools_AESKey.key";
        $credentialFilePath = "$SQLDBATools\SQLDBATools_Credentials.xml";
    }else {
        $SQLDBATools = Invoke-Command -ComputerName $InventoryServerName -ScriptBlock {Get-Module -ListAvailable -Name SQLDBATools | Select-Object -ExpandProperty ModuleBase;}
        $AESKeyFilePath = "\\$InventoryServerName\$($SQLDBATools.Replace(':','$'))\SQLDBATools_AESKey.key";
        $credentialFilePath = "\\$InventoryServerName\$($SQLDBATools.Replace(':','$'))\SQLDBATools_Credentials.xml";
    }
    
    [string]$SQL_Server_Setups = $Global:SQL_Server_Setups;
    if($SQL_Server_Setups.EndsWith('\') -eq $false){$SQL_Server_Setups += '\'};
    [string]$userName = $Global:SQLDBATools_CorporateAccount;
    

    # Create credential Object
    $AESKey = Get-Content $AESKeyFilePath;
    $pwdTxt = (Import-Clixml $credentialFilePath | Where-Object {$_.UserName -eq $userName}).Password;

    [SecureString]$securePwd = $pwdTxt | ConvertTo-SecureString -Key $AESKey;
    [PSCredential]$credentialObject = New-Object System.Management.Automation.PSCredential -ArgumentList $userName, $securePwd;

    Write-Verbose "Registering PSSessionConfiguration for SQLDBATools";
    # Create PSSessionConfig
    $ScriptBlock = { 
        $PSConfigEnabled = $false; Get-PSSessionConfiguration -Name SQLDBATools -ErrorAction SilentlyContinue | ForEach-Object {$PSConfigEnabled = $_.Enabled} | Out-Null;
        if($PSConfigEnabled -eq $false) { Register-PSSessionConfiguration -Name SQLDBATools -RunAsCredential $Using:credentialObject -Force -WarningAction Ignore; }
    }
    Invoke-Command -ComputerName $ServerName -ScriptBlock $ScriptBlock;

    Write-Verbose "Starting PSRemoting Session to perform SQL Installation";
    $scriptBlock = {
        $VerbosePreference = $Using:VerbosePreference;
        $ConfirmPreference = $Using:ConfirmPreference;
        $WhatIfPreference = $Using:WhatIfPreference;
        $DebugPreference = $Using:DebugPreference;

        $SQL_Server_Setups = $Using:SQL_Server_Setups;
        $Version = $Using:Version;
        $Edition = $Using:Edition;
        $SetupFolder = $SQL_Server_Setups+"$Version\$Edition";       
        $SQLServiceAccount = $Using:SQLServiceAccount;
        $SetupFolder_Local = $Using:SetupParentFolderOnTarget;
        $InstanceName = $Using:InstanceName;
        $SQLServiceAccountPassword = $Using:SQLServiceAccountPassword;
        $SAPassword = $Using:SAPassword;
        $Administrators = $Using:Administrators;

        # Copy Setup File
        Write-Verbose "Copying SQL Server setup from path '$SetupFolder' to '$SetupFolder_Local' ..";
        #if(-not (Test-Path -Path "$($SetupFolder_Local)$Edition\") ) {
        if(-not (Test-Path -Path "$SetupFolder_Local\$Version`_$Edition\") ) {
            #Copy-Item "$SetupFolder" -Destination "$SetupFolder_Local" -Recurse -Force;
            Copy-Item -Path "$SetupFolder" -Destination "$SetupFolder_Local\$Version`_$Edition\" -Recurse -Force;
        }

        $response = "YES";
        if($Using:ModifyConfigFile) {
            Write-Output "Kindly make required changes in below Configfile: `nnotepad '\\$($env:COMPUTERNAME)\$($SetupFolder_Local.Replace(':','$'))$Version`_$Edition\ConfigurationFile.ini'`n";
            $response = Read-Host "Type `"YES`" if you are done with Configuration change";
            if($response -ne "YES") {$response = "NO"}
        }

        if($response -ne "YES") {
            Write-Output "Yes, response was not received. So exiting SQL Installation."; return;
        }

        # Start Sql Server Installation
        Set-Location "$($SetupFolder_Local)$Version`_$Edition\";

        Write-Verbose "Starting SQL Server setup from path '$($SetupFolder_Local)$Version`_$Edition\' ..";
        Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope Process | Out-Null;
        . .\AutoBuild.ps1; AutoBuild -SQLServiceAccount $SQLServiceAccount -InstanceName $InstanceName -SQLServiceAccountPassword $SQLServiceAccountPassword -SAPassword $SAPassword -Administrators $Administrators;
    }
    
    if($PSCmdlet.ShouldProcess("$ServerName")) {
        Invoke-Command -ComputerName $ServerName -ScriptBlock $scriptBlock -ConfigurationName SQLDBATools -ErrorVariable err;
    }
    
    Write-Verbose "Installation portion ended.";

    if($RebootIfRequired) {
        Write-Verbose "Rebooting server $ServerName using Set-ServerState";
        Set-ServerState -ServerName $ServerName -Reboot -Force;

        $SQLServiceName = if($InstanceName -eq 'MSSQLSERVER'){'MSSQLSERVER'}ELSE{"MSSQL`$$InstanceName"}
        $EndTime = (Get-Date).AddMinutes(10);
        Do {
            Start-Sleep -Seconds 20;
            try {
                $SQLService = Get-WmiObject win32_service -ComputerName $ServerName -Filter "name='$SQLServiceName'" -ErrorAction Stop -ErrorVariable err;
            } catch {
                if($err.ErrorRecord.Exception.Message.Contains('The RPC server is unavailable')){
                    Write-Verbose "Server is stil rebooting";
                }                
            }
        } while($EndTime.CompareTo([System.DateTime]::Now) -gt 0 -and [string]::IsNullOrEmpty($SQLService)); # Wait for 5 minutes

        Write-Verbose "Server is up again after reboot"
    }

    if($PerformDBAConfigurations) {
        Write-Verbose "Proceeding for Post Instalaltion Configurations using Set-DbaConfigurations";
        Set-DbaConfigurations -SqlInstance $SqlInstance        
    }

    if($RebootIfRequired) {
        Write-Verbose "Rebooting server $ServerName using Set-ServerState";
        Set-ServerState -ServerName $ServerName -Reboot -Force;
        
        $SQLServiceName = if($InstanceName -eq 'MSSQLSERVER'){'MSSQLSERVER'}ELSE{"MSSQL`$$InstanceName"}
        $EndTime = (Get-Date).AddMinutes(10);
        Do {
            Start-Sleep -Seconds 20;
            try {
                $SQLService = Get-WmiObject win32_service -ComputerName $ServerName -Filter "name='$SQLServiceName'" -ErrorAction Stop -ErrorVariable err;
            } catch {
                if($err.ErrorRecord.Exception.Message.Contains('The RPC server is unavailable')){
                    Write-Verbose "Server is stil rebooting";
                }                
            }
        } while($EndTime.CompareTo([System.DateTime]::Now) -gt 0 -and [string]::IsNullOrEmpty($SQLService)); # Wait for 5 minutes

        Write-Verbose "Server is up again after reboot"
        Write-Output "Configuration of server is complete";
    }
}