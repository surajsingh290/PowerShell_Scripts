param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:  SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
	Add-Content $logFilePath "`n XML file loaded successfully"
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}


Function Main()
{
try
{
	foreach($siteName in $ConfigFile.Settings.Search.siteUrl)
	{
		$siteUrl = $siteName.attributes['Url'].value
		$type = $siteName.attributes['Type'].value

		$SPWeb = Get-SPWeb $siteUrl -AssignmentCollection $spAssignment
		$pweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($SPWeb)
		$site = new-object Microsoft.SharePoint.Publishing.PublishingSite($siteUrl)
		if($type -eq "Edit")
		{
			$pageName= $ConfigFile.Settings.Search.PageName
			$pageLayoutNameNew = $siteName.pageLayout
			ChangeLayout $siteName $pageName $pageLayoutNameNew $site $siteUrl
		}
		elseif($type -eq "New")
		{
			#$pageName= $siteName.pageTitle
			$pageName= $ConfigFile.Settings.Search.PageName

			$pageLayoutNameNew = $siteName.pageLayout
			CreateSearchPage $siteName $pageName $pageLayoutNameNew $site $siteUrl $pweb
			AddLinks $siteName $site
		}
		
	
	}
	}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}
}

Function AddLinks($siteName, $site)
{
try
{
	##Write-Host "Adding search nav links to $siteUrl"
	$spweb = Get-SPweb $siteUrl
	foreach($Link in $siteName.NavigationLink)
	{
		$navs = $spweb.Navigation.SearchNav
		$flag = $null
		##Write-Host $navs
		##Write-Host "Searching for navigation exist!" $spweb
   		foreach ($nav in $navs.nodes)
   		{
			##Write-Host $_.title
			if($nav.Name -eq $Link.LinkName)
			{
				$flag=$true
				break;
			}
		}
		if($flag -eq $null)
		{
			$node = new-object  -TypeName "Microsoft.SharePoint.Navigation.SPNavigationNode"  -ArgumentList $Link.title, $Link.Url, $false
			##Write-Host "Creating new navigation link $node"
 			$spweb.Navigation.SearchNav.AddAsLast($node)
			##Write-Host "navigation link $Link.LinkName added"
			Add-Content $logFilePath "`n Navigation Link Added." 
		}
	}
	catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

}

Function CreateSearchPage($siteName, $pageName, $pageLayoutNameNew, $site, $url, $pweb)
{
try
{
	$pageLayoutNew = $null
	##Write-Host "Checking if new page layouts exist in the site..."
			Add-Content $logFilePath "`n Checking if new page layouts exist in the site..." 

	$pageLayouts = $site.GetPageLayouts($true);

	# Check if the new pagelayout exists in this site collection
	$pageLayouts | ForEach-Object {
		if ($_.Title -match $pageLayoutNameNew)
		{
				##Write-Host "Found NEW page layout: " $pageLayoutNameNew
				Add-Content $logFilePath "`n Found New page layout..." 
				$pageLayoutNew = $_;
        	}
	}    
	if($pageLayoutNew -ne $null)
	{
		$pages = $pweb.GetPublishingPages($pweb)
		#create a page based on a layout like this
		$PageTitle = $pageName.replace(".aspx","")
		Add-Content $logFilePath "`n Page Title: $($PageTitle)" 
		
		$page = $pages.Add($pageName , $pageLayoutNew)
		$page.Title = $PageTitle; 
		$page.Update();

		#check in & publish your page.
		if ($page -ne $null)
		{
    			$page.ListItem.File.CheckIn("")
    			$page.ListItem.File.Publish("")
    			#$page.ListItem.File.Approve("")
			#Check in and Publish the page  
			if($page.ParentList.EnableMinorVersions -eq $true)
        		{
              			$Page.listitem.File.Publish("Published");
				$page.ListItem.File.Approve("Approved")
	        	}
		}
		$page.ListItem.File.CheckOut();
		# Get the webpartmanager
		$webpartmanager = $page.listitem.Web.GetLimitedWebPartManager($page.Url,[System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared);
 		
		#Iterate through webparts in webpartmanager class  
  		for($i=0;$i -lt $webpartmanager.WebParts.Count;$i++)  
		{   
   			foreach($wpart in $siteName.webpart)
			{
 				#Check for the name of required web part   
  				if($webpartmanager.WebParts[$i].title -eq $wpart.attributes['Name'].value)   
  				{    
   					##Write-Host "***"
     					#Get reference to the web part  
     					$wp=$webpartmanager.WebParts[$i];  
       					$wp.TryInplaceQuery = 0 
    					$wp.ResultsPageAddress = $wpart.SearchPageUrl 
					    $wp.ShowNavigation = $false
    					$webpartmanager.SaveChanges($wp)
       					
     					break;   
   	
  				}   
			}
	 	}   
   	
  		#Check in and Publish the page  
  		$page.listitem.File.CheckIn("Relevant Articles")  
		if($page.ParentList.EnableMinorVersions -eq $true)
        	{
              	$Page.listitem.File.Publish("Published");
				$page.ListItem.File.Approve("Approved")
	        }

	}
	catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

}

Function ChangeLayout($siteName, $pageName, $pageLayoutNameNew, $site, $url)
{
try
{
	#$site = new-object Microsoft.SharePoint.Publishing.PublishingSite($url)
	$pageLayoutNew = $null
	##Write-Host "Checking if new page layouts exist in the site..."
	$pageLayouts = $site.GetPageLayouts($true);

	# Check if the new pagelayout exists in this site collection
	$pageLayouts | ForEach-Object {
		##Write-Host $_.Title $pageLayoutNameNew
		if ($_.Title -match $pageLayoutNameNew)
		{
            		##Write-Host "Found NEW page layout: " $pageLayoutNameNew
            		$pageLayoutNew = $_;
        	}
	}    
	if( $pageLayoutNew -ne $null)
	{
		#Check if this is a publishing web
		$web = Get-SPWeb $url
		$comment = "commented by powershell"
		$page =$null
		$web.AllowUnsafeUpdates = "true";

    		if ([Microsoft.SharePoint.Publishing.PublishingWeb]::IsPublishingWeb($web) -eq $true)
    		{
      			$pubweb = [Microsoft.SharePoint.Publishing.PublishingWeb]::GetPublishingWeb($web);
      			$pubcollection=$pubweb.GetPublishingPages()
      			#Go through all pages checking for pages with the "current" page layout
      			for($i=0; $i -lt $pubcollection.count; $i++)
      			{
        			if($pubcollection[$i].name -eq $pageName)
        			{
					$page = $pubcollection[$i]
    					##Write-Host "Updating the page:" $page.Name "to Page Layout:" $pageLayoutNew.Title
    					$page.CheckOut();
    					$page.Layout = $pageLayoutNew;
    					$page.ListItem.Update();
    					$page.CheckIn($comment);
    					if ($page.ListItem.ParentList.EnableModeration)
    					{
        					$page.ListItem.File.Approve("Publishing Page Layout correction");
    					}
        			}
      			}

			$page.ListItem.File.CheckOut();
			# Get the webpartmanager
			$webpartmanager = $page.listitem.Web.GetLimitedWebPartManager($page.Url,[System.Web.UI.WebControls.WebParts.PersonalizationScope]::Shared);
 	
			#Iterate through webparts in webpartmanager class  
  			for($i=0;$i -lt $webpartmanager.WebParts.Count;$i++)  
			{   
   				foreach($wpart in $siteName.webpart)
				{
 					#Check for the name of required web part   
  					if($webpartmanager.WebParts[$i].title -eq $wpart.attributes['Name'].value)   
  					{    
     						#Get reference to the web part  
     						$wp=$webpartmanager.WebParts[$i];  
       						##Write-Host $wp.ZoneId $wp.ZoneIndex
     						#Set the chrome property  
     						$wp.ChromeType="TitleOnly";

						$webpartmanager.MoveWebPart($wp, $wpart.attributes['Zone'].value, 1);
 
						#$wp.ZoneId = $wpart.attributes['Zone'].value
						
	   
     						#Save changes to webpartmanager. This step is necessary. Otherwise changes won't be reflected  
     						$webpartmanager.SaveChanges($wp);  
     						break;   
   	
  					}   
				}
	 		}   
   	
  			#Check in and Publish the page  
  			$page.CheckIn("Relevant Articles")  
			if($page.ParentList.EnableMinorVersions -eq $true)
        		{
              		$Page.listitem.File.Publish("Published");
					$page.ListItem.File.Approve("Approved")
	        	}
  			#$page..Publish("Relevant Articles")  
   	
  			# Update the SPWeb object  
  			$web.Update();  
			$web.AllowUnsafeUpdates = "false";

	    		$web.Close();
			#UpdateWebPartProperty($pubweb, $page)
	    	}
	}
	catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}

}


Main