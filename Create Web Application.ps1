    param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Web Application SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

    Function CreateWebApp($appPoolName, $account, $webAppName, $webAppUrl, $databaseName)
    {      
	try
    {
	if(!(Get-SPServiceApplicationPool -identity $appPoolName))
    {
       Add-Content $logFilePath "`n Creating New web app pool named $($appPoolName)"
           #New-SPServiceApplicationPool -Name $appPoolName -Account $account
		New-SPServiceApplicationPool -Name $appPoolName -Account $account
		}
    else
    {
    #Write-Host "App Pool named $($appPoolName) already exist"
    }
	if(!(Get-SPWebApplication $webAppUrl -ErrorAction SilentlyContinue))
    {
    Add-Content $logFilePath "`n Creating a new WebApplication at $($webAppUrl)"

	$appPool = (Get-SPServiceApplicationPool $appPoolName).name

	  New-SPWebApplication -ApplicationPool $appPool -Name $webAppName -url $webAppUrl -DatabaseName $databaseName -ApplicationPoolAccount $account 
      Add-Content $logFilePath "`n Webapplication Created"
    }
	else
    {
        #Write-Host "Web Application $($webAppUrl) already exists"
        Add-Content $logFilePath " `n Web Application $($webAppUrl) already exists"

    }
 	 }
	Catch
    {
        $ErrorMessage = $_.Exception.Message
		Add-Content $logFilePath "`n Exception occured in Creating Web application :::::: $($ErrorMessage)"
    }
    }

    $appPoolName=$ConfigFile.Settings.CreateWebApp.ApplicationPoolName
    $account= $ConfigFile.Settings.CreateWebApp.AccountName
    $webAppName= $ConfigFile.Settings.CreateWebApp.WebApplicationName
    $webAppUrl= $ConfigFile.Settings.CreateWebApp.WebApplicationUrl
    $databaseName= $ConfigFile.Settings.CreateWebApp.DatabaseName
    Add-Content $logFilePath "`n Calling create Web App function"

	Add-Content $logFilePath "`n Calling Create  Web App: `n"
	Add-Content $logFilePath "$($appPoolName), $($account), $($webAppName), $($webAppUrl), $($databaseName)"
    CreateWebApp $appPoolName $account $webAppName $webAppUrl $databaseName