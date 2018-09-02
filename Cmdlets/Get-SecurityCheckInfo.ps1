Function Get-SecurityCheckInfo
{
    [OutputType([System.Data.DataSet])]
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','SQLInstance')]
        [String[]]$ServerInstance
    )

    $tsqlSecurityCheck = "EXECUTE [DBA].[dbo].[usp_SecurityCheck] @getMailOnly = 'y'";
    $Result = @();
    $failedServers = @();

    Write-Verbose "Working on server $($ServerInstance -join ', ')";

    if([String]::IsNullOrEmpty($ServerInstance)) {
        Write-Error "Invalid ServerInstance specified.";
        return;
    }

    foreach($server in $ServerInstance)
    {
        $r = $null;
        try  
        {
            $r = Invoke-Sqlcmd -ServerInstance $server -Database 'DBA' -Query $tsqlSecurityCheck -ErrorAction SilentlyContinue | 
                        Select-Object  @{l='ServerInstance';e={$server}}, 
                                        principal_name, type_desc, role_permission, roleOrPermission, 
                                        @{l='CollectionTime';e={Get-Date -Format 'dd-MMM-yyyy hh:mm'}};
            $Result += $r;
        }
        catch
        {
            $failedServers += $server;
            Write-Verbose "Failed for server $server";
        }
    }

    $Result | Write-Output;
}