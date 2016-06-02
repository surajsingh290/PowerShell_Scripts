#----------------------------------------------------------------------------- 
# Filename : ELC.Origins.Migrator.ps1 
#----------------------------------------------------------------------------- 
# Author : Infosys
#----------------------------------------------------------------------------- 
# Includes CSOM and all necessary scripts

#Change the execution policy
Set-ExecutionPolicy Unrestricted

#Clear the console
cls

#Set the Root Directory
$0 = $MyInvocation.MyCommand.Definition
$dp0 = [System.IO.Path]::GetDirectoryName($0)

#For Logging 
$logText = "$(Get-Date -f dd_MM_yyyy_hhmmss): Migration Started..."
$logText > "OriginsMigrationLog.txt"
"===============================================================" >> 'OriginsMigrationLog.txt'

#Function to Create Log
function WriteLog([Parameter(Mandatory=$true)]$errorMessage, [Parameter(Mandatory=$true)]$Color )
{
    #Write to console
    Write-Host $errorMessage -foregroundcolor $Color 

    #Write to Log file
    $errorMessage >> "OriginsMigrationLog.txt"
}

#Load XML
try
{
    $xmlFilePath = $("$dp0\ELC.Origins.Config.xml")
    $xmldata = [xml](Get-Content($xmlFilePath));

    if (-not $xmldata) {

        WriteLog "Configuration data was not loaded successfully." "Red"	
        return
    }
    		
    WriteLog "Configuration data loaded successfully" "Green"
}
catch
{
    $ErrorMessage = $_.Exception.Message
    WriteLog "Error in loading Configuration XML Data : Error Message: $ErrorMessage" "Red"
    return     
}

#Load Assemblies

try
{
    Add-Type -Path $("$dp0\DLLS\Microsoft.SharePoint.Client.dll")
    Add-Type -Path $("$dp0\DLLS\Microsoft.SharePoint.Client.Runtime.dll")
    Add-Type -Path $("$dp0\DLLS\Microsoft.SharePoint.Client.Publishing.dll")
    Add-Type -Path $("$dp0\DLLS\Microsoft.SharePoint.Client.Taxonomy.dll")
}
catch
{
    $ErrorMessage = $_.Exception.Message
    WriteLog "Error in loading Assemblies : Error Message: $ErrorMessage" "Red"
    return     
        
}

#Importing the other Modules

try
{
    Import-Module "$dp0\ELC.Origins.CreatePages.ps1"
    Import-Module "$dp0\ELC.Origins.UploadFiles.ps1"
    Import-Module "$dp0\ELC.Origins.ConfigureTopNavigation.ps1"
    Import-Module "$dp0\ELC.Origins.ThemeAndMasterPage.ps1"
    Import-Module "$dp0\ELC.Origins.GroupsAndPermissions.ps1"
}
catch
{
     $ErrorMessage = $_.Exception.Message
     WriteLog "Error in importing Module : Error Message: $ErrorMessage" "Red"
     return
}

#Website URL
$url = $xmldata.WebSite.Url

#Read the user name 
$username = $xmldata.WebSite.UserName

#Prompt for password
$securePassword = Read-Host -Prompt "Please enter your password" -AsSecureString

$clientContext = New-Object Microsoft.SharePoint.Client.ClientContext($url)
$credentials = New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($username, $securePassword)
$clientContext.Credentials = $credentials
$clientContext.RequestTimeOut = 6000 * 60 * 10


#Try to connect to the website
if (!$clientContext.ServerObjectIsNull.Value)
{
    
    try
    {
       
        $web = $clientContext.Web   
        $clientContext.Load($web)   
        $clientContext.ExecuteQuery()
        
        WriteLog "Connected to SharePoint Online site: '$Url'" "green"
       
        WriteLog "--------------------------------------------------" "white"

        #Create pages
        createPages $web

        #Upload Required Files
        UploadFiles

        #Configure Top Navigation Menu
        ConfigureTopNavigation

        #Update Site Properties
        UpdateSiteProperties

        #Create Security groups and asign Permission
         foreach($group in $xmldata.WebSite.Groups.Group)
        {
            CreateSecurityGroup $group.Name $group.Permissions $group.Owner $clientContext
        }

        ApplyTheme
        $clientContext.Dispose()

        WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Migration Completed..." "Green"

    }
    catch
    {
        $ErrorMessage = $_.Exception.Message
         
        WriteLog "Not Connected to SharePoint Online site: $Url : Error Message: $ErrorMessage" "Red"
        $clientContext.Dispose()
        WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Migration Failed..." "Red"
        return
    }

  
  
}