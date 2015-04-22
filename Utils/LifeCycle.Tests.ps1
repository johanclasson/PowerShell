$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')

. "$here\$sut"

function Create-DummyModuleFile([string[]]$Files, [string]$Root = 'TestDrive:\Source\MyModule') {
    $Files | %{
        $path = Join-Path $root $_
        New-Item $path -ItemType File -Force | Out-Null
    }
}

function Contains-ModuleFiles {
    Param(
        [string[]]$Files,
        [string]$Root = 'TestDrive:\Target\MyModule'
    )
    $result = $true
    $Files | %{
        $path = Join-Path $Root $_
        if (-not (Test-Path $path)) {
            #Write-Warning "Could not find $path"
            $result = $false
        }
    }
    return $result
}


Describe 'Utils/LifeCycle' {
    Mock Get-PSModulePath { return 'TestDrive:\Target' }
    Context 'Install-ScriptInUserModule: No manifest file ' {
        Create-DummyModuleFile 'MyModule.ps1','SomeBinary.dll','MyModule.Init.ps1','SubFolder/file1.txt'
        Install-AllSciptsInUserModule 'TestDrive:\Source'

        It 'has copied the module file' {
            Contains-ModuleFiles 'MyModule.psm1','SomeBinary.dll','MyModule.Init.ps1','SubFolder/file1.txt' | Should Be $true
        }
    }

    Context 'Install-ScriptInUserModule: Manifest file present ' {
        Create-DummyModuleFile 'MyModule.ps1','MyNestedModule.ps1','SomeBinary.dll','MyModule.Init.ps1','SubFolder/file1.txt','junkfile.txt'
        New-ModuleManifest -Path 'TestDrive:\Source\MyModule\MyModule.psd1'`
            -FileList 'MyModule.psm1','MyNestedModule.psm1','SomeBinary.dll','MyModule.Init.ps1','SubFolder'
        Install-AllSciptsInUserModule 'TestDrive:\Source'

        It 'has copied the module file' {
            Contains-ModuleFiles 'MyModule.psm1','MyNestedModule.psm1','SomeBinary.dll','MyModule.Init.ps1','MyModule.psd1','SubFolder/file1.txt' | Should Be $true
        }

        It 'has only copied files present i manifest' {
            Contains-ModuleFiles 'junkfile.txt' | Should Be $false
        }
    }

    Context 'Install-ScriptInUserModule: Locked dll-file' {
        It 'ignore locked dll-files' {

        }
    }
}
