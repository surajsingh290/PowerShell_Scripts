param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Set Content Hub SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

Add-Content $logFilePath.txt "`n Starting script $ScriptName"
try 
{
        $siteUrl = $ConfigFile.Settings.SetContentHub.siteUrl
        if(!(Get-SPWeb $siteUrl -ErrorAction SilentlyContinue))
        {
            Add-Content $logFilePath "`n $($siteUrl) does not exist. Please enter a valid site URL"
        }
        else
        {
            $MMS = $ConfigFile.Settings.SetContentHub.MMS

            $sa = Get-SPServiceApplication | Where-Object {$_.Name -eq $MMS}            
            if ($sa -eq $null)            
            {         
                 Add-Content $logFilePath.txt "`n Manage Metadata Service does not exist."
            }
            else
            {
               
               $MetadataInstance = Get-SPServiceApplication -Name $MMS
                Set-SPMetadataServiceApplication -Identity $MetadataInstance -HubURI $siteUrl -Confirm:$false
                Add-Content $logFilePath.txt "`n ContentTypeHub Setup done"
             }

        }
}
catch
{
    $ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath.txt "`n Exception occured in Content Type Creation :::::: $($ErrorMessage)"
}