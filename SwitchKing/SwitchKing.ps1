Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Add-Type -TypeDefinition @'
public class SkDevice
{
    public SkDevice(int id, string name, string mode, bool on, string group, bool dimmable)
    {
        Id = id;
        Name = name;
        On = on;
        Mode = mode;
        Group = group;
        Dimmable = dimmable;
    }

    public int Id { get; private set; }
    public string Name { get; private set; }
    public bool On { get; private set; }
    public string Mode { get; private set; }
    public bool Dimmable { get; private set; }
    public string Group { get; private set; }
}
'@
Add-Type -AssemblyName System.Web

function Get-SKDevice {
    param(
        [Parameter(Position=0)]
        [int] $Id,
        [string]$Uri
    )
    $xml = $null
    $devices = @()
    if ($Id -eq 0) {
        $responce = (Invoke-SKService "devices" -Uri $Uri)
        $xml = $responce.ArrayOfRESTDevice.RESTDevice
    }
    else {
        $responce = (Invoke-SKService "devices/$Id" -Uri $Uri)
        $xml = $responce.RESTDevice
    }
    $xml | ForEach-Object { 
        $id = $_.ID
        $name = [System.Web.HttpUtility]::HtmlDecode($_.Name)
        $mode = $_.ModeType
        $on = $_.CurrentStateID -eq 2
        $group = $_.GroupName
        $dimmable = $_.SupportsAbsoluteDimLvl -eq 'true'
        $devices += New-Object SkDevice $id,$name,$mode,$on,$group,$dimmable
    }
    return $devices 
}

function Invoke-SKService ([string]$Action, [string]$Uri) {
    if ($Uri -eq $null -or $Uri -eq "") { $Uri = "http://localhost:8800" }
    $responce = Invoke-WebRequest "$Uri/$Action" -Credential (Get-SKCredential)
    if ($responce.Content -eq '<string xmlns="http://schemas.microsoft.com/2003/10/Serialization/">Internal error</string>') {
        throw "Rest call to $Uri/$Action resulted in: Internal error"
    }
    return [xml]$responce.Content
}

function Set-SKCredential {
    $credential = Get-Credential
    $entry = "$($credential.UserName),$(ConvertFrom-SecureString $credential.Password)"
    # Save for current session
    $env:SwitchKingCredential = $entry
    # Save for next session
    [Environment]::SetEnvironmentVariable("SwitchKingCredential", $entry, "User")
}

function Get-SKCredential {
    Set-StrictMode -Off
    if ($env:SwitchKingCredential -eq $null) {
        Set-SKCredential        
    }
    $strings = $env:SwitchKingCredential.split(',')
    $username = $strings[0]
    $password = ConvertTo-SecureString $strings[1]
    $credential = New-Object System.Management.Automation.PSCredential $username,$password
    return $credential
}

function Invoke-SkDeviceAction {
    [cmdletbinding()]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [SkDevice] $Device,
        [Parameter(Position=0)]
        [int] $Id,
        [Parameter(Position=1, Mandatory=$true)]
        [ValidateSet('TurnOn','TurnOff')] #dim,synchronize,cancelsemiauto
        [string]$Action,
        [switch]$Force,
        [string]$Uri
    )
    process {
        if ($Device -ne $null) {
            if (!$Force) {
                if ($Action -eq 'TurnOn' -and $Device.On) { return }
                if ($Action -eq 'TurnOff' -and -not $Device.On) { return }
            }
            if ($Id -ne 0) {
                throw "Parameter Id cannot be combined with Device"
            }
            $Id = $Device.Id
        }
        Invoke-SKService -Action "devices/$Id/$Action" -Uri $Uri | Out-Null
        Write-Verbose "performed action $Action on device with id $Id"
    }
}

#Get-SKDevice | Format-Table #| Set-SkDeviceState -Action TurnOff -Verbose
#Invoke-SkDeviceAction 12 TurnOn -Force
#Invoke-SkDeviceAction -Id 78 -Action TurnOn
#Get-SKDevice 1 | Format-Table