Function Setup-SelfServiceModules
{
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true)]
        [Alias('SqlInstance')]
        [String]$ServerInstance
    )

    $SelfServiceModules_CleanUp_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-Certificate Cleanup.sql";
    #$SelfServiceModules_CleanUp_File_DBA = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-Certificate Cleanup-DBA.sql";
    $SelfServiceModules_AllProcedures_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-All-Procedures.sql";
    $SelfServiceModules_SignModules_File = "$((Get-ItemProperty $PSScriptRoot).Parent.FullName)\SQLQueries\SelfServiceModules-Sign-Procedures.sql";

    $tsqlQuery = @"
    IF DB_ID('DBA') IS NOT NULL
	    SELECT 1 as [Exists]
    ELSE
	    SELECT 0 as [Exists]
"@;
    $abort = $false;
    $runningCode = $null;
    $friendlyErrorMessage = "Kindly make sure [DBA] database is created before you execute this cmdlet.";
    $exists = Invoke-DbaQuery -SqlInstance $ServerInstance -Query $tsqlQuery | Select-Object -ExpandProperty Exists;
    if([string]::IsNullOrEmpty($exists) -eq $true -or $exists -eq 0) {
        $abort = $true;
    }
    if ($abort) {
        if ([string]::IsNullOrEmpty($ErrorMessage) -eq $false) {
            $returnMessage = if([string]::IsNullOrEmpty($FailedItem)){$ErrorMessage}else{"$FailedItem => $ErrorMessage"};
        } else {$returnMessage = '';}
        if ([string]::IsNullOrEmpty($runningCode) -eq $false) {
            $rcMessage = "RunningCode => $runningCode" + $NewLine_Single;
        } else {$rcMessage = '';}
        if ([string]::IsNullOrEmpty($friendlyErrorMessage) -eq $false) {
            $feMessage = "FriendlyErrorMessage => $friendlyErrorMessage" + $NewLine_Double;
        } else {$feMessage = '';}

        $returnMessage = $rcMessage + $feMessage + $returnMessage;

        Write-Host "$returnMessage" -ForegroundColor Red;
        return;
    }

    Write-Verbose "Creating connection against [$ServerInstance] server";
    $ServerToken = Connect-DbaInstance -SqlInstance $ServerInstance;
    
    Write-Verbose "Running Cleanup code from file '$SelfServiceModules_CleanUp_File'.";
    Invoke-DbaQuery -SqlInstance $ServerToken -File $SelfServiceModules_CleanUp_File;

    Write-Verbose "Compiling All procedures from file '$SelfServiceModules_AllProcedures_File'.";
    Invoke-DbaQuery -SqlInstance $ServerToken -File $SelfServiceModules_AllProcedures_File;

    Write-Verbose "Creating certificate and signing the modules. Code from file '$SelfServiceModules_SignModules_File'.";
    Invoke-DbaQuery -SqlInstance $ServerToken -File $SelfServiceModules_SignModules_File;

    Write-Host "SelfServiceModules creation finished." -ForegroundColor Green;
     
}