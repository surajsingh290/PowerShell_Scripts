param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Export Search Configurations O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)

$parentDir = Split-Path -Parent $path
$url=$ConfigFile.Settings.ExportSearchConfig.siteUrl
#$url="https://infyakash.sharepoint.com/sites/ConfigNext-POC/"

$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$web = $clientContext.Web

$clientContext.Load($web)
$clientContext.Credentials = $credentials  
# TODO: replace this path with yours..
$pathToSearchSchemaXmlFile = $ConfigFile.Settings.ExportSearchConfig.SearchConfigFile
# we can work with search config at the tenancy or site collection level:
#$configScope = "SPSiteSubscription"
$configScope = $ConfigFile.Settings.ExportSearchConfig.SearchConfigScope
 
try
{
$searchConfigurationPortability = New-Object Microsoft.SharePoint.Client.Search.Portability.SearchConfigurationPortability($clientContext)
$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.SearchObjectOwner($clientContext, $configScope)
	
$value = $searchConfigurationPortability.ExportSearchConfiguration($owner)
$context.ExecuteQuery()
[xml]$schema = $value.Value
$schema.OuterXml | Out-File $pathToSearchSchemaXmlFile -Encoding UTF8
Add-Content $logFilePath "`n Search configuration Exported "
#Write-Host "Search configuration Exported" -ForegroundColor Green
}
catch
{
#Write-Host $_.Exception.ToString()
 $ErrorMessage = $_.Exception.Message
 Add-Content $logFilePath "`n Exception occured in Exporting config file:::::: $($ErrorMessage)"
}