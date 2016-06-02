#param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:  Export-Import Lists"
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


Function ExportLists($sourceWeb, $Paths, $ListName)
{
	try
	{
        Export-SPWeb -identity $sourceWeb -path $Paths -itemurl $ListName -force –includeusersecurity -NoFileCompression
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
    	$FailedItem = $_.Exception.ItemName
		"This script gave error message as $ErrorMessage and Failed item as $FailedItem" | out-file $logFilePath -append
	}	
}

Function ImportLists($destWeb, $Paths)
{
	try
	{
        Import-SPWeb -identity $destWeb -path $Paths –force -NoFileCompression
	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
    	$FailedItem = $_.Exception.ItemName
		"This script gave error message as $ErrorMessage and Failed item as $FailedItem" | out-file $logFilePath -append
	}	
}


#loop to get all sitecollection
foreach ($web in $ConfigFile.Settings.ExportLists.SourceWeb.Web)
{
	$sourceWeb=$web.attributes['Url'].value
    $PathName=$Web.Path.attributes['Name'].value

    $Paths = $path + "\" + $PathName
    $ListName = $Web.ListName.attributes['Name'].value
                 
    ExportLists $sourceWeb $Path $ListName
    Add-Content $logFilePath "`n sourceWeb: $($sourceWeb) Path: $($Paths) ListName: $($ListName)"
}

foreach ($web in $ConfigFile.Settings.ImportLists.DestWeb.Web)
{
	$destWeb=$web.attributes['Url'].value
    $PathName=$Web.Path.attributes['Name'].value

    $Paths = $path + "\" + $PathName
                 
    ImportLists $destWeb $Path $ListName
    Add-Content $logFilePath "`n sourceWeb: $($destWeb) Path: $($Paths)"
}