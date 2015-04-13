<#
TODO:
- Start-Job för att starta invoke-pester, alternativt att göra om event-actionen
  till att sätta $bool som triggar oändlig poll-slinga.
#>

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
<#
Works - F5 from PowerShell IDE
Works - Running .\utils.tests.ps1
Works - Invoke-Pester
Fails - Start-PesterWatch (even hangs after tests are run due to deadlock between stopping job/event and event itself)
#>
. "$here\$sut"

function Get-ChangedFile([string]$Name, $ChangedFiles) {
    return  $ChangedFiles | ?{ $_ -ne $null -and $_.EndsWith($Name) }
}

Describe "Utils" {
    Context "Start-FileWatch" {
        $root = Get-Item TestDrive:\
        New-Item TestDrive:\FileWithContentChange.txt -ItemType "File"
        $watch = Start-FileWatch -Path $root -Exclude "\.git" -Action {
            $changedFiles = $eventArgs.Files
            Write-Host "Detected changed files: $changedFiles"

            It "detects new files with content" {
                Get-ChangedFile "NewFileWithContent.txt" $changedFiles | Should Not BeNullOrEmpty
            }

            It "detects file content changes" {
                Get-ChangedFile "FileWithContentChange.txt" $changedFiles | Should Not BeNullOrEmpty
            }

            It "ignores excluded files" {
                Get-ChangedFile "ExcludedFile.txt" $changedFiles | Should BeNullOrEmpty
            }
        }
        # File with content
        "dummy text" | Out-File TestDrive:\NewFileWithContent.txt
        # File with changed content
        Set-Content -Path TestDrive:\FileWithContentChange.txt -Value "new content"
        # File to ignore
        New-Item TestDrive:\.git -ItemType Dir
        "dummy text" | Out-File TestDrive:\.git\ExcludedFile.txt
        Start-Sleep -Milliseconds 1000
        $watch | Stop-FileWatch -Verbose
    }
}
