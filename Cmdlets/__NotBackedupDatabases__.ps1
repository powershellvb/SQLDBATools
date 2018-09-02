<# Script to Find databases which are not backed up in Last 7 Days
#>

$Server2Analyze = 'TUL1CIPXDB19';
$DateSince = (Get-Date).AddDays(-7) # Last 7 days

# Find Latest Bacukps
$Backups = Get-DbaBackupHistory -SqlInstance $Server2Analyze -Type Full -Since $DateSince #'5/5/2018 00:00:00'

$BackedDbs = $Backups | Select-Object -ExpandProperty Database -Unique
$QueryFindDbs = @"
select d.name from sys.databases as d
	where d.is_in_standby = 0 and d.state_desc = 'ONLINE'
    and d.name not in ('tempdb')
"@;

# List of available dbs
$dbs = Invoke-Sqlcmd -ServerInstance $Server2Analyze -Database master -Query $QueryFindDbs | select -ExpandProperty name;

$NotBackedDbs = @();
$NotBackedDbs_AddString = @();
foreach($db in $dbs)
{
    if($BackedDbs -contains $db){
        Write-Host "$db is +nt";
    }
    else {
        $NotBackedDbs += $db;
        $NotBackedDbs_AddString += "Insert into tempdb.dbo.DBChecksDBList values('$db')";
    }
}

Write-Host "Returing Dbs for which backup is not there.." -ForegroundColor Green;
$NotBackedDbs | Add-Member -NotePropertyName ServerName -NotePropertyValue $Server2Analyze -PassThru -Force | 
    Out-GridView -Title "Not Backed Dbs";

$NotBackedDbs_AddString | Out-GridView -Title "Insert Queries"

#Remove-Variable -Name NotBackedDbs