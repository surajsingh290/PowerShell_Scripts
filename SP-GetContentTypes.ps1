param ($path)
$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Get Content Types"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
  
try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
	Add-Content $logFilePath "`n XML file loaded successfully"
	
	$siteUrl = $ConfigFile.Settings.ContentHub.Url
	#Add-Content $logFilePath "`n Site URL $($siteUrl)"
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

try
{

    $site = new-object Microsoft.SharePoint.SPSite($siteurl)
    #Check Site Existence
    if ($site -eq  $null ) {
    Add-Content $logFilePath "`n Unable to load the site. Please check the site URL.."
    } 
    else {    
    $cts = $site.rootweb.ContentTypes
    $CSVFilePath = $("$path\ContentType.csv")

    'Content Type' + `
    ',Metadata' + `
    ',Required' + `
    ',Hidden' + `
    ',Default Value' + `
    ',Column Order' | Out-File -Append -FilePath $CSVFilePath -Encoding ASCII


    $sb = New-Object -TypeName "System.Text.StringBuilder" 
    $Required =  New-Object -TypeName "System.Text.StringBuilder" 
    $Hidden =  New-Object -TypeName "System.Text.StringBuilder" 
    $HiddenField =  New-Object -TypeName "System.Text.StringBuilder" 

    ForEach ($id in $cts)
    {
        if ($id.Group -eq "Custom Content Types") {

    
            ForEach ($field in $id.Fields)
            {
                #Required Fields
                if($field.Required -eq "TRUE")
                {
                    $Required = "YES"
                }
                else
                {
                    $Required = "NO"
                }
                #Hidden fields
                if($field.Hidden -eq "TRUE")
                {
                    $Hidden = "YES"
                    $fieldName = $field.InternalName
                    ForEach ($fieldLinks in $id.FieldLinks)
                    {
                        if($fieldLinks.Name -ne "ContentType"){
                            if($fieldLinks.Name -ne $fieldName){
                                [void]$sb.Append($fieldLinks.Name + ";")
                            }
                        }                            
                    }
                }
                else
                {
                    $Hidden = "NO"
                }
                #Remove Content Type Name As "Content Type"
                if($field.InternalName -ne "ContentType")
                {
                    '' + $id.Name + `
                    #',' + $id.SchemaXml + `
                    ',' + $field.InternalName + `
                    ',' + $Required + `
                    ',' + $Hidden + `
                    ',' + $field.DefaultValue + `
                    ',' + $sb + `
                    '' | Out-File -Append -FilePath $CSVFilePath -Encoding ASCII
                }
                #$sb=$null  
            }
        }
    }
    Add-Content $logFilePath "`n Script Executed Successfully..." 
    }
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}
finally
{
    $site.Dispose()
}
