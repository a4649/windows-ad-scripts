$secpasswd = ConvertTo-SecureString "email_pwd" -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("from@email.pt", $secpasswd)
$EmailFrom = "from@email.pt"
$EmailTo = "to@email.pt"
$Subject = "Users passwords about to expire"
$SMTPServer = "smtp.gmail.com"
$PasswordNotificationStartInDays = 2
$DaysToExpire = 1
$Encoding  = New-Object System.Text.utf8encoding 

$Body = @"
    <html>
        <body style="font-family:calibri"> 
"@

# Get todays date
$Today = Get-Date

# Get Group
$ADGroup = Get-ADGroupMember 'Domain Users'

# Get list of AD Users
$ADUsers = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} -Properties passwordlastset,msDS-UserPasswordExpiryTimeComputed

foreach ($ADUser in $ADUsers)
{
    
    # Parse password expiry date/time
    $PasswordExpiresOn = [DateTime]::FromFileTime([Int64]::Parse($ADUser."msDS-UserPasswordExpiryTimeComputed"))
    $DaysToExpire = (New-TimeSpan -Start $Today -End $PasswordExpiresOn).Days

    $DaysToExpire = $DaysToExpire -as [int]
    if ($DaysToExpire -lt 0)
    {
        $positiveNumber = 0 - $DaysToExpire
        $Body2 += "<br>$($ADUser.Name) password expired about $positiveNumber days ago<br>"
    }
    if ($DaysToExpire -le $PasswordNotificationStartInDays -and $DaysToExpire -ge 0)
    {

        $Body2 += "<br>$($ADUser.Name) password will expire in $DaysToExpire days<br>"
    }
    
}

$Body += $Body2
$Body +=@"
    </body>
    </html> 
"@

# If there any user, send email to IT support
if ([String]::IsNullOrEmpty($Body2))
    {
        Continue
    } Else {
        Send-MailMessage -SmtpServer $SMTPServer -Credential $cred -UseSsl -From $EmailFrom -To $EmailTo -Subject $Subject -BodyAsHtml $Body -Encoding $Encoding
    }

