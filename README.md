# SQLDBATools
Powershell Module containing cmdlets for carrying out SQL DBA activities. It includes:-

# Get-ServerInfo

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


# Get-VolumeInfo

This function returns utilization of Disk Volumes on machine including mounted volumes.

[![Watch this video](GitHub_Images/Get-VolumeInfo.gif)](https://youtu.be/n160GyC0g-8)

## Script-SQLDatabaseRestore

This function accepts backup path, data and log directory for restore operation on destination sql instance, and create RESTORE script for database restore/migration activity.
It can be used for performing database restore operation with latest available backups on BackupPath.
Can be used to restore database for Point In Time.
Can be used for restoring database with new name on Destination SQL Instance.

![](GitHub_Images/Help___Script-SQLDatabaseRestore.gif)

For more information on how to use this, kindly [watch below YouTube video](https://youtu.be/v4r2lhIFii4):-

[![Watch this video](GitHub_Images/PlayThumbnail____Script-SQLDatabaseRestore.jpg)](https://youtu.be/v4r2lhIFii4)
