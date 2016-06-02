[reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
[reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.search") | Out-Null
$context = New-Object Microsoft.SharePoint.Client.ClientContext("http://bhukrk272121d:8888/")
$searchConfigurationPortability = New-Object Microsoft.SharePoint.Client.Search.Portability.searchconfigurationportability($context)
#$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"SPWeb")
$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"SPSite")
#$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"Ssa")
$value = $searchConfigurationPortability.ExportSearchConfiguration($owner)
$context.ExecuteQuery()
[xml]$schema = $value.Value
$schema.OuterXml | Out-File "C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\ExecutePowershell\Resources\SearchConfigXML\SearchConfig.xml" -Encoding UTF8