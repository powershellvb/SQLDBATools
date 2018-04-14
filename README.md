# SQLDBATools
Powershell Module containing cmdlets for carrying out SQL DBA activities. It includes:-

## Get-ServerInfo
This function returns basic information about machine(s) passed in pipeline or as value. This includes Operating System, Service Pack, LastBoot Time, Model, RAM & CPU for computer(s).

![](GitHub_Images/Get-ServerInfo.gif)

## Get-VolumeInfo
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
