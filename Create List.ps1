param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create List O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
 
$url = $ConfigFile.Settings.CreateList.Sites.site.attributes['Url'].value
#$url = "https://infyakash.sharepoint.com/sites/ConfigNext-POC/"
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
	$lists=$clientContext.Web.Lists  
	$clientContext.Load($lists)
    $clientContext.ExecuteQuery()  
}


#Method To Create List 
function CreateList($siteUrl, $listName, $list, $listTemplate)
{
try
{
$clientContext.Load($web.Lists)
$clientContext.ExecuteQuery()
$chklist = $web.Lists | where{$_.Title -eq $listName}
	if(!$chklist)
	{
	#Add-Content $logFilePath "`n List does not exists..."
	#Create List
	$ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
	$ListInfo.Title = $listName
	$ListInfo.TemplateType = "100"
	$List = $clientContext.Web.Lists.Add($ListInfo)
	$List.Description = $listName
	$List.Update()
	$clientContext.ExecuteQuery()
	Add-Content $logFilePath "`n List Created..."

	$fieldXML = $ConfigFile.Settings.CreateList.Sites.site.ListName.Template.InnerXml.ToString()
	$separator = [string[]]@("/>")
	$fieldXML.Split($separator, [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
		$fldXML = [string[]]$_ + [string[]]@("/>")
		$List.Fields.AddFieldAsXml($fldXML,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
		$List.Update()
		$clientContext.ExecuteQuery()      
		#Add-Content $logFilePath "`n Fields Created..."  	 
		}
	}
	else
	{
	Add-Content $logFilePath "`n List exists..."
	}	

}
catch
{
$ErrorMessage = $_.Exception.Message
Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}	
#Add-Content $logFilePath "`n Script Executed..."
}
$count =0

#loop to get all sitecollection
foreach ($site in $ConfigFile.Settings.CreateList.Sites.site)
{
	$siteUrl=$site.attributes['Url'].value
    #$siteUrl="https://infyakash.sharepoint.com/sites/ConfigNext-POC/"
    ##Write-Host "URL of the Site: " $siteUrl

    #loop to get all lists      
    foreach ($list in $site.ListName) 
    {
        $listName=$list.attributes['Name'].value
        ##Write-Host "ListName of the Site: " $listName
	    Add-Content $logFilePath "`n Creating List : $($list.attributes['Name'].value)"

        $listTemplate=$list.attributes['ListTemplate'].value
        ##Write-Host "List Template of the Site: " $listTemplate
        #Add-Content $logFilePath "`ncalling Method to create lists"           
        
        CreateList $siteUrl $listName $list $listTemplate

    }

}