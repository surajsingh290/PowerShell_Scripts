CLS

#============= Addition of the snapin to run the sharepoint 2013 commands ================================
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Publishing.dll"
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Taxonomy.dll"

# ============== XML Path ================================
$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

# ============== Log File Path ================================
$LogfilePath = $scriptPath+"\Logs.txt" 

Add-Content $LogfilePath "`n===================================================================="
Add-Content $LogfilePath "`n Beginning Execution : $(Get-Date -f dd_MM_yyyy_hhmmss)"

#================ Load the site ==========================
$siteUrl = "https://infyelc.sharepoint.com/sites/RedDotDev/TestLook/"

#================ Credentials ==========================
$password=convertto-securestring "Infy@1234" -asplaintext -force 
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials('Yogen@infyelc.onmicrosoft.com', $password)

#$Context = Get-SPOContext -Url $siteUrl -UserName $userName -Password $password

$Context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
[Microsoft.SharePoint.Client.Web]$Web = $context.Web
$context.Load($web)

if($credentials -eq $null) {
$credentials = Get-Credential
}
$context.Credentials = $credentials
$context.ExecuteQuery()        
$lib = $web.ServerRelativeUrl

$themeurl = "/sites/RedDotDev/_catalogs/theme/15/palette032.spcolor"

Write-Host $fontSchemeUrl

$fontSchemeUrl = Out-Null
$imageUrl = Out-Null

$web.ApplyTheme( $themeurl, $fontSchemeUrl, $imageUrl, $true)
$web.update()
$Context.Load($Web)
$Context.ExecuteQuery()