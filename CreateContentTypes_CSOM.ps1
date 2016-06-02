#Get data from public Sharepoint Site using Client Object Model
# ================ Input parameters ==========================
$location= "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI"
$credentials = New-Object System.Net.NetworkCredential('Suraj_Singh05', 'ssingh@4','ITLINFOSYS')
# ============== End of Input ================================
#Defining Load method for context, not accessible in Powershell
$csharp2 = @"
using Microsoft.SharePoint.Client;
namespace SharepointComLoad
{
    public class PSClientContext: ClientContext
    {
        public PSClientContext(string siteUrl)
            : base(siteUrl)
        {
        }
        // need a plain Load method here, the base method is some
        // kind of dynamic method which isn't supported in PowerShell.
        public void Load(ClientObject objectToLoad)
        {
            base.Load(objectToLoad);
        }
    }
}
"@
$assemblies = @("$location\Microsoft.SharePoint.Client.dll",
    "$location\Microsoft.SharePoint.Client.Runtime.dll",
    "System.Core")
$ErrorActionPreference = "Stop"

# To run the SharePoint 2013 commandlets add the snapin
Set-ExecutionPolicy Unrestricted
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
    Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
}

$ConfigFileName = "ConsolidatedXML.xml" 
$xmlFilePath = "C:\Users\Suraj_Singh05\Documents\Visual Studio 2013\Projects\ExecutePowershell\ExecutePowershell\XMLFile\ConsolidatedXML.xml"

#Write-Host "XML Loaded..."


  
try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
    Write-Host "XML Loaded..."
	
	#$FieldName = $ConfigFile.Settings.CreateList.Sites.site.ListName.Template.Field.attributes['Name'].value
    Write-Host $FieldName
    $siteUrl = $ConfigFile.Settings.CreateList.Sites.site.attributes['Url'].value
	Write-Host "Site Url: " $siteUrl

    $context = New-Object SharepointComLoad.PSClientContext($siteUrl)
}
catch [System.Management.Automation.PSArgumentException]
{
	$ErrorMessage = $_.Exception.Message
	#Add-Content D:\ErrorFile\Output.txt "`n Exception Occured :::::: $($ErrorMessage)" 
    Write-Host "Error Occured : " $ErrorMessage

    Add-Type -TypeDefinition $csharp2 -ReferencedAssemblies $assemblies
    $context= New-Object SharepointComLoad.PSClientContext($siteUrl)
}

[Microsoft.SharePoint.Client.Web]$web = $context.Web
$context.Load($web)
if($credentials -eq $null) {
 $credentials = Get-Credential
}
$context.Credentials = $credentials
$context.ExecuteQuery();
#Get web title
Write-Host "Web Title: " $web.Title

function CreateContentType()
{
 $ctColl=$web.ContentTypes;
 # Get the parent content type - Item (0x01)
 $parentCT=$web.ContentTypes.GetById("0x010002A3DF0ECCFC9B42B6BAFD1C429F306B");
 # Specify the properties that are used as parameters to initialize a new contenttype
 $ctCreationInfo=New-Object Microsoft.SharePoint.Client.ContentTypeCreationInformation;
 $ctCreationInfo.Name="Test Content Types";
 $ctCreationInfo.Description="My custom content types created using Powershell";
 $ctCreationInfo.Group="Suraj Content Types";
 $ctCreationInfo.ParentContentType=$parentCT;
 # Add the new content type to the collection
 $ct=$ctColl.Add($ctCreationInfo);

 # Execute the query
 $context.ExecuteQuery();
}

### Calling the function
CreateContentType