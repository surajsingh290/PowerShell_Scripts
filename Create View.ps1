param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create View O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
 
$url = $ConfigFile.Settings.CreateView.SiteUrl
#$url = “https://infyakash.sharepoint.com/sites/ConfigNext-POC/”
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)
$clientContext.Credentials = $credentials
 
if (!$clientContext.ServerObjectIsNull.Value)
{
    Add-Content $logFilePath "`n Connected to SharePoint site: $($Url)"
    
    $web = $clientContext.Web   
    $clientContext.Load($web)   
    $clientContext.ExecuteQuery()  
}
 
function createViews([Microsoft.SharePoint.Client.Web] $web)
{
 
foreach($view in $ConfigFile.Settings.CreateView.Views.View)
{
try
{
	$clientContext.Load($web.Lists)
	$clientContext.ExecuteQuery()
	$list = $web.Lists | where{$_.Title -eq $view.List}
	if(!$list)
	{
	Add-Content $logFilePath "`n List does not exists..."
	}
	else
	{	    
	    #Add-Content $logFilePath "`n List is loaded..."
	
	    $pageViews=$web.Lists.GetByTitle($view.List).Views
        $clientContext.Load($pageViews)
        $clientContext.ExecuteQuery()

        #Add-Content $logFilePath "`n Views are loaded..." 

        if($pageViews.Title -eq $view.Title)
        { 
            Add-Content $logFilePath "`n View with same name already exists..."
	    }
        else
        {                
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

			$pageList = $web.Lists.GetByTitle($view.List)
            $clientContext.Load($pageList)
            $clientContext.ExecuteQuery()
 
            $addView=$pageList.Views.Add($ViewInfo)
            $clientContext.Load($list)
            $clientContext.ExecuteQuery()
	        Add-Content $logFilePath "`n Views created..."
        }
        
    }
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}
 }
 
}
createViews $web