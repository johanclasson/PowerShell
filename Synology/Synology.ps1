Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Movies {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    return Get-ChildItem -LiteralPath $Path -Include @("*.avi","*.mp4","*.flv","*.mkv") -Recurse |
        where { -not ($_.Mode -match "d") }
}

function Get-SrtPath {
    param(
        [string]$Directory,
        [string]$BaseName
    )
    Process {
        return Join-Path $Directory -ChildPath "$BaseName.srt"
    }
}

function Convert-MoviesFilenameToParts {
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [IO.FileInfo]$File
    )
    Process {
        $fullName = $File.FullName
        if (!($fullName -match "[sS]\d\d[eE]\d\d")) {
            return
        }
        if ($fullName.ToLower().Contains("sample")) {
            return
        }
        $marker = $Matches[0]
        $name = $File.BaseName
        if (-not ($name -match $marker) ) {
            if (-not ($fullName -match "([^\[\\]+)$marker([^\[\\]+)")) {
                Write-Error "$fullName did not match the marker containing $marker"
            }
            $name = $Matches[0]
        }
        if ($name.EndsWith($File.Extension)) {
            $name = $name.Substring(0, $name.Length - $File.Extension.Length)
        }
        $season = $marker.Substring(0,3).ToUpper()
        $indexOfMarker = $name.IndexOf($marker, [System.StringComparison]::CurrentCultureIgnoreCase)
        $indexAfterDash = $name.Substring(0,$indexOfMarker).LastIndexOf('\') + 1
        $length = $indexOfMarker - $indexAfterDash
        $series = $name.Substring($indexAfterDash,$length).Replace("."," ").Trim(' ','-')
        if ($series -match "20\d\d$") {
            $series = $series.Replace($Matches[0],"").Trim(' ','-')
        }
        $series = (Get-Culture).TextInfo.ToTitleCase($series)
        return New-Object psobject -Property @{
            'Series'=$series;
            'Season'=$season;
            'File'=$File;
            'Name'=$name
        }
    }
}

