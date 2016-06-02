param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Content Type SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
  
$siteUrl = $ConfigFile.Settings.CreateContentType.ContentTypeHub

$site = get-spsite $siteUrl
$web = $site.openweb()
$ctypeName = $ConfigFile.Settings.CreateContentType.Name
$ctypeParent = $web.availablecontenttypes['Document' ]
$ctype = new-object Microsoft.SharePoint.SPContentType($ctypeParent, $web.contenttypes, $ctypeName)
$web.contenttypes.add($ctype)
$fieldName = $ConfigFile.Settings.CreateContentType.FieldName
$web.fields.add($fieldName, ([Type]'Microsoft.SharePoint.SPFieldType')::Text, $false)
$field = $web.fields.getfield($fieldName)
$fieldLink = new-object Microsoft.SharePoint.SPFieldLink($field)
$ctype.fieldlinks.add($fieldLink)
$ctype.Update()
$web.Dispose()
$site.Dispose()
Add-Content $logFilePath "`n Content type created."