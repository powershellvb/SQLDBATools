function Get-OrphanDatabaseFiles {
<#
    .SYNOPSIS
    Get databases files present on disk that are not active, and require deletion
    .DESCRIPTION
    This function accepts SqlInstance name & Drive path to return all the orphan data/log files that are not part of any active database.
    .PARAMETER SqlInstance
    Name of Sql server instance
    .PARAMETER Directory
    Path of folder which will be scanned recursively to find database files (*.mdf, *.ldf, *.ndf)
    .EXAMPLE
    Get-OrphanDatabaseFiles -SqlInstance dbsep2018 -Directory 'F:\'
    Gets orphan database files on path F:\ of server dbsep2018
    .LINK
    https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$SqlInstance,

        [Parameter(Mandatory=$true)]
        [Alias('Path','DrivePath','FileLocation','FileDirectory')]
        [string]$Directory
    )

    Write-Verbose "Validating Parameters..";
    $ComputerName = $SqlInstance.Split('\')[0];

    $tsqlQuery = @"
    select db_name(mf.database_id) as dbName, mf.name, mf.type_desc, mf.physical_name 
    from sys.master_files mf where mf.physical_name like '$Directory%';
"@;

    Write-Verbose "Executing query to find database files on SqlInstance [$SqlInstance]";
    $rs = Invoke-DbaQuery -SqlInstance $SqlInstance -Query $tsqlQuery;

    Write-Verbose "Executing remote script on computer [$ComputerName] to find database files present on disk"
    $scriptBlock = {
        Get-ChildItem -Path $Using:Directory -Recurse | Where-Object {-not $_.PSIsContainer} | Where-Object {$_.Extension -eq '.mdf' -or $_.Extension -eq '.ndf' -or $_.Extension -eq '.ldf'}
    }
    $files = Invoke-Command -ComputerName $ComputerName -ScriptBlock $scriptBlock;


    $dbFiles = $rs | Select-Object -ExpandProperty physical_name;
    $diskFiles = $files;

    Write-Verbose "Filtering orphan files";
    [System.Collections.ArrayList]$orphanFiles = @();
    foreach($fl in $diskFiles)
    {
        $diskFile = $fl.FullName;
        $diskFileProps = [Ordered]@{file = $fl.FullName}
        $diskFileObj = New-Object -TypeName psobject -Property $diskFileProps;

        if($diskFile -in $dbFiles) {
            Write-Verbose "$diskFile is ACTIVE file";
        }
        else {
            $orphanFiles.Add($diskFileObj) | Out-Null;
        }
    }

    Write-Output $orphanFiles;
}


