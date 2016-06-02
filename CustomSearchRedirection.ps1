param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Custom Search Page Redirection SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
$webUrl=$ConfigFile.Settings.CustomRedirection.WebURL
$SearchCenterURl=$ConfigFile.Settings.CustomRedirection.SearchCenterPageURL
$SearchResultPageURL=$ConfigFile.Settings.CustomRedirection.SearchResultPageURL
Write-Host $SearchResultPageURL
Add-Content $logFilePath "`n Getting Site Context"
try
{
$web = get-spweb $webUrl
Add-Content $logFilePath "`n Updating custom search page URL"
$web.AllProperties["SRCH_SB_SET_WEB"] = '{"Inherit":false,"ResultsPageAddress":"'+ $SearchResultPageURL +'","ShowNavigation":false}'
$web.AllProperties["SRCH_ENH_FTR_URL_WEB"] = $SearchCenterURl
$web.Update()
}
catch
{
Add-Content $logFilePath -red "Exception found"
Add-Content $logFilePath $_.exception.Message
}
Add-Content $logFilePath "`n URL updated"