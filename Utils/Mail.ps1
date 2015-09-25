Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Send-Gmail {
    Param(
        [Parameter(Mandatory=$True)]
        [string]$EmailFrom,
        [Parameter(Mandatory=$True)]
        [string[]]$EmailTo,
        [Parameter(Mandatory=$True)]
        [string]$Subject,
        [Parameter(Mandatory=$True)]
        [string]$Body,
        [switch]$Html
    )
    $message = New-Object System.Net.Mail.MailMessage
    $message.From = $EmailFrom
    $EmailTo | foreach { $message.To.Add($_) }
    $message.Subject = $Subject
    $message.IsBodyHtml = $Html
    $message.Body = $Body

    $SMTPClient = New-Object Net.Mail.SmtpClient("smtp.gmail.com", 587) 
    $SMTPClient.EnableSsl = $true 
    $SMTPClient.Credentials = [Net.NetworkCredential](Get-SavedCredential 'Gmail') 
    $SMTPClient.Send($message)
}

function Save-GmailCredential {
    Save-Credential -Key "Gmail"
}

function Send-MailGun {
    Param(
        [Parameter(Mandatory=$True)]
        [string]$MailGunDomain,
        [Parameter(Mandatory=$True)]
        [string]$EmailFrom,
        [Parameter(Mandatory=$True)]
        [string[]]$EmailTo,
        [Parameter(Mandatory=$True)]
        [string]$Subject,
        [Parameter(Mandatory=$True)]
        [string]$Body,
        [switch]$Html
    )
    $uri = "https://api.mailgun.net/v3/$MailGunDomain/messages"
    $requestBody = @{
        from=$EmailFrom;
        to=[string]::Join(";",$EmailTo);
        subject=$Subject;
    }
    if ($Html) {
        $requestBody += @{html = $Body}
    }
    else {
        $requestBody += @{text = $Body}
    }
    $cred = Get-SavedCredential 'MailGun'
    $result = Invoke-WebRequest -UseBasicParsing -Uri $uri -Body $requestBody -Method Post -Credential $cred
    if ($result.StatusCode -ne 200) {
        throw "Got status code $($result.StatusCode) when posting to $uri"
    }
}

function Save-MailGunCredential {
    Save-Credential -Key "MailGun"
}
