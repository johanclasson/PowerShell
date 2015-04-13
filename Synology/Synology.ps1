Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-Movies {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )
    return Get-ChildItem $Path -Include @("*.avi","*.mp4","*.flv","*.mkv") -Recurse |
        where { -not ($_.Mode -match "d") }
}

function Get-SrtPath([string]$Path,[IO.FileInfo]$File) {
    return Join-Path $Path -ChildPath "$($File.BaseName).srt"
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

    function Convert-MoviesFilenameToParts {
        param(
            [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
            [IO.FileInfo]$File
        )
        Process {
            $name = $File.FullName
            if (!($name -match "[sS]\d\d[eE]\d\d")) {
                return
            }
            if ($name.ToLower().Contains("sample")) {
                return
            }
            $marker = $Matches[0]
            $season = $marker.Substring(0,3).ToUpper()
            $indexOfMarker = $name.IndexOf($marker)
            $indexAfterDash = $name.Substring(0,$indexOfMarker).LastIndexOf('\') + 1
            $length = $indexOfMarker - $indexAfterDash
            $series = $name.Substring($indexAfterDash,$length).Replace("."," ").Trim()
            if ($series -match "20\d\d$") {
                $series = $series.Replace($Matches[0],"").Trim()
            }
            $series = (Get-Culture).TextInfo.ToTitleCase($series)
            return New-Object psobject -Property @{
                'Series'=$series;
                'Season'=$season;
                'File'=$File
            }
        }
    }

    function Tidy-UpFolder([IO.DirectoryInfo]$Dir) {
        $fileDirIsRootDir = $Dir.FullName -eq (Get-Item $Path).FullName
        if ($fileDirIsRootDir) { # Do not tamper with this!
            return
        }
        $items = Get-ChildItem -LiteralPath $Dir -Force | Where-Object { -not $_.Name.ToLower().EndsWith(".srt") }
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
        $fileCount = @((Get-ChildItem -LiteralPath $Dir -Force)).Count
        if ($fileCount -eq 0) {
            Remove-Item -LiteralPath $Dir
            Write-Verbose "Deleted empty folder: $Dir"
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
            [Parameter(Mandatory=$True)]
            [string]$Destination
        )
        Process {
            $destSubPath = Join-Path $Destination -ChildPath $Series | Join-Path -ChildPath $Season
            #Create folder
            if (!(Test-Path -LiteralPath $destSubPath)) {
                New-Item $destSubPath -ItemType Dir | Out-Null
                Write-Verbose "Created folder $destSubPath"
            }
            #Move subtitle
            $subtitlePath = Get-SrtPath -Path $File.Directory -File $File
            if (-not (Test-Path -LiteralPath $subtitlePath)) {
                Invoke-DownloadSubtitle -Path $File.FullName
            }
            if (Test-Path -LiteralPath $subtitlePath) {
                Move-Item -LiteralPath $subtitlePath -Destination $destSubPath
                Write-Verbose "Moved $subtitlePath to $destSubPath"
            }
            #Move movie
            Move-Item -LiteralPath $File -Destination $destSubPath -Force
            Write-Verbose "Moved $File to $destSubPath"
            #Tidy up folder
            if ($TidyUp) {
                Tidy-UpFolder -Dir $File.Directory
            }
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
                Remove-Item -LiteralPath $deleteMe -Force
                return $_
            } | Remove-Item
    }

    Get-Movies -Path $Path | Convert-MoviesFilenameToParts | Move-MovieInternal -Destination $Destination
    Delete-EmptyFolder
}

function Invoke-DownloadSubtitle {
    [CmdletBinding()]
    param(
        [string]$Path,
        [string]$Language = "English"
    )

    Write-Verbose "Start download subtitle for $Path"
    [IO.FileInfo]$File = Get-Item -LiteralPath $Path
    
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

    function DownloadAndCopy-SrtFileToDestination([string]$path) {
        $zipPath = (Join-Path $path -ChildPath "tmp.zip")
        Invoke-SubsceneRequest -Path $downloadLink -OutFile $zipPath

        [System.Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem') | Out-Null
        [System.IO.Compression.ZipFile]::ExtractToDirectory($zipPath, $path)

        $srtFile = Get-ChildItem $path -Filter "*.srt" | select -First 1
        if ($srtFile -eq $null) {
            Write-Warning "The downloaded file did not contain any srt-file"
        }
        else {
            $targetPath = Join-Path $File.Directory.FullName -ChildPath "$($File.BaseName).srt"
            Copy-Item $srtFile.FullName $targetPath
            Write-Verbose "Downloaded subtitle $targetPath"
        }
    }

    function Save-MissingSubtitle([string]$Text) {
        New-Item sqlite:\SubsceneSearchMiss -text $Text | Out-Null
    }

    function Is-SubtitleMissing([string]$Text) {
        return @(Get-ChildItem sqlite:\SubsceneSearchMiss -Filter "text='$Text'").Length -gt 0
    }

    # Search for subtitle
    $name = $File.BaseName
    $desiredLinkText = "$Language $name"
    if (Is-SubtitleMissing $desiredLinkText) {
        Write-Warning "Could not previously find any $($Language.ToLower()) subtitles for $name"
        return
    }
    $result = Invoke-SubsceneRequest "/subtitles/release?q=$name"
    $detailsUri =  Select-Link -Result $result -InnerText $desiredLinkText
    if ([string]::IsNullOrEmpty($detailsUri)) {
        Write-Warning "Could not find any $($Language.ToLower()) subtitles for $name"
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
        DownloadAndCopy-SrtFileToDestination $tempPath
    }
    catch {
        Write-Error "Something bad happened: $($_.Message)"
    }
    finally {
        Delete-Folder $tempPath
    }
}

function Get-MissingSubtitles {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path,
        [string]$Language = "English"
    )
    $movies = Get-Movies -Path $Path
    $movies | foreach {
        $subtitlePath = Get-SrtPath -Path $_.Directory -File $_
        if (-not(Test-Path -LiteralPath $subtitlePath)) {
            Invoke-DownloadSubtitle -Path $_.FullName -Language $Language
        }
    }
}

# TODO: Recognize 4x07 format
#Y:\TV-serier\Downton Abbey\Season 4

#Invoke-DownloadSubtitle (Get-Item 'Y:\TV-serier\The 100\s02\The.100.S02E10.HDTV.x264-KILLERS.mp4')
#Invoke-DownloadSubtitle (Get-Item 'Y:\TV-serier\The 100\s02\the.100.203.hdtv-lol.mp4')
#Move-Movie -Path W:\ -Destination Y:\TV-serier -TidyUp -Verbose
#Get-MissingSubtitles -Path "Y:\TV-serier\The 100\s02" -Verbose
#Get-MissingSubtitles w:\ -Verbose