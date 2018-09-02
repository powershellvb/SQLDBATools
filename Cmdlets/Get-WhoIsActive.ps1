Function Get-WhoIsActive
{
    [CmdletBinding()]
    Param(
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('ServerName','SqlInstance')]
        [String[]]$ServerInstance,

        [String]$Database = 'master'        

        ,[Switch]$ResultToExcel = $false
    )
    BEGIN 
    {
        $Servers = @();
        $RunningQueries = @();
        $sqlQuery = @" 
exec sp_whoIsActive @get_full_inner_text=1, 
                    @get_transaction_info=1, @get_task_info=2, 
                    @get_locks=1, @get_avg_time=1, @get_additional_info=1,
                    @find_block_leaders=1
"@;
    }
    PROCESS
    {
        foreach($InstanceName in $ServerInstance)
        {
            $RunningQueries += Invoke-Sqlcmd -ServerInstance $InstanceName  -Database $Database -Query $sqlQuery |
                                    Add-Member -NotePropertyName ServerInstance -NotePropertyValue $InstanceName -PassThru;
            $Servers += $InstanceName;
        }
    }
    END
    {
        $ServerCommaSeparated = $Servers -join ', ';
        $ExcelSheet = "C:\Temp\WhoIsActive_Result_$ServerCommaSeparated_$(Get-Date -Format 'yyyy-MM-dd HHmm').xlsx";

        if($ResultToExcel) {
            Write-Host "Generating excel file=>   $ExcelSheet" -ForegroundColor Green;
            $RunningQueries | Export-Excel -Path $ExcelSheet;
        }
        else {
            $RunningQueries | Out-GridView -Title "WhoIsActive on $ServerCommaSeparated";
        }
    }
<#
        .SYNOPSIS
            Execute sp_WhoIsActive  procedure and displays the result either in gridview or excel

        .DESCRIPTION
            Execute sp_WhoIsActive  procedure and displays the result either in gridview or excel

        .NOTES
            Name: Get-WhoIsActive
            Author: Ajay Dwivedi

        .EXAMPLE
            Get-WhoIsActive -ServerInstance ServerName

            Description
            -----------
            Executes sp_WhoIsActive procedure and displays the result either in gridview or excel

        .EXAMPLE
            Get-WhoIsActive -ServerInstance ServerName -ResultToExcel

            Description
            -----------
            Executes sp_WhoIsActive procedure and displays the result either in gridview or excel

        .LINK
            http://ajaydwivedi.com
#>
}
