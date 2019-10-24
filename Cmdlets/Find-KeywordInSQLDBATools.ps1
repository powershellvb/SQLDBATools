function Find-KeywordInSQLDBATools
{
<#
.SYNOPSIS
The function returns all searches for a keyword in all the scripts that are part of SQLDBATools module
.DESCRIPTION
The function returns all searches for a keyword in all the scripts that are part of SQLDBATools module
.PARAMETER KeywordsToSearch
Enter the keywork to search in all the scripts
.EXAMPLE
Find-KeywordInSQLDBATools -KeywordsToSearch SQLDBATools
This will display result whenever SQLDBATools keyword is found in any script
.EXAMPLE
'Clear-Host' | Find-KeywordInSQLDBATools | ogv
This will dislay result whenever any of the words in array are found inside scripts
.LINK
https://github.com/imajaydwivedi/SQLDBATools
#>
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Mandatory=$True,
                   Position=1)]
        [Alias('Keywords','SearchKeywords')]
        [String]$KeywordToSearch
    )

    # =========================================================
    # Iterate through all files
    # Get content of Each file
    # Find keyword 'Clear-Host' inside them
    # =========================================================

    Write-Verbose "Finding path for SQLDBATools Module";
    $modulePath = ((Get-Module -ListAvailable SQLDBATools).Path | Split-Path);

    Write-Verbose "Filtering files with extension *.ps1 & *.psm1";
    $fileExtension = @('.ps1','.psm1');

    $files = Get-ChildItem -Recurse -Path $modulePath | 
                Where-Object {$_.PSIsContainer -eq $false -and $_.Extension -in $fileExtension};

    # -Verbose
    if ($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent) {
        Write-Verbose "Below are the files found (`$files):- ";
        $files | ft -AutoSize;
    }

    $SearchResults = @();
    if($files.Count -gt 0) {
        $SearchResult = $files | Select-String -Pattern $KeywordToSearch;
        Write-Verbose "Passing `$searchResult to Output pipeline.";
        $SearchResult | Write-Output;
    } else {
        Write-Verbose "No files found to search";
    }
}