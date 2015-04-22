$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')

. "$here\cSharp.ps1"
. "$here\$sut"

function Is-AllUsingAtTheTop([string]$Content) {
    $noMoreUsingFound = $false
    $result = $true
    $Content.Split([System.Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries) | 
        foreach {
            if ($_ -match '^ *using .*; *$') {
                if ($noMoreUsingFound) {
                    Write-Warning "Found unexpected $_"
                    $result = $false
                }
            }
            else {
                $noMoreUsingFound = $true
            }
        }
    return $result
}

Describe 'Utils/FileWatch' {
    Context 'Start-FileWatch' {
        if (Get-Variable -Name 'PesterWatchRunning' -ErrorAction SilentlyContinue) {
            Write-Warning 'Aborting test to prevent deadlocks'
            return
        }

        $root = Get-Item TestDrive:\
        New-Item TestDrive:\FileWithContentChange.txt -ItemType File
        $watch = Start-FileWatch -Path $root -Exclude '\.git' -Verbose -Action {
            function Get-ChangedFile([string]$Name, $ChangedFiles) {
                return  $ChangedFiles | ?{ $_ -ne $null -and $_.EndsWith($Name) }
            }

            $changedFiles = $eventArgs.Files
            Write-Host "Detected changed files: $changedFiles"

            It 'detects new files with content' {
                Get-ChangedFile 'NewFileWithContent.txt' $changedFiles | Should Not BeNullOrEmpty
            }

            It 'detects file content changes' {
                Get-ChangedFile 'FileWithContentChange.txt' $changedFiles | Should Not BeNullOrEmpty
            }

            It 'ignores excluded files' {
                Get-ChangedFile 'ExcludedFile.txt' $changedFiles | Should BeNullOrEmpty
            }
        }
        # File with content
        'dummy text' | Out-File TestDrive:\NewFileWithContent.txt
        # File with changed content
        Set-Content -Path TestDrive:\FileWithContentChange.txt -Value 'new content'
        # File to ignore
        New-Item TestDrive:\.git -ItemType Dir
        'dummy text' | Out-File TestDrive:\.git\ExcludedFile.txt
        Start-Sleep -Milliseconds 1000
        $watch | Stop-FileWatch
    }
}
