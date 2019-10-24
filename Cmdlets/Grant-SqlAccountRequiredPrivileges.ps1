function Grant-SqlAccountRequiredPrivileges {
<#
    .SYNOPSIS
    The function grants recommended permissions under User Rights Assignment in Local Secuirty Policy for SQL Service account
    .DESCRIPTION
    This function grants below recommended permissions for SQL Service account:-
    Log on as a service (SeServiceLogonRight)
    Replace a process-level token (SeAssignPrimaryTokenPrivilege)
    Bypass traverse checking (SeChangeNotifyPrivilege)
    Adjust memory quotas for a process (SeIncreaseQuotaPrivilege)
    Perform Volume Maintainence Tasks (SeManageVolumePrivilege)
    .PARAMETER SqlInstance
    Name of SQL Instance for which these permission are to be granted
    .EXAMPLE
    Grant-SqlAccountRequiredPrivileges -SqlInstance 'TESTVM'
    .LINK
    https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param(
        [Parameter(Mandatory=$true)]
        [string] $SqlInstance
    )

    Write-Verbose "Fetching SQLServiceAccount.";
    $ServerName = $SqlInstance.Split('\')[0];
    $InstanceName = if($SqlInstance.Contains('\')){$SqlInstance.Split('\')[1]}else{'MSSQLSERVER'}
    $SQLServiceName = if($InstanceName -eq 'MSSQLSERVER'){'MSSQLSERVER'}else{"MSSQL`$$InstanceName"}
    $SQLServiceAccount = (Get-WmiObject win32_service -ComputerName $ServerName  -Filter "name='$SQLServiceName'").StartName;

    $ScriptBlock = {
        $SQLServiceAccount = $Using:SQLServiceAccount;
        
        # Find SID for Service Account
        Write-Verbose "Find SID for Service Account";
        $sidstr = $null
        try {
	        $ntprincipal = new-object System.Security.Principal.NTAccount "$SQLServiceAccount"
	        $sid = $ntprincipal.Translate([System.Security.Principal.SecurityIdentifier])
	        $sidstr = $sid.Value.ToString()
        } catch {
	        $sidstr = $null
        }

        # Find temp File path
        $exportFile = [System.IO.Path]::GetTempFileName();

        Write-Verbose "Export current Local Security Policy to temp file '$exportFile'";
        secedit.exe /export /cfg "$($exportFile)" | Out-Null

        $c = Get-Content -Path $exportFile;

        $SqlServicePriviledges = @();
        $ArrySqlPriviledges = @('SeInteractiveLogonRight','SeServiceLogonRight','SeAssignPrimaryTokenPrivilege','SeChangeNotifyPrivilege','SeIncreaseQuotaPrivilege','SeManageVolumePrivilege');

        <#
            Log on as a service (SeServiceLogonRight)
            Replace a process-level token (SeAssignPrimaryTokenPrivilege)
            Bypass traverse checking (SeChangeNotifyPrivilege)
            Adjust memory quotas for a process (SeIncreaseQuotaPrivilege)
            Perform Volume Maintainence Tasks (SeManageVolumePrivilege)
        #>
        Write-Verbose "Go through line by line in exported local security policy content";
        foreach($s in $c) 
        {
            foreach($p in $ArrySqlPriviledges)
            {
                $currentSetting = "";
                $actionNeeded = $true;
	            if( $s -like "$p*") 
                {
                    Write-Verbose "`tModifying line for policy '$p'";
		            $x = $s.split("=",[System.StringSplitOptions]::RemoveEmptyEntries)
		            $currentSetting = $x[1].Trim();

                    if( [string]::IsNullOrEmpty($currentSetting) ) {
		                $currentSetting = "*$($sidstr)";
	                } elseif ($currentSetting -notlike "*$($sidstr)*") {
                        $currentSetting = "*$($sidstr),$($currentSetting)";
                    } else {
		                Write-Verbose "No action needed for Log on Locally";
                        $actionNeeded = $false;
	                }
        
                    if ($actionNeeded)
                    {
                        $priviledge = [Ordered]@{
                            'PolicyName' = $x[0];
                            'PolicyMembers' = $currentSetting;
                        }
                        $priviledgeObj = New-Object -TypeName PSObject -Property $priviledge;
                        $SqlServicePriviledges += $priviledgeObj;
                    }
	            }        
            }
        }

        if( $SqlServicePriviledges.Count -gt 0)
        {
            $SqlServicePriviledges;
            $outfile = '';
            foreach($item in $SqlServicePriviledges)
            {
                $outfile += @"
        [Unicode]
        Unicode=yes
        [Version]
        signature="`$CHICAGO`$"
        Revision=1
        [Privilege Rights]
        $($item.PolicyName) = $($item.PolicyMembers)
"@
            }

            $importFile = [System.IO.Path]::GetTempFileName()
	
	
	        Write-Verbose "Import new settings to Local Security Policy";
	        $outfile | Set-Content -Path $importFile -Encoding Unicode -Force

	        #notepad.exe $tmp2
	        Push-Location (Split-Path $importFile)
	
	        try {
		        secedit.exe /configure /db "secedit.sdb" /cfg "$($importFile)" /areas USER_RIGHTS 
		        #write-host "secedit.exe /configure /db ""secedit.sdb"" /cfg ""$($tmp2)"" /areas USER_RIGHTS "
	        } finally {	
		        #Pop-Location
	        }
        }
        else {
	        Write-Verbose "NO ACTIONS REQUIRED regarding SQL Service Account Priviledges!"
        }
        Write-Output 0;
    }

    if($PSCmdlet.ShouldProcess($SqlInstance)) {
        $r = Invoke-Command -ComputerName $ServerName -ScriptBlock $ScriptBlock;
    }
    Write-Verbose "SQL Service Account Priviledges! Finished!"
    return r;
}