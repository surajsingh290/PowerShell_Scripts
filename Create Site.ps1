param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Site O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

$location= "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)

Function CreateSiteCollection($Title, $templateId, $Url)
    {
    try
    {
        $webCreationInformation = New-Object Microsoft.SharePoint.Client.WebCreationInformation 
        $webCreationInformation.Url = $Url
        $webCreationInformation.Title = $Title 
        $webCreationInformation.WebTemplate = $templateId
        $webCreationInformation.UseSamePermissionsAsParentSite = $true
        $newWeb = $context.Web.Webs.Add($webCreationInformation) 
 
        $context.Load($newWeb)  
        $context.ExecuteQuery() 
        Add-Content $logFilePath "`n Site Title : $($Title) Created"
    }
    Catch
    { 
        $ErrorMessage = $_.Exception.Message
        Add-Content $logFilePath "`n Exception occured in Creating site collection :::::: $($ErrorMessage)"
    }
}

try
{      
    $siteUrl = $ConfigFile.Settings.Csom_CreateSiteCollection.RootSiteUrl
                
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
    [Microsoft.SharePoint.Client.Web]$web = $context.Web
    $context.Load($web)

    if($credentials -eq $null) {
    $credentials = Get-Credential
    }
    $context.Credentials = $credentials
    $context.ExecuteQuery();
    
    $appPoolIdentity=$ConfigFile.Settings.Csom_CreateSiteCollection.ApplicationPoolIdentity
    $templateId = $ConfigFile.Settings.Csom_CreateSiteCollection.TemplateId
    $Title=$ConfigFile.Settings.Csom_CreateSiteCollection.Title    
    $Url= $ConfigFile.Settings.Csom_CreateSiteCollection.Url    
    Add-Content $logFilePath "`n Calling Create Site collection Method"
    CreateSiteCollection $Title $templateId $Url
}
catch 
{
    $ErrorMessage = $_.Exception.Message
    Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

