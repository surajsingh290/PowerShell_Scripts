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
    #Write-Host $FieldName
    $siteUrl = $ConfigFile.Settings.CreateList.Sites.site.attributes['Url'].value
	Write-Host "Site Url: " $siteUrl

    $context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)
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
$lists=$context.Web.Lists;
$context.Load($lists);
if($credentials -eq $null) {
 $credentials = Get-Credential
}
$context.Credentials = $credentials
$context.ExecuteQuery();
#Get web title
Write-Host "Web Title: " $web.Title


#Method To Create List 
function CreateList($siteUrl, $listName, $list, $listTemplate)
{
	try
	{
#Create List
$ListInfo = New-Object Microsoft.SharePoint.Client.ListCreationInformation
$ListInfo.Title = $listName
$ListInfo.TemplateType = "100"
$List = $Context.Web.Lists.Add($ListInfo)
$List.Description = $listName
$List.Update()
$Context.ExecuteQuery()

$fieldXML = $ConfigFile.Settings.CreateList.Sites.site.ListName.Template.InnerXml.ToString()
$separator = [string[]]@("/>")
$fieldXML.Split($separator, [System.StringSplitOptions]::RemoveEmptyEntries) | ForEach {
$fldXML = [string[]]$_ + [string[]]@("/>")
$List.Fields.AddFieldAsXml($fldXML,$true,[Microsoft.SharePoint.Client.AddFieldOptions]::AddFieldToDefaultView)
$List.Update()
$Context.ExecuteQuery()        	 
        }
        }
        catch
        {
        		$ErrorMessage = $_.Exception.Message        
        		#Add-Content D:\ErrorFile\Output.txt "`n Exception :::::: $($ErrorMessage)"
                Write-Host "Exception Occured : " $ErrorMessage
        }	

}




$count =0

#loop to get all sitecollection
foreach ($site in $ConfigFile.Settings.CreateList.Sites.site)
{
	$siteUrl=$site.attributes['Url'].value
    Write-Host "URL of the Site: " $siteUrl

    #loop to get all lists      
    foreach ($list in $site.ListName) 
    {
        $listName=$list.attributes['Name'].value
        Write-Host "ListName of the Site: " $listName
	    #Add-Content D:\ErrorFile\Output.txt "`n List Name ::::: $($list.attributes['Name'].value)"

        $listTemplate=$list.attributes['ListTemplate'].value
        Write-Host "List Template of the Site: " $listTemplate
        #Add-Content D:\ErrorFile\Output.txt "`ncalling Method to create lists"           
        
        CreateList $siteUrl $listName $list $listTemplate

    }

}