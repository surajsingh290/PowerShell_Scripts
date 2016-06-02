param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:  Site Collection Upgrade"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
	Add-Content $logFilePath "`n XML file loaded successfully"
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

Function SiteCollectionUpgrade
{
	try
	{
		$ContentDatabase = $ConfigFile.Settings.SiteCollectionUpgrade.ContentDBName
		Get-SPSite -Limit All  -ContentDatabase $ContentDatabase | Select-Object URL >> test.txt
		$test = Get-Content test.txt
		$count =$test.count
		for($i=3; $i -le $count-3; $i++)
		{
			Upgrade-SPSite $test[$i] -VersionUpgrade -Unthrottled
		}
		Remove-item test.txt
		Add-Content $logFilePath "`n Script Executed Successfully..."
	}
	catch
	{
		Remove-item test.txt
		$ErrorMessage = $_.Exception.Message
	    Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
	}
}

SiteCollectionUpgrade 
