function Get-VolumeSpaceConsumers
{
   <#
    .SYNOPSIS 
      Displays all files and folders with sizing information for folder on computerName.
    .DESCRIPTION
      This gives all files and folders including hidden items with details like Owner, Size, Created Date, Updated By etc path passed in parameter.
    .PARAMETER  ComputerName
      Computer name on which the folder to analyze is present.
    .PARAMETER  pathOrFolder
      Folder or drive path which needs to be analyzed
    .EXAMPLE
      PS C:\> Get-VolumeSpaceConsumers -ComputerName $env:computerName -pathOrFolder 'D:\' | Out-GridView

      Returns all files and folder with size, owner, and last modified date.

    .LINK
      https://github.com/imajaydwivedi/SQLDBATools
  #>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias('ServerName','MachineName')]
        [String]$ComputerName = $env:ComputerName,

        [Parameter( Mandatory=$true )]
        [Alias('FolderOrPath')]
        [String]$pathOrFolder
    )

    $searchPath = "\\$ComputerName\$pathOrFolder" -replace ":","$";
    Write-Host "`$searchPath = '$searchPath'" -ForegroundColor Green;
    
    # Get Folders
    Write-Host "   Finding all folders on search path" -ForegroundColor Green;
    $folders = Get-ChildItem -Path $searchPath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer} |
                    Select-Object @{l='Name';e={$_.FullName -replace "\\\\$computerName\\", ""}}, @{l='Parent';e={(Split-Path -Path $_.FullName) -replace "\\\\$computerName\\", ""}}, @{l='SizeBytes';e={[bigint]$null}}, @{l='Size(KB)';e={[bigint]$null}}, @{l='Size(MB)';e={[bigint]$null}}, @{l='Size(GB)';e={[bigint]$null}}, @{l='Owner';e={((Get-ACL $_.FullName).Owner)}}, CreationTime, LastAccessTime, LastWriteTime, @{l='IsFolder';e={1}}, @{l='SortColumn';e={$_.FullName -replace "\\\\$computerName\\", ""}};
    # Get Base Details
    $baseFolder = Get-ItemProperty -Path $searchPath |
                    Select-Object @{l='Name';e={$_.FullName -replace "\\\\$computerName\\", ""}}, @{l='Parent';e={$null}}, @{l='SizeBytes';e={[bigint]$null}}, @{l='Size(KB)';e={[bigint]$null}}, @{l='Size(MB)';e={[bigint]$null}}, @{l='Size(GB)';e={[bigint]$null}}, @{l='Owner';e={((Get-ACL $_.FullName).Owner)}}, CreationTime, LastAccessTime, LastWriteTime, @{l='IsFolder';e={1}}, @{l='SortColumn';e={$null}};
    # Get all containers as One
    $folders = $folders + $baseFolder;

    # Get All Files
    Write-Host "   Finding all files on search path" -ForegroundColor Green;
    $files = Get-ChildItem -Path $searchPath -Recurse -Force -ErrorAction SilentlyContinue | Where-Object {$_.PSIsContainer -eq $false} | ForEach-Object {$counter = 1} {$counter++; $_ | Add-Member -Name ID -Value $counter -MemberType NoteProperty -PassThru} |
                ForEach-Object { New-Object -TypeName psobject -Property `
                                    @{
                                        'Name' = $_.Name;
                                        'Parent' = ((Split-Path -Path $_.FullName) -replace "\\\\$computerName\\", "");
                                        'SizeBytes' = [bigint]$_.Length;
                                        'Size(KB)' = [bigint]($_.Length/1kb);
                                        'Size(MB)' = [bigint]($_.Length/1mb);
                                        'Size(GB)' = [bigint]($_.Length/1gb);
                                        'Owner' = ((Get-ACL $_.FullName).Owner);
                                        'CreationTime' = $_.CreationTime;
                                        'LastAccessTime' = $_.LastAccessTime;
                                        'LastWriteTime' = $_.LastWriteTime;
                                        'IsFolder' = 0;
                                        'SortColumn' = ((Split-Path -Path $_.FullName) -replace "\\\\$computerName\\", "");
                                     }
                               } | Select-Object Name, Parent, SizeBytes, 'Size(KB)', 'Size(MB)', 'Size(GB)',Owner, CreationTime, LastAccessTime, LastWriteTime, IsFolder, SortColumn;
    
    Write-Host "   Computing Size for folders.." -ForegroundColor Green;
    foreach($f in $folders)
    {
        # Get Size of folders
        $f.SizeBytes = [bigint]($files | Where-Object {$_.Parent -like "$($f.Name)*"} | Measure-Object -Property SizeBytes -Sum).Sum;
        $f.'Size(MB)' = [bigint]($files | Where-Object {$_.Parent -like "$($f.Name)*"} | Measure-Object -Property SizeBytes -Sum).Sum/1mb;
        $f.'Size(KB)' = [bigint]($files | Where-Object {$_.Parent -like "$($f.Name)*"} | Measure-Object -Property SizeBytes -Sum).Sum/1kb;
        $f.'Size(GB)' = [bigint]($files | Where-Object {$_.Parent -like "$($f.Name)*"} | Measure-Object -Property SizeBytes -Sum).Sum/1gb;
    }

    $finalResult = $folders + $files;
    Write-Host "   Writing the result to default Output.." -ForegroundColor Green
    $finalResult | Sort-Object -Property SortColumn, @{Expression="IsFolder";Descending=$true}, Name | ForEach-Object {$counter = 0} {$counter++; $_ | Add-Member -Name SortingOrderID -Value $counter -MemberType NoteProperty -PassThru} |    
                        Select-Object @{l='Name';e={if($_.IsFolder){$_.Name}else{ ("     |" * (($_.Parent).Length + 1 - (($_.Parent -replace "\\","").Length))) + "   $($_.Name)" }}}, @{l='Parent';e={if(($_.Parent).Length -eq 2){$_.Parent+'\'}else{$_.Parent}}}, SizeBytes, 'Size(KB)', 'Size(MB)', 'Size(GB)', Owner, CreationTime, LastAccessTime, LastWriteTime, IsFolder, @{l='FileName';e={if($_.IsFolder){$null}else{$_.Name}}}, SortingOrderID | 
                            Select-Object @{l='Name';e={if($_.Name.Substring(1,1) -eq '$') { $_.Name.Insert(1,':').Remove(2,1); } else { $_.Name; }}},
                                          @{l='Parent';e={if($_.Parent.Substring(1,1) -eq '$') { $_.Parent.Insert(1,':').Remove(2,1); } else { $_.Parent; }}}, 
                                          SizeBytes, 'Size(KB)', 'Size(MB)', 'Size(GB)', Owner, CreationTime, LastAccessTime, LastWriteTime, IsFolder, 
                                          @{l='FileName';e={if($_.FileName.Substring(1,1) -eq '$') { $_.FileName.Insert(1,':').Remove(2,1); } else { $_.FileName; }}},
                                          SortingOrderID |
                            Write-Output;
}
