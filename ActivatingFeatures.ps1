
 
  param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
 ############################# Feature Names ###############################
  
 $SiteScopedFeatureSiteFeed = "SiteFeed" #Target Site Collection
  
 $SiteScopedFeatureFollowingContent = "FollowingContent"
  
 ######################################################################################
 
 function AddPowerShellSnapin()
 {
     try
     {
         #write-host "Adding PowerShell Snap-in" -ForegroundColor Green
         # Try to get the PowerShell Snappin.  If not, then adding the PowerShell snappin on the Catch Block
         Get-PSSnapin "Microsoft.SharePoint.PowerShell"
     }
     catch
     {
         if($Error[0].Exception.Message.Contains("No Windows PowerShell snap-ins matching the pattern 'Microsoft.SharePoint.PowerShell' were found"))
         {
             Add-PSSnapin "Microsoft.SharePoint.PowerShell"
         }
     }
     #write-host "Finished Adding PowerShell Snap-in" -ForegroundColor Green
 }
  
 function ActivateFeature($DisplayName, $siteurl)
 {
     #write-host "Activating " $DisplayName "In Site Collection " $siteurl
     $TempCount = (Get-SPSite  $siteurl | %{ Get-SPFeature -Site $_ } | Where-Object {$_.DisplayName -eq $DisplayName} ).Count
     if($TempCount -eq 0)
     {
         # if not, Enable the Feature.
         Get-SPFeature  $DisplayName | Enable-SPFeature -Url  $siteurl
     }           
     else
     {
         # If already Activated, then De-Activate and Activate Again.
         Disable-SPFeature $DisplayName -Url $siteurl  –Confirm:$false
         Get-SPFeature  $DisplayName | Enable-SPFeature -Url  $siteurl
     }
 }
  
 
try
 {

      Add-Content $logFilePath "`n -----------------------------------"
      Add-Content $logFilePath "`n Script Name: Activating Features SOM"
      Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

     
     AddPowerShellSnapin
      
         #Read arguement and store environment URL
  
         $xmlFilePath = $("$path\PSConfig.xml")
         [xml]$ConfigFile = Get-Content $xmlFilePath
         $SiteCollectionURL =$ConfigFile.Settings.Url
         #$WebApplicationURL ="http://SathishServer:1001/"
          Add-Content $logFilePath "`n  Activating SiteFeed Feature "
          ActivateFeature $SiteScopedFeatureSiteFeed $SiteCollectionURL
         add-Content $logFilePath "`n  Activating Feature Follow Content "
           ActivateFeature $SiteScopedFeatureFollowingContent $SiteCollectionURL
       Add-Content $logFilePath "`n  Script Execution Completed Successfully "
    
     } 
        
 catch
 {
     Add-Content $logFilePath"Custom Exception Happened on Main :   $Error[0].Exception.Message" -ForegroundColor Red 
 }
