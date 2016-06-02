param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Get Content Organizer rules CSOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

$UserName= $ConfigFile.Settings.Credentials.UserName
$Password= $ConfigFile.Settings.Credentials.Password
$DomainName= $ConfigFile.Settings.Credentials.DomainName
$credentials = New-Object System.Net.NetworkCredential($UserName, $Password, $DomainName)
 
$url = $ConfigFile.Settings.COR.SiteUrl
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$clientContext.Credentials = $credentials

if (!$clientContext.ServerObjectIsNull.Value) 
{

    try
    {

        Add-Content $logFilePath "`n Connected to SharePoint site: $($Url)" 

        #for(i=)

        $web = $clientContext.Site.RootWeb
        $listRoutingRules = $web.Lists.GetByTitle("Content Organizer Rules")
        $clientContext.Load($listRoutingRules)
        $clientContext.ExecuteQuery()
        $itemcount = $listRoutingRules.ItemCount
        
        $CSVFilePath = $("$path\ContentOrganizerRules.csv")

        'Title' + `
        ',RoutingRuleName' + `
        ',RoutingRuleDescription' + `
        ',RoutingContentType' + `
        ',RoutingPriority' + `
        ',RoutingConditions' + `
        ',RoutingConditionProperties' + `
        ',RoutingEnabled' + `
        ',RoutingAliases' + `
        ',RoutingTargetLibrary' + `
        ',RoutingTargetFolder' + `
        ',RoutingTargetPath' + `
        ',RoutingAutoFolderProp' + `
        ',RoutingAutoFolderSettings' + `
        ',RoutingCustomRouter' + `
        ',RoutingRuleExternal' | Out-File -Append -FilePath $CSVFilePath -Encoding ASCII

        $i=1

        while ($i -le $itemcount) {

        $item = $listRoutingRules.GetItemById($i) 
        $clientContext.Load($item)
        $clientContext.ExecuteQuery()

        '' + $item["Title"] + `
        ',' + $item["RoutingRuleName"] + `
        ',' + $item["RoutingRuleDescription"] + `
        ',' + $item["RoutingContentType"] + `
        ',' + $item["RoutingPriority"]  + `
        ',' + $item["RoutingConditions"]  + `
        ',' + $item["RoutingConditionProperties"]  + `
        ',' + $item["RoutingEnabled"] + `
        ',' + $item["RoutingAliases"] + `
        ',' + $item["RoutingTargetLibrary"]  + `
        ',' + $item["RoutingTargetFolder"] + `
        ',' + $item["RoutingTargetPath"]  + `
        ',' + $item["RoutingAutoFolderProp"]  + `
        ',' + $item["RoutingAutoFolderSettings"]  + `
        ',' + $item["RoutingCustomRouter"]  + `
        ',' + $item["RoutingRuleExternal"] + `
        '' | Out-File -Append -FilePath $CSVFilePath -Encoding ASCII

        $i++
        }
        Add-Content $logFilePath "`n Script Executed Successfully" 
        
    }
    catch
    {
	    $ErrorMessage = $_.Exception.Message
	    Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
    }
} 