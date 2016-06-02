param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Schema Properties SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
$XmlDoc = [xml](Get-Content $xmlFilePath)

#Search Service Application
    $sa = $XmlDoc.Settings.CreateSchemaProperties.SearchProperties.ServiceName
    if(!(Get-SPEnterpriseSearchServiceApplication -Identity $sa -ErrorAction SilentlyContinue))
    {
         
    Add-Content $logFilePath "`n $searchapplication does not exists"
    ##Write-Host "searchapp does not exists"
    }
    else
    {
		$searchapp = Get-SPEnterpriseSearchServiceApplication $sa

		#process crawled properties
		Add-Content $logFilePath "`n processing  crawled properties"
		$CrawledPropNodeList = $XmlDoc.Settings.CreateSchemaProperties.SearchProperties.CrawledProperties
		try
		{
		foreach ($CrawledPropNode in $CrawledPropNodeList.CrawledProperty)
		{
			#create crawled property if it doesn't exist
			Add-Content $logFilePath "`n creating  crawled property $($CrawledPropNode.Name)"
			if (!(Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $searchapp -Name $CrawledPropNode.Name -ea "silentlycontinue"))
			{
				$varType = 0
				switch ($CrawledPropNode.Type)
				{
					"Text" { $varType=31 }
					"Integer" { $varType=20 }  
					"Decimal" { $varType=5 }  
					"DateTime" { $varType=64 }
					"YesNo" { $varType=11 }
					default { $varType=31 }
				}
				$crawlprop = New-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $searchapp -Category SharePoint -VariantType $varType -Name $CrawledPropNode.Name -IsNameEnum $false -PropSet "00130329-0000-0130-c000-000000131346"
			}
			else
			{
			#Write-Host "crawled property $($CrawledPropNode.Name) already exists"
			Add-Content $logFilePath "`n crawled property $($CrawledPropNode.Name) already exists"
			}
	}
}
catch
{
    $ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured in creating crawled properties:::::: $($ErrorMessage)" 
}
#process managed properties
Add-Content $logFilePath "`n processing managed properties"
try
{
$PropertyNodeList = $XmlDoc.Settings.CreateSchemaProperties.SearchProperties.ManagedProperties
foreach ($PropertyNode in $PropertyNodeList.ManagedProperty)
{
    $SharePointPropMapList = $PropertyNode.Map
	$recreate = [System.Convert]::ToBoolean($PropertyNode.Recreate)
    if ($recreate)
    {
		#Delete if property should be recreated and it exists
         
		if($mp = Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $searchapp -Identity $PropertyNode.Name -ea "silentlycontinue")
		{
            ##Write-Host "Managed Property Removed: " $PropertyNode.Name
			$mp.DeleteAllMappings()
			$mp.Delete()
			$searchapp.Update()
		}
		
		#create managed property
        Add-Content $logFilePath "`n Creating Managed Property $($PropertyNode.Name)"
		New-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $searchapp -Name $PropertyNode.Name -Type $PropertyNode.Type
    }

	if($mp = Get-SPEnterpriseSearchMetadataManagedProperty -SearchApplication $searchapp -Identity $PropertyNode.Name)
	{ 
         

		if($recreate)
		{
			#set configuration for new property
			$mp.RespectPriority = [System.Convert]::ToBoolean($PropertyNode.RespectPriority)
			$mp.Searchable = [System.Convert]::ToBoolean($PropertyNode.Searchable)
			$mp.Queryable = [System.Convert]::ToBoolean($PropertyNode.Queryable)
			$mp.Retrievable = [System.Convert]::ToBoolean($PropertyNode.Retrievable)
			$mp.HasMultipleValues = [System.Convert]::ToBoolean($PropertyNode.HasMultiple)
			$mp.Refinable = [System.Convert]::ToBoolean($PropertyNode.Refinable)
			$mp.Sortable = [System.Convert]::ToBoolean($PropertyNode.Sortable)
			$mp.Update()
		}

		#add property mappings
        Add-Content $logFilePath "`n adding property mappings"
		foreach ($SharePointPropMap in $SharePointPropMapList)
		{
			$cat = Get-SPEnterpriseSearchMetadataCategory -SearchApplication $searchapp -Identity $SharePointPropMap.Category
			$prop = Get-SPEnterpriseSearchMetadataCrawledProperty -SearchApplication $searchapp -Category $cat -Name $SharePointPropMap.InnerText
			New-SPEnterpriseSearchMetadataMapping -SearchApplication $searchapp -CrawledProperty $prop -ManagedProperty $mp
		}
	}
}
}
catch
{
       $ErrorMessage = $_.Exception.Message
	   Add-Content $logFilePath "`n Exception Occured in Processing managed properties:::::: $($ErrorMessage)" 
}
}