﻿$0 = $MyInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)
$xmlFilePath = $("C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\XMLFile\ConsolidatedXML.xml")
$xmldata = [xml](Get-Content($xmlFilePath));
 
$url = $xmldata.Settings.SetWelcomePage.Site.attributes['Url'].value
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$credentials = New-Object System.Net.NetworkCredential('Suraj_Singh05', 'ssingh@4','ITLINFOSYS')
$clientContext.Credentials = $credentials
 
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
 
if (!$clientContext.ServerObjectIsNull.Value)
{
    Write-Host "Connected to SharePoint site: '$Url'" -ForegroundColor Green
    
    $web = $clientContext.Web   
    $clientContext.Load($web)   
    $clientContext.ExecuteQuery()    
}

function Set-WelcomePage($SiteUrl, $PageUrl, $IsVariationSite)
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

  
foreach($siteName in $xmldata.Settings.SetWelcomePage.Site)
{
	$url=$siteName.attributes['Url'].value
	$PageUrl=$siteName.PageUrl
	$IsVariationSite = $siteName.IsVariationSite
Write-Host "Site Url: " $url "Page Url:" $PageUrl $IsVariationSite
	Set-WelcomePage $url $PageUrl $IsVariationSite
}