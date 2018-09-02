function Invoke-TsqlScript 
  { 
    #[OutputType([System.Data.DataSet])] 
    [CmdletBinding( DefaultParameterSetName='ByScriptFilePath')] 
    Param 
      ( 
          [Parameter(Mandatory = $true)] 
          [string]$ServerInstance 
   
        , [Parameter(Mandatory = $false)] 
          [string]$Database =  'master'
   
        , [Parameter(Mandatory = $true, ParameterSetName = 'ByScriptFilePath')]           
          [string]$InputFile 
 
        , [Parameter(Mandatory = $true, ParameterSetName = 'ByTSQLString')] 
          [string]$Query   
   
        , [Parameter(Mandatory = $false)] 
          [Switch]$GetPipelineOutput  
      ) 
 
    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO');
     
    switch($PSCmdlet.ParameterSetName) 
    { 
        'ByScriptFilePath'
        { 
            $script_contents = Get-Content -Path "$InputFile" | Out-String;
            $OutputFile = "$SQLDBATools_ResultsDirectory\Logs\Invoke-TsqlScript\$((Get-ItemProperty $InputFile).BaseName)__$(($ServerInstance -split '\\')[0]).txt";
        }

        'ByTSQLString'
        { 
            $script_contents = $Query;
            $OutputFile = "$SQLDBATools_ResultsDirectory\Logs\Invoke-TsqlScript\$ServerInstance.txt";
        }
    }

    Write-Verbose "`$OutputFile = '$OutputFile'";
    $OutputFinal = @();

    # Create Output File
    if (!(Test-Path "$SQLDBATools_ResultsDirectory\Logs\Invoke-TsqlScript")) 
    {
        Write-Verbose "Path "+"$SQLDBATools_ResultsDirectory\Logs\Invoke-TsqlScript does not exist. Creating it.";
        New-Item -ItemType "directory" -Path "$SQLDBATools_ResultsDirectory\Logs\Invoke-TsqlScript";
    }

    # Separate script into different groups by 'GO'
    $createScriptList = [regex]::Split($script_contents, '\bGO');

    foreach ($cSL in $createScriptList)
    {
        #$cSl;
        $Output = $null;
        
        Try
        {
            $Output = Execute-SqlQuery -ServerInstance $ServerInstance -Database $Database -Query "$cSL" -ErrorAction SilentlyContinue;
        }
        Catch
        {
            $ErrorMessage = $_.Exception.Message;
            $FailedItem = $_.Exception.ItemName;

            $Output = @"
========================================================================
========================================================================
Error occurred while executing script. Below is the Error Message:-

        $ErrorMessage

"@;
        
        }
        if([String]::IsNullOrEmpty($Output) -eq $false ) { $OutputFinal += $Output; }
    }

    #$dtable = $Result | Out-DataTable; 
    $OutputFinal | Out-File -FilePath "$OutputFile" -Append;
}

<#
Invoke-TsqlScript -ServerInstance $env:COMPUTERNAME `
                -InputFile 'C:\Users\adwivedi\Documents\WindowsPowerShell\Modules\SQLDBATools\SQLQueries\__06_Setup_DBA_db.sql' `
                -Verbose
#>