Function Get-AdUserInfo
{
    [CmdletBinding()]
    Param (
        [String[]]$UserName_Ad
    )

    $UserInfo = @();
    foreach($wildCardName in $UserName_Ad)
    {
        Write-Verbose "Finding info for name like '$wildCardName'";
        $SearchKeyWord = "*$wildCardName*";
        $Users = Get-ADUser -Filter {Name -like $SearchKeyWord} | Select-Object * # multiple entries received
        #$Users | Select-Object * | Out-GridView

        foreach($User in $Users)
        {
            # Reset Variables
            $UserProps = $null;
            $obj = $null;
            $userGroups = $null;
            $userGroupsCommaSeparated = $null;

            $FullName = $User.Name;
            $LoginName = $User.SamAccountName; 
            $EmailId = (Get-ADUser -Identity $LoginName -Properties EmailAddress).EmailAddress;
            if([String]::IsNullOrEmpty($EmailId)) {
                $EmailId = $User.UserPrincipalName;
            }
            $userGroups = (Get-ADPrincipalGroupMembership $LoginName | Select-Object -ExpandProperty name);
            $userGroupsCommaSeparated = $userGroups -join ', ';

            $UserProps = [Ordered]@{
                                FullName = $FullName;
                                LoginName = $LoginName;
                                EmailId = $EmailId;
                                'Domain Groups' = $userGroupsCommaSeparated;
                            }
            $obj = New-Object -TypeName psobject -Property $UserProps;
            $UserInfo += $obj;
        }
        
    }

    Write-Host "Showing final result.." -ForegroundColor Green;
    $UserInfo | Out-GridView -Title "User Information";
}

<#
Import-Module ActiveDirectory;
Get-AdUserInfo -UserName 'Ajay' -Verbose
#>

