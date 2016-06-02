Add-Content D:\ErrorFile\CreateSiteColumnCSOM.txt "`n -----------------------------------"
Add-Content D:\ErrorFile\CreateSiteColumnCSOM.txt "`n Begin Execution $(Get-Date -f dd_MM_yyyy_hhmmss)"

$0 = $MyInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)
$myDir="C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\ExecutePowershell\CSOM SCRIPTS"
$ConfigFileName = $myDir -replace "CSOM SCRIPTS","Resources\XML Data File\ConsolidatedXML.xml"
$xmlFilePath = $ConfigFileName
# Import settings from config file
$xmldata = [xml](Get-Content($xmlFilePath));
 
$url = "http://bhukrk272121d:8888/"
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$credentials = New-Object System.Net.NetworkCredential('Suraj_Singh05', 'ssingh@4','ITLINFOSYS')
$clientContext.Credentials = $credentials
 
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
 
if (!$clientContext.ServerObjectIsNull.Value)
{
    Add-Content D:\ErrorFile\CreateSiteColumnCSOM.txt "`n Connected to SharePoint site"
    
    $web = $clientContext.Web   
    $clientContext.Load($web)   
    $clientContext.ExecuteQuery()
  
}

$clientContext.Load($web.Lists)
$clientContext.ExecuteQuery()
$assetLib=$web.Lists.GetByTitle("Site Assets")
$web.SiteLogoUrl = "http://bhukrk272121d:8888" + "/SiteAssets/Logo1.png";
#Write-Host $web.ServerRelativeUrl.ToString()
$web.Update();
$web.Context.ExecuteQuery();