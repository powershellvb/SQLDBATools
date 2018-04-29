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
        [Alias('ApplicationOwner_EmailId')]
        [String]$Owner_EmailId,

        [Parameter(Mandatory=$false,Position=4)]
        [String]$DelegatedOwner_EmailId,

        [Parameter( Position=5, Mandatory=$false, HelpMessage="Enter DateTime in 24 hours format (yyyy-MM-dd hh:mm:ss)")]
        [String]$OwnershipDelegationEndDate = $null,

        [Parameter(Mandatory=$True,Position=6)]
        [Alias('ContactPrimary_EmailId')] # Shoud be AD account
        [String]$PrimaryContact_EmailId,

        [Parameter(Mandatory=$false,Position=7)]
        [Alias('ContactSecondary_EmailId')]
        [String]$SecondaryContact_EmailId,

        [Parameter(Mandatory=$false,Position=8)]
        [String]$SecondaryContact2_EmailId,

        [Parameter(Mandatory=$True,Position=9)]
        [Alias('Department')]
        [String]$BusinessUnit,

        [Parameter(Mandatory=$True,Position=10)]
        [Alias('ProductName')]
        [String]$Product,  

        [Parameter(Mandatory=$false,Position=11)]
        [Alias('GeneralDescription')]
        [String]$Description
    )

    $AddSwitch = $true;
    <#  $name = 'Marc Axler'
        $sam = (Get-ADUser -Filter {Name -eq $name}).SamAccountName
        (Get-ADUser -Identity $sam -Properties EmailAddress).EmailAddress
    #>

    # Verify Owner
    $Owner = Get-ADUser -Filter {EmailAddress -eq $Owner_EmailId};
    if($Owner -eq $null) {
        $AddSwitch = $false;
        Write-Host "`$Owner_EmailId = '$Owner_EmailId' is invalid" -ForegroundColor Red;
    }
    else {
        $Owner_FullName = $Owner.Name;
        Write-Host "Owner name = $Owner_FullName" -ForegroundColor Yellow;
    }

    # Verify DelegatedOwner_EmailId
    if([String]::IsNullOrEmpty($DelegatedOwner_EmailId) -eq $false)
    {
        $DelegatedOwner = Get-ADUser -Filter {EmailAddress -eq $DelegatedOwner_EmailId};
        if($DelegatedOwner -eq $null) {
            $AddSwitch = $false;
            Write-Host "`$DelegatedOwner_EmailId = '$DelegatedOwner_EmailId' is invalid" -ForegroundColor Red;
        }
        else {
            $DelegatedOwner_FullName = $DelegatedOwner.Name;
            Write-Host "DelegatedOwner = $DelegatedOwner_FullName" -ForegroundColor Yellow;
        }
    }

    if ([string]::IsNullOrEmpty($OwnershipDelegationEndDate) -eq $false) 
    {
        # StopAt in String format
        try 
        {   
            Write-Verbose "`$OwnershipDelegationEndDate = '$OwnershipDelegationEndDate'";

            $format = "yyyy-MM-dd HH:mm:ss";
            Write-Verbose "`$format = '$format'";

            $OwnershipDelegationEndDate_Time = [DateTime]::ParseExact($OwnershipDelegationEndDate, $format, $null);
            Write-Verbose "`$OwnershipDelegationEndDate_Time = '$OwnershipDelegationEndDate_Time'";

            $OwnershipDelegationEndDate_String = ($OwnershipDelegationEndDate_Time).ToString('MMM dd, yyyy hh:mm:ss tt');
            Write-Verbose "`$OwnershipDelegationEndDate_String = '$OwnershipDelegationEndDate_String'";
        }
        catch 
        {
            Write-Error "Invalid datetime format specified for `$OwnershipDelegationEndDate parameter. Kindly use format:  (yyyy-MM-dd hh:mm:ss)";
            return;
        }
    }

    # Verify PrimaryContact
    $PrimaryContact = Get-ADUser -Filter {EmailAddress -eq $PrimaryContact_EmailId};
    if($PrimaryContact -eq $null) {
        $AddSwitch = $false;
        Write-Host "`$PrimaryContact_EmailId = '$PrimaryContact_EmailId' is invalid" -ForegroundColor Red;
    }
    else {
        $PrimaryContact_FullName = $PrimaryContact.Name;
        Write-Host "PrimaryContact_FullName = $PrimaryContact_FullName" -ForegroundColor Yellow;
    }

    # Verify SecondaryContact
    if([String]::IsNullOrEmpty($SecondaryContact_EmailId) -eq $false)
    {
        $SecondaryContact = Get-ADUser -Filter {EmailAddress -eq $SecondaryContact_EmailId};
        if($SecondaryContact -eq $null) {
            $AddSwitch = $false;
            Write-Host "`$SecondaryContact_EmailId = '$SecondaryContact_EmailId' is invalid" -ForegroundColor Red;
        }
        else {
            $SecondaryContact_FullName = $SecondaryContact.Name;
            Write-Host "SecondaryContact_FullName = $SecondaryContact_FullName" -ForegroundColor Yellow;
        }
    }

    # Verify SecondaryContact2
    if([String]::IsNullOrEmpty($SecondaryContact2_EmailId) -eq $false)
    {
        $SecondaryContact2 = Get-ADUser -Filter {EmailAddress -eq $SecondaryContact2_EmailId};
        if($SecondaryContact2 -eq $null) {
            $AddSwitch = $false;
            Write-Host "`$SecondaryContact2_EmailId = '$SecondaryContact2_EmailId' is invalid" -ForegroundColor Red;
        }
        else {
            $SecondaryContact2_FullName = $SecondaryContact2.Name;
            Write-Host "SecondaryContact2_FullName = $SecondaryContact2_FullName" -ForegroundColor Yellow;
        }
    }
    
    # Add Application Now
    if($AddSwitch)
    {
        #ApplicationName, BusinessUnit, Product, Priority, Owner_EmailId, 
        #DelegatedOwner_EmailId, OwnershipDelegationEndDate, PrimaryContact_EmailId,
        #SecondaryContact_EmailId, SecondaryContact2_EmailId, CollectionTime
        $props = [Ordered]@{
                    'ApplicationName' = $ApplicationName;
                    'BusinessUnit' = $BusinessUnit;
                    'Product' = $Product;
                    'Priority' = $Priority;
                    'Owner_EmailId' = $Owner_EmailId;
                    'DelegatedOwner_EmailId' = $DelegatedOwner_EmailId;
                    'OwnershipDelegationEndDate' = $OwnershipDelegationEndDate_Time;
                    'PrimaryContact_EmailId' = $PrimaryContact_EmailId;
                    'SecondaryContact_EmailId' = $SecondaryContact_EmailId;
                    'SecondaryContact2_EmailId' = $SecondaryContact2_EmailId;
                    'CollectionTime' = [DateTime]((Get-Date).ToString("yyyy-MM-dd HH:mm:ss"));
                }
        $obj = New-Object -TypeName psobject -Property $props;

        # Convert data into SQL Format
        $dtable = $obj | Out-DataTable;
        if($PSCmdlet.MyInvocation.BoundParameters["Verbose"].IsPresent)
        {
            Write-Host "VERBOSE: Showing data from `$dtable : " -ForegroundColor Yellow;
            $dtable | fl;
        } 
        
        $cn = new-object System.Data.SqlClient.SqlConnection("Data Source=$InventoryInstance;Integrated Security=SSPI;Initial Catalog=$InventoryDatabase");
        $cn.Open();

        $bc = new-object ("System.Data.SqlClient.SqlBulkCopy") $cn;
        $bc.DestinationTableName = "Staging.ApplicationInfo";
        $bc.WriteToServer($dtable);
        $cn.Close();

        # Populate Main table from Staging
        $sqlQuery = @"
    EXEC [Staging].[usp_ETL_ApplicationInfo];
"@;
        Invoke-Sqlcmd -ServerInstance $InventoryInstance -Database $InventoryDatabase -Query $sqlQuery;
        Write-Host "Application Added Successfully." -ForegroundColor Green;
    }
    else 
    {
        Write-Host "Application could not be added. Kindly validate passed parameters" -ForegroundColor DarkMagenta -BackgroundColor Yellow;
        return;
    }
}
<#
Add-ApplicationInfo -ApplicationName 'Cosmo' `
                    -Priority 1 `
                    -Owner_EmailId 'Matt.Dymek@tivo.com' `
                    -DelegatedOwner_EmailId 'ajay.dwivedi@tivo.com' `
                    -OwnershipDelegationEndDate $null `
                    -PrimaryContact_EmailId 'Sameer.Jadhav@tivo.com' `
                    -SecondaryContact_EmailId 'Marc.Axler@tivo.com' `
                    -SecondaryContact2_EmailId 'Nasir.Malik@tivo.com' `
                    -BusinessUnit 'MetaData' `
                    -Product 'Cosmo ' `
                    -Description $null #-Verbose

#>