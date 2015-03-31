Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PSModulePath {
    return $env:PSModulePath.split(";")[0]
}

function Install-ScriptInUserModule {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
      [Alias('FullName')]
      [string] $Path
    )
    Process {
        # Get correct file (apparently not so easy if relative paths to a FileInfo is used inside a module...)
        if (!(Test-Path $Path)) {
            Write-Error "File $Path does not exist!"
            return
        }
        $moduleSourceFolder = Get-Item $Path
        if (-not($moduleSourceFolder.Mode -match 'd')) {
            Write-Error "$Path is not a directory"
            return
        }
        $ModuleName = $moduleSourceFolder.Name
        $expectedModuleFile = "$ModuleName.ps1"
        $filePath = Join-Path $Path $expectedModuleFile
        if (-not(Test-Path $filePath)) {
            Write-Error "$Path does not have the expected file $expectedModuleFile"
            return
        }
        # Create folder
        $modulesPath = Get-PSModulePath
        $moduleTargetPath = Join-Path -Path $modulesPath -ChildPath $ModuleName
        if(Test-Path $moduleTargetPath) {
            Remove-Item $moduleTargetPath -Force -Recurse
            Write-Verbose "Removed directory $moduleTargetPath"
        }
        New-Item -Path $moduleTargetPath -ItemType Directory | Out-Null
        Write-Verbose "Created directory $moduleTargetPath"
        # Copy file
        $newFilePath = Join-Path -Path $moduleTargetPath "$ModuleName.psm1"
        Copy-Item $filePath $newFilePath
        $allFilesSource = Join-Path $Path "*"
        Copy-Item $allFilesSource $moduleTargetPath -Exclude $expectedModuleFile
        Write-Verbose "Copied $Path to $moduleTargetPath"
    }
}

function Install-AllSciptsInUserModule {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$True)]
      [System.IO.DirectoryInfo] $Path
    )
    Get-ChildItem -Path $Path -Filter *.ps1 -Recurse |
        %{ $_.Directory } |
        select -Unique |
        Install-ScriptInUserModule
}

# Install SQLite PS Module:
# https://psqlite.codeplex.com/

function Save-Credential {
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Key
    )
    $credential = Get-Credential -Message "Enter credentials to be used for ""$Key"""
    $username = $credential.UserName
    $password = ConvertFrom-SecureString $credential.Password
    new-item sqlite:/Credential -key $Key -username $username -password $password | Out-Null
}

function Get-SavedCredential() {
    Param(
        [Parameter(Mandatory=$True)]
        [string]$Key
    )
    function Get-Entry {
        return @(Get-ChildItem sqlite:\Credential -Filter "key='$Key'") | select username,password -First 1
    }
    $entry = Get-Entry
    if ($entry -eq $null) {
        Save-Credential $Key
        $entry = Get-Entry
    }
    $username = $entry.username
    $password = ConvertTo-SecureString $entry.password
    $credential = New-Object System.Management.Automation.PSCredential $username,$password
    return $credential
}

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

function Write-Log([string]$Message,[switch]$Error) {
    $logEntry = "[{0:yyyy-MM-dd HH:mm:ss.fff}] - $Message" -f (Get-Date)
    Write-Output $logEntry
    if ($Error) {
        $Message | Write-Error
    }
    else {
        $Message | Write-Verbose
    }
}

#Install-ScriptInUserModule -Path C:\Mippel\PowerShell\Utils -Verbose
#Install-AllSciptsInUserModule -Path C:\Mippel\PowerShell -Verbose