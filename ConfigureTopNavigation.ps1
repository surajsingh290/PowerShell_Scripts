#----------------------------------------------------------------------------- 
# Filename : ELC.Origins.ConfigureTopNavigation.ps1 
#----------------------------------------------------------------------------- 
# Author : Infosys
#----------------------------------------------------------------------------- 
# Includes function to create Top Navigation menu



#Function to create top navigation
function ConfigureTopNavigation()
{
    WriteLog "------------------------------------------------------------------" "White"
    WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Started creating the top navigation." "Green" 
    WriteLog "------------------------------------------------------------------" "White"
    

    $web = $clientContext.Web   
    $clientContext.Load($web)   
    $clientContext.ExecuteQuery()
       
      foreach($nav in $xmldata.WebSite.globalnav.nav)
    {
        try
        {
            $Nodes = $web.Navigation.QuickLaunch	
            $clientContext.Load($Nodes)   
            $clientContext.ExecuteQuery()
        }
        catch 
        {
            $ErrorMessage = $_.Exception.Message
            WriteLog "Exception Occured : $($ErrorMessage)" "Red"             
        }

	    $NavigationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
	    $NavigationNode.Title = $nav.Title

        if($nav.TYPE -eq "Page")
        {
	        $NavigationNode.Url = "Pages/"+$nav.Url 
        }
        elseif($nav.TYPE -eq "Document")
        {
	        $NavigationNode.Url = "Documents/"+$nav.Url 
        }
        elseif($nav.TYPE -eq "External")
        {
	        $NavigationNode.Url = $nav.Url 
            $NavigationNode.IsExternal = $true
        }
        else
        {
            $NavigationNode.Url = $nav.Url 
        }
            
        try
        {       
	        $NavigationNode.AsLastNode = $true
	        $clientContext.Load($Nodes.Add($NavigationNode))
            $web.Update()
            $clientContext.ExecuteQuery()
            WriteLog "Success nav: $($nav.Title)" "green"
        }
        catch 
        {
            $ErrorMessage = $_.Exception.Message
            WriteLog "Exception Occured : $($ErrorMessage)" "Red"            
        }

        foreach($subnav in $nav.subnav)
        {
            try
            {
                $Nodes = $clientContext.Web.Navigation.QuickLaunch  
                $clientContext.Load($Nodes)   
                $clientContext.ExecuteQuery()
            }
            catch 
            {
                $ErrorMessage = $_.Exception.Message
                WriteLog "Exception Occured : $($ErrorMessage)" "Red"            
            }

            $node = $Nodes | Where-Object { $_.Title -eq $nav.Title }

            $ChildNavigationNode = New-Object Microsoft.SharePoint.Client.NavigationNodeCreationInformation
            $ChildNavigationNode.Title = $subnav.Title
            
            if($subnav.TYPE -eq "Page")
            {
	            $ChildNavigationNode.Url = "Pages/"+$subnav.Url 
            }
            
            elseif($subnav.TYPE -eq "Document")
            {
	            $ChildNavigationNode.Url = "Documents/"+$subnav.Url 
            }
            
            elseif($subnav.TYPE -eq "External")
            {
	            $ChildNavigationNode.Url = $subnav.Url 
                $ChildNavigationNode.IsExternal = $true
            }  
            else
            {
                $ChildNavigationNode.Url = $subnav.Url 
            }         
            
            $ChildNavigationNode.AsLastNode = $true
	          
             
            if($node.Count -gt 1)
            {
                
                $clientContext.Load($node[1].Children.Add($ChildNavigationNode))
            }
            else
            {
                    $clientContext.Load($node[0].Children.Add($ChildNavigationNode))
            }

            WriteLog "Succcess Subnav: $($subnav.Title)" "green"
        }
    }
        $web.Update()
        $clientContext.ExecuteQuery()

     
            WriteLog "------------------------------------------------------------------" "White"
            WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Completed creation of top navigation." "Green" 
            WriteLog "------------------------------------------------------------------" "White"

    
}