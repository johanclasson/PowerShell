$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace('.Tests.', '.')

. "$here\$sut"

function Is-AllUsingAtTheTop([string]$Content) {
    $noMoreUsingFound = $false
    $result = $true
    $Content.Split([System.Environment]::NewLine, [System.StringSplitOptions]::RemoveEmptyEntries) | 
        foreach {
            if ($_ -match '^ *using .*; *$') {
                if ($noMoreUsingFound) {
                    Write-Warning "Found unexpected $_"
                    $result = $false
                }
            }
            else {
                $noMoreUsingFound = $true
            }
        }
    return $result
}

Describe 'Utils/CSharp' {
    Context 'Get-SourceCode' {
        $source = Get-SourceCode -SlnPath "$here\Source\Utils.sln"
        $typeDef = $source.TypeDefinition

        It 'should find some source code' {
            $typeDef | Should Not BeNullOrEmpty
        }

        It 'should find all classes in cs-files' {
            $typeDef -match 'DelayedFileWatcherEventArgs' | Should Be $true
            $typeDef -match 'DelayedFileWatcher' | Should Be $true
        }

        It 'should only contain using in the start' {
            Is-AllUsingAtTheTop $typeDef | Should Be $true
        }

        It 'should not contain AssemblyInfo.cs' {
            $typeDef -match '\[assembly:' | Should Be $false
        }
    }
}
