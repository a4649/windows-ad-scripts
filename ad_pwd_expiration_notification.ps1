####### change only these envs ####################

$Company = # your company name
$EmailAccount = # your email account
$EmailAccountPwd = # your email account password
$EmailFrom = # your email address
$Support = # your company support email address
$PasswordNotificationStartInDays = 10 
$SMTPServer = # your SMTP server address

###################################################

$SecPasswd = ConvertTo-SecureString $EmailAccountPwd -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($EmailAccount, $SecPasswd)
$Encoding  = New-Object System.Text.utf8encoding 

function Send-MailPasswordExpiresMessage
{
    [CmdletBinding()]
    Param
    (
        [String]$Name,
        [Int]$DaysToExpire,
        [String]$ToEmailAddress
    )
    
    $Subject = "Your $Company password will expire in $DaysToExpire days"

    $Body = @"
    <html>
        <body style="font-family:calibri"> 
            <b>Dear $Name,</b><br><br>
            <b>This message is to notify you that your $Company password will expire in $DaysToExpire day(s). Please consider to change it before expires.</b>
            <br><br>If you need further assistance or have questions, please contact $Support<br><br>
            Thank you 
        </body>
    </html>
"@

    Send-Mailmessage -smtpServer $SMTPServer -Credential $cred -UseSsl -from $EmailFrom -to $ToEmailAddress -subject $Subject -body $Body -bodyasHTML -priority High -Verbose -Encoding $Encoding
}

# Get todays date
$Today = Get-Date

# Get list of Active Directory Users
$ADUsers = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False} -Properties emailaddress,passwordlastset,msDS-UserPasswordExpiryTimeComputed

foreach ($ADUser in $ADUsers)
{   
    # Parse password expiry date/time
    $PasswordExpiresOn = [DateTime]::FromFileTime([Int64]::Parse($ADUser."msDS-UserPasswordExpiryTimeComputed"))
    $DaysToExpire = (New-TimeSpan -Start $Today -End $PasswordExpiresOn).Days
        
    # If the days to expire are between 1 & PasswordNotificationStartInDays, send an email to the user
    if (($DaysToExpire -ge '1') -and ($DaysToExpire -le $PasswordNotificationStartInDays))
    {
        Send-MailPasswordExpiresMessage -Name $($ADUser.Name) -DaysToExpire $DaysToExpire -ToEmailAddress $($ADUser.EmailAddress) -Verbose
    }
}