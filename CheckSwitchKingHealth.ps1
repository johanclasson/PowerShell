[string]$sqliteLibraryPath = "C:\Program Files\System.Data.SQLite\2010\bin\System.Data.SQLite.dll"
[string]$connectionString = "URI=file:C:\Program Files (x86)\Switch King\Switch King Server\DB\switchKing.server.db3"
[string]$query = @"
select [DataSourceValues].[DataSourceValueLocalTimestamp] from [DataSourceValues]
  inner join DataSources on [DataSources].[DataSourceID] = [DataSourceValues].[DataSourceID]  
  where [DataSources].[DataSourceTypeName] = 'Telldus'
  order by DataSourceValueLocalTimestamp desc limit 1
"@
[void][System.Reflection.Assembly]::LoadFrom($sqliteLibraryPath)

function Get-LastDataSourceValueLocalTimestamp() {
    $connection = New-Object System.Data.SQLite.SQLiteConnection($connectionString)
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
    
    Stop-Service -Name "SwitchKing Data Collector Service" -PassThru -Force
    Stop-Service -Name "SwitchKing Hub Communicator Service" -PassThru -Force
    Stop-Service -Name "SwitchKing REST Service" -PassThru -Force
    Stop-Service -Name "SwitchKing Invocation Service" -PassThru -Force
    Stop-Service -Name "SwitchKing Framework Service" -PassThru -Force
    Stop-Service -Name "telldusservice" -PassThru -Force

    Start-Service -Name "telldusservice" -PassThru
    Start-Service -Name "SwitchKing Framework Service" -PassThru
    Start-Service -Name "SwitchKing Invocation Service" -PassThru
    Start-Service -Name "SwitchKing REST Service" -PassThru
    Start-Service -Name "SwitchKing Hub Communicator Service" -PassThru
    Start-Service -Name "SwitchKing Data Collector Service" -PassThru
}

function Log-Message([string]$message) {
    $message | Write-Host
    $logEntry = "[{0:yyyy-MM-dd HH:mm:ss.fff}] - $message" -f (Get-Date)
    Add-Content c:\mippel\log.txt $logEntry
}

function Wait-UntilFirstDataSourceValue([datetime]$lastTime) {
    $nextTime = $lastTime
    $timer = New-Object System.Diagnostics.Stopwatch
    Write-Host ""
    Write-Host "Waiting" -NoNewline
    $timer.Start()
    while($nextTime.ToString() -eq $lastTime.ToString()) {
        Write-Host "." -NoNewline
        Start-Sleep -Seconds 1
        if ($timer.Elapsed.Minutes > 15) {
            Log-Message "Wait for new data source values timed out! $($timer.Elapsed)"
            Exit-PSSession -ErrorVariable -1
        }
        $nextTime = Get-LastDataSourceValueLocalTimestamp
    }
    " and found one at {0:yyyy-MM-dd HH:mm:ss.fff}!" -f $nextTime | Write-Host
    Log-Message "Waited for new data source values for $($timer.Elapsed)"
}

#if ($false) { # Block comment support for Windows Powershell ISE...
try {
    $lastTime = Get-LastDataSourceValueLocalTimestamp
    "Last data source value was added {0:yyyy-MM-dd HH:mm:ss.fff}" -f $lastTime | Write-Host
    $aFewMinutesAgo = (Get-Date).AddMinutes(-5)
    if ($lastTime -lt $aFewMinutesAgo) {
        Log-Message ("Have not recieved any data source values since {0:yyyy-MM-dd HH:mm:ss.fff}, restarting services..." -f $lastTime)
        Restart-SwitchKing
        Wait-UntilFirstDataSourceValue $lastTime
    }
}
catch [Exception] {
    $message = "Something bad happended: $($_.Exception.Message)"
    Log-Message $message
    Write-Error $message 
}
#}
