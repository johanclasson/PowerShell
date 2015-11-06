Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-BlocketSearchHits([string]$Query, [string]$Category, [string]$Area) {
    if ([string]::IsNullOrEmpty($Category)) {
        $Category = 0 # 2040 is furniture
    }
    if ([string]::IsNullOrEmpty($Area)) {
        $Area = "orebro" # TODO: Fixa validering på alla områden, inkl. hela_sverige
    }
    # TODO: Fixa möjlighet att söka närliggande
    # w=1 => bara area
    # w=2 => Närliggande
    # w=3 => hela sverige
    $baseUri = "http://www.blocket.se/$($Area)?q=$($query.Trim())&cg=$Category"
    Write-Verbose "Search uri: $($baseUri)"
    return Read-Html $baseUri | Select-HtmlByClass "item_link" | Get-HtmlAttribute href
}

function Get-SearchHitContent([string]$Uri) {
    $html = Read-Html $Uri
    $images = $html | Select-HtmlByXPath '//img[@data-src]' | Get-HtmlAttribute 'data-src'
    $title = $html | Select-HtmlByXPath "//h1" | select -First 1 | %{ $_.innerText.Trim() }
    if ([string]::IsNullOrEmpty($title)) {
        $title = $html | Select-HtmlByXPath "//h2" | select -First 1 | %{ $_.innerText.Trim() }
    }
    $text = $html | Select-HtmlByClass body | select -ExpandProperty innerHtml
    $text = $text -join " "
    $indexOfInfoPage = $text.IndexOf("<!-- Info page -->")
    if ($indexOfInfoPage -ge 0) {
        $text = $text.Substring(0, $indexOfInfoPage).Trim()
    }
    $place = $html | Select-HtmlByClass area_label | %{ $_.innerText.Trim((' ','(',')')) }
    $price = $html | Select-HtmlById vi_price | foreach { $_.innerText.Trim() }
    
    return New-Object PSObject -Property @{ 'images'=$images; 'title'=$title; 'text'=$text; 'place'="$place"; 'price'="$price"; 'uri'=$Uri }
}

# Mocked
function Test-Hit($Uri) {
    @(Get-ChildItem sqlite:\BlocketSearchHit -Filter "uri='$Uri'").Length -gt 0
}

# Mocked
function Test-Query($Query) { # TODO: Här borde area också tas med
    @(Get-ChildItem sqlite:\BlocketSearchQuery -Filter "text='$Query'").Length -gt 0
}

# Mocked
function Add-Hit($Uri) {
    New-Item sqlite:\BlocketSearchHit -uri $Uri | Out-Null
}

# Mocked
function Add-Query($Query) { # TODO: Här borde area också tas med
    New-Item sqlite:\BlocketSearchQuery -text $Query | Out-Null
}

function Format-Body {
    [OutputType('System.String')]
    param(
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string[]]$Images,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Title,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Text,
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Place,
        [Parameter(ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Price,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Uri
    )
    Process {
        $imageTagsArray = $Images | %{ "<img src=""$_""/>" }
        $imageTags = [string]::Join("`r`n", $imageTagsArray)
        $PriceTags = $null
        if (-not [string]::IsNullOrEmpty($Price)) {
            $PriceTags = "<h3>Pris</h3><p>$Price</p>"
        }
        return @"
<h2>$Title</h2>
<p>$Text</p>
<h3>Plats</h3><p>$Place</p>
$PriceTags
<p>$imageTags</p>
<p><a href="$Uri">Se annonsen på Blocket</a></p>
"@
    }
}

# It is a good thing not to load queries from db since one can rely on different schedules for differnt queries
function Send-BlocketSearchHitsMail {
    [CmdletBinding()]    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Query,
        [string]$Category,
        [string]$Area,
        [Parameter(Mandatory=$True)]
        [string[]]$EmailTo,
        [Parameter(Mandatory=$True)]
        [string]$EmailFrom
    )
    Process {
        $hits = Get-BlocketSearchHits -Query $Query -Category $Category -Area $Area
        # Mute emails the first run
        if (-not (Test-Query $Query)) {
            Add-Query $Query
            $hits | %{ Add-Hit $_ }
            Write-Output "Added $(@($hits).Length) items to recorded search hits. No mails are sent out this time!"
            return
        }
        $newHits = @($hits | where { -not (Test-Hit $_) })
        if ($newHits.Length -eq 0) {
            return
        }
        Write-Log "Found new search hits"
        # Send emails for new hits
        $newHits | foreach {
            $hit = $_
            $content = Get-SearchHitContent $hit
            Write-Verbose "Got content for: $hit"
            [string]$body = $content | Format-Body
            $subject = "Blocket $($content.Place): $($content.Title) - $($content.Price)"
            Send-Gmail -EmailFrom $EmailFrom -EmailTo $EmailTo -Subject $subject -Body $body -Html
            Write-Log "Email with subject '$subject' to $EmailTo"
            Add-Hit $hit
        } 
    }
}

function Remove-BlocketRecordedHits {    [CmdletBinding()]    param()    Remove-Item sqlite:\BlocketSearchHit\*
    Remove-Item sqlite:\BlocketSearchQuery\*
}

Get-SearchHitContent -Uri "http://www.blocket.se/ostergotland/VillaAntiks_Charmiga_Mobler_med_Historia_63684584.htm?ca=14&w=1" | Format-Body

#Remove-BlocketData -Verbose
#Send-BlocketSearchHitsMail "*hemnes* *byrå*" "johan@classon.eu","johan2@classon.eu" "johan@classon.eu" -Verbose
#Get-BlocketSearchHits "*hemnes* *byrå*"
