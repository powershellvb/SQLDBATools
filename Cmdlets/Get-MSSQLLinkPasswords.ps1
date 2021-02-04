function Get-LinkedServer {
<#
    .SYNOPSIS
    This function returns LinkedServers presents on SqlInstance
    .DESCRIPTION
    This function accept SqlInstance name and return all LinkedServers present on the Instance.
    .PARAMETER SqlInstance
    Name of the Sql Instance where Linked Server username passwords have to be decrypted.
    .PARAMETER ScriptOut
    Use this switch to get ScriptOut of LinkedServers in .sql file
    .EXAMPLE
    Get-LinkedServer -SqlInstance 'testvm' | Out-GridView
    Find all Linked servers with usernames and passwords present on SqlInstance 'testvm'. Display the result in Grid view.
    .EXAMPLE
    Get-LinkedServer -SqlInstance 'testvm' -ScriptOut
    Get drop/create statements for all Linked servers with corrent usernames and passwords present on SqlInstance 'testvm' in a text file.
    .LINK
    https://github.com/imajaydwivedi/SQLDBATools
#>  
    [CmdletBinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string[]]$SqlInstance = $Env:computername,

        [Parameter(Mandatory=$false)]
        [switch]$ScriptOut,

        [Parameter(Mandatory=$false)]
        [string]$File
    )

    $LinkedServerAllInstances = @();

    # Create file to store ScriptOut result
    if([string]::IsNullOrEmpty($File)) {
        $File = "c:\temp\LinkedServers_ScripOut_4_"+(($SqlInstance -join '__').Replace('\','-'))+".sql";
    }
    Remove-Item -Path $File -Force -ErrorAction SilentlyContinue;

    Write-Verbose "Start looping through each SqlInstance";
    foreach($SqlInst in $SqlInstance) {
        [System.Collections.ArrayList]$LinkedServerCollection = @();
        
        Write-Verbose "Get credentials of LinkedServers using Get-MSSQLLinkPasswords for [$SqlInst]"
        $LinkedServerCredentials = Get-MSSQLLinkPasswords -SqlInstance $SqlInst;        
        
        # Create Server Object
        $srv = New-Object Microsoft.SqlServer.Management.Smo.Server($SqlInst);    
        #Write-Debug "Server handle created";        

        #create a Scripter object
        $script = New-Object Microsoft.SqlServer.Management.Smo.Scripter $srv;
        #create a ScriptingOptions object
        $scriptOptions = New-Object Microsoft.SqlServer.Management.Smo.ScriptingOptions;

        # Default Script Options
        $scriptOptions.AllowSystemObjects = $false
        $scriptOptions.ScriptSchema = $true
        $scriptOptions.IncludeDatabaseContext = $true
        $scriptOptions.SchemaQualify = $true
        $scriptOptions.ScriptBatchTerminator = $true
        $scriptOptions.NoExecuteAs = $true
        $scriptOptions.Permissions = $true
        $scriptOptions.ScriptForCreateDrop = $true
        $scriptOptions.NoCommandTerminator = $false
        #if($ScriptOut) { $scriptOptions.ToFileOnly = $true; $scriptOptions.Filename = $File; $scriptOptions.AppendToFile; }

        #assign the options to the Scripter object
        $script.Options = $scriptOptions
        #$transfer.ScriptTransfer() 

        Write-Verbose "Find all Linked Servers on [$SqlInst]"
        $LinkedServers = $srv.LinkedServers | Sort-Object Name;
        $StatementTerminator = @"
;

"@;
        foreach($link in $LinkedServers) {
            
            $tsqlDrop = @"


EXEC master.dbo.sp_dropserver @server=N'$($link.Name)', @droplogins='droplogins'
GO

"@;
            $tsqlCreate = ($script.Script($link)) -join $StatementTerminator;
            $tsql = $tsqlDrop + $tsqlCreate;

            $obj = [PSCustomObject]@{
                        SqlInstance  = $SqlInst;
                        LinkServer = $link.Name;
                        ProductName = $link.ProductName;
                        DataSource = $link.DataSource;
                        ProviderName = $link.ProviderName;    
                        CreateScript = $tsql;
                    }
            $LinkedServerCollection.Add($obj)|Out-Null;
            Write-Debug "Inside Loop: First LinkedServer Object";
        }# LinkedServer Loop

        $LinkedServersFinal = Join-Object -Left $LinkedServerCollection -Right $LinkedServerCredentials -LeftJoinProperty LinkServer -RightJoinProperty Linkserver -Type AllInLeft -RightProperties User, Password;
        $LinkedServerAllInstances += $LinkedServersFinal;
    } # SQlInstance Loop
    $LinkedServerAllInstances = $LinkedServerAllInstances | Select-Object SqlInstance, LinkServer, ProductName, DataSource, ProviderName, User, Password, CreateScript | Sort-Object -Property SqlInstance, LinkServer;
    
    Write-Verbose "Creating Linked server scriptout with actual Passwords";
    $LinkedServerAllInstances = $LinkedServerAllInstances | ForEach-Object {
        $ScriptWithPassword = $_.CreateScript;
        if([string]::IsNullOrEmpty($_.Password) -eq $false) {
            $ScriptWithPassword = $_.CreateScript.Replace("@rmtpassword='########'","@rmtpassword='$($_.Password)'");
        }
        Add-Member -InputObject $_ -NotePropertyName ScriptOut -NotePropertyValue $ScriptWithPassword;
        $_;
    } | Select-Object SqlInstance, LinkServer, ProductName, DataSource, ProviderName, User, Password, ScriptOut;

    if($ScriptOut) {
        foreach($link in $LinkedServerAllInstances) {            
            $link.ScriptOut | Out-File -FilePath $File -Append -Force;
            "`nGO`n" | Out-File -FilePath $File -Append -Force;
        }
        Write-Host "Output saved in file '$File'";
        #notepad $File
    }
    else {
        Write-Verbose "Returning result back to Caller";
        Write-Output $LinkedServerAllInstances;
    }
}
