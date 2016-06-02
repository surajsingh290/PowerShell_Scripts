$0 = $MyInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)
$xmlFilePath = $("C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\XMLFile\ConsolidatedXML.xml")
$xmldata = [xml](Get-Content($xmlFilePath));
 
$url = $xmldata.Settings.CreateViews.Url
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
#############*********************************************************************#########

#Create Site columns 
Write-Host "Creating site columns with in the site started....."
$xmlSiteColumnsFilePath = $xmldata.Settings.CreateSiteColumn.File
Write-Host $xmlSiteColumnsFilePath
$contentXML=[xml](Get-Content($xmlSiteColumnsFilePath))
Write-Host "Site Column File Loaded Successfully..."


$FieldAsXML = $contentXML.Fields.Field
$separator = [string[]]@("</Field>")
$fieldXML.Split($separator, [System.StringSplitOptions]::None) | ForEach {
$fldXML = [string[]]$_ + [string[]]@("</Field>")
Write-Host $fldXML
$fld = $fldWeb.AddFieldAsXml($fldXML, $true, [Microsoft.SharePoint.Client.AddFieldOptions]::DefaultValue)
#$web.Update()
$clientContext.ExecuteQuery()
}

