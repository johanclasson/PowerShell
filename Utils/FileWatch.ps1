Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function Get-ModulePath($SubPath) {
    $module = Get-Module Utils
    if ($module -eq $null) {
        $path = $here
        Write-Warning "Using local path: $path"
    }
    else {
        $path = $module.ModuleBase
    }
    return Join-Path $path $SubPath
}

<#
Note that in the $Action script block:
- $Path will be avaliable through the $event.MessageData property, or the global valiable through (Get-Global -Name "MyName").Path
- The actual changed files can be accessed through the $eventArgs.Files property
#>
function Start-FileWatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$true)]
        [ScriptBlock]$Action,
        [string]$Exclude = "",
        [int]$Interval = 500
    )
    $Path = Resolve-Path $Path
    Add-CSharpType (Get-ModulePath "Source\Utils.sln")
    $watcher = New-Object Utils.DelayedFileWatcher($Path,$Exclude,$Interval)
    $changed = Register-ObjectEvent $watcher "Changed" -Action $Action -MessageData $Path

    Write-Host "Watching $Path"
    
    return [PSCustomObject]@{
        Id = $changed.Id
        SourceIdentifier = $changed.Name
        Path = $Path
    }
}

function Stop-FileWatch {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True,ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [int]$Id,
        [Parameter(Mandatory=$false,ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Path
    )
    Process {
        $jobs = (Get-Job) | %{ $_.Id }
        if ($jobs -contains $Id) {
            Write-Verbose "removing job $Id"
            Stop-Job -Id $Id
            Remove-Job -Id $Id
        }
        $subscriptions = (Get-EventSubscriber -Force) | %{ $_.SubscriptionId }
        if ($subscriptions -contains $Id) { #TODO: Is subscriptions really an int? A string?
            Write-Verbose "Unregistering event $Id"
            Unregister-Event $Id #Hangs here - Deadlock!
        }
        if (-not ([string]::IsNullOrEmpty($Path))) {
            Write-Output "Stoped watching $Path"        
        }
    }
}
