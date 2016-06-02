param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Variation Labels SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")

try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
	Add-Content $logFilePath "`n XML file loaded successfully"
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}
 
$Sites = $ConfigFile.Settings.CreateVariationLabels.SiteUrl 


function ConfigureVariationsSettings($SiteUrl)
{
try
{
  # param($rootWeb);
      $site = Get-SPSite $SiteUrl
#Check Site Existence
if ($site -eq  $null ) {
Add-Content $logFilePath "`n Unable to load the site.Please check the site URL.."
} 
else {
Add-Content $logFilePath "`n Site has been Loaded..."
}

      $rootWeb = Get-SPWeb $SiteUrl
#Check Site Collection Existence
if ($rootWeb -eq  $null ) {
Add-Content $logFilePath "`n Unable to load site web.Please check the site URL.."
} 
else {
Add-Content $logFilePath "`n Site Web Loaded..."
}
     

    $guid = [Guid]$rootWeb.GetProperty("_VarRelationshipsListId");
      $list = $rootWeb.Lists[$guid];
    $rootFolder = $list.RootFolder;
    $rootFolder.Properties["EnableAutoSpawnPropertyName"] ="false";
    $list.RootFolder.Properties["AutoSpawnStopAfterDeletePropertyName"] = "false";
    $list.RootFolder.Properties["UpdateWebPartsPropertyName"] = "false";
    $list.RootFolder.Properties["CopyResourcesPropertyName"] = "true";
    $list.RootFolder.Properties["SendNotificationEmailPropertyName"] = "false";
    $list.RootFolder.Properties["SourceVarRootWebTemplatePropertyName"] = "CMSPUBLISHING#0";
    $list.RootFolder.Update();
    $item = $null;
    if (($list.Items.Count -gt 0))
    {
       $item = $list.Items[0];
    }
    else
    {
        $item = $list.Items.Add();
        $item["GroupGuid"] = new-object System.Guid("F68A02C8-2DCC-4894-B67D-BBAED5A066F9");
    }

    $item["Deleted"] = $false;
    $item["ObjectID"] = $site.RootWeb.ServerRelativeUrl;
    $item["ParentAreaID"] = [System.String]::Empty;
    $item.Update();
	}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

}


Function CreateHierarchies($SiteUrl)
{
try
{
     
      $site = Get-SPSite $SiteUrl
#Check Site Existence
if ($site -eq  $null ) {
Add-Content $logFilePath "`n Unable to load the site.Please check the site URL.."
} 
else {
Add-Content $logFilePath "`n Site has been Loaded..."
}
      $rootWeb = Get-SPWeb $SiteUrl
#Check Site Collection Existence
if ($rootWeb -eq  $null ) {
Add-Content $logFilePath "`n Unable to load site web.Please check the site URL.."
} 
else {
Add-Content $logFilePath "`n Site Web Loaded..."
}
      
       ##Write-Host "Creating Hierarchies for $SiteUrl" -BackgroundColor Yellow -ForegroundColor Black
      
      $id = [Guid]("e7496be8-22a8-45bf-843a-d1bd83aceb25");
    $guid=$site.AddWorkItem([System.Guid]::Empty, [System.DateTime]::Now.ToUniversalTime(), $id, $rootWeb.ID, $site.ID, 1, $false, [System.Guid]::Empty, [System.Guid]::Empty, $rootWeb.CurrentUser.ID, $null, [System.String]::Empty, [System.Guid]::Empty, $false);
      
    $webApplication = $site.WebApplication;
    $variationsJob = $webApplication.JobDefinitions | where { $_.Name -match "VariationsCreateHierarchies" };
      
     $variationsSiteJob = $webApplication.JobDefinitions | where { $_.Name -match "VariationsSpawnSites" };

   
   wait4timer($variationsJob)
   wait4timer($variationsSiteJob)
   }
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

 
         
}

function wait4timer($variationsJob)
 { 
 try
{  
    $variationsJob.RunNow();
    $startet = $variationsJob.LastRunTime
    ##Write-Host -ForegroundColor Yellow -NoNewLine "Running" $variationsJob.DisplayName "Timer Job."
     ##Waiting until job has finished
			while (($startet) -eq $variationsJob.LastRunTime)
			{
				##Write-Host -NoNewLine -ForegroundColor Yellow "."
				Start-Sleep -Seconds 2
			}

			##Checking for error messages, assuming there will be errormessage if job fails
			if($variationsJob.ErrorMessage)
			{
			Add-Content $logFilePath "`n Error in Timer Job"
			}
			else 
			{
				Add-Content $logFilePath "`n Timer Job has completed.";
			}
			}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}


} 



Function CreateLabels($Sites)
{
try
{
foreach($site in $Sites)
{
	
        $SiteUrl= $site.attributes['Url'].value
	    $objSite = Get-SPSite $SiteUrl
#Check Site Existence
if ($objSite -eq  $null ) {
Add-Content $logFilePath "`n Unable to load the site.Please check the site URL.."
} 
else {
Add-Content $logFilePath "`n Site has been Loaded..."
}
	    $Web = $objSite.RootWeb
#Check Site Collection Existence
if ($Web -eq  $null ) {
Add-Content $logFilePath "`n Unable to load root web.Please check the site URL.."
} 
else {
Add-Content $logFilePath "`n Root Web Loaded..."
}

        ConfigureVariationsSettings $SiteUrl
        Start-Sleep -Seconds 30
	    $VariationsList = $Web.Lists["Variation Labels"]
#Check if List Exists
if($VariationsList -ne $null)
{
  Add-Content $logFilePath "`n Variation List exists.."
}
else
{
  Add-Content $logFilePath "`n Variation List does not exists.."
}

  	foreach($label in $site.Labels)
  	{
	$DisplayName=$label.DisplayName
	Add-Content $logFilePath "`n Creating variation label for site"
	  
   		$item = $VariationsList.items.add()
              
   		$item["Title"] = $label.Label
   		$item["Flag Control Display Name"] = $label.DisplayName
   		$item["Language"] = $label.Language
   		$item["Locale"] = $label.Locale
                if($label.IsSource -eq "true")
   		 {
                  $item["Is Source"] = $true
               
                 }
                elseif($label.IsSource -eq "false")
   		 {
                  $item["Is Source"] = $false
                 }

                  if($label.HierarchyIsCreated -eq "true")
   		 {
                  $item["Hierarchy Is Created"] = $true
                 }
                elseif($label.HierarchyIsCreated -eq "false")
   		 {
                  $item["Hierarchy Is Created"] = $false
                 }
   	
   		$item["Hierarchy Creation Mode"] =$label.HierarchyCreationMode
   		$item.update()
  	}
     CreateHierarchies $SiteUrl
}
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

}

CreateLabels $Sites

