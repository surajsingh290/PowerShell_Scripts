Add-PSSnapin Microsoft.SharePoint.Powershell     

#get the XML file     
#[System.Xml.XmlDocument] $XmlDoc = new-object System.Xml.XmlDocument     
$file = resolve-path(".\CreateSubsite.xml")     
if (!$file)     
{     
    Write-Host "Could not find the configuration file specified."     
    Break     
}     

[xml]$XmlDoc = Get-Content $file

#Get the site template code     
$SiteTemplate = $XmlDoc.input.SiteCollection.TemplateCode     
     
$siteCollectionUrl = $XmlDoc.input.SiteCollection.Url
   
# add solution     
Write-Host "Checking if site:: $siteCollectionUrl exist..."     

Write-Host "Now Creating Subsites.." 
$subSites = $XmlDoc.input.SiteCollection.SubSites     
foreach($subsiteNode in $subSites.Site) 
{
    $SubSiteName = $subsiteNode.Name

    $SubSiteUrl = $siteCollectionUrl+$subsiteNode.Url     

    Write-Host "Creating new subsite : $SubSiteUrl"     
    Write-Host "Creating Subsite..."   
    $NewSubSite = New-SPWeb -Url $SubSiteUrl -Template $SiteTemplate -Name $SubSiteName   
        
    Write-Host "Breaking Inheritance On A Subsite"     
    $NewSubSite.BreakRoleInheritance($true,$true)     
    $NewSubSite.Update()
            
    Write-Host "SubSite Created Successfully..!!"
} 