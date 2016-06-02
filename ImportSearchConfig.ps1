param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Import Search Config SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

     try
     {
	       $SiteUrl = $ConfigFile.Settings.ImportSearchConfig.siteUrl
			if((Get-SPWeb $SiteUrl -ErrorAction SilentlyContinue))
			{
            $SearchConfigXMLFileName = $ConfigFile.Settings.ImportSearchConfig.SearchConfigFile
            $xmlSearchConfigFilePath = "D:\PowershellConfg\EVADeploymentAutomation\EVADeploymentAutomation\SearchConfiguration.xml"
            
            
            [reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
            [reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.search") | Out-Null
            $context = New-Object Microsoft.SharePoint.Client.ClientContext($SiteUrl)
            
            $searchConfigurationPortability = New-Object Microsoft.SharePoint.Client.Search.Portability.searchconfigurationportability($context)
            #$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"SSA")
            $owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"SPSite")
            
             Add-Content $logFilePath "`n Importing Schema"
            [xml]$schema = Get-Content $xmlSearchConfigFilePath  #gc .\SearchConfiguration.xml [???????????]
            
            $searchConfigurationPortability.ImportSearchConfiguration($owner,$schema.OuterXml)
            $context.ExecuteQuery()
             
             $SSA=$ConfigFile.Settings.ImportSearchConfig.ssa
             $ContentsourceName=$ConfigFile.Settings.ImportSearchConfig.Contentsourcename
             $startadress=$ConfigFile.Settings.ImportSearchConfig.startaddress
            
            if(!(Get-SPEnterpriseSearchServiceApplication -Identity $SSA -ErrorAction SilentlyContinue))
              {
            
            
               Add-Content $logFilePath "`n $searchapp does not exists"
               #Write-Host "searchapp does not exists"
               }
            else
               {
               $searchapp = Get-SPEnterpriseSearchServiceApplication $SSA
               $ContentSources = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchapp | ForEach-Object {    
            if ($_.Name.ToString() -eq $ContentSourceName)  
              
                {        
               #Write-Host "Content Source : $ContentSourceName already exist.Deleting the Content source..."       
                Remove-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchapp -Identity $ContentSourceName -Confirm:$false   
                 }
                 }
                
            New-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchapp -Type file -name $ContentsourceName -StartAddresses  $startadress
            Add-Content $logFilePath "`n Import Completed"
            }
            }
            }

catch
{
           $ErrorMessage = $_.Exception.Message
		   Add-Content $logFilePath "`n Exception occured in ImportSearchConfig :::::: $($ErrorMessage)"
}