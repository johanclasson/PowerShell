function Set-SqlClientAlias {
    param(
        [Parameter(Position=0, Mandatory=$true)]
        [string]$Alias,
        [Parameter(Position=1, Mandatory=$true)]
        [string]$Instance,
        [Parameter(Position=2, Mandatory=$false)]
        [int]$Port = -1
    )
    function Set-RegistryValue([string]$Path, [string]$Name, [string]$Value) {
        if (-not (Test-Path $Path)) {
            New-Item $Path | Out-Null
        }
        New-ItemProperty -Path $Path -Name $Name -PropertyType String -Value $Value -Force | Out-Null
    }

    $x86Path = "HKLM:\Software\Microsoft\MSSQLServer\Client\ConnectTo"
    $x64Path = "HKLM:\Software\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo"
    $Value = "DBMSSOCN,$Instance" # DBMSSOCN => TCP/IP
    if ($Port -ne -1) {
        $Value += ",$Port"
    }

    Set-RegistryValue -Path $x86Path -Name $Alias -Value $Value
    Set-RegistryValue -Path $x64Path -Name $Alias -Value $Value
}
