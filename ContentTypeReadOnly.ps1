param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
Add-PSSnapin Microsoft.SharePoint.Powershell -ea SilentlyContinue
#Get site collection
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Set content type read only"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
$webUrl=$ConfigFile.Settings.ContentTypeReadOnly.webUrl
$SiteCollection = Get-SPSite $webUrl

#Groups 
$xmlFilePath = $("$path\PSConfig.xml")
   [xml]$ConfigFile = Get-Content $xmlFilePath
$ContentTypes = $SiteCollection.RootWeb.ContentTypes 
foreach ($ContentType in $ContentTypes)
{
try
{
Add-Content $logFilePath "`n setting all content types to read only"

if(($ContentType.ReadOnly -eq $false) -AND ($ContentType.Hidden -eq $false))
{
$ContentType.ReadOnly = $True
$ContentType.Update()
}
Catch
    {
    Add-Content $logFilePath -red "Exception found"
    Add-Content $logFilePath $_.exception.Message
    }
}
}
