#Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-VMIP {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Name
    )
    return Get-VM -Name $Name | select -ExpandProperty NetworkAdapters | select -ExpandProperty IPAddresses | select -First 1 
}

function Mount-VhdxAndGetLargestDriveLetter {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    $old = [System.IO.DriveInfo]::GetDrives()
    Mount-DiskImage $Path
    $new = [System.IO.DriveInfo]::GetDrives()
    [string]$drive = Compare-Object $old $new |
        %{ $_.InputObject } | sort -Property TotalSize -Descending |
        select -First 1 -ExpandProperty Name
    return $drive
}

function Set-IpAddressIfNotNull([string]$Name, [string]$Ip) {
    if (-not [string]::IsNullOrEmpty($Ip)) {
        New-NetIPAddress -InterfaceAlias "vEthernet ($Name)" -IPAddress $Ip | Out-Null
        Write-Verbose "Set IP of $Name to $Ip"
    } 
}

function New-InternalVMSwitchFromXml {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Name,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Ip
    )
    Process {
        if (-not (Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue)) {
            New-VMSwitch -Name $Name -SwitchType Internal | Out-Null
            Write-Verbose "Created internal switch: $Name"
            Set-IpAddressIfNotNull -Name $Name -Ip $Ip
        }
    }
}

function New-ExternalVMSwitchFromXml {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Name,
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$NetAdapterName,
        [Parameter(Mandatory=$false, ValueFromPipeline=$true, ValueFromPipelineByPropertyName=$true)]
        [string]$Ip
    )
    Process {
        if (-not (Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue)) {
            New-VMSwitch -Name $Name -NetAdapterName $NetAdapterName | Out-Null
            Write-Verbose "Created external switch: $Name - $NetAdapterName"
            Set-IpAddressIfNotNull -Name $Name -Ip $Ip
        }
    }
}

function New-VMFromXml {
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
        [System.Xml.XmlElement]$Xml,
        [Parameter(Mandatory=$true)]
        [string]$Root
    )
    Process {
        $name = $Xml.Name
        if (Get-VM -Name $name -ErrorAction SilentlyContinue) {
            return
        }
        New-VM -Name $name -Path $Root
        Get-VMDvdDrive -VMName $name | Remove-VMDvdDrive
        Get-VMNetworkAdapter -VMName $name | Remove-VMNetworkAdapter
        Write-Verbose "Created VM: $name"
        # Disks
        $disks = $Xml.ChildNodes | ?{ $_.name -match "vhd" }
        if ($disks) {
            $disks | %{
                $filename = $_.filename
                if ([string]::IsNullOrEmpty($filename)) {
                    $filename = "$name.vhdx"
                }
                $path = "$Root\$name\$filename"
                if (Test-Path $path) {
                    Write-Verbose "Skipped creating $path because it already existed" 
                }
                else {
                    $tagName = $_.Name
                    if ($tagName -eq "Vhd") {
                        $size = $_.size
                        $expression = "New-VHD -Path ""$path"" -SizeBytes $size"
                        Invoke-Expression $expression
                        Write-Verbose "Created VHDX: $path - $size"
                    }
                    if ($tagName -eq "CopyVhd" -or $tagName -eq "MoveVhd") {
                        $sourcePath = $_.path
                        if (-not (Test-Path $sourcePath)) {
                            throw "Cannot find VHD path '$sourcePath' because it does not exist."
                        }
                        $sourcePath = Resolve-Path $sourcePath | select -First 1
                        New-Item (Split-Path $path -Parent) -ItemType Dir -ErrorAction SilentlyContinue | Out-Null # Just make sure parent dir exists
                        if ($tagName -eq "MoveVhd") {
                            Write-Verbose "Starting to move $sourcePath to $path..."
                            Move-Item $sourcePath $path -Force
                        }
                        else {
                            Write-Verbose "Starting to copy $sourcePath to $path..."
                            Copy-Item $sourcePath $path -Force
                        }
                        Write-Verbose "Done"
                        $replaceContent = $_.ReplaceContent
                        if ($replaceContent -and $replaceContent.add) {
                            [string]$drive = Mount-VhdxAndGetLargestDriveLetter $path
                            $filePath = '{0}{1}' -f $drive,$replaceContent.pathRelativeRoot
                            try {
                                $expression = "(Get-Content ""$filePath"") "
                                $replaceContent.add | %{
                                    $expression += "-replace '$($_.key)','$($_.value)' "
                                }
                                $expression += "| Out-File ""$filePath"""
                                Invoke-Expression $expression
                                Write-Verbose "Replaced content of $filePath"
                            }
                            catch {
                                Dismount-DiskImage -ImagePath $path
                                if ($tagName -eq "MoveVhd") {
                                    Move-Item $path $sourcePath # Move back vhd
                                }
                                throw
                            }
                            Dismount-DiskImage -ImagePath $path
                        }
                    }
                }
                Add-VMHardDiskDrive -VMName $name -Path $path
                Write-Verbose "Added VHDX to VM: $path - $name"
            }
        }
        # Switches
        $switches = $Xml.switches | ?{ $_ -ne $null } | %{ $_.Split((',',' '), [System.StringSplitOptions]::RemoveEmptyEntries) }
        if ($switches) {
            $switches | %{
                Add-VMNetworkAdapter -VMName $name -SwitchName $_
                Write-Verbose "Added network adapter to VM: $_ - $name"
            }
        }
        # DVDs
        $dvds = $Xml.ChildNodes | ?{ $_.name -match "dvd" }
        if ($dvds) {
            $dvds | %{
                $path = $_.path
                Add-VMDvdDrive -VMName $name -Path $path
                Write-Verbose "Added DVD to VM: $path - $name"
            }
        }
        # Processor
        $processorCount = $Xml.processorCount
        if ($processorCount) {          
            Set-VMProcessor -VMName $name -Count $processorCount
            Write-Verbose "Set processor count to VM: $processorCount - $name"
        }
        # Memory
        $startupBytes = $Xml.startupBytes
        if ($startupBytes) {
            $expression = 'Set-VMMemory -VMName "{0}" -StartupBytes {1}' -f $name,$startupBytes
            Invoke-Expression $expression
            Write-Verbose "Set startup bytes: $startupBytes - $name"
        }
        $dynamicMemory = $Xml.dynamicMemory
        if ($dynamicMemory) {
            $expression = 'Set-VMMemory -VMName "{0}" -DynamicMemoryEnabled ${1}' -f $name,$dynamicMemory
            Invoke-Expression $expression
            Write-Verbose "Set dynamic memory: $dynamicMemory - $name"
        }
    }
}

function New-VMFromConfig {
    [CmdletBinding()]
    param(
        [string]$Path,
        [xml]$Config
    )
    if (-not [string]::IsNullOrEmpty($Path)) {
        $Config = [xml](Get-Content $Path)
    }
    $internalVmSwitches = $Config.config.VMSwitches.InternalVMSwitch
    if ($internalVmSwitches) { $internalVmSwitches | New-InternalVMSwitchFromXml }
    $externalVmSwitches = $Config.config.VMSwitches.ExternalVMSwitch
    if ($externalVmSwitches) { $externalVmSwitches | New-ExternalVMSwitchFromXml }
    if (-not $Config.config.VMs) {
        return        
    }
    $root = $Config.config.VMs.root
    $vms = $Config.config.VMs.VM
    if ($vms) { $vms | New-VMFromXml -Root $root }
}
