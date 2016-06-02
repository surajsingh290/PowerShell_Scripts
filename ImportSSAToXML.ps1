[reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint.Client") | Out-Null
[reflection.assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.search") | Out-Null
$context = New-Object Microsoft.SharePoint.Client.ClientContext("http://bhukrk272121d:8888")
$searchConfigurationPortability = New-Object Microsoft.SharePoint.Client.Search.Portability.searchconfigurationportability($context)
#$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"SPWeb")
$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"SPSite")
#$owner = New-Object Microsoft.SharePoint.Client.Search.Administration.searchobjectowner($context,"Ssa")
[xml]$schema = gc .\schema.xml
$searchConfigurationPortability.ImportSearchConfiguration($owner,$schema.OuterXml)
$context.ExecuteQuery()