function Move-Movie {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [Parameter(Mandatory=$True)]
        [string]$Destination,
        [switch]$TidyUp
    )
    $dirsToTidyUp = New-Object System.Collections.ArrayList

    function Tidy-UpFolder([string]$DirPath) {
        $fileDirIsRootDir = $DirPath -eq (Get-Item -LiteralPath $Path).FullName
        if ($fileDirIsRootDir) { # Do not tamper with this!
            return
        }
        $items = Get-ChildItem -LiteralPath $DirPath -Force
        $items | foreach { # Force includes hidden items such as thumbs.db
            if ($_.PSIsContainer) {
                if ($_.Name.ToLower().Contains("sample")) {
                    Remove-Item -LiteralPath $_.FullName -Recurse
                    Write-Verbose "Deleted junk: $($_.FullName)"
                }
            }
            else {
                $contentLessThan100k = $_.Length / 1025 -lt 100
                if ($_.Name -eq "Thumbs.db" -or $contentLessThan100k) {
                    $_.Delete()    
                    Write-Verbose "Deleted junk: $($_.FullName)"
                }
            }
        }
        $fileCount =  @(Get-ChildItem -LiteralPath $DirPath -Force).Count
        if ($fileCount -eq 0) {
            $parentPath = Split-Path $DirPath -Parent
            Remove-Item -LiteralPath $DirPath
            Write-Verbose "Deleted empty folder: $DirPath"
            Tidy-UpFolder -DirPath $parentPath
        }
    }

	function Move-ItemIfPresent([string]$Source, [string]$Destination) {
        if (Test-Path -LiteralPath $Source) {
            Move-Item -LiteralPath $Source -Destination $Destination
            Write-Verbose "Moved $Source to $Destination"
        }	
	}
	
    function Move-MovieInternal {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
            [IO.FileInfo]$File,
            [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
            [string]$Season,
            [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
            [string]$Series,
            [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
            [string]$Name,
            [Parameter(Mandatory=$True)]
            [string]$Destination
        )
        Process {
            $destSubPath = Join-Path $Destination -ChildPath $Series | Join-Path -ChildPath $Season
            $destinationPath = (Join-Path $destSubPath "$Name$($File.Extension)")
            $srtDestinationPath = Get-SrtPath -Directory $destSubPath -BaseName $Name
            $srtSourcePath1 = Get-SrtPath -Directory $File.Directory -BaseName $Name
            $srtSourcePath2 = Get-SrtPath -Directory $File.Directory -BaseName $File.BaseName
            #Create folder
            if (!(Test-Path -LiteralPath $destSubPath)) {
                New-Item $destSubPath -ItemType Dir | Out-Null
                Write-Verbose "Created folder $destSubPath"
            }
            #Move subtitle
            if (-not (Test-Path -LiteralPath $srtSourcePath1) -and -not (Test-Path -LiteralPath $srtSourcePath2)) {
                Invoke-DownloadSubtitle -Destination $File.Directory -Name $Name
            }
			Move-ItemIfPresent $srtSourcePath1 $srtDestinationPath
			Move-ItemIfPresent $srtSourcePath2 $srtDestinationPath
            #Move movie
            Move-Item -LiteralPath $File -Destination $destinationPath -Force
            Write-Verbose "Moved $File to $destSubPath"
            #Tidy up folder
            if ($TidyUp -and -not ($dirsToTidyUp -contains $File.Directory.FullName)) {
                $dirsToTidyUp.Add($File.Directory.FullName) | Out-Null
            }
        }
        End {
            $dirsToTidyUp | %{ Tidy-UpFolder -DirPath $_ }
        }
    }

    function Delete-EmptyFolder {
        if (-not $TidyUp) {
            return
        }
        Get-ChildItem -Path $Path -Recurse |
            Where-Object {
                $_.Mode.Contains('d') -and
                @(Get-ChildItem -LiteralPath $_.FullName -Force |
                    Where-Object { -not ($_.Name -eq "Thumbs.db")}).Count -eq 0
            } | foreach {
                $deleteMe = Join-Path $_.FullName -ChildPath "Thumbs.db"
                if (Test-Path $deleteMe) {
                    Remove-Item -LiteralPath $deleteMe -Force
                }
                return $_
            } | Remove-Item
    }

    Get-Movies -Path $Path | Convert-MoviesFilenameToParts | Move-MovieInternal -Destination $Destination
    Delete-EmptyFolder
}

function Invoke-DownloadSubtitle {
    [CmdletBinding()]
    param(
        [string]$Name,
        [string]$Destination,
        [string]$Language = "English"
    )

    Write-Verbose "Start download subtitle for $Name"
    
    function Invoke-SubsceneRequest([string]$Path, [string]$OutFile) {
        if ([string]::IsNullOrEmpty($Path)) {
            throw "Empty path"
        }
        $uri = "http://subscene.com$Path"
        if ([string]::IsNullOrEmpty($OutFile)) {
            return Invoke-WebRequest -Uri $uri
        }
        Invoke-WebRequest -Uri $uri -OutFile $OutFile
    }

    function Select-Link {
        param(
            [Microsoft.PowerShell.Commands.HtmlWebResponseObject]$Result,
            [string]$InnerText,
            $First = 1
        )
        return $result.Links | 
            ?{ $_.InnerText.Trim() -eq $InnerText } |
            Select-Object -First $First |
            foreach { $_.href }
    }

    function Create-TempFolder {
        $path = Join-Path $env:TEMP -ChildPath ([Guid]::NewGuid())
        return (New-Item $path -ItemType Dir).FullName
    }

    function Delete-Folder([string]$path) {
        Remove-Item -Path $path -Recurse -Force
    }

    function DownloadAndCopy-SrtFileToDestination([string]$path, [string]$downloadLink) {
        $zipPath = (Join-Path $path -ChildPath "tmp.zip")
        Invoke-SubsceneRequest -Path $downloadLink -OutFile $zipPath

        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $path)

        $srtFile = Get-ChildItem $path -Filter "*.srt" | select -First 1
        if ($srtFile -eq $null) {
            Write-Warning "The downloaded file did not contain any srt-file"
            return $null
        }
        $targetPath = Join-Path $Destination -ChildPath "$name.srt"
        Copy-Item $srtFile.FullName $targetPath
        Write-Verbose "Downloaded subtitle $targetPath"
        return $targetPath
    }

    function Save-MissingSubtitle([string]$Text) {
        New-Item sqlite:\SubsceneSearchMiss -text $Text | Out-Null
    }

    function Is-SubtitleMissing([string]$Text) {
        return @(Get-ChildItem sqlite:\SubsceneSearchMiss -Filter "text='$Text'").Length -gt 0
    }

    # Search for subtitle
    $desiredLinkText = "$Language $Name"
    if (Is-SubtitleMissing $desiredLinkText) {
        Write-Warning "Could not previously find any $($Language.ToLower()) subtitles for $Name"
        return
    }
    $result = Invoke-SubsceneRequest "/subtitles/release?q=$Name"
    $detailsUri = Select-Link -Result $result -InnerText $desiredLinkText
    if ([string]::IsNullOrEmpty($detailsUri)) {
        Write-Warning "Could not find any $($Language.ToLower()) subtitles for $Name"
        Save-MissingSubtitle $desiredLinkText
        return
    }
    # Navigate to subtitle
    $result = Invoke-SubsceneRequest $detailsUri
    $downloadLink = Select-Link -Result $result -InnerText "Download English Subtitle"
    if ([string]::IsNullOrEmpty($downloadLink)) {
        Write-Warning "Could not find the download link"
        return
    }
    #Download and extract file
    $tempPath = ""
    try {
        $tempPath = Create-TempFolder
        return DownloadAndCopy-SrtFileToDestination $tempPath $downloadLink
    }
    catch {
        Write-Error "Something bad happened: $($_.Message)"
    }
    finally {
        Delete-Folder $tempPath
    }
    return $null
}

function Get-MissingSubtitles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Language = "English"
    )
    $movies = Get-Movies -Path $Path | Convert-MoviesFilenameToParts
    $movies | foreach {
        $subtitlePath = Get-SrtPath -Directory $_.File.Directory -BaseName $_.File.BaseName
        if (-not(Test-Path -LiteralPath $subtitlePath)) {
            $path = Invoke-DownloadSubtitle -Name $_.Name -Destination $_.File.Directory -Language $Language
            if (-not [string]::IsNullOrEmpty($path)) {
                Move-Item -LiteralPath $path -Destination $subtitlePath
            }
        }
    }
}

#Get-MissingSubtitles -Path w:\ -Verbose

# TODO: Recognize 4x07 format
#Y:\TV-serier\Downton Abbey\Season 4
