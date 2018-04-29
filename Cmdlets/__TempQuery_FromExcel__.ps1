#Get-Command *excel*
#help Import-Excel -Full

$exclFile = 'C:\temp\SQLDBATools\DBServers_master.xlsx';

#Import-Excel -Path $exclFile -WorksheetName Production | Where-Object {[String]::IsNullOrEmpty($_.'Server/Instance Name') -eq $false} | ft -AutoSize -Wrap

$servers = Import-Excel -Path $exclFile -WorksheetName Production | Where-Object {[String]::IsNullOrEmpty($_.'Server/Instance Name') -eq $false} | 
                Select-Object 'Server/Instance Name', Domain, @{l='ServerName';e={ ((($_.'Server/Instance Name').Split('\'))[0]).Trim() }} | 
                    Select-Object Domain, @{l='ComputerName';e={if([String]::IsNullOrEmpty($_.Domain)){$_.ServerName+'.Corporate.Local'}else{$_.ServerName+'.'+$_.Domain}}} |
                        Select-Object -ExpandProperty ComputerName

foreach($computerName in $servers)
{
    #Get-ServerInfo -ComputerName $computerName;
    Add-ServerInfo -ComputerName $computerName -EnvironmentType Prod -CallTSQLProcedure No
}