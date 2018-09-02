Function Get-PowerPlanInfo
{
    [CmdletBinding()]
    Param (
        [Parameter( Mandatory = $true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','MachineName')]
        [String[]]$ComputerName
    )
    
    BEGIN
    {
        $PowerInfo = @();
    }

    PROCESS 
    {
        $PowerInfo += Get-WmiObject -Class win32_powerplan -Namespace root\cimv2\power `
                        -CN $ComputerName -Filter "isActive='true'" -EA silentlyContinue | 
        ForEach-Object { New-Object -TypeName psobject -Property @{
                                Powerplan = $_.elementName;
                                ComputerName = $_.__Server;
                            }
                        }
    }

    END
    {
        $PowerInfo | Write-Output
    }

<#
    .SYNOPSIS 
      Return current active setting for Power Plan of Computer.
    .DESCRIPTION
      Displays ComputerName and ative Power plan on it.
    .PARAMETER  ComputerName
      List of computer or machine names. This list can be passed either as computer name or through pipeline.
    .EXAMPLE
      $servers = 'Server01','Server02';
      Get-PowerPlanInfo $servers | ft -AutoSize;

      Ouput:-
ComputerName   Powerplan
------------   ---------
Server01       Balanced 
Server02       Balanced 
      
      Server names passed as parameter. Returns all the disk drives for computers Server01 & Server02.

    .LINK
      https://github.com/imajaydwivedi/SQLDBATools
      https://sqlserverperformance.wordpress.com/2010/09/28/windows-power-plans-and-cpu-performance/
 #>
}