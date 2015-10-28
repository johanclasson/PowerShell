param([string]$SourceDir = $env:BUILD_SOURCESDIRECTORY,
      [string]$TempDir = $env:TEMP)
$ErrorActionPreference = "Stop"
<#
Pester is downloaded to the local user temp directory instead of the build source
folder because of two reasons:
* It can be reused between runs on the same machine.
* Pester is actually tested by tests written in Pesters own test framework, and 
  they are included in the module source. To prevent that these tests will be run
  along with the tests of your project, the module is placed in an outside folder.
#>
$modulePath = Join-Path $TempDir Pester-master\Pester.psm1
# Determine if Pester has already been downloaded.
if (-not(Test-Path $modulePath)) {
    # If not so, download latest version as an archive.
    $tempFile = Join-Path $TempDir pester.zip
    Invoke-WebRequest https://github.com/pester/Pester/archive/master.zip -OutFile $tempFile
    # Extract the content from the archive.
    [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
    [System.IO.Compression.ZipFile]::ExtractToDirectory($tempFile, $tempDir)
    # Delete the archive since it is no longer needed.
    Remove-Item $tempFile
}
# Dissable autoloading of modules to catch errors on local development machine.
$PSModuleAutoloadingPreference = "none"
# Set the default strict mode to Latest.
Set-StrictMode -Version Latest
# Load the module.
Import-Module $modulePath
# Run all tests, and fail the build when a test is broken.
$outputFile = Join-Path $SourceDir "TEST-pester.xml"
Invoke-Pester -Path $SourceDir -OutputFile $outputFile -OutputFormat LegacyNUnitXml -EnableExit