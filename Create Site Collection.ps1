param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Site Collection SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

    Function CreateSiteCollection($appPoolIdentity, $templateId, $webAppUrl, $siteUrl)
    {
    Try
    {

		if(!(Get-SPWebApplication $webAppUrl -ErrorAction SilentlyContinue))
		{
			Add-Content $logFilePath "`n Webapplication not exist"
		}
		else
		{
		    if(!(Get-SPWeb $siteUrl -ErrorAction SilentlyContinue))
		    {
				Add-Content $logFilePath "`n Creating Site Collection"
				New-SPSite -Url $siteUrl -OwnerAlias $appPoolIdentity -Name "ConfigTest" -Template  $templateId
				Add-Content $logFilePath "`n Site Collection created"

				# Enabling Server publishing infrastructre
				 Enable-SPFeature -identity F6924D36-2FA8-4f0b-B16D-06B7250180FA -URL $siteUrl

				 # Enabling SharePoint Server Publishing
				 Enable-SPFeature -identity 94c94ca6-b32f-4da9-a9e3-1f3d343d7ecb -URL $siteUrl
			}
			else
			{
				#Write-Host "Site Already Exist exist"
				Add-Content $logFilePath "`n Site Already Exist exist"
			}
		}
	}
	Catch
    {
        $ErrorMessage = $_.Exception.Message
		Add-Content $logFilePath "`n Exception occured in Creating site collection :::::: $($ErrorMessage)"

    }
 }

 $count =0

#loop to get all sitecollection
foreach ($site in $ConfigFile.Settings.CreatesiteCollection.SiteCollection)
{	
	Add-Content $logFilePath "`n Site Collection count : $($count+1)"
    $appPoolIdentity=$site.ApplicationPoolIdentity
    $templateId= Get-SPWebTemplate $site.TemplateId
	$webAppUrl= $site.WebAppUrl
    $siteUrl= $site.SiteUrl

    Add-Content $logFilePath "`n Calling Create Site collection Method"
    CreateSiteCollection $appPoolIdentity $templateId $webAppUrl $siteUrl
}


    