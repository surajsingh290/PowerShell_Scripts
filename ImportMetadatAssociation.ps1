param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Import Manged Metadata and Termsets Assocation"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
  
$ConfigFile = [xml](get-content $xmlFilePath)
Add-Content $logFilePath "`n XML file loaded successfully"

$webUrl = $ConfigFile.Settings.ImportManagedMetadataAssociation.webUrl
$listName = $ConfigFile.Settings.ImportManagedMetadataAssociation.ListName

$FileName = $ConfigFile.Settings.ImportManagedMetadataAssociation.FileName

$FilePath = $("$path\$FileName")

$Stuff = Import-CSV $FilePath

if((Get-SPWeb $webUrl -ErrorAction SilentlyContinue))
{	try
    {
	    $spWeb = Get-SPWeb $webUrl 
        $spsite = $spWeb.Site
        $objlist = $spWeb.Lists[$listName]
                	
	    if($objlist -ne $null)
        {
            $taxonomySession = Get-SPTaxonomySession -Site $spsite
            for($i=0; $i -lt $objlist.Fields.Count; $i++)
            #foreach ($field in $objlist.Fields)
            {   
                $fieldSelected = $objlist.Fields[$i]
                #Write-Host $fieldSelected.InternalName                
                if($fieldSelected.TypeDisplayName -match "Metadata")
                {
                    $fieldName = $fieldSelected.InternalName
                    ForEach ($victim in $Stuff) 
                    {
                        if($victim.ColumnName -eq $fieldName)
                        {                          
                            $taxonomySession = Get-SPTaxonomySession -Site $spsite
                            $taxonomyField = $objlist.Fields[$fieldName]
                            
                            $termStoreName = $victim.TermStore 
                            $groupName = $victim.Termgroup 
                            $termsetName = $victim.termset

                            if($termStoreName -ne $null)
                            {
                                $termStore = $taxonomySession.TermStores[$termStoreName]
                                if($termStore -ne $null)
                                {                     
                                    $group = $termStore.Groups[$groupName]
                                    if($group -ne $null)
                                    { 
                                        $termSet = $group.TermSets[$termsetName]
                                        if($termSet -ne $null)
                                        { 
                                            $taxonomyField.SspId = $termSet.TermStore.Id
                                            $taxonomyField.TermSetId = $termSet.Id
                                            $taxonomyField.Update()
                                        }
                                        else
                                        {
                                             Add-Content $logFilePath "`n Termset $($termsetName) does not exist"
                                        }
                                    }
                                    else
                                    {
                                        Add-Content $logFilePath "`n Termgroup $($groupName) does not exist" 
                                    }
                                 }
                                 else
                                 {
                                    Add-Content $logFilePath "`n Terrmstore $($termStoreName) does not exist" 
                                 }
                            }
                            else
                            {
                                Add-Content $logFilePath "TermStore name is empty"
                            }
                        }
                    }                
                }
            }
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