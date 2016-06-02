param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Publishing Page O365"
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

        try
        {
            $ConfigFile = [xml](get-content $xmlFilePath)
            $siteUrl = $ConfigFile.Settings.csom_CreatePublishingPage.site.Attributes['Url'].Value
            #$siteUrl ="https://infyakash.sharepoint.com/sites/ConfigNextPubSite/"
			 Add-Content $logFilePath "`n  Site Url::::: $($siteUrl)" 
            $context = New-Object Microsoft.SharePoint.Client.ClientContext($siteUrl)

            [Microsoft.SharePoint.Client.Web]$web = $context.Web
            $context.Load($web)            
            $context.Credentials = $credentials
            $context.ExecuteQuery();
        
        }
        catch 
        {
            $ErrorMessage = $_.Exception.Message
            Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)"             
        }

        
       
    function Main()
    {
	    Add-Content $logFilePath "`n Inside Main Program"
	    try
	    {
		    foreach($siteName in $ConfigFile.Settings.csom_CreatePublishingPage.site)
		    {
    		    $siteUrl = $siteName.attributes['Url'].value
		        #Write-Host $siteUrl
			
                $nweb = $context.Web
                $context.Load($nweb)
                $context.ExecuteQuery()

                $pageLayout = $siteName.pageLayout
			    $PageTitle = $siteName.PageTitle

			    CreatePage $siteUrl $pageLayout $PageTitle 
           
			    foreach($wp in $siteName.Webparts.Webpart)
			    {
                    $ListName= $wp.List
                    $WebPartPath= $wp.Path
                    $ServerRelativeUrl = $wp.ServerRelativeUrl
                    $ZoneId= $wp.ZoneId
                    $ZoneIndex= $wp.ZoneIndex
                    $PageName=$wp.PageName   
				    AddWebpart $web $ListName $WebPartPath $PageName $ServerRelativeUrl $ZoneId $ZoneIndex	
    		    }
	    }
    }
	    catch
	    {
		Add-Content $logFilePath "`Exception Occured in Create Page"
		Add-Content $logFilePath $_.Exception.Message
	    }
	    finally
	    {
    		    if($Web -ne $null)
    		    {
        		    #$Web.Dispose()
    		    }
 
	    }
        }

