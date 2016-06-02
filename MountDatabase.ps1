param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:  Mount Database"
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


Function MountDB
{
	try
	{
		$DatabaseName = $ConfigFile.Settings.MountDB.DatabaseName
		$DatabaseServer = $ConfigFile.Settings.MountDB.DatabaseServer
		$WebApplication = $ConfigFile.Settings.MountDB.WebApplication

		Mount-SPContentDatabase $DatabaseName -DatabaseServer $DatabaseServer -WebApplication $WebApplication
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
	    Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)"
	}	
}

MountDB