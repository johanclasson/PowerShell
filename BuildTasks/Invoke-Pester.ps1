param([string]$SourceDir = $env:BUILD_SOURCESDIRECTORY,
      [string]$TempDir = $env:TEMP)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$modulePath = Join-Path $TempDir Pester-master\Pester.psm1

if (-not(Test-Path $modulePath)) {
    $tempFile = Join-Path $TempDir pester.zip
    Invoke-WebRequest https://github.com/pester/Pester/archive/master.zip -OutFile $tempFile

    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $tempDir)
    Remove-Item $tempFile
}

Import-Module $modulePath

$PSModuleAutoloadingPreference = "none"
Invoke-Pester $SourceDir -EnableExit