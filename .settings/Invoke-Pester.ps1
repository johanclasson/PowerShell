param($Path, $Mode)

# write-host "Fick: $Path - $mode - $(whoami)"

Import-Module C:\Users\Johan\Documents\WindowsPowerShell\Modules\Pester\Pester.psm1
Invoke-Pester $Path
