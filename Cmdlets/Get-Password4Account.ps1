function Get-Password4Account {
    <#
        .SYNOPSIS
            Return password value for UserName either in plain text or as secure string.
        .DESCRIPTION
            The function accepts UserName that is saved in "$SQLDBATools\SQLDBATools_Credentials.xml" file, and returns password either in plain text, or as secure string
        .PARAMETER UserName
            Name of account for which Password has to be fetched
        .PARAMETER AsSecureString
            Return password as SecureString rather than plain text
        .EXAMPLE
            $username = "Contso\SQLServices";
            $username | Get-Password4Account;

            Return plain password for $UserName from file "$SQLDBATools\SQLDBATools_Credentials.xml"

        .EXAMPLE
            $username = "Contso\SQLServices";
            $username | Get-Password4Account -AsSecureString;

            Return secure string password for $UserName from file "$SQLDBATools\SQLDBATools_Credentials.xml"

        .LINK
            https://github.com/imajaydwivedi/SQLDBATools
            https://stackoverflow.com/a/7469473/4449743
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [Alias('Account')]
        [String]$UserName,

        [parameter( Mandatory=$false)]
        [Switch]$AsSecureString
    )

    BEGIN {}
    PROCESS {
        if($_ -ne $null) {
            $UserName = $_;
            Write-Verbose "Received value from pipeline.";
        }
        #[System.Security.SecureString]$Password
        # Recover Password
        # File Path for Credentials & Key
        $SQLDBATools = Get-Module -ListAvailable -Name SQLDBATools | Select-Object -ExpandProperty ModuleBase;
        $AESKeyFilePath = "$SQLDBATools\SQLDBATools_AESKey.key";
        $credentialFilePath = "$SQLDBATools\SQLDBATools_Credentials.xml";
        $AESKey = Get-Content $AESKeyFilePath;
        $pwdTxt = (Import-Clixml $credentialFilePath | Where-Object {$_.UserName -eq $username}).Password;
        $securePwd = $pwdTxt | ConvertTo-SecureString -Key $AESKey;

        if($AsSecureString) {
            $password = $securePwd;
        }
        else {
            $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($securePwd)
            $password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
            [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
        }        
    }
    END {
        Write-Output $password;
    }
    
}
