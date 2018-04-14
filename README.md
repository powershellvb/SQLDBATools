# SQLDBATools
Powershell Module containing cmdlets for carrying out SQL DBA activities. It includes:-

<b>1)</b>
PS C:\\> <b>Get-ServerInfo</b> -ServerName 'BAN-1ADWIVEDI-L'
<table>
  <tr><td>ComputerName</td><td>:</td><td>BAN-1ADWIVEDI-L</td></tr>
  <tr><td>OS</td><td>:</td><td>Microsoft Windows 7 Professional</td></tr>
  <tr><td>SPVersion</td><td>: </td><td>Service Pack 1</td></tr>
  <tr><td>LastBootTime</td><td>:</td><td></td></tr>
  <tr><td>Model</td><td>:</td><td>HP EliteBook 840 G3</td></tr>
  <tr><td>RAM(MB)</td><td>:</td><td>8073</td></tr>
  <tr><td>CPU</td><td>:</td><td>4</td></tr>
 </table>

This function returns basic information about machine passed as parameter.


<b>2)</b>
PS C:\\> <b>Get-VolumeInfo</b> -ComputerName 'BAN-1ADWIVEDI-L' | ft -AutoSize
<table>
<tr><td>ComputerName   </td><td>VolumeName</td><td><td>Capacity(GB)</td><td>Used Space(GB)</td><td>Used Space(%)</td><td>FreeSpace(GB)</td><td>Label   </td></tr>
<tr><td>------------   </td><td>----------</td><td><td>------------</td><td>--------------</td><td>-------------</td><td>-------------</td><td>-----   </td></tr>
<tr><td>BAN-1ADWIVEDI-L</td><td>C:\       </td><td><td>         237</td><td>           102</td><td>           43</td><td>          134</td><td>		   </td></tr>
<tr><td>BAN-1ADWIVEDI-L</td><td>D:\       </td><td><td>           2</td><td>             0</td><td>            4</td><td>            2</td><td>HP_TOOLS</td></tr>
</table>

This function returns utilization of Disk Volumes on machine including mounted volumes.

## Script-SQLDatabaseRestore

This function accepts backup path, data and log directory for restore operation on destination sql instance, and create RESTORE script for database restore/migration activity.
It can be used for performing database restore operation with latest available backups on BackupPath.
Can be used to restore database for Point In Time.
Can be used for restoring database with new name on Destination SQL Instance.

![](GitHub_Images/Help___Script-SQLDatabaseRestore.gif)

For more information on how to use this, kindly [watch below YouTube video](https://youtu.be/v4r2lhIFii4):-

[![Watch this video](GitHub_Images/PlayThumbnail____Script-SQLDatabaseRestore.jpg)](https://youtu.be/v4r2lhIFii4)
