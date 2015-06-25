$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = "HyperV-WorkaroundMountDiskImageProblem.ps1" #(Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

Describe "HyperV" {
    Context "Get-VMIP" {
        Mock Get-VM { return [PSCustomObject]@{ NetworkAdapters = [PSCustomObject]@{ IPAddresses="169.254.188.87" },[PSCustomObject]@{ IPAddresses="169.254.188.99" } } }
        $ip = Get-VMIP win2012r2_tmpl
        It "returns the expected value" {
            $ip | Should Be 169.254.188.87
        }
    }

    $root = "TestDrive:\Hyper-V"
    Context "New-VMFromConfig" {
        $config = [xml]@"
<config>
	<VMSwitches>
		<InternalVMSwitch name="LocalComputer" dns="172.0.0.1" ip="172.0.0.2" />
		<InternalVMSwitch name="LocalComputer2" />
		<ExternalVMSwitch name="ExternalEthernet" netAdapterName="Ethernet" dns="192.168.0.1" ip="192.168.0.66" />
	</VMSwitches>
	<VMs root="$root">
		<VM name="BrandNewVM" switches="LocalComputer,ExternalEthernet" startupBytes="512MB" dynamicMemory="true" processorCount="4">
			<DvdDrive path="TestDrive:\iso\dvd.iso" />
			<DvdDrive path="TestDrive:\iso\dvd2.iso" />
			<Vhd size="100GB" />
			<Vhd filename="ExtraStuff.vhdx" size="7GB" />
		</VM>
		<VM name="NewVMFromTemplate" switches="LocalComputer,ExternalEthernet" startupBytes="1GB" dynamicMemory="false" processorCount="2">
			<DvdDrive path="TestDrive:\iso\dvd.iso" />
			<CopyVhd path="TestDrive:\Templates\Template.vhdx">
                <ReplaceContent pathRelativeRoot="Windows\Panther\unattended.xml">
                    <add key="__Locale__" value="en-US" />
                    <add key="__ComputerName__" value="*" />
                    <add key="__ProductKey__" value="AAAAA-BBBBB-CCCCC-DDDDD-EEEEE" />
                    <add key="__Password__" value="p@ssword" />
                </ReplaceContent>
			</CopyVhd>
            <MoveVhd filename="MovedDisk.vhdx" path="TestDrive:\Templates\Copies\Templ*.vhdx" />
		</VM>
		<VM name="VMWithoutDisks" />
        <VM name="AlreadyPresentVM" />
        <VM name="VMWithAlreadyPresentDisks">
            <Vhd filename="AlreadyPresetDisk1.vhdx" size="17GB" />
            <CopyVhd filename="AlreadyPresetDisk2.vhdx" path="TestDrive:\Templates\Template.vhdx" />
            <MoveVhd filename="AlreadyPresetDisk3.vhdx" path="TestDrive:\Templates\Copies\Templ*.vhdx" />
        </VM>
	</VMs>
</config>
"@
        Mock New-VMSwitch { }
        Mock Get-VMSwitch { return $true } -ParameterFilter { $Name -eq "LocalComputer2" }
        Mock Get-VMSwitch { return $false }
        Mock Get-VM { return $false } -ParameterFilter { $Name -eq "BrandNewVM" }
        Mock Get-VM { return $false } -ParameterFilter { $Name -eq "NewVMFromTemplate" }
        Mock Get-VM { return $false } -ParameterFilter { $Name -eq "VMWithoutDisks" }
        Mock Get-VM { return $false } -ParameterFilter { $Name -eq "VMWithAlreadyPresentDisks" }
        Mock Get-VM { return $true }
        Mock New-VM {}
        Mock Add-VMNetworkAdapter {}
        Mock Set-VMMemory {}
        Mock Set-VMProcessor {}
        Mock Add-VMDvdDrive {}
        Mock Add-VMNetworkAdapter {}
        Mock New-VHD {}
        Mock Add-VMHardDiskDrive { }
        Mock Mount-VhdxAndGetLargestDriveLetter { return "TestDrive:\" }
        Mock Dismount-DiskImage {}
        Mock New-NetIPAddress {}
        Mock Set-DnsClientServerAddress {}
        # Yes, I'm cheating by not testing this. But I was not able to get the pipelining between the Mocked Get- and Remove-* to work.
        Mock Get-VMDvdDrive { return @() }
        Mock Remove-VMDvdDrive {}
        Mock Get-VMNetworkAdapter { return @() }
        Mock Remove-VMNetworkAdapter {}
        # Done with cheating...
        New-Item TestDrive:\Templates -ItemType Dir | Out-Null
        "Template Content" | Out-File TestDrive:\Templates\Template.vhdx
        New-Item TestDrive:\Templates\Copies -ItemType Dir | Out-Null
        "Template Content" | Out-File TestDrive:\Templates\Copies\Template01.vhdx
        "Template Content" | Out-File TestDrive:\Templates\Copies\Template02.vhdx
        New-Item $root\VMWithAlreadyPresentDisks -ItemType Dir | Out-Null
        "Already Present Content" | Out-File $root\VMWithAlreadyPresentDisks\AlreadyPresetDisk1.vhdx
        "Already Present Content" | Out-File $root\VMWithAlreadyPresentDisks\AlreadyPresetDisk2.vhdx
        "Already Present Content" | Out-File $root\VMWithAlreadyPresentDisks\AlreadyPresetDisk3.vhdx
        New-Item TestDrive:\Windows\Panther -ItemType Dir | Out-Null
        @"
__Locale__
__ComputerName__
__ProductKey__
__Password__
"@ | Out-File TestDrive:\Windows\Panther\unattended.xml
        New-VMFromConfig -Config $config -Verbose

        It "creates an internal switch" {
            Assert-MockCalled New-VMSwitch -ParameterFilter { $Name -eq "LocalComputer" -and $SwitchType -eq "Internal" }
        }
        It "creates an external switch" {
            Assert-MockCalled New-VMSwitch -ParameterFilter { $Name -eq "ExternalEthernet" -and $NetAdapterName -eq "Ethernet" }
        }
        It "creates only switches wich does not exist already" {
            Assert-MockCalled New-VMSwitch -Times 2 -Exactly 
        }
        It "sets IP address of internal switches" {
            Assert-MockCalled New-NetIPAddress -Times 1 -Exactly -ParameterFilter { $InterfaceAlias -eq "vEthernet (LocalComputer)" -and 
                                                                                    $IPAddress -eq "172.0.0.2"}
        }
        It "sets IP address of external switches" {
            Assert-MockCalled New-NetIPAddress -Times 1 -Exactly -ParameterFilter { $InterfaceAlias -eq "vEthernet (ExternalEthernet)" -and 
                                                                                    $IPAddress -eq "192.168.0.66"}
        }
        It "sets DNS address of internal switches" {
            Assert-MockCalled Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter { $InterfaceAlias -eq "vEthernet (LocalComputer)" -and 
                                                                                              $ServerAddresses -eq "172.0.0.1"}
        }
        It "sets DNS address of external switches" {
            Assert-MockCalled Set-DnsClientServerAddress -Times 1 -Exactly -ParameterFilter { $InterfaceAlias -eq "vEthernet (ExternalEthernet)" -and 
                                                                                              $ServerAddresses -eq "192.168.0.1"}
        }
        It "creates VMs with new vhds" {
            Assert-MockCalled New-VM -ParameterFilter { $Name -eq "BrandNewVM" -and 
                                                        $Path -eq $root }
        }
        It "mounts the DVDs" {
            Assert-MockCalled Add-VMDvdDrive -ParameterFilter { $VMName -eq "BrandNewVM" -and 
                                                                $Path -eq "TestDrive:\iso\dvd.iso" }
            Assert-MockCalled Add-VMDvdDrive -ParameterFilter { $VMName -eq "BrandNewVM" -and 
                                                                $Path -eq "TestDrive:\iso\dvd2.iso" }
        }
        It "sets the processor count" {
            Assert-MockCalled Set-VMProcessor -ParameterFilter { $VMName -eq "BrandNewVM" -and
                                                                 $Count -eq 4 }
        }
        It "sets memory configuration" {
            Assert-MockCalled Set-VMMemory -ParameterFilter { $VMName -eq "BrandNewVM" -and
                                                              $StartupBytes -eq "512MB"}
            Assert-MockCalled Set-VMMemory -ParameterFilter { $VMName -eq "BrandNewVM" -and
                                                              $DynamicMemoryEnabled -eq $true }
        }
        It "sets switches" {
            Assert-MockCalled Add-VMNetworkAdapter -ParameterFilter { $VMName -eq "BrandNewVM" -and
                                                                      $SwitchName -eq  "LocalComputer" }
            Assert-MockCalled Add-VMNetworkAdapter -ParameterFilter { $VMName -eq "BrandNewVM" -and
                                                                      $SwitchName -eq  "ExternalEthernet" }
        }
        It "adds VHDs" {
            Assert-MockCalled New-VHD -ParameterFilter { $Path -eq "$root\BrandNewVM\BrandNewVM.vhdx" -and
                                                         $SizeBytes -eq "100GB" }
            Assert-MockCalled Add-VMHardDiskDrive -ParameterFilter { $VMName -eq "BrandNewVM" -and
                                                                     $Path -eq "$root\BrandNewVM\BrandNewVM.vhdx" }
        }
        It "adds VHDs with custom name" {
            Assert-MockCalled New-VHD -ParameterFilter { $Path -eq "$root\BrandNewVM\ExtraStuff.vhdx" -and
                                                         $SizeBytes -eq "7GB" }
            Assert-MockCalled Add-VMHardDiskDrive -ParameterFilter { $VMName -eq "BrandNewVM" -and
                                                                     $Path -eq "$root\BrandNewVM\ExtraStuff.vhdx" }
        }
        It "adds copies of template vhds" {
            $copiedVhdxPath = "$root\NewVMFromTemplate\NewVMFromTemplate.vhdx"
            $copiedVhdxPath | Should Exist
            Get-Content $copiedVhdxPath | Should Be "Template Content"
            Assert-MockCalled Add-VMHardDiskDrive -ParameterFilter { $VMName -eq "NewVMFromTemplate" -and
                                                                     $Path -eq $copiedVhdxPath }
        }
        It "replace stuff in unnatend.xml" {
            $expectedContent = "en-US`r`n" + `
                               "*`r`n" + `
                               "AAAAA-BBBBB-CCCCC-DDDDD-EEEEE`r`n" + `
                               "p@ssword"
            $actualContent = Get-Content TestDrive:\Windows\Panther\unattended.xml -Raw
            $actualContent.Trim() | Should Be $expectedContent
            $copiedVhdxPath = "$root\NewVMFromTemplate\NewVMFromTemplate.vhdx"            
            Assert-MockCalled Mount-VhdxAndGetLargestDriveLetter -ParameterFilter { $Path -eq $copiedVhdxPath }
            Assert-MockCalled Dismount-DiskImage -ParameterFilter { $ImagePath -eq $copiedVhdxPath }
        }
        It "moves template vhds with whildcard" {
            $movedVhdxPath = "$root\NewVMFromTemplate\MovedDisk.vhdx"
            $movedVhdxPath | Should Exist
            Get-Content $movedVhdxPath | Should Be "Template Content"
            Assert-MockCalled Add-VMHardDiskDrive -Exactly -Times 1 -ParameterFilter { $VMName -eq "NewVMFromTemplate" -and
                                                                     $Path -eq $movedVhdxPath }
            "TestDrive:\Templates\Copies\Template01.vhdx" | Should Not Exist
            "TestDrive:\Templates\Copies\Template02.vhdx" | Should Exist
        }
        It "does not create VMs that are already there" {
            Assert-MockCalled New-VM -Exactly -Times 0 { $Name -eq "AlreadyPresentVM" }
        }
        It "does not create VHDs that are already there" {
            Assert-MockCalled New-VHD -Exactly -Times 0 -ParameterFilter { $Path -eq "$root\VMWithAlreadyPresentDisks\AlreadyPresetDisk1.vhdx" }
            Get-Content "$root\VMWithAlreadyPresentDisks\AlreadyPresetDisk1.vhdx" | Should Be "Already Present Content"
            Get-Content "$root\VMWithAlreadyPresentDisks\AlreadyPresetDisk2.vhdx" | Should Be "Already Present Content"
            Get-Content "$root\VMWithAlreadyPresentDisks\AlreadyPresetDisk3.vhdx" | Should Be "Already Present Content"
        }
        It "adds VHDs that are already present on disk" {
            Assert-MockCalled Add-VMHardDiskDrive -ParameterFilter { $VMName -eq "VMWithAlreadyPresentDisks" -and
                                                                     $Path -eq "$root\VMWithAlreadyPresentDisks\AlreadyPresetDisk1.vhdx" }
            Assert-MockCalled Add-VMHardDiskDrive -ParameterFilter { $VMName -eq "VMWithAlreadyPresentDisks" -and
                                                                     $Path -eq "$root\VMWithAlreadyPresentDisks\AlreadyPresetDisk2.vhdx" }
            Assert-MockCalled Add-VMHardDiskDrive -ParameterFilter { $VMName -eq "VMWithAlreadyPresentDisks" -and
                                                                     $Path -eq "$root\VMWithAlreadyPresentDisks\AlreadyPresetDisk3.vhdx" }
        }
        It "use resonable default values for non mandatory attributes which are not set" {
            Assert-MockCalled Set-VMMemory -Exactly -Times 0 -ParameterFilter { $VMName -eq "VMWithAlreadyPresentDisks" }
            Assert-MockCalled Set-VMProcessor -Exactly -Times 0 -ParameterFilter { $VMName -eq "VMWithAlreadyPresentDisks" }
            Assert-MockCalled Add-VMNetworkAdapter -Exactly -Times 0 -ParameterFilter { $VMName -eq "VMWithAlreadyPresentDisks" }
        }
    }

    Context "New-VMFromConfig with bad configuration" {
        Mock Get-VM { return $false }
        Mock New-VM {}
        # Yes, I'm cheating by not testing this. But I was not able to get the pipelining between the Mocked Get- and Remove-* to work.
        Mock Get-VMDvdDrive { return @() }
        Mock Remove-VMDvdDrive {}
        Mock Get-VMNetworkAdapter { return @() }
        Mock Remove-VMNetworkAdapter {}
        # Done with cheating...

        It "checks if VHD path does not exist" {
            $config = [xml]@"
<config>
	<VMs root="TestDrive:\">
         <VM name="DummyVM">
            <CopyVhd filename="MissingDisk.vhdx" path="TestDrive:\Templates\MissingTemplate.vhdx" />
        </VM>
	</VMs>
</config>
"@
            { New-VMFromConfig -Config $config -Verbose } | Should Throw "Cannot find VHD path 'TestDrive:\Templates\MissingTemplate.vhdx' because it does not exist."
        }
        It "Does not throw with empty config" {
            $config = [xml]@"
<config>
</config>
"@
            New-VMFromConfig -Config $config -Verbose
        }
        It "does not throw with almost empty config" {
            $config = [xml]@"
<config>
	<VMSwitches>
	</VMSwitches>
	<VMs root="TestDrive:\">
	</VMs>
</config>
"@
            New-VMFromConfig -Config $config -Verbose
        }
    }
    Context "New-VMFromConfig tidy up after move error" {
        $config = [xml]@"
<config>
	<VMs root="$root">
         <VM name="DummyVM">
            <MoveVhd filename="MissingDisk.vhdx" path="TestDrive:\Templates\Template.vhdx">
                <ReplaceContent pathRelativeRoot="Windows\Panther\unattended.xml">
                    <add key="__Locale__" value="en-US" />
                </ReplaceContent>
            </MoveVhd>
        </VM>
	</VMs>
</config>
"@

        Mock Get-VM { return $false }
        Mock New-VM {}
        # Yes, I'm cheating by not testing this. But I was not able to get the pipelining between the Mocked Get- and Remove-* to work.
        Mock Get-VMDvdDrive { return @() }
        Mock Remove-VMDvdDrive {}
        Mock Get-VMNetworkAdapter { return @() }
        Mock Remove-VMNetworkAdapter {}
        Mock Mount-VhdxAndGetLargestDriveLetter { return "TestDrive:\" }
        Mock Dismount-DiskImage {}
        # Done with cheating...
        Mock Get-Content { throw "Strange Error!" }
        New-Item TestDrive:\Templates -ItemType Dir | Out-Null
        "Template Content" | Out-File TestDrive:\Templates\Template.vhdx
        
        It "dismounts and moves back disk to its original position" {
            { New-VMFromConfig -Config $config -Verbose } | Should Throw "Strange Error!"
            Assert-MockCalled Dismount-DiskImage -ParameterFilter { $ImagePath -eq "$root\DummyVM\MissingDisk.vhdx"}
            "TestDrive:\Templates\Template.vhdx" | Should Exist
        }
        
        
    }
}
