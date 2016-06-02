param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
Function ConvertTo-Json {

param($inputObject)

    if ($inputObject -eq $null) { "null" }
    else {
        switch ($inputObject.GetType().Name) {
            "String" { '"' + $inputObject +'"' }
            "Boolean" { 
                if($inputObject){
                    "true"
                }
                else {
                    "false"
                }
            }
            "Object[]" {
                $items = @()
                $inputObject | % {
                    $items += ConvertTo-Json $_
                }
                $ofs = ","; "[" + [string]$items + "]"
            }
            "PSCustomObject" {
                $properties = @()
                $inputObject | Get-Member -MemberType *Property | % {
                    $properties += '"'+ $($_.Name) + '":' + $(ConvertTo-Json $inputObject.($_.Name))
                }
                $ofs = ","; "{" + [string]$properties + "}"
            }
            default { $inputObject }
        }
    }
}
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:Refinement metdata check SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
# Get our page and check it out
try
{
Add-Content $logFilePath "`n getting web and page url"
$web=$ConfigFile.Settings.web
$spweb = Get-SPWeb $web 
$file=$ConfigFile.Settings.file
$page = $spweb.GetFile($file)
#$page.CheckOut()
$pageurl=$ConfigFile.Settings.pageurl
# Find the Refinement web part
$webPartManager = $spweb.GetLimitedWebPartManager($pageurl, [System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared)
$rwp = $webpartmanager.webparts | ? { $_.title -eq 'Refinement' }


$newRefinerConfigurations = @()
$newJsonObject = @{}



Add-Content $logFilePath "`n getting refinementconfigurationjson"
$jsonFilePath = $($ConfigFile.Settings.jsonpath)
$newRefinerJson = (Get-Content $jsonFilePath  -Raw) | ConvertFrom-Json

$newRefinerConfigurations += $newRefinerJson
$newJsonObject.refinerConfigurations= $newRefinerConfigurations

Add-Content $logFilePath "`n seeting refinements for webpart"
$rwp.SelectedRefinementControlsJson= ConvertTo-Json $newJsonObject.refinerConfigurations



$webpartmanager.SaveChanges($rwp)

}
catch
{
Add-Content $logFilePath -red "Exception found"
Add-Content $logFilePath $_.exception.Message
}




