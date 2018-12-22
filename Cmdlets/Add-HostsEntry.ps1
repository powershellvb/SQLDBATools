function Add-HostsEntry
{
    <#
    .SYNOPSIS
    Sets a hosts entry in a hosts file of HostFileComputer.
    
    .DESCRIPTION
    Sets the IP address for a given hostname inside HostFileComputer. 
    
    .EXAMPLE
    Set-HostsEntry -IPAddress 10.10.10.2 -HostName 'Host'

    .EXAMPLE        
    Set-HostsEntry -IPAddress 10.10.10.2 -HostName 'Host' -HostFileComputer 'SQL-A.contso.com'
    
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Net.IPAddress]
        # The IP address for the hosts entry.
        $IPAddress,

        [Parameter(Mandatory=$true)]
        [string]
        # The hostname for the hosts entry.
        $HostName,
        
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','ComputerName')]
        [String[]]$HostFileComputer = $env:COMPUTERNAME
    )

    $EntryString = @"
$IPAddress		$HostName
"@;
    
    $hostsFilePath = 'C:\Windows\System32\drivers\etc\hosts';
    if($HostFileComputer -ne $env:COMPUTERNAME) {
        $hostsFilePath = "\\$HostFileComputer\" + $hostsFilePath.Replace(':','$')
    }

    Add-Content -Path $hostsFilePath -Value $EntryString;
    Write-Verbose "Host Entry made successfully";
    
}