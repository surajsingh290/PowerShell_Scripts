param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:  Add Site Logo SOM"
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

function SetLogo($siteCollection)
{
try
{
   $string="SiteAssets/" + $ConfigFile.Settings.AddSiteLogo.imageName
	Add-Content $logFilePath "`n Site Assets :::::: $($string)"         

   $sitelogo="$siteCollectionUrl$string"
	Add-Content $logFilePath "`n Site logo :::::: $($sitelogo)"         

   foreach($web in $siteCollection.Allwebs) 
   {
		$web.SiteLogoUrl=$sitelogo
		$web.Update()
   }
  }
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

}

     
$DocLibName = $ConfigFile.Settings.AddSiteLogo.DocLibName           
$imageName = $ConfigFile.Settings.AddSiteLogo.imageName  

$siteCollectionUrl=$ConfigFile.Settings.AddSiteLogo.SiteCollUrl
$siteCollection =get-spsite $siteCollectionUrl 
#Check Site Existence
if ($siteCollection -eq  $null ) {
Add-Content $logFilePath "`n Unable to load the site.Please check the site URL.."
} 
else {
Add-Content $logFilePath "`n Site has been Loaded..."
}
Add-Content $logFilePath "`n Site Collection :::::: $($siteCollectionUrl)"         
SetLogo $siteCollection

