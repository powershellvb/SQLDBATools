Function Send-SQLMail
{
    [CmdletBinding()]
    Param ( [String]$Subject,
            [Alias('Message')]
            [String]$Body,
            [String]$To = 'ajay.dwivedi2007@gmail.com'
    )

    #Setup Basic Information
    $From = 'sqlagentservice@gmail.com';
    $SMTPServer = "smtp.gmail.com";

    # Create the e-mail object
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
    
    # Enable SSL Protocol (Secure Socket Layers) so our e-mail will be sent securely
    $SMTPClient.EnableSsl = $true;

    # Create credential
    $User = 'sqlagentservice@gmail.com';
    $File = 'E:\Ajay\Important Documents\Password_4_sqlagentservice.txt'
    $MailCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, (Get-Content $File | ConvertTo-SecureString);
    
    # Create a credential objec we'll use to authenticate ourselves to the SMTP server
    $SMTPClient.Credentials = $MailCredential;
    
    # Finally, send the mail
    $SMTPClient.Send($From, $To, $Subject, $Body);
    Write-Host "Mail sent to $To.." -ForegroundColor Green;
}