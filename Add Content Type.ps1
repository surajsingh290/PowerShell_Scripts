param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Add Content Type O365"
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

#Defining Load method for context, not accessible in Powershell
$csharp2 = @"
using Microsoft.SharePoint.Client;
namespace SharepointComLoad
{
    public class PSClientContext: ClientContext
    {
        public PSClientContext(string siteUrl)
            : base(siteUrl)
        {
        }
        // need a plain Load method here, the base method is some
        // kind of dynamic method which isn't supported in PowerShell.
        public void Load(ClientObject objectToLoad)
        {
            base.Load(objectToLoad);
        }
    }
}
"@
$assemblies = @("$location\Microsoft.SharePoint.Client.dll",
    "$location\Microsoft.SharePoint.Client.Runtime.dll",
    "System.Core")
$ErrorActionPreference = "Stop"
$parentDir = Split-Path -Parent $path
  
function AddContentTypes ($siteUrl,$ContentTypes,$credentials)
{
foreach ($ContenType in $ContentTypes.ContentType) 
{	
            
         
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
Add-Content $logFilePath "`n  adding $($ContenType) to $($siteUrl)"
       
$clientContext.Credentials = $credentials
$site = $clientContext.Site;
$web = $site.RootWeb; 
$clientContext.Load($web) ;
$clientContext.Load($site);
$ContentTypes = $web.ContentTypes ;
$clientContext.Load($ContentTypes)
$clientContext.ExecuteQuery()
foreach ($ct in  $ContentTypes)
{
       
if($ct.Name -eq $ContenType)
{
	Add-Content $logFilePath "`n  $($ContenType) is defined as a content type in $($web.Url)"
	#Write-Host $ContenType is defined as a content type in $web.Url
                   
	$list = $web.Lists.GetByTitle("Pages")
	##Write-Host  "$list.Name"
	$clientContext.Load($list)

	$cts = $list.ContentTypes
	$clientContext.Load($cts)
	#$clientContext.Load($ct)
	$list.ContentTypesEnabled=$true
	$AddedContentType=$cts.AddExistingContentType($ct)
	$list.Update()

	try
     {
        
         $clientContext.ExecuteQuery()
         #Write-Host "Adding content type "
         Add-Content $logFilePath "`n ContentType Added"
     }
     catch [Net.WebException]
     {
        #Write-Host $_.Exception.ToString()
     }
 }
}
     
         }

    }
    $siteUrl = $ConfigFile.Settings.SiteUrl

    $ContentTypes=$ConfigFile.Settings.ContentTypes

    #calling Method To Add Contenttypes
 
    AddContentTypes $siteUrl $ContentTypes $credentials
