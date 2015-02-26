Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Install-ScriptInUserModule {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
      [System.IO.FileInfo] $File
    )
    Process {
        # Create folder
        $ModuleName = $File.BaseName
        $modulesPath = $env:PSModulePath.split(";")[0]
        $modulePath = Join-Path -Path $modulesPath -ChildPath $ModuleName
        if(Test-Path $modulePath) {
            Remove-Item $modulePath -Force -Recurse
            Write-Verbose "Removed directory $modulePath"
        }
        New-Item -Path $modulePath -ItemType Directory | Out-Null
        Write-Verbose "Created directory $modulePath"
        # Copy file
        $newFilePath = Join-Path -Path $modulePath -ChildPath ($File.Name -replace ".ps1",".psm1")
        Copy-Item $File.FullName $newFilePath
        Write-Verbose "Copied item $newFilePath"
    }
}

function Install-AllSciptsInUserModule {
    Param(
      [Parameter(Mandatory=$True)]
      [System.IO.DirectoryInfo] $Path
    )
    Get-ChildItem -Path $Path -Filter *.ps1 -Recurse | Install-ScriptInUserModule -ModuleName $ModuleName
}

#Install-ScriptInUserModule -File C:\Mippel\PowerShell\Utils\Utils.ps1 -Verbose