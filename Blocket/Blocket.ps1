Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-BlocketSearchHits([string[]]$Words, $Category = 2040) {
    $query =  "*$([string]::Join('*+*', $Words))*"
    $baseUri = "http://www.blocket.se/orebro?q=$query&cg=$Category&w=1&st=s&c=&ca=8&is=1&l=0&md=th"
    $result = Invoke-WebRequest $baseUri
    $result.Links |
        where { $_.outerHTML -match 'class=item_link' } |
        foreach { $_.href }
}

function Get-SearchHitContent([string]$Uri) {
    $result = Invoke-WebRequest $Uri
    $image = $result.Images |
        where { $_.PSobject.Properties.name -match "^id$" -and $_.id -eq 'main_image' } |
        select -First 1 |
        foreach { $_.src }
    $body = $result.ParsedHtml.body
    $title = $body.getElementsByTagName('h2') | select -First 1 | %{ $_.innerText }
    $text = $body.getElementsByTagName('div') |
        where { $_.getAttributeNode('class').Value -eq 'body' } |
        foreach { $_.innerHtml }
    $price = $body.getElementsByTagName('span') |
        where { $_.getAttributeNode('id').Value -eq 'vi_price' } |
        foreach { $_.innerText }
    return New-Object PSObject -Property @{ 'image'=$image; 'title'=$title; 'text'=$text; 'price'=$price; 'uri'=$Uri }
}

function Send-Gmail([string]$EmailFrom, [string]$EmailTo) {
    $Subject = "Notification from XYZ" 
    $Body = "this is a notification from XYZ Notifications.." 
    $SMTPServer = "smtp.gmail.com" 
    $SMTPClient = New-Object Net.Mail.SmtpClient($SmtpServer, 587) 
    $SMTPClient.EnableSsl = $true 
    $SMTPClient.Credentials = [Net.NetworkCredential](Get-SavedCredential 'Gmail') 
    $SMTPClient.Send($EmailFrom, $EmailTo, $Subject, $Body)
}

function Add-BlocketWatch([string[]]$Words) {
    #TODO: Add words to db, get search hits to avoid onödigt mejlutskick
}

#Get-BlocketSearchHits "hemnes","byrå"
#Get-SearchHitContent "http://www.blocket.se/orebro/Byra_och_vitrinskap_59342792.htm?ca=8&amp;w=1"

Send-Gmail -EmailFrom "johan@classon.eu" -EmailTo "johan@classon.eu"