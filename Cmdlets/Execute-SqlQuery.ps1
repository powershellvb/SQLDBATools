Function Execute-SqlQuery {
    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','SQLInstance')]
        [String]$ServerInstance = $env:COMPUTERNAME,

        [String]$Database = 'master',
        [String]$Query
    )
    
    #$Server = 'TUL1DBAPMTDB1'    
    #$database = 'SQLDBATools'
    $Connection = New-Object System.Data.SQLClient.SQLConnection;
    $Connection.ConnectionString = "server=$($ServerInstance);database=$($Database);trusted_connection=true;"
    $Connection.Open();
    $Command = New-Object System.Data.SQLClient.SQLCommand;
    $Command.Connection = $Connection;
    $Command.CommandText = $Query; #'SELECT Name as InstanceName FROM [dbo].[Instance] WHERE IsDecommissioned = 0';
    $Reader = $Command.ExecuteReader();
    $Datatable = New-Object System.Data.DataTable;
    $Datatable.Load($Reader);
    $Connection.Close();

    return $Datatable;
}