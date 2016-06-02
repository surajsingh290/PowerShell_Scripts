$0 = $MyInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)
$xmlFilePath = $("C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\XMLFile\ConsolidatedXML.xml")
$xmldata = [xml](Get-Content($xmlFilePath));
 
$url = $xmldata.Settings.SearchPropertyBag.Site
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
    
    #$web = $clientContext.Web   
    #$clientContext.Load($web)   
    #$clientContext.ExecuteQuery()

    $web = $clientContext.Web
    $clientContext.Load($web)
    $clientContext.ExecuteQuery();  
}

foreach ($sPropertyBagKey in $xmldata.Settings.SearchPropertyBag.Room)
{
    $allProperties = $web.AllProperties
    $allProperties[$sPropertyBagKey.Name] = $sPropertyBagKey.Value
    #$web.AllProperties.FieldValues.Add($sPropertyBagKey.Name, $sPropertyBagKey.Value);
    Write-Host "Created property Bag in SharePoint site" -ForegroundColor Green 
    Write-Host $sPropertyBagKey.Value -ForegroundColor Red 
    Write-Host $sPropertyBagKey.Name -ForegroundColor Red
    $web.Update();
    $clientContext.ExecuteQuery()
}