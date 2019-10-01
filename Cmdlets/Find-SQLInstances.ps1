Function Find-SQLInstances
{
    <#
        .SYNOPSIS
            Retrieves all Machines within network where SQL server is installed.

        .DESCRIPTION
            Retrieves SQL server information from network. Pulls all 
            instances from a SQL server and detects if in a cluster or not.

        .NOTES
            Name: Discover-SQLInstances
            Author: Ajay Dwivedi

        .EXAMPLE
            Discover-SQLInstances 

            Description
            -----------
            Retrieves all SQL Servers installed within network

        .LINK
            https://www.mssqltips.com/sqlservertip/2013/find-sql-server-instances-across-your-network-using-windows-powershell/
    #>

    $machines = @([System.Data.Sql.SqlDataSourceEnumerator]::Instance.GetDataSources() | Select-Object -ExpandProperty ServerName);
    $machines | Write-Output;
}