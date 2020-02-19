function Set-DbaConfigurations {
<#
    .SYNOPSIS
        This function sets various configuration for SQL Server
    .DESCRIPTION
        This function sets following configurations:-

        Create DBA database
        Set SQL Server Max Memory
        Set SQL Instance DOP
        Configure Secondary Multiple TempDb Files
        Set Sql Instance Configurations like xp_cmdshell, database mail, cost threshold of parallelism
        Set Database Mail Account/Profile/Default Agent Profile
        Set Model database with Optimal Settings
        Setup Self-Service Modules like whoisactive, sp_HealthCheck, etc
        Setup WhoIsActive Baselining
        Compile Ola Scripts
        Setup IndexOptimize Jobs

    .PARAMETER SqlInstance
        Sql Server Instance on which various configurations are to be set up.

    .EXAMPLE
        Set-DbaConfigurations -SqlInstance 'testvm'

        This command sets various configurations on server 'testvm'. For example max memory, dop, etc.

    .LINK
        https://github.com/imajaydwivedi/SQLDBATools

#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias('Server','Instance')]
        [string]$SqlInstance
    )

    $ServerName = $SqlInstance.Split('\')[0];

    # Create Database TSQL
    $tsql_CreateDb = @"
SET NOCOUNT ON;
IF DB_ID('DBA') IS NULL
	CREATE DATABASE DBA;
"@;
    #Write-Debug "Start of executions"
    Write-Verbose "Create if not exists [DBA] database";
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $tsql_CreateDb -Verbose:$false | Out-Null;

    # Set PowerPlan to High Performance
    Write-Verbose "Make sure PowerPlan is set to 'High Performance'";
    Set-DbaPowerPlan -ComputerName $ServerName -PowerPlan 'High Performance' -Verbose:$false | Out-Null;

    # Grant User Rights Assignments Policy permissions for ServiceAccount
    Write-Verbose "Grant User Rights Assignments Policy permissions for ServiceAccount";
    Grant-SqlAccountRequiredPrivileges -SqlInstance $SqlInstance -Verbose:$false | Out-Null;

    # Set SQL Server Max Memory
    Write-Verbose "Set Max SQL Server Memory to ideal value suggested by 'Test-DbaMaxMemory' cmdlet";
    Set-DbaMaxMemory -SqlInstance $SqlInstance -WarningAction SilentlyContinue -Verbose:$false | Out-Null;

    # Set SQL Instance DOP
    Write-Verbose "Set Degree of Parallelism (DOP) to ideal value suggested by 'Test-DbaMaxDop' cmdlet";
    Set-DbaMaxDop -SqlInstance $SqlInstance -WarningAction SilentlyContinue -Verbose:$false | Out-Null;

    # Configure Secondary Multiple TempDb Files
    Write-Verbose "Set TempDbConfiguration as per suggestions by 'Test-DbaTempDbConfig' cmdlet";
    Set-DbaTempdbConfig -SqlInstance $SqlInstance -DataFileSize 8000 -WarningAction SilentlyContinue -Verbose:$false | Out-Null;
    
    # Set Sql Instance Configurations
    Write-Verbose "Set CostThresholdForParallelism to 50";
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name CostThresholdForParallelism -Value 50 -Verbose:$false;

    Write-Verbose "Enable XPCmdShellEnabled, IsSqlClrEnabled, AdHocDistributedQueriesEnabled, OptimizeAdhocWorkloads, DatabaseMailEnabled, RemoteDacConnectionsEnabled";
    Set-DbaSpConfigure -SqlInstance $SqlInstance `
                        -Name XPCmdShellEnabled, IsSqlClrEnabled, AdHocDistributedQueriesEnabled, `
                                OptimizeAdhocWorkloads, DatabaseMailEnabled, RemoteDacConnectionsEnabled `
                        -Value $true -WarningAction SilentlyContinue -Verbose:$false | Out-Null;

    # Set Database Mail Account/Profile/Default Agent Profile
    Write-Verbose "Set MailProfile";
    Set-DbaMailProfile -SqlInstance $SqlInstance -Verbose:$false;

    # Set Model database with Optimal Settings
    Write-Verbose "Set [model] database with Optimal Settings";
    Optimize-modelDatabase -SqlInstance $SqlInstance -WarningAction SilentlyContinue -Verbose:$false | Out-Null;

    # Setup Self-Service Modules
    Write-Verbose "Create Self-Service Modules like sp_WhoIsActive, sp_HealthCheck, sp_Kill etc";
    Set-SelfServiceModules -SqlInstance $SqlInstance -Verbose:$false | Out-Null;

    # Setup WhoIsActive Baselining
    Write-Verbose "Setup WhoIsActive Baselining";
    Set-BaselineWithWhoIsActive -ServerInstance $SqlInstance -Verbose:$false | Out-Null;

    # Compile Ola Scripts
    Write-Verbose "Compile Ola Hallengren Maintenance Scripts";
    Install-OlaHallengrenMaintenanceScripts -SqlInstance $SqlInstance -Verbose:$false | Out-Null;

    # Create DBAGroup Operator
    Write-Verbose "Create DBAGroup Operator";
    Add-SqlAgentOperator -SqlInstance $SqlInstance -OperatorName 'DBAGroup' -EmailId 'It-Ops-DBA@tivo.com' -Verbose:$false | Out-Null;

    # Setup IndexOptimize Jobs
    Write-Verbose "Create IndexOptimize Jobs";
    Set-IndexOptimizeJobs -SqlInstance $SqlInstance -Verbose:$false | Out-Null;

    # Setup DatabaseBackup Jobs
    Write-Verbose "Create DatabaseBackup Jobs";
    Set-DatabaseBackupJobs -SqlInstance $SqlInstance -Verbose:$false | Out-Null;

    # Create Blocking Alert
    Write-Verbose "Create Blocking Alert Job";
    Set-BlockingAlert -SqlInstance $SqlInstance -Verbose -Confirm:$false | Out-Null;
}