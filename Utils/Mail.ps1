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

function Invoke-MailGunMonitoredCommand(){
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [string]$MailGunDomain,
        [Parameter(Mandatory=$True)]
        [string]$YourEmail,
        [Parameter(Mandatory=$True)]
        [string]$Command
    )
    $lastErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    $output = powershell -ExecutionPolicy RemoteSigned -NoProfile -NoLogo -Command $Command 2>&1
    $ErrorActionPreference = $lastErrorActionPreference
    $err = $output | ?{$_.gettype().Name -eq "ErrorRecord"}
    if($err){
        Add-Type -AssemblyName System.Web
        $htmlCommand = [System.Web.HttpUtility]::HtmlEncode($Command)
        $htmlOutput = [System.Web.HttpUtility]::HtmlEncode([string]::Join([System.Environment]::NewLine, $output)) -replace " ","&nbsp;" -replace [System.Environment]::NewLine,"<br />" -replace "<br /><br />","<br />"
        $body = @"
<h2>A monitored PowerShell command failed!</h3>
<h3>Command:</h3>
<code>$Command</code>
<h3>Output</h3>
<code>$htmlOutput</code>
"@
        Send-MailGun -MailGunDomain $MailGunDomain -EmailFrom $YourEmail -EmailTo $YourEmail -Subject "Monitored PowerShell failed!" -Body $body -Html
        throw $err
    }
    Write-Output $output
}