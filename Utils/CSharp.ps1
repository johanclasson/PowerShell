Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-CsFiles($SlnPath) {
    function Get-FilesFrom($content, $fileSuffix) {
        $pattern = """(\w|\\|\s)*\.$fileSuffix"""
        return $content -match $pattern | %{
            $_ -match $pattern | Out-Null
            $Matches[0].Trim('"')
        }
    }
    $content = Get-Content -Path $SlnPath
    $dir = (Get-Item $SlnPath).Directory
    $csprojFiles = Get-FilesFrom $content "csproj" |
        %{ Join-Path $dir $_ } |
        where {
            $exist = Test-Path $_
            if (-not $exist) { Write-Warning "$_ does not exist" }
            return $exist
        }
    return $csprojFiles | %{
        $csProjDir = (Get-Item $_).Directory
        $content = Get-Content $_
        $csFiles = Get-FilesFrom $content "cs" |
            %{ Join-Path $csProjDir $_ } |
            where {
                $exist = Test-Path $_
                if (-not $exist) { Write-Warning "$_ does not exist" }
                else {
                    if ((Get-Item  $_).Name -eq "AssemblyInfo.cs") {
                        return $false
                    }
                }
                return $exist
            }
        return $csFiles
    }
}

function Get-TypeDefinition($CsFiles) {
    $usingLines = @()
    $codeLines = @()
    @($CsFiles | %{ Get-Content $_ }) | foreach {
        if ($_ -match "^\s*using .*;\s*$") {
            $usingLines += $_.Trim()
        }
        else {
            $codeLines += $_
        }
    }
    return [string]::Join([System.Environment]::NewLine, ($usingLines | select -Unique)) +
        [System.Environment]::NewLine + 
        [string]::Join([environment]::NewLine, $codeLines)
}

function Get-SourceCode {
    param(
        [Parameter(Mandatory=$true)]
        [string]$SlnPath
    )

    $csFiles = Get-CsFiles $SlnPath
    $typeDefinition = Get-TypeDefinition $csFiles

    return [PsCustomObject]@{
        TypeDefinition = $typeDefinition
        ReferencedAssemblies = ""
    }
}

function Add-CSharpType {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$SlnPath
    )
    $SlnPath = Resolve-Path $SlnPath
    $name = $SlnPath -replace "\W",""
    $variable = Get-Variable $name -Scope Global -ErrorAction SilentlyContinue
    if ($variable -ne $null) {
        Write-Verbose "Type with name $name already loaded"
        return
    }
    Set-Variable $name $true -Scope Global
    $sourceCode = Get-SourceCode -SlnPath $SlnPath
    Write-Verbose "Loading type with name $name"
    Add-Type -TypeDefinition $sourceCode.TypeDefinition #-ReferencedAssemblies $sourceCode.ReferencedAssemblies

}