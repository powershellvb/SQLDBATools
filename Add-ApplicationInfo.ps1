Function Add-ApplicationInfo
{    
    [CmdletBinding()]
    Param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Mandatory=$True,
                   Position=1)]
        [Alias('Name')]
        [String]$ApplicationName,

        [ValidateSet(1,2,3,4,5)]
        [Parameter(Mandatory=$True,Position=2)]
        [Alias('ApplicationPriority')]
        [int]$Priority = 3,

        [Parameter(Mandatory=$True,Position=3)]
        [Alias('ApplicationOwner')]
        [String]$Owner,

        [Parameter(Position=4)]
        [Alias('DelegatedOwner')]
        [String]$DelegateOwner,

        [Parameter(Position=5)]
        [String]$OwnershipDelegationEndDate,

        [Parameter(Mandatory=$True,Position=6)]
        [Alias('ContactPrimary')] # Shoud be AD account
        [String]$PrimaryContact,

        [Parameter(Mandatory=$True,Position=7)]
        [Alias('ContactSecondary')]
        [String]$SecondaryContact,

        [Parameter(Position=8)]
        [String]$SecondaryContact2,

        [Parameter(Mandatory=$True,Position=9)]
        [Alias('Department')]
        [String]$BusinessUnit,

        [Parameter(Mandatory=$True,Position=10)]
        [Alias('ProductName')]
        [String]$Product        
    )

    Write-Host $ApplicationName;
}
