Function Get-DatabasePermissions {
<#
.SYNOPSIS 
Get users and permissions for server and databases
.DESCRIPTION
This function accepts sql instance and database name, and scripts out all the permissions
.PARAMETER SqlInstance
Name of the Sql Server Instance for which permissions are to be scripted out
.PARAMETER Database
Name(s) of database for which permissions are to be scripted out
.EXAMPLE
Get-DatabasePermissions -SqlInstance TestVm
Scripts out all permission for user databases on TestVm instance
.EXAMPLE
Get-DatabasePermissions -SqlInstance TestVm -Database DBA
Scripts out all permission for user database [DBA] on TestVm instance
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','ServerInstance')]
        [String]$SqlInstance = (Read-Host "Enter SqlInstance"),

        [Parameter(Mandatory=$false)]
        [Alias('DatabaseName')]
        [String[]]$Database
    )

    BEGIN {
        Write-Verbose "Creating connection to $SqlInstance"
        $con = Connect-DbaInstance -SqlInstance $SqlInstance;

        # Create folder for storing result files
        $fldr = New-Item -Path "C:\temp\$(Get-Date -Format ddMMMyyyyTHHmm)" -ItemType Directory;
        New-Item -Path "$($fldr.FullName)\DatabasePermissions" -ItemType Directory | Out-Null;
        $scriptPath = "$($fldr.FullName)\DatabasePermissions";
        Write-Verbose "Saving Script files into path '$scriptPath'"
    }
    PROCESS {
        if ($_ -ne $null)
        {
            $ComputerName = $_;
            Write-Verbose "Parameters received from PipeLine.";
        }
        
        Write-Verbose "Scanning TSQL script files to be executed";
        $migration_scriptout_database_permissions_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\migration.scriptout.database.permissions.sql";
        #$migration_scriptout_database_permissions_File;
        #Get-Content -Path $migration_scriptout_database_permissions_File
        if ([String]::IsNullOrEmpty($Database)) {
            $Database = Invoke-DbaQuery -SqlInstance $con -Query 'select name from sys.databases' | Select-Object -ExpandProperty name;
        }

        foreach($db in $Database) {
            Write-Verbose "Processing for database $db"
            $output = Invoke-DbaQuery -SqlInstance $con -Database $db -MessagesToOutput `
                                    -File $migration_scriptout_database_permissions_File;

            # Save result in file
            $ResultFile = $scriptPath+'\'+$db+'.sql';
            $output | Out-File $ResultFile;
        }
    }
    END{
        Write-Output $scriptPath;
    }    
}    
