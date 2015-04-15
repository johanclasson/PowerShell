Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

#Exported
function Send-NewMailAsForward {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$To,
        [string]$Prefix = "Work"
    )
    $mails = Get-NotForwardedMail
    if ($mails -eq $null) { 
        Write-Verbose "Found no new email"
        return
    }
    Write-Verbose "Found $(@($mails).length) new email"
    Forward-Mail -To $To -Mails $mails -Prefix $Prefix
    Save-ForwardedMails $mails
}

function Get-NotForwardedMail {
    $restrictFilter = "[ReceivedTime] > '$(Get-24HoursAgoInUsTime)'"
    $mails = Get-Email -RestrictFilter $restrictFilter |
        sort ReceivedTime
    return $mails | ?{
        -not (Is-MailForwarded -EntryID $_.EntryID) -and $_.MessageClass -eq "IPM.Note"
    }
}

function Get-24HoursAgoInUsTime {
    $date = (Get-Date).AddDays(-1.0)
    $culture = New-Object System.Globalization.CultureInfo("en-US")
    return [string]::Format($culture,"{0:M/d/yyyy h:mm tt}",$date)
}

function Save-ForwardedMails($mails) {
    $mails | ?{ Save-ForwardedMail $_.EntryId | Out-Null }
}

#Mocked
function Save-ForwardedMail([string]$EntryId) {
    New-Item -Path "sqlite:\ForwardedOutlookMail" -EntryId $EntryId
}

#Mocked
function Get-Email {
    param(
        [Parameter(Mandatory=$true)]
        [string]$RestrictFilter
    )
    #Add-type -assembly "Microsoft.Office.Interop.Outlook" | out-null 
    $olFolders = "Microsoft.Office.Interop.Outlook.olDefaultFolders" -as [type]
    $outlook = New-Object -ComObject Outlook.Application 
    $namespace = $outlook.GetNameSpace("MAPI") 
    $folder = $namespace.getDefaultFolder($olFolders::olFolderInBox) 
    return $folder.items.Restrict($RestrictFilter) #| Select-Object -Property EntryID,To,SenderName,ReceivedTime,Subject,Body
}

#Mocked
function Forward-Mail {
    param(
        [Parameter(Mandatory=$true)]
        $Mails,
        [Parameter(Mandatory=$true)]
        [string]$To,
        [Parameter(Mandatory=$true)]
        [string]$Prefix
    )
    $Mails | foreach {
        $senderName = $_.SenderName
        $subject = $_.Subject
        $f = $_.Forward()
        $f.Recipients.Add($To) | Out-Null
        $f.Subject = "$($Prefix): ($senderName) $subject"
        Write-Verbose "Sending '$($f.Subject)' to $To"
        $f.Send()
    }
}

#Mocked
function Is-MailForwarded {
       param(
        [Parameter(Mandatory=$true)]
        [string]$EntryId
       )
       if ([string]::IsNullOrEmpty($EntryId)) { throw "Got an empty EntryID" }
       return Test-Path "sqlite:\ForwardedOutlookMail\$EntryId"
}
