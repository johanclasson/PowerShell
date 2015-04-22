Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HtmlAttribute {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$true)]
      [string] $AttributeName,
      [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
      [HtmlAgilityPack.HtmlNode] $Node
    )
    Process {
        if ($Node.Attributes.Contains($AttributeName)) { 
            return $Node.Attributes[$AttributeName].Value
        }
        return $null
    }
}

function Convert-HtmlNode {
    [CmdletBinding()]
    Param(
      [Parameter(Mandatory=$false)]
      [string[]] $AttributeNames,
      [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
      [HtmlAgilityPack.HtmlNode] $Node
    )
    Process {
        $converted = @{
            OuterHtml = $Node.OuterHtml
            InnerHtml = $Node.InnerHtml
        }
        if ($AttributeNames -ne $null) {
            $AttributeNames | foreach {
                $value = Get-HtmlAttribute -AttributeName $_ -Node $Node
                $converted.Add($_,$value)
            }
        }
        return New-Object psobject -Property $converted
    }
}

function Read-Html {
    [CmdletBinding()]
    [OutputType("HtmlAgilityPack.HtmlNode")]
    Param(
      [Parameter(Mandatory=$True)]
      [string] $Url
    )

    $hw = New-Object HtmlAgilityPack.HtmlWeb
    $doc = $hw.Load($Url)

    return $doc.DocumentNode
}

function Select-HtmlByXPath {
    [CmdletBinding()]
    [OutputType("HtmlAgilityPack.HtmlNode")]
    param(
        [Parameter(Mandatory=$True)]
        [string]$XPath,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        $foundNodes = $Node.SelectNodes($XPath)
        if ($foundNodes -eq $null) {
            return @()
        }
        return $foundNodes
    }
}

function Select-HtmlLink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//a[@href]"
    }
}

function Select-HtmlImage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//img[@src]"
    }
}

function Select-HtmlByClass {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Class,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//*[contains(@class,'$Class')]"
    }
}

function Select-HtmlById {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$True)]
        [string]$Id,
        [Parameter(Mandatory=$True, ValueFromPipeline=$True)]
        [HtmlAgilityPack.HtmlNode]$Node
    )
    Process {
        return $Node | Select-HtmlByXPath -XPath "//*[@id='$Id']"
    }
}
