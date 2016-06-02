param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Quick Launch Management O365"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath


$location= "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI"
$UserName= $ConfigFile.Settings.O365Credentials.UserName
$password=convertto-securestring $ConfigFile.Settings.O365Credentials.Password -asplaintext -force
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $password)

Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"

  
try
{       
	$siteUrl = $ConfigFile.Settings.QuickLaunch.siteUrl                       
    #$siteUrl = "https://infyakash.sharepoint.com/sites/ConfigNext-POC/SubsiteNew/"
    $context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
    
    [Microsoft.SharePoint.Client.Web]$web = $context.Web
    $context.Load($web)
    if($credentials -eq $null) {
        $credentials = Get-Credential
    }
    $context.Credentials = $credentials
    
    $qlNav = $web.Navigation.QuickLaunch
    $context.Load($qlNav)
    
    $context.ExecuteQuery();
}
catch
{
	 $ErrorMessage = $_.Exception.Message        
     Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}

     Add-Content $logFilePath "`n Clearing old Quick Launch links"               
     for($i = $web.Navigation.QuickLaunch.Count-1; $i -gt -1;$i = $i-1)
     {
         $web.Navigation.QuickLaunch[$i].DeleteObject();					  
     }
     foreach ($heading in $ConfigFile.Settings.QuickLaunch.Navigation.Headings.Heading) 
     {      
		try
	    {                                        
            $nodeCreation = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
            $nodeCreation.Title = $heading.Title
            $nodeCreation.Url = $heading.Url
            $nodeCreation.AsLastNode = $true;
            $Info=$context.Web.Navigation.QuickLaunch.Add($nodeCreation)
            #Write-Host "Creating Node"
            $Info.Update()
            
            #$context.Load($qlNav);
            $context.ExecuteQuery();  
			Add-Content $logFilePath "`n QuickLaunch Node $($heading.Title) Created Successfully"  
	    }
	      catch
	    {
			$ErrorMessage = $_.Exception.Message        
		     Add-Content $logFilePath "`n Exception while creating Node $($_.Title) :::::: $($ErrorMessage)"
		}
    }
		 
