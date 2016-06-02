param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}

Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n PDFs in Client Apps"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$filePath = "C:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\TEMPLATE\LAYOUTS"
$fileName ="PDFFIX.js"

$xmlFilePath = $("$path\PSConfig.xml")
  
$ConfigFile = [xml](get-content $xmlFilePath)
Add-Content $logFilePath "`n XML file loaded successfully"


if (!(Test-Path $("$filePath\$fileName")))
{
    Copy-Item $("$path\$fileName") $filePath
}

try
{
    $webUrl = $ConfigFile.Settings.PDFinClientApp.webUrl
    $listName = $ConfigFile.Settings.PDFinClientApp.ListName
    $fieldName = $ConfigFile.Settings.PDFinClientApp.FieldName
    
    $web = Get-SPWeb $webUrl
    
    $list = $web.Lists[$listName]
    $field = $list.Fields.GetFieldByInternalName($fieldName)
    $field.JSLink = $("/_layouts/15/$fileName")
    $field.Update($true)
    Add-Content $logFilePath "`n Field $($fieldName) updated successfully"
}
catch
{
     $ErrorMessage = $_.Exception.Message
     Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}

