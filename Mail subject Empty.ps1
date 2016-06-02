param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Mail Subject Empty"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
  
$ConfigFile = [xml](get-content $xmlFilePath)
Add-Content $logFilePath "`n XML file loaded successfully"

$siteUrl = $ConfigFile.Settings.MailSubjectEmpty.Siteurl
$listName = $ConfigFile.Settings.MailSubjectEmpty.ListName
$featureName= $ConfigFile.Settings.MailSubjectEmpty.FeatureId

if((Get-SPWeb $siteUrl -ErrorAction SilentlyContinue))
{	try
    {
	    $spWeb = Get-SPWeb -Identity $siteUrl	
        $spListCollection = $spWeb.Lists
	    $objlist=$spListCollection.TryGetList($listName)		
	    if($objlist -ne $null)
	    {
            $itemCollection =  $objlist.Items;
            foreach($item in $itemCollection)
            {
                if(!$item["Unit"])
                {
                    Add-Content $logFilePath "`n Mail Subject is empty.. Deleting list"
                    $objlist.AllowDeletion = $true
                    $objlist.Update()
                    $objlist.Delete()

                    Add-Content $logFilePath "`nReactivating Feature"

                    $Sitefeatures=Get-SPFeature -Web $siteUrl

                    foreach($feature in $Sitefeatures)           
                    {
                        Write-Host $feature.Id
                        if($feature.Id -eq $featureName)
                        {                
                            Disable-SPFeature $featureName -Url $siteUrl -Confirm:$False
                            break;          
                        }                             
                    }
                    Enable-SPFeature $featureName -Url $siteUrl      
                }
            }
        }
        else
        {
             Add-Content $logFilePath "`n List Does not exist"
        }
    }
    catch
    {
         $ErrorMessage = $_.Exception.Message
         Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
    }
}

else
{
    Add-Content $logFilePath "`n $($siteUrl) does not exist. Please enter a valid site Url"
}
