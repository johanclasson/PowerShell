# PowerShell
PowerShell modules and scripts for automation of my everyday life.

![](https://johanclasson.visualstudio.com/DefaultCollection/_apis/public/build/definitions/17242261-a50b-45cd-be6b-04e5c51b0bc4/4/badge)

## Dependent modules
* [SQLite PowerShell Provider](https://psqlite.codeplex.com/) - So that the persistent store can be used to save for example credentials or command history.

## Get started
Copy the dependent modules to your module folder, preferably by:
```
#PSGet
(new-object Net.WebClient).DownloadString("http://psget.net/GetPsGet.ps1") | iex
Install-Module Pester
#CodePlex
Invoke-WebRequest "https://psqlite.codeplex.com/downloads/get/405083" -OutFile tmp.zip
gi .\tmp.zip | %{ [System.IO.Compression.ZipFile]::ExtractToDirectory($_.FullName, $_.Directory.FullName) }
mi .\SQLite $env:PSModulePath.Split(';')[0]
rm .\tmp.zip

```

Then install the PowerShell modules by running the following:
```
cd C:\PathToRepo\PowerShell
. .\Utils\LifeCycle.ps1
Install-AllSciptsInUserModule . -Verbose
```

# Modules

## Blocket
Functionality for searching for ads at [Blocket.se](http://www.blocket.se/). An email is sent out when new content is discovered.

## SwitchKing
Is used against the Rest API of [Switch King](http://www.switchking.se), which is an application for controlling and scheduling remote relays and reading sensor information.

The Switch King application hangs from time to time, possibly because of Garbage Collection of the TelldusNETWrapper. When used in a schedule, `Restart-SKIfNoActivity` can monitor for no activity by Switch King and restart the related windows services if needed.

## Synology
I keep my TV-series in a separate folder organized by name and season. When new episodes are downloaded (*I don't know how it happens, or who does it. But it happens...*) I usually do some maintenance such as moving the file from the download folder to the appropriate folder, and download subtitles from [Subscene](subscene.com).

This module helps in automating these tedious tasks.

## Outlook
One can normally use Outlook rules to redirect email automatically, even to external recipients. But if your local exchange admins has not configured Exchange to allow that, then this does not work. This module can be used to schedule a task with does the automatic redirection anyway!

## Utils
Common functionality for the other modules. For example credential handling, mail sending etc.

### Workflow

TBD

### Credentials

TBD

### Log output

TBD

### Read-Html

I have had a number problems with `(Invoke-HtmlRequest ...).ParsedHtml` to search through and filter out information from web pages.

* It has very bad performance
* It has very few search related methods, and its `getElementById` does not even work
* When scheduling, the html parsing sometimes made the script hang indefinitely

Here comes [Html Agility Pack](https://htmlagilitypack.codeplex.com/) to the rescue. Fast, reliable, and quite powerful since it use XPath. It's simply awesome! For example, it was a relatively straightforward process using it for making this command to work:

```
Import-Module Utils
Read-Html "http://mysite.xyz" | Select-HtmlById myid | Get-HtmlAttribute href
```

One odd thing though. The `myHtmlNode.Select(xpath)` of Html Agility Pack seams to return hits from the whole document and not only children of the node. Therefore, chaining commands like `Select-HtmlById myid | Select-HtmlImage` makes no sense. I you want to query for images under a tag with id myid, use the a complete XPath query instead. For example `Select-HtmlByXPath '//*[@id="myid"]//img'`.
