$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

function Check-IfAllTitlesAreUnique($parsedHits) {
    $uniqueTitles = @()
    $notUniqueTitles = @()
    $parsedHits | select -ExpandProperty Title | %{
        if ($uniqueTitles -contains $_) {
            $notUniqueTitles += $_
        }
        else {
            $uniqueTitles += $_
        }
    }
    if ($notUniqueTitles.length -ne 0) {
        Write-Warning "Found not unique titles: '$([string]::Join("', '", $notUniqueTitles))'"
        return $false
    }
    return $true
}

function Check-IfAllImageUrlsAreCorrect($parsedHits) {
    $result = $true
    
    $parsedHits | %{
        if ($_.images -contains $null) {
            Write-Warning "Found null images in $($_.title)"
            #$result = $false
        }
    }

    $images = $parsedHits | select -ExpandProperty images
    $images | %{
        $_ | %{
            if (([regex]::Matches($_, ".jpg" )).count -ne 1) {
                Write-Warning "Found many .jpg in $_"
                $result = $false
            }
        }
    }
    return $result
} 

Describe "Blocket" {
    Context "Send-BlocketSearchHitsMail" {
        Mock Send-Gmail -Verifiable  { 
            Set-Variable subject $Subject -Scope Global
            Set-Variable body $Body -Scope Global
        }
        Mock Get-BlocketSearchHits -ParameterFilter { $Query -eq "..." } { return "url1","url2" }
        Mock Get-SearchHitContent -ParameterFilter { $Uri -eq "url1" } { return New-Object PSObject -Property @{ 'images'='imgUrl1'; 'title'='Title 1'; 'text'='Text 1'; 'price'='Price 1'; 'uri'='url1' } }
        Mock Get-SearchHitContent -ParameterFilter { $Uri -eq "url2" } { return New-Object PSObject -Property @{ 'images'='imgUrl2'; 'title'='Title 2'; 'text'='Text 2'; 'price'='Price 2'; 'uri'='url2' } }
        Mock Test-Hit
        Mock Test-Query { return $true } # Simulate not first time query is used
        Mock Add-Hit
        Mock Add-Query
        
        Send-BlocketSearchHitsMail -Query "..." -EmailTo "emailto@test.com" -EmailFrom "emailfrom@test.com"

        It "sends email" {
            Assert-MockCalled Send-Gmail -Exactly -Times 2
        }

        It "sends email to correct reciepient" {
            Assert-MockCalled Send-Gmail -ParameterFilter { $EmailTo -eq "emailto@test.com" }
        }

        It "sends email from correct sender" {
            Assert-MockCalled Send-Gmail -ParameterFilter { $EmailFrom -eq "emailfrom@test.com" }
        }

        It "formats the subject" {
            $subject = (Get-Variable subject -Scope Global).Value
            $subject | Should Be "Blocket: Title 2 - Price 2"
        }

        It "formats the body" {
            $body = (Get-Variable body -Scope Global).Value
            $body | Should Be @"
<h2>Title 2</h2>
<p>Text 2</p>
<h3>Pris</h3><p>Price 2</p>
<p><img src="imgUrl2"/></p>
<p><a href="url2">Se annonsen på Blocket</a></p>
"@
        }
    }
    Context "Get-SearchHitContent" {
        $hits = Get-BlocketSearchHits -Query "bil"
        $parsedHits = $hits | select -First 4 | %{ Get-SearchHitContent $_ }

        It "gets hits" {
            @($parsedHits).length | Should Be 4
        }

        It "gets unique titles" {
            Check-IfAllTitlesAreUnique $parsedHits | Should Be $true
        }

        It "gets images" {
            @($parsedHits | select -ExpandProperty images).Length | Should Not Be 0
        }

        It "gets images with correct url" {
            Check-IfAllImageUrlsAreCorrect $parsedHits | Should Be $true
        }
    }
}
