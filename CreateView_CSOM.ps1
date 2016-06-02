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
 
function createViews([Microsoft.SharePoint.Client.Web] $web)
{
 
    foreach($view in $xmldata.Settings.CreateViews.Views.View)
    {
    $pageList = $web.Lists.GetByTitle($view.List)
    $clientContext.Load($pageList)
    $clientContext.ExecuteQuery()
 
    $pageViews=$pageList.Views
    $clientContext.Load($pageViews)
    $clientContext.ExecuteQuery()
 
    $viewFields = New-Object System.Collections.Specialized.StringCollection
   
    foreach($field in $view.Field){
        $viewFields.Add($field.Name)
    }
 
    $viewQuery = "<Where><Gt><FieldRef Name='ID'/><Value Type='Counter'>0</Value></Gt></Where>"
 
    $ViewInfo = New-Object Microsoft.SharePoint.Client.ViewCreationInformation
    $ViewInfo.ViewTypeKind =[Microsoft.SharePoint.Client.ViewType]::Html
    $ViewInfo.Query = $viewQuery   
    $ViewInfo.RowLimit = 50
    $ViewInfo.ViewFields = $viewFields
    $ViewInfo.Title = $view.Title
    $ViewInfo.Paged = $true
    $ViewInfo.PersonalView = $false
 
    $addi=$pageList.Views.Add($ViewInfo)
    $clientContext.Load($pageList)
    $clientContext.ExecuteQuery()
    }
 
}
createViews $web