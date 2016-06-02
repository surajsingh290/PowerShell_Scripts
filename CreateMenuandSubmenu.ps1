#============= Addition of the snapin to run the sharepoint 2013 commands ================================
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"


Function Get-SPOContext([string]$Url,[string]$UserName,[string]$Password)
{
   $context = New-Object Microsoft.SharePoint.Client.ClientContext($Url)
   $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
   $credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
   $context.Credentials = $credentials
   return $context
}


Function FindNavigationNodeByTitle([Microsoft.SharePoint.Client.NavigationNodeCollection]$Nodes,[string]$Title)
{
      $context = $Nodes.Context
      $context.Load($Nodes)
      $context.ExecuteQuery()
      $node = $Nodes | Where-Object { $_.Title -eq $Title }
      return $node
} 


Function AddNavigationNode([Microsoft.SharePoint.Client.NavigationNode]$ParentNode,[string]$Title,[string]$Url){
   $context = $ParentNode.Context
   $Node = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation 
   $Node.Title = $Title
   $Node.Url = $Url 
   $Node.AsLastNode = $true
   $context.Load($ParentNode.Children.Add($Node))
   $context.ExecuteQuery()
}


# ============== XML Path ================================
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$xmlFilePath = "$scriptPath\Navigation.xml"

# ============== Log File Path ================================
$LogfilePath = $scriptPath+"\Logs.txt" 

Add-Content $LogfilePath "`n===================================================================="
Add-Content $LogfilePath "`n Beginning Execution : $(Get-Date -f dd_MM_yyyy_hhmmss)"
Add-Content $LogfilePath "`n XML Path : $($xmlFilePath)"

#================ Get the XML Content ==========================
$ConfigFile = [xml](get-content $xmlFilePath)

#================ Load the site ==========================
$siteUrl = $ConfigFile.sites.site.Attributes['Url'].Value
#$tenantUrl = "https://infyelc.sharepoint.com/sites/RedDotDev/RedDot_Pub/"
#Credentials to connect to office 365 site collection url 
$username="Yogen@infyelc.onmicrosoft.com"
$password="Infy@1234"

$Context = Get-SPOContext -Url $siteUrl -UserName $userName -Password $password

foreach($sitenav in $ConfigFile.sites.site.globalnav.nav)
{
   # $Title = $sitenav.Attributes['Title'].Value.ToString()
    $Title=$sitenav.Title
    #$Url = $sitenav.Attributes['Url'].Value.ToString()
    $Url=$sitenav.Url
    $Nodes = $Context.Web.Navigation.QuickLaunch
	$NavigationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
	$NavigationNode.Title = $Title
	$NavigationNode.Url = $Url   
	$NavigationNode.AsLastNode = $True
	$Context.Load($Nodes.Add($NavigationNode))
    $Context.ExecuteQuery()
    foreach($sitesubnav in $sitenav.subnav)
    {
        $SubTitle=$sitesubnav.Title    
        $SubUrl=$sitesubnav.Url
        $NavBar = $Context.Web.Navigation.QuickLaunch 
        $Context.Load($NavBar)
        $Context.ExecuteQuery()
        $parentNode = FindNavigationNodeByTitle -Nodes $NavBar -Title $Title
        if($parentNode) {
           AddNavigationNode -ParentNode $parentNode -Title $SubTitle -Url $SubUrl
        }
    }
}

$Context.Dispose()