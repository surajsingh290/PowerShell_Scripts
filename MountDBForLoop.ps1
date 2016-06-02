param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:  Mount Databases"
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


Function MountDatabases($WebApplication, $DatabaseName, $DatabaseServer)
{
	try
	{
        Mount-SPContentDatabase $DatabaseName -DatabaseServer $DatabaseServer -WebApplication $WebApplication
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
    	$FailedItem = $_.Exception.ItemName
		"This script gave error message as $ErrorMessage and Failed item as $FailedItem" | out-file $logFilePath -append
	}	
}

$count =0

#loop to get all sitecollection
foreach ($web in $ConfigFile.Settings.MountDatabases.WebApplication.Web)
{
	$WebApplication=$web.attributes['Url'].value
    $DatabaseName=$Web.DatabaseName.attributes['Name'].value
    $DatabaseServer = $Web.DatabaseServer.attributes['Name'].value
                 
    MountDatabases $WebApplication $DatabaseName $DatabaseServer
    Add-Content $logFilePath "`n WebApplication: $($WebApplication) DatabaseName: $($DatabaseName) DatabaseServer: $($DatabaseServer)"
}