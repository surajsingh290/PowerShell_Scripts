param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Export Manged Metadata and Termsets Assocation"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
  
$ConfigFile = [xml](get-content $xmlFilePath)
Add-Content $logFilePath "`n XML file loaded successfully"

$webUrl = $ConfigFile.Settings.ExportManagedMetadataAssociation.webUrl
$listName = $ConfigFile.Settings.ExportManagedMetadataAssociation.ListName

$FileName = $ConfigFile.Settings.ExportManagedMetadataAssociation.FileName

$exportPath = $("$path\$FileName")

$exportlist = @()
$exportlist | Export-Csv -path 'C:\ExportMetadata.csv'

if((Get-SPWeb $webUrl -ErrorAction SilentlyContinue))
{	try
    {
	    $spWeb = Get-SPWeb $webUrl 
        $spsite = $spWeb.Site
        $objlist = $spWeb.Lists[$listName]
        #$spFolder = $spWeb.GetFolder($docLibrary.rootFolder.URL + "/")	
        	
	    if($objlist -ne $null)
        {
            $taxonomySession = Get-SPTaxonomySession -Site $spsite
            
            foreach ($field in $objlist.Fields)
            {                    
                if($field.TypeDisplayName -match "Metadata")
                {
                    $fieldName = $field.InternalName
                    $taxonomySession = Get-SPTaxonomySession -Site $spsite
                    $taxonomyField = $objlist.Fields[$fieldName]
                    $termStoreID = $taxonomyField.SspId 
                    $termStore = $taxonomySession.TermStores[$termStoreID] 
                   
                    $termsetID = $taxonomyField.TermSetId  
                    
                   $termsets = $termStore.GetTermSet($termsetID)
                    $Termgroup =$termsets.Group.Name
                    $termset = $termsets.Name
                    

                    $details = @{      
                                    
                        ColumnName     = $fieldName                 
                        TermStore      = $termStore.Name
                        Termgroup      = $Termgroup
                        termset        = $termset
                        }                           
                    $exportlist += New-Object PSObject -Property $details 
                }
            }
        }

        $exportlist | export-csv -Path $exportPath -NoTypeInformation

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