Function Export-Password
{
    [CmdletBinding()]
    Param (
        [Alias('FileName','Path')]
        [String]$FilePath
    )
    #https://www.pdq.com/blog/secure-password-with-powershell-encrypting-credentials-part-1/

    # Get UserName and Password from User
    $pass = Read-Host "Enter Password" -AsSecureString;
    if ($FilePath.Length -eq 0)
    {
        $FilePath = "E:\Ajay\Important Documents\Password_$(Get-Date -f "yyyy-MM-dd HHMM").txt";
    }

    $pass | ConvertFrom-SecureString | Out-File $FilePath;
    Write-Host "Secured Password saved into file $FilePath" -ForegroundColor Green;
}