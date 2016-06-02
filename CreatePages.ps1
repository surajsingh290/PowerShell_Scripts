#----------------------------------------------------------------------------- 
# Filename : ELC.Origins.CreatePages.ps1 
#----------------------------------------------------------------------------- 
# Author : Infosys
#----------------------------------------------------------------------------- 
# Includes function to create pages from the input XML data

#Function to read the XMl and create site pages
function createPages([Microsoft.SharePoint.Client.Web] $web)
{
    WriteLog "------------------------------------------------------------------" "White"
    WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Page creation started..." "Green"
    WriteLog "------------------------------------------------------------------" "White"

     try
    {
        $lib = $web.ServerRelativeUrl

        #================ Create the pages ==========================
        foreach($Pages in $xmldata.WebSite.Pages.Page)
        {
            $Image = ""
            $HLinkEnd = ""
            $PageContent = ""
            $PageContentComplete = ""
            $ImageContent = ""

            $pageLayout = $xmldata.WebSite.Pages.Layout
           
	        $PageTitle = $Pages.Attributes['PageTitle'].Value
            $PageName = $Pages.Attributes['PageName'].Value
            if($Pages.Attributes['Image'].Value -ne "")
            {
                $Image = $lib + '/Documents/' + $Pages.Attributes['Image'].Value      
                #Write-Host $Image      
            }
            
	        WriteLog "Creating page: $($PageTitle)..." "Green"
	        try
            {
                #================ Load the Root Web ==========================
                $rootWeb = $clientContext.Site.RootWeb
                $clientContext.Load($rootWeb)
                $clientContext.ExecuteQuery()
        
                #================ Get the Page Layout ==========================
                $mpList = $rootWeb.Lists.GetByTitle('Master Page Gallery')
                $camlQuery = New-Object Microsoft.SharePoint.Client.CamlQuery
                $camlQuery.ViewXml = '<View><Query><Where><Eq><FieldRef Name="FileLeafRef" /> `
                                        <Value Type="Text">'+$pageLayout+'</Value></Eq></Where></Query></View>'
                $items = $mpList.GetItems($camlQuery)
                $clientContext.Load($items)    
                $clientContext.ExecuteQuery()
        
                #================ Get the Article Page Layout ==========================
                $articleLayoutItem = $items[0]
                $clientContext.Load($articleLayoutItem)    
                $clientContext.ExecuteQuery()
        
                #================ Get all the Pages ==========================
		        $pagesList = $web.Lists.GetByTitle('Pages')
                $clientContext.Load($pagesList)
                $clientContext.ExecuteQuery()

                $camlQuery2 = New-Object Microsoft.SharePoint.Client.CamlQuery
                $camlQuery2.ViewXml = '<View><Query><Where><Eq><FieldRef Name="Title" /> `
                                        <Value Type="Text">'+$PageName+'</Value></Eq></Where></Query></View>'
                $Pageitems = $pagesList.GetItems($camlQuery2)
                $clientContext.Load($Pageitems)    
                $clientContext.ExecuteQuery()

                #================ Check if page already exists and Skip page creation ==========================
                if($Pageitems.Count -gt 0)
                {
                    WriteLog "$($PageTitle) page already exists..." "Red"
                }

                #================ Create the new page ==========================
                else
                {
                    $pubWeb = [Microsoft.SharePoint.Client.Publishing.PublishingWeb]::GetPublishingWeb($clientContext, $web)		
                    $clientContext.Load($pubWeb)
                    $clientContext.ExecuteQuery()
                    $pubPageInfo = New-Object Microsoft.SharePoint.Client.Publishing.PublishingPageInformation
                    $pubPageInfo.Name = $PageName.Replace(" ", "-") + ".aspx"  
                    $pubPageInfo.PageLayoutListItem = $articleLayoutItem

                    $pubPage = $pubWeb.AddPublishingpage($pubPageInfo)
                    $pubPage.ListItem.File.CheckIn("", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)
                    $pubPage.ListItem.File.Publish("")
                    $clientContext.Load($pubPage)
                    $clientContext.ExecuteQuery()
		    		
                   
    
                    $listItem = $pubPage.get_listItem()
                    $clientContext.Load($listItem)
                    $clientContext.ExecuteQuery()

                    $file = $listItem.File
                    $file.CheckOut()
                    $clientContext.Load($file)
                    $clientContext.ExecuteQuery()

                    #================ Creating the hyperlinks in the pages ==========================

                    if($Image -eq "")
                    {
                        $PageHead = '<tr>
                                        <td style="width:280px;padding-left:5px;padding-top:5px;">
                                            <table border="0" width="auto" style="border-collapse: collapse; border-width: 0" cellpadding="3" cellspacing="3">
                                                <tbody>'
                        $HLinkEnd = '</tbody></table></td></tr>'

                        foreach($HLink in $Pages.HLink)
                        {
                            if($HLink.Attributes['Type'].Value -eq "Document")
                            {
                                $href = $lib + '/Documents/' + $HLink.Attributes['href'].Value
                            }
                            elseif($HLink.Attributes['Type'].Value -eq "Page")
                            {
                                $href = $lib + '/Pages/' + $HLink.Attributes['href'].Value
                            }
                            elseif($HLink.Attributes['Type'].Value -eq "External")
                            {
                                $href = $HLink.Attributes['href'].Value
                            }
                            else
                            {
                                $href = $HLink.Attributes['href'].Value
                            }
                            $HLinkText = $HLink.Attributes['label'].Value.ToString()

                            if ($HLinkText -like "*.*.*") 
                            {

                                $PageContent = $PageContent + '<tr>
                                                                <td>
                                                                    <img border="0" src="' + $lib +'/Documents/dot.jpg" width="10" height="10">
                                                                    <em>' + $HLinkText.SubString(0,10) + '</em>&nbsp;
                                                                    <b><a style="color: #333;" href="' + $href + '">' + $HLinkText.SubString(10) + '</a></b></br></br></td></tr>'
                            }
                            else
                            {
                                $PageContent = $PageContent + '<tr>
                                                                <td>
                                                                    <img border="0" src="' + $lib +'/Documents/dot.jpg" width="10" height="10">
                                                                    <b><a style="color: #333;" href="' + $href + '">' + $HLinkText + '</a></b></br></br></td></tr>'
                            }
                        }
                        $PageContentComplete = $PageHead + $PageContent + $HLinkEnd
                
                    }
                    else
                    {
                        $PageHead = '<div id="center" valign="top" style="background-color:#ffffff;width:798px;">
	                                    <!-- Body Content -->
	                                    <table width="auto" border="0">
                                        <tbody><tr>'
                        $ImageContent = '<td valign="top">
			                                <img src="' + $Image + '" border="0" width="auto" height="auto" />
                                            </td>'
                        $HLinkStart = '<td width="auto" valign="top">'
                        $HLinkEnd = '</td></tr></tbody></table></div>'

                        foreach($HLink in $Pages.HLink)
                        {
                            if($HLink.Attributes['Type'].Value -eq "Document")
                            {
                                $href = $lib + '/Documents/' + $HLink.Attributes['href'].Value
                            }
                            elseif($HLink.Attributes['Type'].Value -eq "Page")
                            {
                                $href = $lib + '/Pages/' + $HLink.Attributes['href'].Value
                            }
                            elseif($HLink.Attributes['Type'].Value -eq "External")
                            {
                                $href = $HLink.Attributes['href'].Value
                            }
                            else
                            {
                                $href = $HLink.Attributes['href'].Value
                            }
                            $HLinkText = $HLink.Attributes['label'].Value.ToString()

                            if ($HLinkText -like "*.*.*") 
                            {
                                $PageContent = $PageContent + '<table width="auto" border="0" cellpadding="0" cellspacing="0">
                                                                <tbody>
                                                                <tr>
                                                                    <td width="400px" colspan="1">
                                                                    <img border="0" src="' + $lib +'/Documents/dot.jpg" width="10" height="10" />
                                                                    <em>' + $HLinkText.SubString(0,10) + '</em>&nbsp;
                                                                        <b><a style="color: #333;" 
                                                                        href="' + $href + '">' + $HLinkText.SubString(10) + '</a></b></br></br></td></tr></tbody></table>'
                            }
                            else
                            {
                                $PageContent = $PageContent + '<table width="auto" border="0" cellpadding="0" cellspacing="0">
                                                                <tbody>
                                                                <tr>
                                                                    <td width="400px" colspan="1">
                                                                        <a style="color: #333;" 
                                                                        href="' + $href + '">' + $HLinkText + '</a></br></br></td></tr></tbody></table>'
                            }
                        }
                        $PageContentComplete = $PageHead + $HLinkStart + $PageContent + $ImageContent + $HLinkEnd
                    }
            
                    #Write-Host $PageContent          
                    $listItem.Set_Item("PublishingPageContent", $PageContentComplete)	

                    $listItem.Set_Item("Title", $PageTitle)
                    $listItem.Update()
                    $listItem.File.CheckIn("", [Microsoft.SharePoint.Client.CheckinType]::MajorCheckIn)
                    $listItem.File.Publish("")   
                    $clientContext.Load($listItem)
                    $clientContext.ExecuteQuery()
                    
                     WriteLog "Success: $($PageTitle)" "Green"			        
                }
            }
	        catch
	        {
		        $ErrorMessage = $_.Exception.Message
               WriteLog "Exception occured in Creating page : $($ErrorMessage)" "red"
	        } 
        }
       
    }
    catch
    {
       WriteLog "Exception Occured in Create Pages $($_.Exception.Message)" "Red"
    }

    WriteLog "------------------------------------------------------------------" "White"
    WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Page creation completed..." "Green"
    WriteLog "------------------------------------------------------------------" "White"
}