param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Navigation O365"
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

$url = $ConfigFile.Settings.CSOMCreateNavigation.WebSite.Url

$securePassword = ConvertTo-SecureString $password -AsPlainText -Force 
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url) 

$clientContext.Credentials = $credentials 
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

if (!$clientContext.ServerObjectIsNull.Value) 
{ 
    #Write-Host "Connected to SharePoint Online site: '$Url'" -ForegroundColor Green 
     
    $web = $clientContext.Web    
    $clientContext.Load($web)    
    $clientContext.ExecuteQuery() 
   
}


function createTerms([Microsoft.SharePoint.Client.Web] $web) 


{ 

$TMS =[Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($clientContext)
$clientContext.Load($TMS)
$clientContext.ExecuteQuery()
if(!$TMS.ServerObjectIsNull.Value)

{
Add-Content $logFilePath "`n Connected to SharePoint Taxonomy"
#Write-Host "Connected to SharePoint Taxonomy" -ForegroundColor Green
#Retrieve Term Stores
$TermStores = $TMS.TermStores
$clientContext.Load($TermStores)
$clientContext.ExecuteQuery()
    if(!$TermStores.ServerObjectIsNull.Value)
    {
    Add-Content $logFilePath "`n Get  SharePoint Taxonomy TermStores"
    #Write-Host "Get  SharePoint Taxonomy TermStores" -ForegroundColor Green
    #Bind to Term Store
    $TermStore = $TermStores[0]
    $clientContext.Load($TermStore)
    $clientContext.ExecuteQuery()
 
  #Get Groups
  Add-Content $logFilePath "`n Get Groups"
$Groups = $TermStore.Groups
 
$clientContext.Load($Groups)
try
{
 
$clientContext.ExecuteQuery()
}
catch
{


       #Write-Host $_.Exception.ToString()
         $ErrorMessage = $_.Exception.Message
        Add-Content $logFilePath "`n Exception occured in creating groups:::::: $($ErrorMessage)"
}

#Get Site collection Group

$Group = $TermStore.CreateGroup($ConfigFile.WebSite.TermMain.GroupURL, [System.Guid]::NewGuid().toString())   
 $clientContext.Load($Group)    
 $clientContext.ExecuteQuery()     
  #Write-Host "Group created successfully" -ForegroundColor Cyan 
  Add-Content $logFilePath "`n Group created successfully"





$clientContext.Load($Group)

$clientContext.ExecuteQuery()
     
      Add-Content $logFilePath "`n Creating Terms"
      try
      {
    if(!$Group.ServerObjectIsNull.Value)
    {      

        Foreach ($TermMain in $ConfigFile.WebSite.TermMain)
        {      

         $TermSet = $Group.CreateTermSet($ConfigFile.WebSite.TermMain.TermName,[System.Guid]::NewGuid().toString(),1033)
         $TermSet.SetCustomProperty("_Sys_Nav_IsNavigationTermSet", "True")
         #$TermSet.SetCustomProperty("_Sys_Nav_CustomSortOrder", "True")
         $clientContext.Load($TermSet)
         $clientContext.ExecuteQuery()
             Foreach ($TermSub1 in $TermMain.TermSet)
             {
                $TermSubSet1 = $TermSet.CreateTerm($TermSub1.Name,1033,[System.Guid]::NewGuid().toString())
                 $TermSubSet1.SetCustomProperty("_Sys_Nav_IsNavigationTermSet","True")
                 $TermSubSet1.SetLocalCustomProperty("_Sys_Nav_SimpleLinkUrl",$TermSub1.Url)
                 $clientContext.Load($TermSubSet1)
                 $clientContext.ExecuteQuery()
 
                 Foreach ($TermSub2 in $TermSub1.Term)
                 {
                     $TermSubSet2 = $TermSubSet1.CreateTerm($TermSub2.Name,1033,[System.Guid]::NewGuid().toString())
                     $TermSubSet2.SetCustomProperty("_Sys_Nav_IsNavigationTermSet","True")
                     $TermSubSet2.SetLocalCustomProperty("_Sys_Nav_SimpleLinkUrl",$TermSub2.Url)
                     $clientContext.Load($TermSubSet2)
                     $clientContext.ExecuteQuery()
                     Foreach ($TermSub3 in $TermSub2.TermSub)
                     {
                     $TermSubSet3 = $TermSubSet2.CreateTerm($TermSub3.Name,1033,[System.Guid]::NewGuid().toString())
                     $TermSubSet3.SetCustomProperty("_Sys_Nav_IsNavigationTermSet","True")
                     $TermSubSet3.SetLocalCustomProperty("_Sys_Nav_SimpleLinkUrl",$TermSub3.Url)
                     $clientContext.Load($TermSubSet3)
                     $clientContext.ExecuteQuery()
                     }
                 }
               } 

        }


       Add-Content $logFilePath "`n Terms created successfully"

    }
    
    }catch
    {
         #Write-Host $_.Exception.ToString()
         $ErrorMessage = $_.Exception.Message
        Add-Content $logFilePath "`n Exception occured in creating terms:::::: $($ErrorMessage)"

    }
}
}

}

createTerms $web


