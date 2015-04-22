Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-PSModulePath {
    return $env:PSModulePath.split(";")[0]
}

function Get-FilenamesFromManifest([string]$ManifestPath) {
    if (-not (Test-Path $manifestFilePath)) {
        return @()
    }
    $content = gc $ManifestPath
    $foundVariable = $false
    $foundFilesVariable = $false
    $filenames = @()
    $content | %{
        if (-not ($_ -match '^\s*#')) {
            if ($_ -match '\s*\w+\s*=') {
                $foundFilesVariable = $false
                $foundVariable = $true
                if ($_ -match '\s*FileList\s*=') {
                    $foundFilesVariable = $true
                }
            }
            if ($foundFilesVariable) {
                if ($_ -match "'.*'") {
                    $entries = @($Matches[0] -replace "'","" |
                        %{ $_.Split(",", [System.StringSplitOptions]::RemoveEmptyEntries) }) |
                        %{ $_.Trim() }
                    $filenames += $entries
                }
            }
        }
    }
    return $filenames | select -Unique
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
        $expectedManifestFile = "$ModuleName.psd1"
        $manifestFilePath = Join-Path $Path $expectedManifestFile
        $files = Get-FilenamesFromManifest $manifestFilePath
        if (@($files).length -ne 0) {
            Write-Verbose "Found files in manifest: $files"
            Copy-Item $manifestFilePath (Join-Path $moduleTargetPath $expectedManifestFile)
            $files | %{
                $sourceFile = Join-Path $Path ($_ -replace ".psm1",".ps1")
                $destFile = Join-Path $moduleTargetPath $_
                if (-not (Test-Path $sourceFile)) {
                    Write-Warning "Could not find $sourceFile"
                }
                else {
                    if ($SkipDll -and $sourceFile -match ".dll$") {}
                    else {
                        Copy-Item $sourceFile $destFile -Recurse
                    }
                }
            }
        }
        else {
            $expectedModuleFile = "$ModuleName.ps1"
            $moduleFilePath = Join-Path $Path $expectedModuleFile
            if (-not(Test-Path $moduleFilePath)) {
                Write-Error "$Path does not have the expected script $expectedModuleFile, nor does it have a manifest $expectedManifestFile"
                return
            }
            $newFilePath = Join-Path -Path $moduleTargetPath "$ModuleName.psm1"
            Copy-Item $moduleFilePath $newFilePath
            $allFilesSource = Join-Path $Path "*"
            Copy-Item $allFilesSource $moduleTargetPath -Exclude $expectedModuleFile,$filter,"*.Tests.ps1" -Recurse
        }
        Write-Verbose "Copied $Path to $moduleTargetPath"
    }
}

function Install-AllSciptsInUserModule {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$True)]
      [string] $Path,
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

function Start-PesterWatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    return Start-FileWatch -Path $Path -Exclude "\.git" -Action {
        Set-Variable -Name "PesterWatchRunning" -Value $true -Scope Global
        Write-Host "Detected changed files: $($eventArgs.Files)"
        Invoke-Pester -Path $event.MessageData
        Set-Variable -Name "PesterWatchRunning" -Value $false -Scope Global
    }
}