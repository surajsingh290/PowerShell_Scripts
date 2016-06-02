param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Add Content Type To Page Library O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

$location= "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)


function AddContentTypes ($siteUrl,$ContentTypes,$credentials)
{
    foreach ($ContenType in $ContentTypes.ContentType) 
    {
         try
         {
            $ContentTypeExist=$false
            $contebtTypeAlreadyPresent = $false
            $clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
            Add-Content $logFilePath "`n  adding $($ContenType) to $($siteUrl)"
       
            $clientContext.Credentials = $credentials
            $site = $clientContext.Site;
            $web = $site.RootWeb; 
            $clientContext.Load($web) ;
            $clientContext.Load($site);
            $ContentTypes = $web.ContentTypes
            $clientContext.Load($ContentTypes)
            $clientContext.ExecuteQuery()
            foreach ($ct in  $ContentTypes)
            {
                if($ct.Name -eq $ContenType)
                {
                    $ContentTypeExist = $true
                    Add-Content $logFilePath "`n  $($ContenType) is defined as a content type in $($web.Url)"
                    
                    $list = $web.Lists.GetByTitle("Pages")
                    $clientContext.Load($list)

                    $cts = $list.ContentTypes
                    $clientContext.Load($cts)
                    $clientContext.ExecuteQuery()
                    foreach ($ctType in  $cts)
                    {
                        if($ctType.Name -eq $ContenType)
                        {
                            $contebtTypeAlreadyPresent = $true
                            Add-Content $logFilePath "`n Content type $($ContenType) is already present in Library"
                            break;

                        }
                    }
                    if($contebtTypeAlreadyPresent -eq $false)
                    {
                        $list.ContentTypesEnabled=$true
                        $AddedContentType=$cts.AddExistingContentType($ct)
                        $list.Update()
                        Add-Content $logFilePath "`n Content type $($ContenType) Added to library"
                    }                   
                    
                        $clientContext.ExecuteQuery()                    
                   
                }

             }        
            if($ContentTypeExist -eq $false)
            {
                 Add-Content $logFilePath "`n Skipped adding Content Type to lIbrary as content type $($ContenType) does not exist "
            }

        }
        catch
        {
           $ErrorMessage = $_.Exception.Message
           Add-Content $logFilePath $ErrorMessage
        }

    }
}

    $siteUrl = $ConfigFile.Settings.AddContentTypesToPageLib.SiteUrl
    #$siteUrl = "https://infyakash.sharepoint.com/sites/ConfigNextPubSite/"
    $exists = (Get-SPWeb $siteUrl -ErrorAction SilentlyContinue) -ne $null

    $ContentTypes=$ConfigFile.Settings.AddContentTypesToPageLib.ContentTypes

    AddContentTypes $siteUrl $ContentTypes $credentials