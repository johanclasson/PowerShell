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

function Restart-SKIfNoActivity {
    [cmdletbinding()]    
    param(
        [string]$SqliteLibraryPath = "C:\Program Files\System.Data.SQLite\2010\bin\System.Data.SQLite.dll",
        [string]$ConnectionString = "URI=file:C:\Program Files (x86)\Switch King\Switch King Server\DB\switchKing.server.db3",
        [ValidateRange(0,[Int32]::MaxValue)]
        [int]$LimitInMinutes = 5
    )
    [string]$query = @"
select [DataSourceValues].[DataSourceValueLocalTimestamp] from [DataSourceValues]
    inner join DataSources on [DataSources].[DataSourceID] = [DataSourceValues].[DataSourceID]  
    where [DataSources].[DataSourceTypeName] = 'Telldus'
    order by DataSourceValueLocalTimestamp desc limit 1
"@
    [void][System.Reflection.Assembly]::LoadFrom($SqliteLibraryPath)

    function Get-LastDataSourceValueLocalTimestamp() {
        $connection = New-Object System.Data.SQLite.SQLiteConnection($ConnectionString)
        $connection.Open()

        $command = New-Object System.Data.SQLite.SQLiteCommand($query,$connection)
        $reader = $command.ExecuteReader();
        [void]$reader.Read()
        $dateTime = $reader.GetDateTime(0)

        [void]$reader.Dispose()
        [void]$command.Dispose()
        [void]$connection.Dispose()
    
        return $dateTime
    }

    function Restart-SwitchKing() {
        # Service dependencies:
        # Telldus Service
        # SwitchKing Framework Service -> SwitchKing Invocation Service -> SwitchKing REST Service -> SwitchKing Hub Communicator Service
        # SwitchKing Framework Service -> SwitchKing Data Collector Service
        
        function Log-ServiceVerbose {
            param(
                [Parameter(ValueFromPipeline=$true)]
                $Service
            )
            $Service | % { Write-Verbose "[$($_.Status)]`t$($_.DisplayName)" }
        }

        Stop-Service -Name "SwitchKing Data Collector Service" -PassThru -Force | Log-ServiceVerbose
        Stop-Service -Name "SwitchKing Hub Communicator Service" -PassThru -Force | Log-ServiceVerbose
        Stop-Service -Name "SwitchKing REST Service" -PassThru -Force | Log-ServiceVerbose
        Stop-Service -Name "SwitchKing Invocation Service" -PassThru -Force | Log-ServiceVerbose
        Stop-Service -Name "SwitchKing Framework Service" -PassThru -Force | Log-ServiceVerbose
        Stop-Service -Name "telldusservice" -PassThru -Force | Log-ServiceVerbose

        Start-Service -Name "telldusservice" -PassThru | Log-ServiceVerbose
        Start-Service -Name "SwitchKing Framework Service" -PassThru | Log-ServiceVerbose
        Start-Service -Name "SwitchKing Invocation Service" -PassThru | Log-ServiceVerbose
        Start-Service -Name "SwitchKing REST Service" -PassThru | Log-ServiceVerbose
        Start-Service -Name "SwitchKing Hub Communicator Service" -PassThru | Log-ServiceVerbose
        Start-Service -Name "SwitchKing Data Collector Service" -PassThru | Log-ServiceVerbose
    }

    function Log-Message([string]$Message,[switch]$Error) {
        if ($Error) {
            $Message | Write-Error
        }
        else {
            $Message | Write-Verbose
        }
        $logEntry = "[{0:yyyy-MM-dd HH:mm:ss.fff}] - $Message" -f (Get-Date)
        Write-Output $logEntry
    }

    function Wait-UntilFirstDataSourceValue([datetime]$LastTime) {
        $nextTime = $LastTime
        $timer = New-Object System.Diagnostics.Stopwatch
        Write-Verbose "Waiting for new data source value"
        $timer.Start()
        while($nextTime.ToString() -eq $LastTime.ToString()) {
            Write-Verbose "."
            Start-Sleep -Seconds 1
            if ($timer.Elapsed.Minutes > 15) {
                Log-Message "Wait for new data source values timed out! $($timer.Elapsed)"
                Exit-PSSession -ErrorVariable -1
            }
            $nextTime = Get-LastDataSourceValueLocalTimestamp
        }
        "Found one at {0:yyyy-MM-dd HH:mm:ss.fff}!" -f $nextTime | Write-Verbose
        Log-Message "Waited for new data source values for $($timer.Elapsed)"
    }

    function Check-SKHealthAndRestartIfNeeded {
        try {
            $lastTime = Get-LastDataSourceValueLocalTimestamp
            "Last data source value was added {0:yyyy-MM-dd HH:mm:ss.fff}" -f $lastTime | Write-Verbose
            $aFewMinutesAgo = (Get-Date).AddMinutes(-1 * $LimitInMinutes)
            if ($lastTime -lt $aFewMinutesAgo) {
                Log-Message ("Have not recieved any data source values since {0:yyyy-MM-dd HH:mm:ss.fff}, restarting services..." -f $lastTime)
                Restart-SwitchKing
                Wait-UntilFirstDataSourceValue $lastTime
            }
        }
        catch [Exception] {
            Log-Message "Something bad happended: $($_.Exception.Message)" -Error
        }
    }

    Check-SKHealthAndRestartIfNeeded
}

Export-ModuleMember -function Get-SKDevice
Export-ModuleMember -function Invoke-SkDeviceAction
Export-ModuleMember -function Invoke-SKService
Export-ModuleMember -function Set-SKCredential
Export-ModuleMember -function Restart-SKIfNoActivity

#Get-SKDevice | Format-Table #| Set-SkDeviceState -Action TurnOff -Verbose
#Invoke-SkDeviceAction 12 TurnOn -Force
#Invoke-SkDeviceAction -Id 78 -Action TurnOn
#Get-SKDevice 1 | Format-Table