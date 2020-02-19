function Get-SpaceToAdd {
<#
    .SYNOPSIS
        This function return the space required to be added to make space free upto threshold

    .DESCRIPTION
        Function accepts current UsedSpace & Target Free space threshold, and gives the space in GB to be added

    .PARAMETER UsedSpace_GB
        Value in Giga bytes for used space on drive

    .PARAMETER Percent_Free_Space_Required
        Value between 1 to 100 that would be considered as target free space threshold percentage required

    .EXAMPLE
        Get-SpaceToAdd -UsedSpace_GB 1425 -TotalSpace_GB 1677

        This command give the size in gb to be added to make a total of 35% free space when used space is 1425 gb.
    .LINK
        https://github.com/imajaydwivedi/SQLDBATools

#>
    [CmdletBinding()]
    Param (
        [float]$TotalSpace_GB = $null,
        [Parameter(Mandatory=$true)]
        [float]$UsedSpace_GB,
        [Parameter(Mandatory=$false)]
        [float]$Percent_Free_Space_Required = 35.0
    )

    Write-Verbose "Declaring local variables";
    $Percent_Used_Space_Required = 100-$Percent_Free_Space_Required;

    $NewTotalSize_GB = ($UsedSpace_GB * 100.0)/$Percent_Used_Space_Required;
    Write-Verbose "`$NewTotalSize_GB = $NewTotalSize_GB";

    Write-Debug "debug here"

    if([string]::IsNullOrEmpty($TotalSpace_GB) -or $TotalSpace_GB -eq 0) {
        Write-Host "New total of " -NoNewline;
        Write-Host "$([math]::Round($NewTotalSize_GB,2))" -ForegroundColor Green -NoNewline;
        Write-Host " gb is required for $Percent_Free_Space_Required% target free space";
    }
    else {
        Write-Host "Add " -NoNewline;
        Write-Host "$([math]::Round($NewTotalSize_GB-$TotalSpace_GB,2))" -ForegroundColor Green -NoNewline;
        Write-Host " gb more space to make a total of $([math]::Round($NewTotalSize_GB,2)) gb size leaving $Percent_Free_Space_Required% free space"
    }
}
