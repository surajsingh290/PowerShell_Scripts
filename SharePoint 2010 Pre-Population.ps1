#############           A tool which could generate the following SharePoint data for me:

############# 			* Create various Web Applications

############# 			* Each Web Application to have multiple site collections spread across two content databases.

############# 			* Pre-populate each site collection’s document library with uniquely named documents.



Set-ExecutionPolicy Unrestricted

Add-PSSnapin microsoft.sharepoint.powershell




#USER Defined Variables

$siteCollTemplate = "WIKI#0"
$webAppProtocol ="http://"
$WebAppsToCreate = @("arianwin2k8:700","arianwin2k8:710")
$numSiteCollectionsPerWebApp =5
$OwnerAlias = "arianwin2k8\Administrator"
$docLib = "AnalyticsReports"
$fileSource = "C:\UploadFiles"
$appPoolExt = "App_Pool"
# DO not edit anything beyond this line

 


function SPContentUpload {

#my document upload function to a sharepoint doc library.

param ([string]$urlDocLib,[string]$urlSPWeb,[string]$strDirPath)

$hshDocProps=@{"ContentType"="Document"}
[void][System.Reflection.Assembly]::LoadWithPartialName(”Microsoft.SharePoint”)
$SPsite=new-object Microsoft.SharePoint.SPSite($urlDocLib)
$SPweb=$SPsite.openweb($urlSPWeb)

#loop through all the files in the source folder and add each file to the defined SharePoint doc library

dir $strDirPath | foreach-object {
               $bytes=get-content $_.fullname -encoding byte
               $arrbytes=[byte[]]$bytes
               $SPWeb.files.Add($($urlDocLib +$docLib"/") + $_.Name + [guid]::newGuid().tostring(),$arrbytes,$hshDocProps, $true)
 

} 

$SPSite.Dispose()

}

 

#[guid]::newGuid().tostring()
$b=1

foreach ($webApp in $WebAppsToCreate) {


$Split=$webApp.split(":")
$webAppUrl=$Split[0]
$webAppPort =$Split[1]

Write-Host Web App Url $webAppUrl $webAppPort


$webAppUrlFull="$webAppProtocol$webAppUrl"


New-SPWebApplication -Name $($webAppUrl + " Web Application" + $b) –URL $webAppUrlFull -port $webAppPort -ApplicationPool "$($webAppUrl + "_app_Pool" + $b)" -ApplicationPoolAccount $OwnerAlias -DatabaseName $($webAppUrl + "_" + $webAppPort)


Write-Host Web App Url $webAppUrlFull

#Create new content db

#New-SPContentDatabase $webAppUrl -WebApplication $webAppUrlFull
New-SPContentDatabase $($webAppUrl + "_" + $webAppPort + "_2") -WebApplication $($webAppUrlFull + ":" + $webAppPort)

$b++

$i=1

do {


$siteCollPath = $($webAppUrlFull + ":" + $webAppPort + "/sites/" + $i)
$siteCollPath2 = $($webAppUrlFull + ":" + $webAppPort + "/sites/" + $i + "_")

Write-Host Creating site collection $siteCollPath

#create site collection to go to unique content database
New-SPSite -url $siteCollPath -OwnerAlias "$OwnerAlias" -Name "Test Wiki content db_1_ $i" -Template $siteCollTemplate -ContentDatabase $($webAppUrl + "_" + $webAppPort)


#populate Doc lib for above site collection
SPContentUpload "$($webAppUrlFull + ":" + $webAppPort + "/sites/" + $i + "/")" "" "$fileSource"


#create site collection to go to sep content database
New-SPSite -url $siteCollPath2 -OwnerAlias "$OwnerAlias" -Name "Test Wiki content db_2_$i" -Template $siteCollTemplate -ContentDatabase $($webAppUrl + "_" + $webAppPort + "_2")

#populate Doc lib for above site collection
SPContentUpload "$($webAppUrlFull + ":" + $webAppPort + "/sites/" + $i + "_/")" "" "$fileSource"

$i++
}
while ($i -le $numSiteCollectionsPerWebApp)
}

 
