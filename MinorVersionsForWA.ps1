param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
       Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:Minor versions for WA SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
function EnableMinorVersions()
{
try
{
$web=$ConfigFile.Settings.MinorVersion.WAUrl
$MVL=$ConfigFile.Settings.MinorVersion.MinorVersionsLimit
$MMVL=$ConfigFile.Settings.MinorVersion.MajorAndMinorVersionsLimit
$web = Get-SPWeb $web
$lists = $web.Lists
foreach($list in $lists)
{
if($list.Basetype -eq "DocumentLibrary")
{
#Make the list changes
Add-Content $logFilePath "`n Enabling minor versions on list $($list.Title)"
$list.Title
$list.EnableVersioning = $False
$list.EnableMinorVersions=$true
$list.MajorVersionLimit = $MVL
$list.MajorWithMinorVersionsLimit = $MMVL
$list.Update()
Add-Content $logFilePath "`n Settings updated"
}
}
}
catch
{
Write-Host "Custom Exception ocured in changing versioning settings : " + $Error[0].Exception.Message -ForegroundColor Red 
}
}
EnableMinorVersions
