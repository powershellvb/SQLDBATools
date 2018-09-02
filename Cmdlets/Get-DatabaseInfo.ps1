Function Get-DatabaseInfo
{
    
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServerName','SqlInstance')]
        [String[]]$ServerInstance
    )
    
    BEGIN 
    {
        # Declare final arry variable
        $DatabaseInfo = @();

    }
    PROCESS
    {
        
        # Loop through each SQL Instance
        foreach($inst in $ServerInstance)
        {
            Write-Verbose "Finding databases on instance [$inst] ..";
            $server = New-Object Microsoft.SqlServer.Management.Smo.Server("$inst");
            $dbs = $server.Databases;
            $
        }
    }
    END
    {
        # Send final output to pipeline
        $DatabaseInfo | Write-Output;
    }
}

Get-DatabaseInfo -ServerInstance DAL2SKYPEBEDB1,TUL1CIPCMPDB1 -Verbose