function Find-KeywordInSQLDBATools
{
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Mandatory=$True,
                   Position=1)]
        [Alias('Keywords','SearchKeywords')]
        [String[]]$KeywordsToSearch
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

    if($files.Count -gt 0) {
        Write-Host "Searching through files found.." -ForegroundColor Green;
        $searchResult = $files | Select-String -Pattern $KeywordsToSearch;
        Write-Verbose "Passing `$searchResult to Output pipeline.";
        $searchResult | Write-Output;
    } else {
        Write-Host "No files found to search" -ForegroundColor Red;
    }
    
}
<#
Clear-Host;
$searchKeywords = @('Clear-Host','cls');
Find-KeywordInSQLDBATools -KeywordsToSearch $searchKeywords | Select-Object Pattern, Filename, LineNumber, Line | ft -AutoSize -Wrap;
#>