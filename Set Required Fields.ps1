param ($path)
$location= "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI"

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Set Required Fields CSOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

$UserName= $ConfigFile.Settings.Credentials.UserName
$Password= $ConfigFile.Settings.Credentials.Password
$DomainName= $ConfigFile.Settings.Credentials.DomainName
$credentials = New-Object System.Net.NetworkCredential($UserName, $Password, $DomainName)

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"
 
#$url = $ConfigFile.Settings.setRequiredField.CreateSiteColumn.ContentTypeHub
foreach($url in $ConfigFile.Settings.setRequiredField.SiteUrl)
{
#getting site context
Add-Content $logFilePath "`n getting site context"
$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url.Url)
$clientContext.Credentials = $credentials
    try
        {

            [Microsoft.SharePoint.Client.Web]$web = $clientContext.Web
            $clientContext.Load($web)
            $clientContext.ExecuteQuery()
            $site = $clientContext.Site
            $clientContext.Load($site)
            $clientContext.ExecuteQuery()
            #Updating Site Column
            $columnexists=$false
           foreach($siteColumn in $url.siteColumn)
           {
           Add-Content $logFilePath "`n Loading Site columns"
             $fields = $site.rootweb.Fields 
             $clientContext.Load($fields)
             $clientContext.ExecuteQuery()

                foreach($field in $fields) 
                { 
                
                if(($field.Title -eq $siteColumn.Name) -and ($columnexists -eq $false))
                {
                $columnexists =$True
                if($siteColumn.Required -eq "yes")
                {
                $field.Required = $True
                Add-Content $logFilePath "`n Setting required field to true for $($siteColumn.Name)  "
                }
                elseIf($siteColumn.Required -eq "No")
                {
                $field.Required = $False
                Add-Content $logFilePath "`n Setting required field to False for $($siteColumn.Name)"

                }

                $field.Update()
                $clientContext.ExecuteQuery() 
                }
                }
              
            } 
            if($columnexists -eq $false)
           {
           #write-Host "Field $($siteColumn.Name) does not exists"
           }
                #Updating Column of a list
                Add-Content $logFilePath "`n Loading list and its fields"
                $fieldExists=$false
         foreach($list in $url.List)
            {
                 $Getlist = $clientContext.Web.Lists.GetByTitle($list.Name)
                 $clientContext.Load($Getlist)
                 $fields = $Getlist.Fields
         
                 $clientContext.Load($fields)
                 $clientContext.ExecuteQuery()
                 foreach($field in $fields) 
                { 
  
                if($field.Title -eq $list.Field.Name -and ($fieldExists -eq $false))
                {
                $fieldExists=$True
                if($list.Field.Required -eq "Yes")
                {
                $field.Required = $True
                Add-Content $logFilePath "`n Setting required field to True for $($list.Field.Name)"
                }
                elseIf($list.Field.Required -eq "No")
                {
                $field.Required = $False
                Add-Content $logFilePath "`n Setting required field to False for $($list.Field.Name)"

                }

                $field.Update()
                $clientContext.ExecuteQuery() 
                }
           }
           if($fieldExists -eq $false)
           {
           #write-Host "Field $($list.Field.Name) does not exists"
           Add-Content $logFilePath "`n Field $($list.Field.Name) does not exists"
           }
         }
 
        }
    catch
        {
        $ErrorMessage = $_.Exception.Message
        #write-Host $_.Exception.Message
        Add-Content $logFilePath "`n  $_.Exception.Message"
        #Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
        }

}
 


