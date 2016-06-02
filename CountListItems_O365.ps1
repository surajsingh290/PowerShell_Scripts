if(!(Get-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction:SilentlyContinue)) 
{ 
    Add-PsSnapin Microsoft.SharePoint.PowerShell 
} 

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
 
$url = "https://nol.sharepoint.com/teams/linerit/CIV/dev/"
#$url = "https://infyakash.sharepoint.com/sites/ConfigNext-POC/"
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$password=convertto-securestring "Parvathi12345" -asplaintext -force 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials('arun_Devarakonda@apl.com', $password)
$clientContext.Credentials = $credentials
 

 
if (!$clientContext.ServerObjectIsNull.Value)
{
    Write-Host "Connected to SharePoint site:" $Url
    
    $list=$clientContext.Web.Lists.GetByTitle("Workflow History")
    $camlQuery= [Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery() 
    $itemColl=$list.GetItems($camlQuery) 
    $clientContext.Load($itemColl) 
    # Execute the query 
    $clientContext.ExecuteQuery();
    $listitems = $list.Items.Count 
    $clientContext.ExecuteQuery()
 
    Write-Host "Items in list: " $listitems
}
