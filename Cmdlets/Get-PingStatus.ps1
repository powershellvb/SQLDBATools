function Get-PingStatus {
<#
    .SYNOPSIS
    Get Ping Result for a computer
    .DESCRIPTION
    Accepts computer name and returns Ping result
    .PARAMETER ComputerName
    Name of machine which has to be pinged
    .EXAMPLE
    Get-PingStatus -ComputerName dbsep1234
    .LINK
    https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true,
                    Mandatory=$true, Position=1)]
        [Alias('ServerName')]
        [string]$ComputerName = $env:COMPUTERNAME
    )
    BEGIN {
        foreach($srv in $ComputerName) {
            if ($_ -ne $null) {
                $ComputerName = $_;
                Write-Verbose "Value received from pipeline";
            }
        }
    }
    PROCESS {
    $Timeout = 100
    $Ping = New-Object System.Net.NetworkInformation.Ping
    $Response = $Ping.Send($machine,$Timeout)
    $Response.Status
    }
    END {
    }
}
