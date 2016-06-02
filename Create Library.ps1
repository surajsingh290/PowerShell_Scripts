param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Library O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)

try
{
	$siteUrl = $ConfigFile.Settings.CreateLibrary.Sites.site.attributes['Url'].value
    #$siteUrl="https://infyakash.sharepoint.com/sites/ConfigNext-POC/"
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)

    Add-Content $logFilePath "`n Connected to SharePoint site: $($siteUrl)"
                
    [Microsoft.SharePoint.Client.Web]$web = $context.Web
    $context.Load($web)
       if ($credentials -eq $null) {            
    $credentials = Get-Credential
    }
    $context.Credentials = $credentials
    $context.ExecuteQuery();       
}
catch
{
       $ErrorMessage = $_.Exception.Message
    Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}

function CreateLibrary($siteUrl, $libraryName, $library, $libraryTemplate)
{
    try
    {
        #Create Library

        $context.Load($web.Lists)
        $context.ExecuteQuery()
        
        $list = $web.Lists | where{$_.Title -eq $libraryName}
            if(!$list)
            {
                $LibraryInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
                $LibraryInfo.Title = $libraryName
                $LibraryInfo.TemplateType = "101"
                $Library = $Context.Web.Lists.Add($LibraryInfo)
                $Library.Description = $libraryName
                $Library.Update()
                $Context.ExecuteQuery()
                
                $fieldXML = $ConfigFile.Settings.CreateLibrary.Sites.site.LibraryName.Template.InnerXml.ToString()
                $separator = [string[]]@("/>")
                
                $fieldXML.Split($separator, [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
                    $fldXML = [string[]]$_ + [string[]]@("/>")
                    $Library.Fields.AddFieldAsXml($fldXML,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
                    $Library.Update()
                    $Context.ExecuteQuery() 
                                  
                }
                Add-Content $logFilePath "`n Library Created Successfully"
            }
            else
            {
                Add-Content $logFilePath "`n List/Library with the same name already exist at $($siteUrl)"
            }
   }
   catch
   {
     $ErrorMessage = $_.Exception.Message        
     Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
   }     
    
}
  
    #loop to get all sitecollection
foreach ($site in $ConfigFile.Settings.CreateLibrary.Sites.site)
{
    try
    {
        $siteUrl=$site.attributes['Url'].value
              #$siteUrl="https://infyakash.sharepoint.com/sites/ConfigNext-POC/"
        
              foreach ($library in $site.LibraryName) 
            {
                $libraryName=$library.attributes['Name'].value
                Add-Content $logFilePath "`n List Name ::::: $($libraryName)"
                           $libraryTemplate=$library.attributes['LibraryTemplate'].value
                
                CreateLibrary $siteUrl $libraryName $library $libraryTemplate            
            }
     }
     catch
     {
        $ErrorMessage = $_.Exception.Message
        Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
     }
}
