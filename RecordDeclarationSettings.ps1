param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Record Declaration Settings SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
   
   $xmlFilePath = $("$path\PSConfig.xml")
   [xml]$ConfigFile = Get-Content $xmlFilePath
   $webUrl=$ConfigFile.Settings.RecordDeclaration.webUrl
   $BoolManualDeclaration=$ConfigFile.Settings.RecordDeclaration.ManualDeclaration
   $web = get-spweb $webUrl
   try
   { 
    $lists = $web.Lists
    Foreach($list in $lists)
    {
    #Add-Content $logFilePath "`n Setting Manual Record Declaration True For $($list.Title)"
    $list.RootFolder.Properties["ecm_IPRListUseListSpecific"] = $BoolManualDeclaration
    $list.RootFolder.Properties["ecm_AllowManualDeclaration"] = $BoolManualDeclaration
    $list.RootFolder.Update()
    #Add-Content $logFilePath "`n Settings Updated"
    }
    }
    Catch
    {
    Add-Content $logFilePath -red "Exception found"
    Add-Content $logFilePath $_.exception.Message
    }