Function Analyze-DBFiles
{
    Param (
        [Alias('ServerName','MachineName','InstanceName')]
        [String[]]$ComputerName
    )

    BEGIN {}
    PROCESS {
        $ScriptPath = $PSScriptRoot+'\Automation - Restrict File growth.sql';
        Write-Verbose "Script path is $ScriptPath";

        foreach ($sqlInstance in $ComputerName)
        {
            # Compile Procedure on tempdb
            Write-Verbose "Compiling the procedure code from script $ScriptPath";
            Invoke-Sqlcmd -ServerInstance $sqlInstance -Database 'tempdb' -InputFile $ScriptPath;

            Write-Verbose "Executing the procedure usp_AnalyzeSpaceCapacity";
            $rs = Invoke-Sqlcmd -ServerInstance $sqlInstance -Database tempdb -Query 'exec [dbo].[usp_AnalyzeSpaceCapacity]';
        
            Write-Output $rs
        }
    }
    END {}
}