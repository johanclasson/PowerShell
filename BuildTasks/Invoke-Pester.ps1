param([string]$SourceDir = $env:BUILD_SOURCESDIRECTORY,
      [string]$TempDir = $env:TEMP)

$tempFile = Join-Path $TempDir pester.zip
Invoke-WebRequest https://github.com/pester/Pester/archive/master.zip -OutFile $tempFile

[System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
[System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $tempDir)

$modulePath = Join-Path $TempDir Pester-master\Pester.psm1
Import-Module $modulePath

Invoke-Pester $SourceDir -EnableExit