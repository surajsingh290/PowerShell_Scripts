param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Get Content Types"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
  
try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
	Add-Content $logFilePath "`n XML file loaded successfully"
	
	$siteUrl = $ConfigFile.Settings.ContentHub.Url
	#Add-Content $logFilePath "`n Site URL $($siteUrl)"
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

function Remove-SPFeatureFromContentDB($ContentDb, $FeatureId, [switch]$ReportOnly)
{
    $db = Get-SPDatabase | where { $_.Name -eq $ContentDb }
    [bool]$report = $false
    if ($ReportOnly) { $report = $true }
    
    $db.Sites | ForEach-Object {
        
        Remove-SPFeature -obj $_ -objName "site collection" -featId $FeatureId -report $report
                
        $_ | Get-SPWeb -Limit all | ForEach-Object {
            
            Remove-SPFeature -obj $_ -objName "site" -featId $FeatureId -report $report
        }
    }
}

function Remove-SPFeature($obj, $objName, $featId, [bool]$report)
{
    $feature = $obj.Features[$featId]
    
    if ($feature -ne $null) {
        if ($report) {
            #write-host "Feature found in" $objName ":" $obj.Url -foregroundcolor Red
        }
        else
        {
            try {
                $obj.Features.Remove($feature.DefinitionId, $true)
                Add-Content $logFilePath "`n Feature successfully removed from ::: $($objName): with URL: $($obj.Url)"
            }
            catch {
                Add-Content $logFilePath "`n There has been an error trying to remove the feature: $($_)"
            }
        }
    }
    else {
        #write-host "Feature ID specified does not exist in" $objName ":" $obj.Url
    }
}

$count =0

#loop to get all sitecollection
foreach ($db in $ConfigFile.Settings.RemoveFeature.ContentDB.DB)
{
	$WebApplication=$db.attributes['DBName'].value
    $FeatureId = $db.FeatureId.attributes['Name'].value
                 
    Remove-SPFeatureFromContentDB -ContentDB $ContentDB -FeatureId $FeatureId
    Add-Content $logFilePath "`n Removing Feature from :::: Content Database Name: $($ContentDB) with Feature ID: $($FeatureId)"
}