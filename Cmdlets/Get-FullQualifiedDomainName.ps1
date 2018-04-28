Function Get-FullQualifiedDomainName #Get-FQN, Get-FQDN
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName')]
        [String[]]$ComputerName
    )
    [System.Net.Dns]::GetHostByName("$ComputerName")  | FL HostName | Out-String | %{ "{0}" -f $_.Split(':')[1].Trim() };
}