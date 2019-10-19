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

    .EXMAPLE
        Set-DbaConfigurations -SqlInstance 'testvm'

        This command sets various configurations on server 'testvm'. For example max memory, dop, etc.

    .LINK
        https://github.com/imajaydwivedi/SQLDBATools

#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [Alias('Server','Instance')]
        [string]$SqlInstance
    )

    Write-Verbose "SqlInstance = $SqlInstance";

    # Create Database TSQL
    $tsql_CreateDb = @"
SET NOCOUNT ON;
IF DB_ID('DBA') IS NULL
	CREATE DATABASE DBA;
"@;
    Invoke-DbaQuery -SqlInstance $SqlInstance -Query $tsql_CreateDb;

    # Set SQL Server Max Memory
    Set-DbaMaxMemory -SqlInstance $SqlInstance;

    # Set SQL Instance DOP
    Set-DbaMaxDop -SqlInstance $SqlInstance;

    # Configure Secondary Multiple TempDb Files
    Set-DbaTempdbConfig -SqlInstance $SqlInstance -DataFileSize 8000;

    # Set Sql Instance Configurations
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name XPCmdShellEnabled -Value 1;
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name IsSqlClrEnabled -Value 1;
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name CostThresholdForParallelism -Value 50;
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name AdHocDistributedQueriesEnabled -Value 1;
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name OptimizeAdhocWorkloads -Value 1;
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name DatabaseMailEnabled -Value 1;
    Set-DbaSpConfigure -SqlInstance $SqlInstance -Name RemoteDacConnectionsEnabled -Value 1;

    # Set Database Mail Account/Profile/Default Agent Profile
    Set-DbaMailProfile -ServerInstance $SqlInstance 

    # Set Model database with Optimal Settings
    Optimize-modelDatabase -SqlInstance $SqlInstance;

    # Setup Self-Service Modules
    Set-SelfServiceModules -SqlInstance $SqlInstance;

    # Setup WhoIsActive Baselining
    Set-BaselineWithWhoIsActive -ServerInstance $SqlInstance;

    # Compile Ola Scripts
    Install-OlaHallengrenMaintenanceScripts -SqlInstance $SqlInstance;

    # Setup IndexOptimize Jobs
    Set-IndexOptimizeJobs -SqlInstance $SqlInstance;
}
<#
    DBA Database -> Ola, LogWalk Objects, Login Permission Issue Tracking
    Add to Inventory - ServerInfo, InstanceInfo, VolumeInfo, DatabaseInfo
    Job History 270 days
    Use master
    GO
    /* 0 = Allow Local Connection, 1 = Allow Remote Connections*/ 
    sp_configure 'remote admin connections', 1 
    GO
    RECONFIGURE
    GO
#>
