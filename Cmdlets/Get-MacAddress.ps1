function Get-MacAddress
{
    [CmdletBinding()]
    Param (
        [String[]]$ComputerName,
        [String]$ExcelPath = "$PSScriptRoot\SQL-Server-Lab-IPv4-Settings.xlsx",
        [Switch]$IncludeRawMACAddress,
        [Switch]$AllComputers
    )
    

    if([String]::IsNullOrEmpty($ComputerName)) {
        $ComputerName = $env:COMPUTERNAME
    }

    $ExcelData = @();
    $ExcelData = Import-Excel -Path $ExcelPath -WorksheetName 'IPv4-Windows' -StartRow 2 -DataOnly;
    $ExcelData += Import-Excel -Path $ExcelPath -WorksheetName 'IPv4-Linux' -StartRow 2 -DataOnly;
    $ExcelData += Import-Excel -Path $ExcelPath -WorksheetName 'Client-Desktops' -StartRow 2 -DataOnly;
    $ExcelData += Import-Excel -Path $ExcelPath -WorksheetName 'Monitoring & Support' -StartRow 2 -DataOnly;

    $SkipNames = @('Router','Host')
    $FilteredData = $ExcelData | Where-Object {$_.'Machine Name' -notin $SkipNames}

    if(-not $AllComputers) {
        $FilteredData = $FilteredData | Where-Object {$_.'Machine Name' -in $ComputerName}
    }
   
    [System.Collections.ArrayList]$IpMacData = @();
    foreach($row in $FilteredData) {
        $raw_IpMac = $row.'Bridged Adapter';
        $BridgedAdap_IP = $raw_IpMac.Split("`n")[0];
        $BridgedAdap_Mac = (($raw_IpMac.Split("`n")[1]).Trim('(')).Trim(')');

        $raw_IpMac = $row.'Host-Only Adapter';
        $HostOnlyAdap_IP = $raw_IpMac.Split("`n")[0];
        $HostOnlyAdap_Mac = (($raw_IpMac.Split("`n")[1]).Trim('(')).Trim(')');

        Write-Debug "Stop Here";
        $obj = [PSCustomObject]@{
            ComputerName = $row.'Machine Name';
            BridgedAdap_MAC = $BridgedAdap_Mac;
            BridgedAdap_IP = $BridgedAdap_IP;
            HostOnlyAdap_MAC = $HostOnlyAdap_Mac;
            HostOnlyAdap_IP = $HostOnlyAdap_IP;
        }
        $IpMacData.Add($obj) | Out-Null;
    }
    
    if($IncludeRawMACAddress) {
        $IpMacData | Add-Member ScriptProperty BridgedAdap_MAC_Raw {$this.BridgedAdap_MAC.Replace(':','')}
        $IpMacData | Add-Member ScriptProperty HostOnlyAdap_MAC_Raw {$this.HostOnlyAdap_MAC.Replace(':','')}
    }
    
    $IpMacData | Write-Output

<#
.SYNOPSIS
Return MACAddress & IP binding for all computers from excel 'SQL-Server-Lab-IPv4-Settings.xlsx'
.DESCRIPTION
This function accepts ExcelPath that would have data of IP/MAC address binding information, and return same in PSObject format
.PARAMETER ComputerName
Name of computer to filter in result set
.PARAMETER ExcelPath
Excel path containing MACAddress & IP binding information
.PARAMETER IncludeRawMACAddress
Include MACAddress in raw format, means without hexadecimal pair separaters like ':' or '-'
.PARAMETER AllComputers
Return all database without filtering any computer.
.EXAMPLE
Import-Module ImportExcel
$Servers = @('SQL-F','SQL-G','SQL-H','SQL-Core')
Get-MacAddress -ComputerName $Servers
.LINK
https://ajaydwivedi.com
#>
}