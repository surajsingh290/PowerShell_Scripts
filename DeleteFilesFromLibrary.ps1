function Get-SPOFolderFiles
{
param (
        [Parameter(Mandatory=$true,Position=1)]
		[string]$Username,
		[Parameter(Mandatory=$true,Position=2)]
		[string]$Url,
        [Parameter(Mandatory=$true,Position=3)]
		$password,
        [Parameter(Mandatory=$true,Position=4)]
		[string]$ListTitle,
        [Parameter(Mandatory=$true,Position=5)]
		[string]$CSVPath 
		)


    $ctx=New-Object Microsoft.SharePoint.Client.ClientContext($Url)
    $ctx.Credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($Username, $password)
    $ctx.Load($ctx.Web)
    $ctx.ExecuteQuery()
    $ll=$ctx.Web.Lists.GetByTitle($ListTitle)
    $ctx.Load($ll)
    $ctx.ExecuteQuery()
    $spqQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
    $spqQuery.ViewXml ="<View Scope='RecursiveAll' />";
    $itemki=$ll.GetItems($spqQuery)
    $ctx.Load($itemki)
    $ctx.ExecuteQuery()
    $count = $itemki.Count - 1

    foreach($item in $itemki)
    {
        $file = $ctx.Web.GetFileByServerRelativeUrl($item["FileRef"]);
        $ctx.Load($file)
        $ctx.ExecuteQuery()  
        $file.DeleteObject()
        $ctx.ExecuteQuery()
        Write-Host "File: "$file.Name "Deleted..." -BackgroundColor Green
    }    
}

#Paths to SDK
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll"  
Add-Type -Path "c:\Program Files\Common Files\microsoft shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll"  
 
#Enter the data
$AdminPassword=Read-Host -Prompt "Enter password" -AsSecureString
$username="suraj@infyelc.onmicrosoft.com"
$Url="https://infyelc.sharepoint.com/sites/RedDotDev/RedDot_Pub/"
$ListTitle="Documents"
$csvPath="D:\DeleteScript.csv"


Get-sPOFolderFiles -Username $username -Url $Url -password $AdminPassword -ListTitle $ListTitle -CSVPath $csvPath