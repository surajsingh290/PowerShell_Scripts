param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:  Deactivate DocId Feature"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
	Add-Content $logFilePath "`n XML file loaded successfully"

    $SiteUrl = $ConfigFile.Settings.DeactivateDocIdFeature.SiteUrl
    $FeatureName = $ConfigFile.Settings.DeactivateDocIdFeature.FeatureName
    $bool = Get-SPFeature | where {$_.DisplayName -eq $FeatureName }
    if(!$bool)
    {
        Add-Content $logFilePath "`n Feature: DocId is already Deactive."
    }
    else
    {
        Disable-SPFeature –Identity $FeatureName –url $SiteUrl –Confirm:$false
	    Add-Content $logFilePath "`n Feature: DocId is Deactivated."
    }
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured : $($ErrorMessage) Feature: DocId is already Deactive." 
}