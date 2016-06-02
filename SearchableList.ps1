
param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Searchable List SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
$webUrl=$ConfigFile.Settings.SearchableList.webUrl
$site = Get-SPWeb $webUrl 
$lists=$site.Lists   
        foreach ($list in $lists) 
        {           try
        {       
                    Add-Content $logFilePath "`n updating the Searchable Settings on the list $($list.Title)"
                    $list.NoCrawl = $false
                    $list.Update()
                   Add-Content $logFilePath "`n settings updated for list $($list.Title) "
                    }
                    catch
                    {
                    Write-Host "Custom Exception occured in changing Advanced settings : " + $Error[0].Exception.Message -ForegroundColor Red 
                    }
        }
    

    $site.Dispose()