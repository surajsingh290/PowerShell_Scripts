$0 = $MyInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)
$xmlFilePath = $("C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\XMLFile\ConsolidatedXML.xml")
$xmldata = [xml](Get-Content($xmlFilePath));
 
$url = $xmldata.Settings.CreateVariationLabels.SiteUrl.Attributes['Url'].Value
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

#Retrieve Variation Labels
$List = $clientContext.Web.Lists.GetByTitle("Variation Labels")
$clientContext.Load($List)
$clientContext.ExecuteQuery()
