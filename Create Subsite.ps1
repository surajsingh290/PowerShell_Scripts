param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Sub-Site SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")  

[xml]$XmlDoc = Get-Content $xmlFilePath

#Get the site template code     
$SiteTemplate = $XmlDoc.Settings.CreateSubSite.SiteCollection.TemplateCode     
     
$siteCollectionUrl = $XmlDoc.Settings.CreateSubSite.SiteCollection.Url

Add-Content $logFilePath "`n Checking if site:: $($siteCollectionUrl) exist..."    
# add solution 
	if(!(Get-SPWeb $siteCollectionUrl -ErrorAction SilentlyContinue))
	{
		Add-Content $logFilePath "`n Webapplication not exist..!!"
	} 
	else
	{   
		Add-Content $logFilePath "`n Site:: $($siteCollectionUrl) exists..."     

		Add-Content $logFilePath "`n Now Creating Subsites.." 
		$subSites = $XmlDoc.Settings.CreateSubSite.SiteCollection.SubSites     
		foreach($subsiteNode in $subSites.Site) 
		{
			try
			{
				$SubSiteName = $subsiteNode.Name

				$SubSiteUrl = $siteCollectionUrl+$subsiteNode.Url     

				Add-Content $logFilePath "`n Creating new subsite : $($SubSiteUrl)"     
				Add-Content $logFilePath "`n Creating Subsite..."   
				$NewSubSite = New-SPWeb -Url $SubSiteUrl -Template $SiteTemplate -Name $SubSiteName   
        
				Add-Content $logFilePath "`n Breaking Inheritance On A Subsite"     
				$NewSubSite.BreakRoleInheritance($true,$true)     
				$NewSubSite.Update()
            
				Add-Content $logFilePath "`n SubSite Created Successfully..!!"
			}
			catch
			{
				Add-Content $logFilePath "`n SubSite could not be created..!!"
			}
		} 
	}