Function CreatePage($siteUrl, $pageLayout, $PageTitle)
{
    Add-Content $logFilePath "`n Creatingpage $($PageTitle) with pagelayout $($pageLayout)"
    #Write-Host "Inside Create Page"
	try
    {
        $rootWeb = $context.Site.RootWeb
        $context.Load($rootWeb)
        $context.ExecuteQuery()
    
        $mpList = $rootWeb.Lists.GetByTitle('Master Page Gallery')
        $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery.ViewXml = '<View><Query><Where><Eq><FieldRef Name="FileLeafRef" /> `
                              <Value Type="Text">'+$pageLayout+'</Value></Eq></Where></Query></View>'
        $items = $mpList.GetItems($camlQuery)
        $context.Load($items)    
        $context.ExecuteQuery()

		Add-Content $logFilePath "Items Loaded"
    
        $articleLayoutItem = $items[0]
        $context.Load($articleLayoutItem)    
        $context.ExecuteQuery()     
		Add-Content $logFilePath "articleLayoutItem loaded"	 

               
		$pagesList = $web.Lists.GetByTitle('Pages')
        $context.Load($pagesList)
        $context.ExecuteQuery()

        $camlQuery2 = New-Object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery2.ViewXml = '<View><Query><Where><Eq><FieldRef Name="Title" /> `
                              <Value Type="Text">'+$PageTitle+'</Value></Eq></Where></Query></View>'
        $Pageitems = $pagesList.GetItems($camlQuery2)
        $context.Load($Pageitems)    
        $context.ExecuteQuery()

        if($Pageitems.Count -gt 0)
        {
            Add-Content $logFilePath "`n Page with same name already exist `n Skipping page Creation......."
        }
        else
        {
            $pubWeb = [Microsoft.SharePoint.Client.Publishing.PublishingWeb]::GetPublishingWeb($context, $web)		
            $context.Load($pubWeb)
            $context.ExecuteQuery()
             
            $title =$PageTitle
            $pubPageInfo = New-Object Microsoft.SharePoint.Client.Publishing.PublishingPageInformation
            $pubPageInfo.Name = $title.Replace(" ", "-") + ".aspx"  
            $pubPageInfo.PageLayoutListItem = $articleLayoutItem

            $pubPage = $pubWeb.AddPublishingpage($pubPageInfo)
            $pubPage.ListItem.File.CheckIn("", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)
            $pubPage.ListItem.File.Publish("")
            $context.Load($pubPage)
            $context.ExecuteQuery()
		    		
            Add-Content $logFilePath "`nPage Ceated: $($title)" 
    
            $listItem = $pubPage.get_listItem()
            $context.Load($listItem)
            $context.ExecuteQuery()

            $file = $listItem.File
            $file.CheckOut()
            $context.Load($file)
            $context.ExecuteQuery()
			Add-Content $logFilePath "'n Page Checked Out'"
            $listItem.Set_Item("Title", $title)
            $listItem.Update()

            $listItem.File.CheckIn("", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)

            $listItem.File.Publish("")       

            $context.Load($listItem)

            $context.ExecuteQuery()
			Add-Content $logFilePath "`n Page Checked In and published"
        }
    }
	catch
	{
		$ErrorMessage = $_.Exception.Message
        Write-Host $ErrorMessage
        Add-Content $logFilePath "`n Exception occured in Creating page :::::: $($ErrorMessage)"
	}
}

    function AddWebpart([Microsoft.SharePoint.Client.Web] $web,$ListName, $WebPartPath, $PageName, $ServerRelativeUrl, $ZoneId, $ZoneIndex)
    {
	try	{
	    Add-Content $logFilePath "`n Inside AddWebPart"
        $pubWeb =[Microsoft.SharePoint.Client.Publishing.PublishingWeb]::GetPublishingWeb($context,$web)

        $context.Load($pubWeb)

        $pagesList = $web.Lists.GetByTitle($ListName)

        $path=$WebPartPath

        $filePath = $("$dp0\$path")
    	Add-Content $logFilePath "`n File Path $($filePath)"
        #Write-Host $filePath
        $webpartdata = [xml](Get-Content($filePath))
        $wpxml=$webpartdata.OuterXml
        $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
        $camlQuery.ViewXml = '<View><Query><Where><Eq><FieldRef Name="FileLeafRef" /> `
                              <Value Type="Text">'+$PageName +'</Value></Eq></Where></Query></View>' 

        $items = $pagesList.GetItems($camlQuery) 
        $context.Load($items)
        $context.ExecuteQuery()

		Add-Content $logFilePath "`n Page Loaded in AddWebPart"
        if($items.Count -gt 0)
        {
            $listItem = $items[0]
            $context.Load($listItem)
            $context.ExecuteQuery()
            try
            {
                $file = $listItem.File
                $file.CheckOut()
                $context.Load($file)

                $context.ExecuteQuery()
		        Add-Content $logFilePath "`n Checked Out for editing"

                $WPManager =$web.GetFileByServerRelativeUrl($ServerRelativeUrl).GetLimitedWebPartManager("Shared")
                $wpd = $WPManager.ImportWebPart($wpxml)		
                $file =$web.GetFileByServerRelativeUrl($ServerRelativeUrl).GetLimitedWebPartManager("Shared").AddWebPart($wpd.WebPart,$ZoneId,$ZoneIndex)
                $listItem.Update()
		        Add-Content $logFilePath "`n ListItem Updated"
                $context.Load($listItem)
                $context.ExecuteQuery()

		        Add-Content $logFilePath "`n Added desired web Part and checked in the page"
            }
            catch
            {
		        $ErrorMessage = $_.Exception.Message
                Add-Content $logFilePath "`n Exception occured in Adding Web Part :::::: $($ErrorMessage)"
		    }
            finally
            {
                $listItem.File.CheckIn("", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)    
                $listItem.File.Publish("")       
                $context.Load($listItem)
                $context.ExecuteQuery()
            }
        }
        else
        {
            Add-Content $logFilePath "`n Page does not exist."
        }
		}
		catch
		{
		$ErrorMessage = $_.Exception.Message
        Add-Content $logFilePath "`n Exception occured in Adding Web Part :::::: $($ErrorMessage)"
		}
    }

Main