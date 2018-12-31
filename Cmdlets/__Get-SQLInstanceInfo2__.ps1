Function Get-SQLInstanceInfo2
{
    <#
        .SYNOPSIS
            Retrieves SQL Server instance general information.

        .DESCRIPTION
            Retrieves SQL Server instance general information based on ComputerName parameter value.

        .NOTES
            Name: Discover-SQLInstances
            Author: Ajay Dwivedi

        .EXAMPLE
            Get-SQLInstanceInfo -ComputerName $env:COMPUTERNAME

            Description
            -----------
            Retrieves SQL Server instance general information based on ComputerName parameter value.

        .LINK
            https://www.mssqltips.com/sqlservertip/2013/find-sql-server-instances-across-your-network-using-windows-powershell/
    #>

    [CmdletBinding()]
    Param(
        <#
        [Parameter( Mandatory=$true,
                    ParameterSetName="InfoBySqlInstance",
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [String[]]$SqlInstance = $env:COMPUTERNAME,
        #>
        [Parameter( Mandatory=$true,
                    ParameterSetName="InfoByServerName",
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [String[]]$ServerName = $env:COMPUTERNAME,
        
        [Parameter(Mandatory=$false)]
        [Switch]$LogErrorInInventory
    )
    BEGIN 
    {
        $Check = $false;
        $Result = @();
        $InstanceInfo = @();
    }
    PROCESS
    {
        # Loop through each machines
        foreach($machine in $ServerName)
        {
            # Reset with each loop
            $Discover = $true;
            $instances = @();
            Write-Host "Starting:- Searching for instances on $machine" -ForegroundColor Yellow;

            if ([String]::IsNullOrEmpty($machine) -or (Test-Connection -ComputerName $machine -Count 1 -Quiet) -eq $false)
            {
                $MessageText = "(Get-SQLInstanceInfo)=> Supplied value '$machine' for ServerName parameter is invalid, or server is not accessible.";
                Write-Host $MessageText -ForegroundColor Red;
                Continue;
            }
            else
            {
                $fqn = (Get-FullQualifiedDomainName -ComputerName $machine);
                if([String]::IsNullOrEmpty($machine)) 
                {
                    Write-Host "(Get-FullQualifiedDomainName)=> Server '$machine' is not reachable." -ForegroundColor Red;
                    Continue;
                }
            }

            $instances = Find-DbaInstance -ComputerName $machine;
            foreach($sqlInstance in $instances)
            {
                $info = Get-DbaInstanceProperty -SqlInstance $sqlInstance;
                $productKey = (Get-DbaProductKey -ComputerName $sqlInstance.ComputerName | Where-Object {$_.SqlInstance -eq $sqlInstance.SqlInstance}).Key;
                if( ($info | Where-Object {$_.Name -eq 'ResourceVersionString'} | Select-Object -ExpandProperty Value) -match "^\d{1,2}\.\d{1,2}\.(?'Build'\d{2,4})$") {
                    $Build = $Matches['Build'] 
                };
    
                $instanceProps = [Ordered]@{
                        'SqlInstance' = $sqlInstance.SqlInstance;
                        'Server' = $sqlInstance.ComputerName;
                        'InstanceName' = $sqlInstance.InstanceName;
                        'RootDirectory' = $info | Where-Object {$_.Name -eq 'RootDirectory'} | Select-Object -ExpandProperty Value;
                        'Version' = $info | Where-Object {$_.Name -eq 'VersionString'} | Select-Object -ExpandProperty Value;
                        'CommonVersion' = ($info | Where-Object {$_.Name -in ('VersionMajor','VersionMinor')} | Select-Object -ExpandProperty Value) -join '.';
                        'Build' = $Build;
                        #'VersionString' = $null;
                        'Edition' = $info | Where-Object {$_.Name -eq 'Edition'} | Select-Object -ExpandProperty Value;
                        'Collation' = $info | Where-Object {$_.Name -eq 'Collation'} | Select-Object -ExpandProperty Value;
                        'ProductKey' =  if($productKey -notlike "*Could not read*") {$productKey} else {$null};
                        'DefaultDataLocation' = $info | Where-Object {$_.Name -eq 'DefaultFile'} | Select-Object -ExpandProperty Value;
                        'DefaultLogLocation' = $info | Where-Object {$_.Name -eq 'DefaultLog'} | Select-Object -ExpandProperty Value;
                        'DefaultBackupLocation' = $info | Where-Object {$_.Name -eq 'BackupDirectory'} | Select-Object -ExpandProperty Value;
                        'ErrorLogPath' = $info | Where-Object {$_.Name -eq 'ErrorLogPath'} | Select-Object -ExpandProperty Value;
                        'MasterDBPath' = $info | Where-Object {$_.Name -eq 'MasterDBPath'} | Select-Object -ExpandProperty Value;
                        'MasterDBLogPath' = $info | Where-Object {$_.Name -eq 'MasterDBLogPath'} | Select-Object -ExpandProperty Value;
                        'Port' = $sqlInstance.Port;
                        'IsStandaloneInstance' = 0;
                        'IsSqlCluster' = 0;
                        'IsAgListener' = 0;
                        'IsAGNode' = 0;
                        'AGListenerName' = $null;
                        'HasOtherHASetup' = 0;
                        'HARole' = '';
                        'HAPartner' = '';
        
                }
                $instanceObj = New-Object -TypeName PSObject -Property $instanceProps;
                $InstanceInfo += $instanceObj;    
            }
        } # process loop
    }
    END
    {
        Write-Output $InstanceInfo;
    }
}

$Server = @('tul1cipedb2','tul1dbapmtdb1','tul1cipcnpdb1');
Get-SQLInstanceInfo -ServerName $Server | ogv

