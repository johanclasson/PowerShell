param($Mode, $Path)

# write-host "Fick: $Path - $mode - $([environment]::UserName)"

Import-Module "C:\Users\$([environment]::UserName)\Documents\WindowsPowerShell\Modules\Pester\Pester.psm1"
Invoke-Pester $Path
