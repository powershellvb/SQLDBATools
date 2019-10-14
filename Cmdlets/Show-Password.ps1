function Show-Password {
    <#
        .SYNOPSIS
            Return raw password value from Secure String
        .DESCRIPTION
            The function accepts Secure String and return plan raw password
        .PARAMETER Password
            Secure String to be decrypted

        .EXAMPLE
            $password = ConvertTo-SecureString 'P@ssw0rd' -AsPlainText -Force
            $password | Show-Password

            Return raw string from Secure String variable $password

        .EXAMPLE
            Show-Password -Password (Get-StoredCredentials -Target 'SQLDBATools').Password;

            Returns password for Target 'SQLDBATools' from Windows Credential Manager.
        .LINK
            https://github.com/imajaydwivedi/SQLDBATools
            https://www.powershellgallery.com/packages/CredentialManagement/1.0.2
            https://stackoverflow.com/a/7469473/4449743
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [Alias('SecureString')]
        [System.Security.SecureString]$Password
    )

    BEGIN {}
    PROCESS {
        if($_ -ne $null) {
            $Password = $_;
            Write-Verbose "Received value from pipeline.";
        }

        $Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($password)
        $result = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
        [System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
    }
    END {
        Write-Output $result;
    }
    
}