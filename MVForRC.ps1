Get the site and list objects
param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
       Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:Major Versions For Record Center SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
$xmlFilePath = $("D:\MVForRC")
[xml]$ConfigFile = Get-Content $xmlFilePath
function EnableMajorVersions()
{ 
try
{
$web=$ConfigFile.Settings.MajorVersion.RCUrl
$MVL=$ConfigFile.Settings..MajorVersion.MinorVersionsLimit
$web = Get-SPWeb $web
$lists = $web.Lists
#Make the list changes
foreach($list in $lists)
{
Add-Content $logFilePath "`n Enabling minor versions on list $($list.Title)"
$list.EnableMinorVersions=$false
$list.EnableVersioning = $true
$list.MajorVersionLimit = $MVL
$list.Update() 
Add-Content $logFilePath "`n Settings updated"
}
}
catch
{
Add-Content $logFilePath "Custom Exception ocured in changing versioning settings :  $($Error[0].Exception.Message) " 
}
}
EnableMajorVersions
#Create major and minor (draft) versions (document libraries only)

#Update the list and dispose of the web object

