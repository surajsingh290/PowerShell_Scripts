param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Content Source SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

$SearchServiceApplicationName = $ConfigFile.Settings.CreateContentSource.SSAName
try
{
    foreach($site in $ConfigFile.Settings.CreateContentSource.siteUrl)
    {
	    $SiteUrl = $site.attributes['Url'].value
        
        if(!(Get-SPWeb $SiteUrl -ErrorAction SilentlyContinue))
        {
            Add-Content $logFilePath "`n $($SiteUrl) does not exist. Please enter a valid site URL"
        }
        else
        {    
	        $ContentSourceName = $site.ContentSourceName
        
            if(!(Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceApplicationName -ErrorAction SilentlyContinue))
            {
                Add-Content $logFilePath "`n Search Service Application does not exist."
            }
            else
            {
    	        $SearchServiceApplication = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceApplicationName -ErrorAction SilentlyContinue

                if((Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $SearchServiceApplication -Identity $ContentSourceName) -ne $null)
                {
                    Add-Content $logFilePath "`n Content Source already exist. Skipping new creation"
                }
                else
                {
 	                $SPContentSource = New-SPEnterpriseSearchCrawlContentSource -SearchApplication $SearchServiceApplication -Type Web -name $ContentSourceName -StartAddresses $SiteUrl -MaxSiteEnumerationDepth 0
                 }
     	        if($SPContentSource.CrawlState -eq "Idle")
                {
                    Add-Content $logFilePath "`n Starting the FullCrawl for the content source : $($SPContentSource)"
         	        $SPContentSource.StartFullCrawl()
    	    	    do {Start-Sleep 2; #Write-Host "." -NoNewline
                    }
     		        While ( $SPContentSource.CrawlState -ne "CrawlCompleting")
                    {
    		             Add-Content $logFilePath "`n FullCrawl for the content source : $($SPContentSource) completed"
                     }
                }
            }
        }
    }
}
Catch
{ 
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception occured in Creating Content Source logo :::::: $($ErrorMessage)"
}