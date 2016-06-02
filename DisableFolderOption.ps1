param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Disable Folder Option SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
$web = Get-SPWeb $ConfigFile.Settings.DisableFolderView.WebUrl
$doclibs = $web.Lists
$listsTochangesetting = @()
$views=@()
try
{
     foreach($list in $web.Lists)
      {
     
              $listsTochangesetting += $web.Lists[$list.Title]
    
      }
Add-Content $logFilePath "`n iterating through all lists"
    foreach($listTochangesetting in $listsTochangesetting) 
      {
             $views +=$listTochangesetting.Views
Add-Content $logFilePath "`n iterating through all views" 
             foreach($view in $views)
              {
              $view.Scope = [Microsoft.SharePoint.SPViewScope]::Recursive
              $view.Update()
     
      }
}
Add-Content $logFilePath "`n script Executed" 
}
catch
{
Add-Content $logFilePath -red "Exception found"
Add-Content $logFilePath $_.exception.Message
}
