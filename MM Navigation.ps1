param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
$location= "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI"

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: MM Navigation O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

$url = $ConfigFile.CSOMMNavigation.WebSite.Url
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url) 
$clientContext.Credentials = $credentials

if (!$clientContext.ServerObjectIsNull.Value) 
{ 
    #Write-Host "Connected to SharePoint Online site: '$Url'" -ForegroundColor Green 
     
    $web = $clientContext.Web    
    $clientContext.Load($web)    
    $clientContext.ExecuteQuery() 
   
}
function UpdateTopNavWebProperty([Microsoft.SharePoint.Client.Web] $web) 
{
     Add-Content $logFilePath "`n set  global navigation settings to Managed Metadata started"
     #Write-Host "set  global navigation settings to Managed Metadata started" -ForegroundColor Green
     $taxonomySession = [Microsoft.SharePoint.Client.Taxonomy.TaxonomySession]::GetTaxonomySession($clientContext)
     $clientContext.Load($taxonomySession) 
     $clientContext.ExecuteQuery() 
     $termStores = $taxonomySession.TermStores
     
      $clientContext.Load($termStores) 
      $clientContext.ExecuteQuery()       
      try { 
      
       $termStore = $termStores[0] 
       $clientContext.Load($termStore)
       $Groups = $termStore.Groups
       $clientContext.Load($Groups)

        $clientContext.ExecuteQuery()

            #Get Site collection Group
            Add-Content $logFilePath "`n Get Site collection Group"
            foreach($Group in $Groups)
            {
                $clientContext.Load($Group)
                $clientContext.ExecuteQuery()
                if($Group.Name.Contains($ConfigFile.CSOMMNavigation.WebSite.TermMain.GroupURL))
                    {
                        $solenisTermSets=$Group.TermSets
                        $clientContext.Load($solenisTermSets)
                        $clientContext.ExecuteQuery()
                        foreach($solenisTermSet in $solenisTermSets)
                        {
                        $clientContext.Load($solenisTermSet)

                        $clientContext.ExecuteQuery()
                        if($solenisTermSet.Name.Contains($ConfigFile.CSOMMNavigation.WebSite.TermMain.TermName))
                            {
                            $TermID=$solenisTermSet.Id                            
                            }
                        }
                    }
            } 
        }
        catch
         {
         #Write-Host "Error detail " $_.Exception.Message -foregroundcolor black -backgroundcolor Red 
 
         $ErrorMessage = $_.Exception.Message
         Add-Content $logFilePath "`n Exception occured in Fetching Terms:::::: $($ErrorMessage)"
         return
          }
     $fId = [GUID]$TermID

     $navigationSettings = New-Object Microsoft.SharePoint.Client.Publishing.Navigation.WebNavigationSettings $clientContext, $clientContext.Web
     Add-Content $logFilePath "`n For Display the same navigation items as the parent site"
     #For Display the same navigation items as the parent site 
     $navigationSettings.GlobalNavigation.Source = "taxonomyProvider"
     $navigationSettings.GlobalNavigation.TermStoreId = $termStore.Id
     $navigationSettings.GlobalNavigation.TermSetId = $fId
     $navigationSettings.Update($taxonomySession) 
   
     try { 
     $clientContext.ExecuteQuery() 
     #Write-Host "setting   global navigation settings to Managed Metadata  Completed" -foregroundcolor black -backgroundcolor green
      Add-Content $logFilePath "`n setting   global navigation settings to Managed Metadata  Completed:::::: $($ErrorMessage)"
      } 
      catch 
      { 
      #Write-Host "Error while setting   global navigation settings to Managed Metadata" $_.Exception.Message -foregroundcolor black -backgroundcolor Red
      Add-Content $logFilePath "`n Error while setting   global navigation settings to Managed Metadata:::::: $($ErrorMessage)"
      
       } 
    }
    UpdateTopNavWebProperty $web
