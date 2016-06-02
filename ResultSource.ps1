
 param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")
Add-PSSnapin Microsoft.SharePoint.PowerShell
 $xmlFilePath = $("$path\PSConfig.xml")
 [xml]$ConfigFile = Get-Content $xmlFilePath

function CreateResultSource(){
[CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$siteUrl,
        [Parameter(Mandatory=$true)][string]$searchServiceName,
        [Parameter(Mandatory=$true)][string]$query,
        [Parameter(Mandatory=$true)][string]$resultSourceName,
        [Parameter(Mandatory=$false)][String]$setAsDefault,
        [Parameter(Mandatory=$false)][String]$setPeopleType
    )

try{

       

        # Get Site, SSA and owner
        #
        $site = get-spsite $siteUrl -WarningAction SilentlyContinue
        $sspApp = Get-SPEnterpriseSearchServiceApplication $searchServiceName
        $fedManager = New-Object Microsoft.Office.Server.Search.Administration.Query.FederationManager($sspApp)
        $searchOwner = New-Object Microsoft.Office.Server.Search.Administration.SearchObjectOwner([Microsoft.Office.Server.Search.Administration.SearchObjectLevel]::SPSite, $site.RootWeb)

        # Query properties
        #
        $queryProperties = New-Object Microsoft.Office.Server.Search.Query.Rules.QueryTransformProperties

        # Check if source exists
        #
        $source = $fedManager.GetSourceByName($resultSourceName, $searchOwner)
        if ($source -eq $null)
        {
            # create result source
            #
            $resultSource = $fedManager.CreateSource($searchOwner)
            $resultSource.Name = $resultSourceName

            if ($setPeopleType -eq "$True")
            {
                $resultSource.ProviderId =  $fedManager.ListProviders()['Local People Provider'].Id
               Add-Content $logFilePath  "$($resultSourceName) set as default 'People Search Results'" -ForegroundColor Yellow
            }
            else{
                $resultSource.ProviderId = $fedManager.ListProviders()['Local SharePoint Provider'].Id
            }

            $resultSource.CreateQueryTransform($queryProperties, $query)
            $resultSource.Commit()

            if ($setAsDefault -eq "$True")
            {
                try{
                    $fedManager.UpdateDefaultSource($resultSource.Id, $searchOwner)
                   Add-Content $logFilePath  "$($resultSourceName) set as default result source" -ForegroundColor Yellow
                }
                catch {
                   Add-Content $logFilePath "Error : fail to set as default $($resultSourceName) :  " $_.Exception.Message -ForegroundColor Red
                }
            }
           Add-Content $logFilePath "Created successfully" -ForegroundColor Green
        }
        else
        {
           Add-Content $logFilePath "Result Source exists!" -ForegroundColor Yellow

        }
    }
    catch{
       Add-Content $logFilePath $_.Exception.Message -ForegroundColor Red
    }

}
$siteURL=$ConfigFile.Settings.ResultSource.SiteURL
$SSA=$ConfigFile.Settings.ResultSource.SSA
$KQLquery=$ConfigFile.Settings.ResultSource.KQLQuery
$ResultSourceName=$ConfigFile.Settings.ResultSource.ResultSourceName

$setAsDefault=$ConfigFile.Settings.ResultSource.setAsDefault
#$setAsDefault=[System.Convert]::ToBoolean($var)
$setPeopleType=$ConfigFile.Settings.ResultSource.setPeopleType
CreateResultSource $siteURL $SSA $KQLquery $ResultSourceName $setAsDefault $setPeopleType