param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

$outputPath = $("$path\03ContentDBDetails.csv")
$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
# Add SharePoint PowerShell Snapin  
  
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: FInal DB Report"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
  
if ( (Get-PSSnapin -Name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue) -eq $null ) {  
    Add-PSSnapin Microsoft.SharePoint.Powershell  
}  
  
$scriptBase = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent  
Set-Location $scriptBase  
 
 
#Deleting any .rtf files in the scriptbase location  
$FindRTFFile = Get-ChildItem $scriptBase\*.* -include *.rtf  
if($FindRTFFile)  
{  
 foreach($file in $FindRTFFile)  
  {  
   remove-item $file  
  }  
}  
   
Function ContentDatabaseReport()  
{  
  try
  {
 $CDBName = $ConfigFile.Settings. DBReport.DBName
 #write-host "Generating report for the Content database " $CDBName -fore yellow  
 Add-Content $logFilePath "Generating report for the Content database  $($CDBName)"  
 #write-host "Processing report..................." -fore magenta 
 Add-Content $logFilePath "Processing report..................."
 $Output =  $outputPath  
 "CDBName" + "," + "CDBServer" + "," + "CDBStatus" + "," + "CDBSize(MB)" + "," + "SiteLevelWarning" + "," + "MaximumAllowedSites" + "," + "TotalSiteCollection" + "," + "SiteCollectionURL" + "," + "Web(s)Count" + "," + "SiteCollectionSize(MB)" | Out-File -Encoding Default -FilePath $Output;  
 $CDB = get-spcontentdatabase -identity $CDBName  
 $CDB.name + "," + $CDB.server + "," + $CDB.Status + "," + $CDB.DiskSizeRequired/1048576 + "," + $CDB.WarningSiteCount + "," + $CDB.MaximumSiteCount + "," + $CDB.Currentsitecount + "," + $empty + "," + $empty + "," + $empty  | Out-File -Encoding Default  -Append -FilePath $Output;  
 $sites = get-spsite -limit all -ContentDatabase $CDBName  
 foreach($site in $sites)  
 {  
  $empty + "," + $empty + "," + $empty + "," + $empty + "," + $empty + "," + $empty + "," + $empty + "," + $site.url + "," + $site.allwebs.count + "," + $site.usage.storage/1048576 | Out-File -Encoding Default  -Append -FilePath $Output;  
 }  
 #write-host "Report collected for content database " $CDBName " and you can find it in the location " $output -fore green  
 Add-Content $logFilePath "Report collected for content database  $($CDBName)  and you can find it in the location $($output)"   
  
  
} 
catch
{

 $ErrorMessage = $_.Exception.Message
 Add-Content $logFilePath "`n Exception occured in Database report creation :::::: $($ErrorMessage)"
              
} 
 }
ContentDatabaseReport  
  

Add-Content $logFilePath "SCRIPT COMPLETED"
  
 