Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PSModulePath {
    return $env:PSModulePath.split(";")[0]
}

function Install-ScriptInUserModule {
    [CmdletBinding()]
    Param(
      [switch]$SkipDll,
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
        $filter = ""
        if ($SkipDll) {
            $filter = "*.dll"
        }
        $modulesPath = Get-PSModulePath
        $moduleTargetPath = Join-Path -Path $modulesPath -ChildPath $ModuleName
        if(Test-Path $moduleTargetPath) {
            Remove-Item $moduleTargetPath -Force -Recurse -Exclude $filter
            Write-Verbose "Removed directory $moduleTargetPath"
        }
        if(-not (Test-Path $moduleTargetPath)) { # Folder might still be there because of $filter
            New-Item -Path $moduleTargetPath -ItemType Directory | Out-Null
        }
        Write-Verbose "Created directory $moduleTargetPath"
        # Copy file
        $newFilePath = Join-Path -Path $moduleTargetPath "$ModuleName.psm1"
        Copy-Item $filePath $newFilePath
        $allFilesSource = Join-Path $Path "*"
        Copy-Item $allFilesSource $moduleTargetPath -Exclude $expectedModuleFile,$filter
        Write-Verbose "Copied $Path to $moduleTargetPath"
    }
}

function Install-AllSciptsInUserModule {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$True)]
      [System.IO.DirectoryInfo] $Path,
      [switch]$SkipDll
    )
    $modules = Get-ChildItem -Path $Path -Filter *.ps1 -Recurse |
        %{ $_.Directory } |
        select -Unique
    if ($SkipDll) {
        $modules | Install-ScriptInUserModule -SkipDll
    }
    else {
        $modules | Install-ScriptInUserModule
    }
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

function Get-HtmlAttribute {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$true)]
      [string] $AttributeName,
      [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
      [HtmlAgilityPack.HtmlNode] $Node
    )
    Process {
        if ($Node.Attributes.Contains($AttributeName)) { 
            return $Node.Attributes[$AttributeName].Value
        }
        return $null
    }
}

function Convert-HtmlNode {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$false)]
      [string[]] $AttributeNames,
      [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
      [HtmlAgilityPack.HtmlNode] $Node
    )
    Process {
        $converted = @{
            OuterHtml = $Node.OuterHtml
            InnerHtml = $Node.InnerHtml
        }
        if ($AttributeNames -ne $null) {
            $AttributeNames | foreach {
                $value = Get-HtmlAttribute -AttributeName $_ -Node $Node
                $converted.Add($_,$value)
            }
        }
        return New-Object psobject -Property $converted
    }
}

function Read-Html {
    [CmdletBinding()]
    [OutputType("HtmlAgilityPack.HtmlNode")]
    Param(
      [Parameter(Mandatory=$True)]
      [string] $Url
    )

    $hw = New-Object HtmlAgilityPack.HtmlWeb
    $doc = $hw.Load($Url)

    return $doc.DocumentNode
}

function Select-HtmlByXPath {
    [CmdletBinding()]
    [OutputType("HtmlAgilityPack.HtmlNode")]
    param(
        [Parameter(Mandatory=$True)]
        [string]$XPath,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        $foundNodes = $Node.SelectNodes($XPath)
        if ($foundNodes -eq $null) {
            return @()
        }
        return $foundNodes
    }
}

function Select-HtmlLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//a[@href]"
    }
}

function Select-HtmlImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//img[@src]"
    }
}

function Select-HtmlByClass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Class,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//*[contains(@class,'$Class')]"
    }
}

function Select-HtmlById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Id,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//*[@id='$Id']"
    }
}

#Read-Html "http://www.blocket.se/orebro/Hemnes_sanggavel_2_st_90_sangar_59591317.htm?ca=8&amp;w=1" |
#    Select-HtmlById -Id main_image| Convert-HtmlNode class,id | Format-Table -Wrap
#Install-ScriptInUserModule -Path C:\Mippel\PowerShell\Utils -Verbose
#Install-AllSciptsInUserModule -Path C:\Mippel\PowerShell -Verbose