param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Set Welcome Page O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
 
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

$url = $ConfigFile.Settings.CreateSiteColumn.ContentTypeHub
#$url = “https://infyakash.sharepoint.com/sites/ConfigNext-POC/”
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)
$clientContext.Credentials = $credentials
 
if (!$clientContext.ServerObjectIsNull.Value)
{
    Add-Content $logFilePath "`n Connected to SharePoint site"
    
    $web = $clientContext.Web   
    $clientContext.Load($web)   
    $clientContext.ExecuteQuery()    
}

function Set-WelcomePage($SiteUrl, $PageUrl, $IsVariationSite)
{
try
{
	if($IsvariationSite -eq "No")
	{ 
        $FolderColl=$web.RootFolder
  		$FolderColl.WelcomePage=$PageUrl
        $FolderColl.Update()
        $clientContext.ExecuteQuery()
	}
	elseif($IsvariationSite -eq "Yes") 
	{
  		$FolderColl=$web.RootFolder
  		$FolderColl.WelcomePage=$PageUrl
        $FolderColl.Update()
        $clientContext.ExecuteQuery()
  	}
	}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}
  }

  
foreach($siteName in $ConfigFile.Settings.SetWelcomePage.Site)
{
	$url=$siteName.attributes['Url'].value
    #$url = “https://infyakash.sharepoint.com/sites/ConfigNext-POC/”
	$PageUrl=$siteName.PageUrl
	$IsVariationSite = $siteName.IsVariationSite
    #Write-Host "Site Url: " $url "Page Url:" $PageUrl $IsVariationSite
	Set-WelcomePage $url $PageUrl $IsVariationSite
}