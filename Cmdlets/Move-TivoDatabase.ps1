cls
$_serverName = 'tul1dbapmtdb1';
$_dbname = 'DBA';

# Provide New Drives
[String]$_new_Data_Drive = 'F';
[String]$_new_Log_Drive = 'E:\';

<# Validate Drive letters #>
$Matches.Clear();
if($_new_Data_Drive -match "^(?'letter'[a-zA-Z]{1})") {$_new_Data_Drive = $Matches['letter']+':\'};

$Matches.Clear();
if($_new_Log_Drive -match "^(?'letter'[a-zA-Z]{1})") {$_new_Log_Drive = $Matches['letter']+':\'};

$_newDataPath = "$($_new_Data_Drive)Mssqldata\Data\";
$_newLogPath = "$($_new_Log_Drive)Mssqldata\Log\";

# Kill all sessions for database
#Stop-DbaProcess -SqlInstance $_serverName -Database $_dbname;

$tsql_GetFiles = @"
select db_name(mf.database_id) as dbName, mf.name as logicalName, mf.physical_name as physicalName,type_desc as typeDesc from sys.master_files mf 
	where mf.database_id = db_id('$_dbname');
"@;
$dbFiles = Invoke-Sqlcmd2 -ServerInstance $_serverName -Database 'master' -Query $tsql_GetFiles;

#$dbFiles | ogv

foreach($file in $dbFiles)
{
    #$file.dbName;
    #$file.logicalName;
    [String]$physicalName = '';
    $Matches.Clear();
    if($file.physicalName -match "(?'physicalName'\w+\.[mdfldfndf]{3})$") {$physicalName = $Matches['physicalName']};
    
    #$physicalName;
    if($file.typeDesc -eq 'ROWS')
    {
        $physicalName = $_newDataPath + $physicalName;
    }
    else
    {
        $physicalName = $_newLogPath + $physicalName;
    }

    $tsqlAlterCode = @"
ALTER DATABASE [$($file.dbName)]   
    MODIFY FILE ( NAME = $($file.logicalName),   
                  FILENAME = '$physicalName'
                )
GO
"@;

    Write-Host $tsqlAlterCode
    #Invoke-Sqlcmd2 -ServerInstance $_serverName -Database 'master' -Query $tsqlAlterCode;
}

# Generate TSQL for Making db Offline
$tsql_setOffline = @"
alter database [$_dbname]
	set offline 
go
"@;

Write-Host $tsql_setOffline;
#Invoke-Sqlcmd2 -ServerInstance $_serverName -Database 'master' -Query $tsql_setOffline;

#Copy files to New Drives
foreach($file in $dbFiles)
{
    $file.physicalName;
    
    if($file.typeDesc -eq 'ROWS')
    {
        #Copy-Item  $file.physicalName -Destination $_newDataPath;
        $path = $file.physicalName;
        Invoke-Command -ComputerName $_serverName -ScriptBlock {Copy-Item  $file.physicalName -Destination $_newDataPath}
    }
    else
    {
        #Copy-Item  $file.physicalName -Destination $_newLogPath;
        Invoke-Command -ComputerName $_serverName -ScriptBlock {Copy-Item  $file.physicalName -Destination $_newLogPath}
    }
}

Invoke-Command -ComputerName tul1cipedb2 -ScriptBlock {Get-ChildItem $Using:path}