param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Site Column O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
 
$url = $ConfigFile.Settings.CreateSiteColumn.ContentTypeHub
#$url = “https://infyakash.sharepoint.com/sites/ConfigNext-POC/”
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)

$clientContext.Credentials = $credentials

 
if (!$clientContext.ServerObjectIsNull.Value)
{
    Add-Content $logFilePath "`n Connected to SharePoint site"
    
    $web = $clientContext.Web   
    $clientContext.Load($web)   
    $clientContext.ExecuteQuery()
  
}

try
{
#Create Site columns 
Add-Content $logFilePath "`n Creating site columns with in the site started....."
$xmlSiteColumnsFilePath = $ConfigFile.Settings.CreateSiteColumn.File
#Write-Host $xmlSiteColumnsFilePath
$contentXML=[xml](Get-Content($xmlSiteColumnsFilePath))
Add-Content $logFilePath "`n Site Column File Loaded Successfully..."

$fldWeb = $web.Fields
$clientContext.Load($fldWeb)
$clientContext.ExecuteQuery()


$FieldAsXML = $contentXML.Fields.InnerXml.ToString()
#Write-Host "Field as XML " $FieldAsXML
$separator = [string[]]@("</Field>")
$FieldAsXML.Split($separator, [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
$fldXML = [string[]]$_ + [string[]]@("</Field>")
#Write-Host $fldXML
$fld = $web.Fields.AddFieldAsXml($fldXML, $true, [Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
$web.Update()
$clientContext.ExecuteQuery()
}
}
catch
{
$ErrorMessage = $_.Exception.Message
Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}

