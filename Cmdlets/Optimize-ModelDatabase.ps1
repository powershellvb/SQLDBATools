function Optimize-ModelDatabase {
<#
.SYNOPSIS
This function sets model databse to Simple recovery and modifies its data/log file size & auto growth
.DESCRIPTION
This function sets model databse to Simple recovery and modifies its data/log file size to 500 MB & 200 MB respectively. Sets auto growth for data file to 500 MB & Log file growth to 200 MB.
.PARAMETER ServerInstance
Sql Server Instance on which [model] database properties are to be optimized
.EXAMPLE
Optimize-modelDatabase -ServerInstance 'testvm'
This command sets model databse to Simple recovery and modifies its data/log file size to 500 MB & 200 MB respectively. Sets auto growth for data file to 500 MB & Log file growth to 200 MB.
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('Server','Instance')]
        [string]$SqlInstance
    )

    # Tsql - Modify model database
    $tsql_Model = @"
USE [master]
GO
ALTER DATABASE [model] SET RECOVERY SIMPLE WITH NO_WAIT
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modeldev', SIZE = 512000KB , FILEGROWTH = 512000KB )
GO
ALTER DATABASE [model] MODIFY FILE ( NAME = N'modellog', SIZE = 204800KB , FILEGROWTH = 204800KB )
GO
"@;
    if($PSCmdlet.ShouldProcess("$SqlInstance")) {
        Write-Verbose "Set [model] database recovery mode to simple. Also, change initial Size and autogrowth appropriately";
        Invoke-DbaQuery -SqlInstance $SqlInstance -Query $tsql_Model | Out-Null;
    }
}