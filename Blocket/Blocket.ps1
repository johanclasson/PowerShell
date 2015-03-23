function Get-BlocketSearchHits([string[]]$Words, $Category = 2040) {
    $query =  "*$([string]::Join('*+*', $Words))*"
    $baseUri = "http://www.blocket.se/orebro?q=$query&cg=$Category&w=1&st=s&c=&ca=8&is=1&l=0&md=th"
    $result = Invoke-WebRequest $baseUri
    $result.Links |
        where { $_.outerHTML -match 'class=item_link' } |
        foreach { $_.href }
}

function Add-BlocketWatch([string[]]$Words) {
    #TODO: Add words to db, get search hits to avoid onödigt mejlutskick
}

function Get-SearchHitContent([string]$Uri) {
    $result = Invoke-WebRequest $Uri
    $image = $result.Images |
        where { $_.id -eq 'main_image' } |
        select -First 1 |
        foreach { $_.src }
    $body = $result.ParsedHtml.body
    $title = $body.getElementsByTagName('h2') | select -First 1 | %{ $_.innerText }
    return New-Object PSObject -Property @{ 'image'=$image; 'title'=$title }
}

#Get-BlocketSearchHits "hemnes","byrå"
Get-SearchHitContent "http://www.blocket.se/orebro/Byra_och_vitrinskap_59342792.htm?ca=8&amp;w=1"
