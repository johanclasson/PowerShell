Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

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
