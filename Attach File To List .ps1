param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Attach File To List CSOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

$UserName= $ConfigFile.Settings.Credentials.UserName
$Password= $ConfigFile.Settings.Credentials.Password
$DomainName= $ConfigFile.Settings.Credentials.DomainName
$credentials = New-Object System.Net.NetworkCredential($UserName, $Password, $DomainName)
 
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" ### 
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Begin Execution $(Get-Date -f dd_MM_yyyy_hhmmss) `n"
#Function attachFileToList
function AttachFileToList() {
 
     try
     {
        foreach($siteurl in $ConfigFile.Settings.AttachFileToList.SiteUrl)
           {
            # Connect to SharePoint Online and get ClientContext object.
            Add-Content $logFilePath "`n Connect to SharePoint Online and get ClientContext object"
            $url = $siteurl.Url
            $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url) 
            $clientContext.Credentials = $credentials 
            $web=$clientContext.Web
            $clientContext.Load($web.Lists)
            $clientContext.ExecuteQuery();
            # Get the list by title 
            Add-Content $logFilePath "`n Get the list by title "
            $listexists = $web.Lists | where{$_.Title -eq $siteurl.ListTitle.Title}
            if($listexists){
            $list=$clientContext.Web.Lists.GetByTitle($siteurl.ListTitle.Title)
            # Get the item by ID 
            Add-Content $logFilePath "`n Get the item by ID"
            $item=$list.GetItemById($siteurl.ListTitle.itemid); # Get all the attachments for the list item 
            $attachColl=$item.AttachmentFiles; 
            $clientContext.Load($attachColl)
            # Execute the query 
            $clientContext.ExecuteQuery();
            #new attachmentCreationinformation object
            $attCI = New-Object Microsoft.SharePoint.Client.AttachmentCreationInformation
            $attCI.FileName = $siteurl.ListTitle.AttachFileName
            if(Test-Path $siteurl.ListTitle.AttachFileUrl -pathType leaf)
            {
            $fileContent = [System.IO.File]::ReadAllBytes($siteurl.ListTitle.AttachFileUrl);
            $memStream = New-Object System.IO.MemoryStream (, $fileContent)
            $attCI.contentStream = $memStream
            #adding file to list item
            Add-Content $logFilePath "`n adding file to list item"
            $item.AttachmentFiles.Add($attCI)
            $clientContext.Load($item)
            $clientContext.ExecuteQuery();
            }else
            {
             Add-Content $logFilePath "`n Path $($siteurl.ListTitle.AttachFileUrl) does not exists "
            }    
           
           }
           else
           {
           Add-Content $logFilePath "`n list $($siteurl.ListTitle.Title) does not exists "
           
           }
           }
      }
     catch
     {
        #Write-Host $_.Exception.Message
        $ErrorMessage = $_.Exception.Message
        Add-Content $logFilePath "`n Exception occured in Content Type Creation :::::: $($ErrorMessage)"
              
     }
                    
    }

### Calling the function
Add-Content $logFilePath "`n Calling the function AttachFileToList" 
AttachFileToList