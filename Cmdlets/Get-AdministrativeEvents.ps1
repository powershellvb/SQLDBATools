Function Get-AdministrativeEvent
{

<#
.Synopsis
The Get-AdministrativeEvent function returns a rollup of administrative events
.EXAMPLE
Run the command against a remote machine with credentials:

Get-AdministrativeEvent -Credential (get-credential domain\admin) -ComputerName srv01
.EXAMPLE
.EXAMPLE
Run the command locally:

Get-AdministrativeEvent
.EXAMPLE
Run the command against remote machines without credentials:
#>

    [CmdletBinding()]
    Param
    (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [Alias('Name','CN')] 
        [string[]]$ComputerName = $env:COMPUTERNAME,

        # Specifies a user account that has permission to perform this action
        [Parameter(Mandatory=$false)]
        [System.Management.Automation.PSCredential]
        $Credential,

        #Number of hours to go back to when retrieving events
        [datetime]$StartTime = (Get-Date).AddHours(-1)

    )
    
    Begin
    {

        $stringTime = (Get-Date $StartTime -Format s)

    $filter = @'

    <QueryList>
      <Query Id="0" Path="Application">
        <Select Path="Application">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Security">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="System">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="HardwareEvents">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Internet Explorer">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Key Management Service">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-All-User-Install-Agent/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-AppHost/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Application Server-Applications/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-AppModel-Runtime/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-AppReadiness/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Storage-ATAPort/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-DataIntegrityScan/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-DataIntegrityScan/CrashRecovery">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-DSC/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-DeviceSetupManager/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Dhcp-Client/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-DhcpNap/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Dhcpv6-Client/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Diagnosis-Scripted/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Storage-Disk/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-EnrollmentPolicyWebService/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-EnrollmentWebService/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-FileServices-ServerManager-EventProvider/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-GenericRoaming/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Kernel-EventTracing/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Management-UI/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-MUI/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-PowerShell/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-PrintService/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-PushNotification-Platform/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Rdms-UI/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-RemoteApp and Desktop Connections/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-RemoteDesktopServices-RdpCoreTS/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-ServerManager-MultiMachine/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-SmartCard-TPM-VCard-Module/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-SMBDirect/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="WitnessClientAdmin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Storage-Tiering/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Storage-ClassPnP/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-WS-Licensing/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Storage-Storport/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-TerminalServices-ClientUSBDevices/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-TerminalServices-LocalSessionManager/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-TerminalServices-PnPDevices/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-TerminalServices-Printers/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-TerminalServices-RemoteConnectionManager/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-TerminalServices-ServerUSBDevices/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-TerminalServices-SessionBroker-Client/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-VerifyHardwareSecurity/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Microsoft-Windows-Workplace Join/Admin">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Operations Manager">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Symantec Endpoint Protection Client">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
        <Select Path="Windows PowerShell">*[System[(Level=1  or Level=2 or Level=3 and Channel = "System") and TimeCreated[@SystemTime&gt;='{0}']]]</Select>
      </Query>
    </QueryList>

'@

        $filter | Write-Debug

        $parm = @{

            FilterXML = $filter -f $stringTime

        }

        if ($Credential)
        {
            $parm.Credential = $Credential
        }

    }

    Process
    {
        foreach ($obj in $ComputerName)
        {    
            Get-WinEvent -ComputerName $obj @parm | Group-Object ID | Select-Object @{ n='ComputerName';e={ $PSItem.Group.MachineName | select -first 1 }},
                Name,
                Count,
                @{ n = 'LastTimeCreated'; e = { $PSItem.Group.TimeCreated | Measure-Object -Maximum | Select-Object -ExpandProperty Maximum }},
                @{ n='ProviderName';e={ $PSItem.Group.ProviderName | select -first 1 }},
                @{ n='LogName';e={ $PSItem.Group.logname | select -first 1 }},
                @{ n='Message';e={ $PSItem.Group.message | select -first 1 }}
        }

    }



}