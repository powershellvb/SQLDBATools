function Set-SQLServiceState {
<#
    .SYNOPSIS
    This function provides options to Stop, Reboot, Start and change StartMode of SQL Service account.
    .DESCRIPTION
    This function helps to stop, reboot, start and change StartMode of SQL Service account. Also, has functionality to drop mail to DBAGroupId
    .PARAMETER SqlInstance
    Accepts SqlInstance to perform action on.
    .PARAMETER State
    Value for desired state of sQL Services. Values supported are restart, stop and start.
    .PARAMETER StartMode
    Value for desired StartMode of SQL Services. Values supported are Automatic, Disabled and Manual.
    By default, this is kept as existing mode.
    .PARAMETER SendMail
    When Yes, a mail will be sent to DBAGroupMailId. Default is Yes.
    .EXAMPLE
    'testvm\sql2017' | Set-SQLServiceState -State ReStart
    Reboot SQL Services of 'testvm\sql2017' instance.
    .EXAMPLE
    Set-SQLServiceState -SqlInstance 'testvm\sql2017' -State Stop -StartMode Disabled
    Stop SQL Services for sql instance 'testserver\sql2017'and set StartMode to Disabled
    .LINK
    https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$True, ConfirmImpact='High')]
    Param(
        [Parameter(Mandatory=$True, ParameterSetName="SqlInstance", ValueFromPipeline=$True, ValueFromPipelineByPropertyName=$True)]
        [Alias("ServerInstance")]
        [string[]]$SqlInstance,

        [Parameter(Mandatory=$True)]
        [ValidateSet("ReStart", "Start", "Stop")]
        [String]$State,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Automatic','Disabled','Manual')]
        [String]$StartMode,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Yes','No')]
        [String]$SendMail = 'No'
    )
    
    BEGIN {
        function getServiceHandle {
            Param($ServerName, $SQLServiceName)
            return (Get-WmiObject win32_service -ComputerName $ServerName  -Filter "name='$SQLServiceName'");
        }

        [System.Collections.ArrayList]$SQLServices = @()
    }
    PROCESS {

        if ($_ -ne $null) {
            $SqlInstance = $_;
        }

        foreach($Inst in $SqlInstance) {        
            $ServerName = $Inst.Split('\')[0];
            $InstanceName = if($Inst.Contains('\')){$Inst.Split('\')[1]}else{'MSSQLSERVER'}
            $SQLServiceName = if($InstanceName -eq 'MSSQLSERVER'){'MSSQLSERVER'}else{"MSSQL`$$InstanceName"}
            
            Write-Verbose "Looking for SQL Services of '$Inst' instance";
            $SQLService = getServiceHandle -ServerName $ServerName -SQLServiceName $SQLServiceName;

            if([String]::IsNullOrEmpty($SQLService)) {
                Write-Error "SQL Instance '$Inst' does not exist.";
            } 
            else {                
                $SQLServiceAccount = $SQLService.StartName;
                $StartMode_Existing = $SQLService.StartMode;
                $IsRunning = $SQLService.Started;
                $DisplayName = $SQLService.Caption;
                
                
                Write-Verbose "About to enforce '$State' state on SQL Services";
                if($State -eq 'Start') {
                    $SQLService.StartService() | Out-Null;
                }
                if($State -eq 'Stop') {
                    $SQLService.StopService() | Out-Null;
                }
                if($State -eq 'ReStart') {
                    $SQLService.StopService() | Out-Null;
                    $EndTime = (Get-Date).AddMinutes(5);
                    Do {
                        Start-Sleep -Seconds 5;
                        $SQLService = getServiceHandle -ServerName $ServerName -SQLServiceName $SQLServiceName;
                        $SQLService.StartService() | Out-Null;
                    } while($EndTime.CompareTo([System.DateTime]::Now) -gt 0 -and $SQLService.State -ne 'Stopped'); # Wait for 5 minutes

                    if($SQLService.State -ne 'Stopped') {
                        Write-Error "Something is wrong! Kindly mantually perform state change";
                        return;
                    }
                    else {
                        $SQLService.StartService() | Out-Null;
                    }
                }

                if([string]::IsNullOrEmpty($StartMode) -eq $false) {
                    if($StartMode -ne $StartMode_Existing) {                        
                        Write-Verbose "About to enforce '$StartMode' StartMode for SQL Services";
                        $SQLService.ChangeStartMode("$StartMode") | Out-Null;
                    }
                }
            }
            $SQLService = getServiceHandle -ServerName $ServerName -SQLServiceName $SQLServiceName;
            $SQLServices.Add($SQLService);
        }
    }
    END {
        Write-Output ($SQLServices | Select Name, DisplayName, State, StartMode)
    }
}


