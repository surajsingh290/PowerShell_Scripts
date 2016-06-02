param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Property Bags CSOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

$UserName= $ConfigFile.Settings.Credentials.UserName
$Password= $ConfigFile.Settings.Credentials.Password
$DomainName= $ConfigFile.Settings.Credentials.DomainName
$credentials = New-Object System.Net.NetworkCredential($UserName, $Password, $DomainName)

$url = $ConfigFile.Settings.SearchPropertyBag.Site
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$clientContext.Credentials = $credentials
 
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
 
if (!$clientContext.ServerObjectIsNull.Value)
{
    Add-Content $logFilePath "`n Connected to SharePoint site"
    
    #$web = $clientContext.Web   
    #$clientContext.Load($web)   
    #$clientContext.ExecuteQuery()

    $web = $clientContext.Web
    $clientContext.Load($web)
    $clientContext.ExecuteQuery();  
}

foreach ($sPropertyBagKey in $ConfigFile.Settings.SearchPropertyBag.Room)
{
    $allProperties = $web.AllProperties
    $allProperties[$sPropertyBagKey.Name] = $sPropertyBagKey.Value
    #$web.AllProperties.FieldValues.Add($sPropertyBagKey.Name, $sPropertyBagKey.Value);
    #Write-Host "Created property Bag in SharePoint site" -ForegroundColor Green 
    #Write-Host $sPropertyBagKey.Value -ForegroundColor Red 
    #Write-Host $sPropertyBagKey.Name -ForegroundColor Red
    $web.Update();
    $clientContext.ExecuteQuery()
}