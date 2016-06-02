Add-Content D:\ErrorFile\CreateSSA.txt "`n -----------------------------------"
Add-Content D:\ErrorFile\CreateSSA.txt "`n Begin Execution $(Get-Date -f dd_MM_yyyy_hhmmss) `n"


$myDir="C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\ExecutePowershell\CSOM SCRIPTS"
$ConfigFileName = $myDir -replace "CSOM SCRIPTS","Resources\XML Data File\ConsolidatedXML.xml"
$xmlFilePath = $ConfigFileName

[xml]$ConfigFile = Get-Content $xmlFilePath
$parentDir = Split-Path -Parent $myDir

Set-ExecutionPolicy unrestricted
 
# Start Loading SharePoint Snap-in
$snapin = (Get-PSSnapin -name Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue)
if ($snapin -ne $null){
#write-host -f Green "SharePoint Snap-in is loaded... No Action taken"
Add-Content D:\ErrorFile\CreateSSA.txt "`n SharePoint Snap-in is loaded... No Action taken"
}
else  {
#write-host -f Yellow "SharePoint Snap-in not found... Loading now"
Add-Content D:\ErrorFile\CreateSSA.txt "`n SharePoint Snap-in not found... Loading now"
Add-PSSnapin Microsoft.SharePoint.PowerShell
#write-host -f Green "SharePoint Snap-in is now loaded"
Add-Content D:\ErrorFile\CreateSSA.txt "`n SharePoint Snap-in is now loaded"
}
# END Loading SharePoint Snapin

$pwd = $ConfigFile.Settings.CreateSSA.Password
# Settings 
$AppPoolName = $ConfigFile.Settings.CreateSSA.AppPoolName
$AppPoolAccount = $ConfigFile.Settings.CreateSSA.AppPoolAccount
$UserName = $ConfigFile.Settings.CreateSSA.UserName
$Password = ConvertTo-SecureString $pwd -AsPlainText -Force
$SearchServerName = (Get-ChildItem env:computername).value 
$SearchServiceName = $ConfigFile.Settings.CreateSSA.SearchServiceName
$SearchServiceProxyName = $ConfigFile.Settings.CreateSSA.SearchServiceProxyName
$DatabaseName = $ConfigFile.Settings.CreateSSA.DatabaseName

#Write-Host $AppPoolName "+" $AppPoolAccount "+" $UserName "+" $Password "+" $SearchServerName "+" $SearchServiceName "+" $SearchServiceProxyName "+" $DatabaseName


#Write-Host "Checking if Managed account exists"
Add-Content D:\ErrorFile\CreateSSA.txt "`n Checking if Managed account exists" 
$SPManagedAccount = Get-SPManagedAccount -Identity $AppPoolAccount -ErrorAction SilentlyContinue

if (!$SPManagedAccount) 
{ 
    #Write-Host "Creating SharePoint Managed Account" 
    Add-Content D:\ErrorFile\CreateSSA.txt "`n Creating SharePoint Managed Account" 
    $spManAccnt = New-SPManagedAccount -Identity $UserName,$password -AutoGeneratePassword false
}


#Write-Host "Checking if Search Application Pool exists" 
Add-Content D:\ErrorFile\CreateSSA.txt "`n Checking if Search Application Pool exists"
$SPAppPool = Get-SPServiceApplicationPool -Identity $AppPoolName -ErrorAction SilentlyContinue

if (!$SPAppPool) 
{ 
    #Write-Host "Creating Search Application Pool" 
    Add-Content D:\ErrorFile\CreateSSA.txt "`n Creating Search Application Pool"
    $spAppPool = New-SPServiceApplicationPool -Name $AppPoolName -Account $AppPoolAccount
}


# Start Services search service instance 
#Write-host "Start Search Service instances...."
Add-Content D:\ErrorFile\CreateSSA.txt "`n Start Search Service instances...." 
Start-SPEnterpriseSearchServiceInstance $SearchServerName -ErrorAction SilentlyContinue 
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $SearchServerName -ErrorAction SilentlyContinue

#Write-Host -ForegroundColor Yellow "Checking if Search Service Application exists" 
Add-Content D:\ErrorFile\CreateSSA.txt "`n Checking if Search Service Application exists"
$ServiceApplication = Get-SPEnterpriseSearchServiceApplication -Identity $SearchServiceName -ErrorAction SilentlyContinue

if (!$ServiceApplication) 
{ 
    #Write-Host -ForegroundColor Green "Creating Search Service Application" 
    Add-Content D:\ErrorFile\CreateSSA.txt "`n Creating Search Service Application"
    $ServiceApplication = New-SPEnterpriseSearchServiceApplication -Partitioned -Name $SearchServiceName -ApplicationPool $spAppPool.Name -DatabaseName $DatabaseName 
}

#Write-Host -ForegroundColor Yellow "Checking if Search Service Application Proxy exists" 
Add-Content D:\ErrorFile\CreateSSA.txt "`n Checking if Search Service Application Proxy exists"
$Proxy = Get-SPEnterpriseSearchServiceApplicationProxy -Identity $SearchServiceProxyName -ErrorAction SilentlyContinue

if (!$Proxy) 
{ 
    #Write-Host -ForegroundColor Green "Creating Search Service Application Proxy" 
    Add-Content D:\ErrorFile\CreateSSA.txt "`n Creating Search Service Application Proxy"
    New-SPEnterpriseSearchServiceApplicationProxy -Partitioned -Name $SearchServiceProxyName -SearchApplication $ServiceApplication 
}




