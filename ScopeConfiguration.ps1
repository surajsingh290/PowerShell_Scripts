param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Custom scope configuration SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
$SearchResultPageURL=$ConfigFile.Settings.Scope.SearchpageURL
$NavigationTitle=$ConfigFile.Settings.Scope.NavigationTitle
$NavigationURL=$ConfigFile.Settings.Scope.NavigationURL
function AddSearchLink([string]$searchsiteUrl, [string] $navTitle,[string] $navUrl){
try
{
$searchweb=Get-SPWeb $searchsiteUrl
DeleteSearchLink -searchsiteUrl $searchsiteUrl -navTitle $navTitle
$node=New-Object Microsoft.SharePoint.Navigation.SPNavigationNode($navTitle,$navUrl,$true);

$searchweb.Navigation.AddToSearchNav($node);
$searchweb.AllProperties["SRCH_SB_SET_WEB"]= '{"Inherit":false,"ResultsPageAddress":"'+ $SearchResultPageURL +'","ShowNavigation":true}'

$searchweb.Update()
}
catch
{
Add-Content $logFilePath -red "Exception found"
Add-Content $logFilePath $_.exception.Message
}

}
function DeleteSearchLink([string]$searchsiteUrl, [string] $navTitle){

$searchweb=Get-SPWeb $searchsiteUrl

$oldNode = $searchweb.Navigation.SearchNav | where {$_.Title -eq $navTitle}

if( $oldNode -ne $null){

$oldNode.Delete();

}

$searchweb.Update()

}
AddSearchLink -searchsiteUrl $SearchResultPageURL -navTitle $NavigationTitle -navUrl $NavigationURL