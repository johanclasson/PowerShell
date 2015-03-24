Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-BlocketSearchHits([string]$Query, [string]$Category, [string]$Area) {
    if ([string]::IsNullOrEmpty($Category)) {
        $Category = 2040
    }
    if ([string]::IsNullOrEmpty($Area)) {
        $Area = "orebro"
    }
    $baseUri = "http://www.blocket.se/$($Area)?q=$($query.Trim())&cg=$Category&w=1&st=s&c=&ca=8&is=1&l=0&md=th"
    $result = Invoke-WebRequest $baseUri
    $result.Links |
        where { $_.outerHTML -match 'class=item_link' } |
        foreach { $_.href }
}

function Get-SearchHitContent([string]$Uri) {
    $result = Invoke-WebRequest $Uri
    $images = $result.links.href | where { $_ -match "jpg$" }
    if ($images -eq $null) {
        $images = $result.Images |
            where { $_.PSobject.Properties.name -match "^id$" -and $_.id -eq 'main_image' } |
            select -First 1 |
            foreach { $_.src }
    }
    $body = $result.ParsedHtml.body
    $title = $body.getElementsByTagName('h2') | select -First 1 | %{ $_.innerText.Trim() }
    $text = $body.getElementsByTagName('div') |
        where { $_.getAttributeNode('class').Value -eq 'body' } |
        foreach { $_.innerHtml }
    $price = $body.getElementsByTagName('span') |
        where { $_.getAttributeNode('id').Value -eq 'vi_price' } |
        foreach { $_.innerText.Trim() }
    
    return New-Object PSObject -Property @{ 'images'=$images; 'title'=$title; 'text'=$text; 'price'="$price"; 'uri'=$Uri }
}

function Test-Hit($Uri) {
    @(Get-ChildItem sqlite:\BlocketSearchHits -Filter "uri='$Uri'").Length -gt 0
}

function Test-Query($Query) {
    @(Get-ChildItem sqlite:\BlocketSearchQuery -Filter "text='$Query'").Length -gt 0
}

function Add-Hit($Uri) {
    New-Item sqlite:\BlocketSearchHits -uri $Uri | Out-Null
}

function Add-Query($Query) {
    New-Item sqlite:\BlocketSearchQuery -text $Query | Out-Null
}

function Format-Body {
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string[]]$Images,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Title,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True, ValueFromPipelineByPropertyName)]
        [string]$Text,
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
        $hits = Get-BlocketSearchHits $Query
        # Mute emails the first run
        if (-not (Test-Query $Query)) {
            Add-Query $Query
            $hits | %{ Add-Hit $_ }
            Write-Output "Added $(@($hits).Length) items to recorded search hits. No mails are sent out this time!"
            return
        }
        # Send emails for new hits
        $hits | where { -not (Test-Hit $_) } | foreach {
            $hit = $_
            $content = Get-SearchHitContent $hit
            $body = $content | Format-Body
            $subject = "Blocket: $($content.Title) - $($content.Price)"
            Send-Gmail -EmailFrom $EmailFrom -EmailTo $EmailTo -Subject $subject -Body $body -Html
            Write-Output "Email with subject '$subject' to $EmailTo"
            Add-Hit $hit
        } 
    }
}

function Remove-BlocketRecordedHits {    [CmdletBinding()]    param()    Remove-Item sqlite:\BlocketSearchHits\*
    Remove-Item sqlite:\BlocketSearchQuery\*
}

#Remove-BlocketData -Verbose
#Send-BlocketSearchHitsMail "*hemnes* *byrå*" "johan@classon.eu","johan2@classon.eu" "johan@classon.eu" -Verbose
#Get-BlocketSearchHits "*hemnes* *byrå*"
#Get-SearchHitContent "http://www.blocket.se/orebro/Matbord_59466470.htm?ca=8&w=1" | Format-Body