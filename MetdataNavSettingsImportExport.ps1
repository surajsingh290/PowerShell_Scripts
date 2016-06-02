
param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Custom scope configuration SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
try
{
$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
$Sourceweb = Get-SPWeb $ConfigFile.Settings.MetdataNavigation.SourceWeb
$sourceListName=$ConfigFile.Settings.MetdataNavigation.SourceList
$Sourcelist = $web.Lists[$sourceListName]


Write-Host $listNavSettings.SettingsXml
$targetWebURL=$ConfigFile.Settings.MetdataNavigation.targetWebURL
$TargetListName=$ConfigFile.Settings.MetdataNavigation.TargetListName

$Targetweb = Get-SPWeb $targetWebURL
$Targetlist = $web.Lists[$TargetListName]
Add-Content $logFilePath "`n Get metadata navigation settings for the source list"
$listNavSettings=[Microsoft.Office.DocumentManagement.MetadataNavigation.MetadataNavigationSettings]::GetMetadataNavigationSettings($Sourcelist)
Add-Content $logFilePath "`n set metadata navigation settings for the target list"
[Microsoft.Office.DocumentManagement.MetadataNavigation.MetadataNavigationSettings]::SetMetadataNavigationSettings($Targetlist, $listNavSettings, $true) 
$list2.RootFolder.Update()
}
catch
{
    Add-Content $logFilePath "`n Custom Exception Happened on Main :   $Error[0].Exception.Message "
}