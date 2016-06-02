	param ($path)

	$logFilePath =$("$path\LOGS\PowershellLogs.txt")

	#Add-Content $logFilePath "Path is $($path)"
	if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
	{
		Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
	}
	Add-Content $logFilePath "`n -----------------------------------"
	Add-Content $logFilePath "`n Script Name: Fetch Users And Groups CSOM"
	Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

	$xmlFilePath = $("$path\PSConfig.xml")
	[xml]$ConfigFile = Get-Content $xmlFilePath

	$UserName= $ConfigFile.Settings.Credentials.UserName
	$Password= $ConfigFile.Settings.Credentials.Password
	$DomainName= $ConfigFile.Settings.Credentials.DomainName
	$credentials = New-Object System.Net.NetworkCredential($UserName, $Password, $DomainName)
    #write-host "XML Loaded..." -ForegroundColor Green 
    #Adding the Client OM Assemblies  
    Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
    Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 
     
      #method to specify retrievals parameter for ClientRuntimeContext.Load<T> method 
   Function Invoke-LoadMethod() {
        param(
    [Microsoft.SharePoint.Client.ClientObject]$Object = $(throw "Please provide a Client Object"),
    [string]$PropertyName
              ) 
            $ctx = $Object.Context
            $load = [Microsoft.SharePoint.Client.ClientContext].GetMethod("Load") 
            $type = $Object.GetType()
            $clientLoad = $load.MakeGenericMethod($type) 


            $Parameter = [System.Linq.Expressions.Expression]::Parameter(($type), $type.Name)
            $Expression = [System.Linq.Expressions.Expression]::Lambda(
                     [System.Linq.Expressions.Expression]::Convert(
                         [System.Linq.Expressions.Expression]::PropertyOrField($Parameter,$PropertyName),
                         [System.Object]
                     ),
                     $($Parameter)
            )
            $ExpressionArray = [System.Array]::CreateInstance($Expression.GetType(), 1)
            $ExpressionArray.SetValue($Expression, 0)
            $clientLoad.Invoke($ctx,@($Object,$ExpressionArray))
          }
          # Method to fetch all user groups and libraries of a site
    function Get-SPAllSharePointUsersInGroups 
    { 
        param ($sSite) 
        try 
        {     
            #write-host "----------------------------------------------------------------------------"  -foregroundcolor Green 
            #write-host "Getting all Groups in a SharePoint Site" -foregroundcolor Green 
            #write-host "----------------------------------------------------------------------------"  -foregroundcolor Green 
      
                  
       
           #loading groups
            $spGroups=$sSite.RoleAssignments.Groups
            $spCtx.Load($spGroups) 
            $spCtx.ExecuteQuery()  
       

         
           
            $GroupCount=0; 
            Add-Content  $logFilePath " `n`n `r`n SITE URL--$($sSite.Url)"
            #write-host "fetching groups for $($sSite.Title)"
             Add-Content  $logFilePath "`n `n `r`n Displaying all the groups and permission levels for $($sSite.Title)"
             #fetching groups and corresponding permission levels     
                 $spCtx.Load($sSite.RoleAssignments)
                 $spCtx.ExecuteQuery()
          foreach($roleAssignment in $sSite.RoleAssignments)
                {

                 $spCtx.Load($roleAssignment.Member)
                 $spCtx.ExecuteQuery()
                 Add-Content  $logFilePath "`n `n `r`n  Group Name: $($roleAssignment.Member.Title)"
                 $spCtx.Load($roleAssignment.RoleDefinitionBindings)
                 $spCtx.ExecuteQuery()
                 #Add-Content  $logFilePath "`n `n `r`n bindings Name: $($roleAssignment.RoleDefinitionBindings)"
                 foreach($roleDefinition in $roleAssignment.RoleDefinitionBindings)
                {
                      $spCtx.Load($roleDefinition)
                      $spCtx.ExecuteQuery()
                      Add-Content  $logFilePath "`n `n `r Permission Name: $($roleDefinition.Name)" 
                }

               
                
                

               }
                #We need to iterate through the $spGroups Object in order to get individual Group information
               Add-Content  $logFilePath "`n `n `r`n Displaying all the groups and their users for $($sSite.Title)" 
            foreach($spGroup in $spGroups)
            {  
               $GroupCount=$GroupCount+1; 
                $spCtx.Load($spGroup) 
                $spCtx.ExecuteQuery() 
                Add-Content  $logFilePath "`n `n `r`n   Group$($GroupCount):$($spGroup.Title)" 
                $spSiteUsers=$spGroup.Users 
                $spCtx.Load($spSiteUsers) 
                $spCtx.ExecuteQuery()
                 
                 foreach ($user in $spSiteUsers) 
                {
                    Add-Content  $logFilePath "`n             User:   $($user.Title)"
                }
           }
                
            #write-host "fetching groups and users for $($sSite.Title) completed"
            $Lists = $sSite.Lists 
            $spCtx.Load($Lists) 
            $spCtx.ExecuteQuery() 

            #write-host "Fetching libraries of $($sSite.Title)" 
            Add-Content  $logFilePath " `n Document libraries of site $($sSite.Title) ....."   

          #Get Document Libraries having unique permissions
             $listunique=$false
          foreach($list in $Lists) 
           { 
             Invoke-LoadMethod -Object $list -PropertyName "HasUniqueRoleAssignments"
              $spCtx.ExecuteQuery()

             if( ($list.BaseType -eq "DocumentLibrary")  -and ($list.hasuniqueroleassignments  -eq "True"))
              {

               $listunique=$True
              Add-Content  $logFilePath "`n `n `r`n     $($list.Title) "
           
               $listroleassignments = $list.RoleAssignments
                  $spCtx.Load($listroleassignments)
                  $spCtx.ExecuteQuery()

               foreach($listroleassgnment in $listroleassignments)
                      {
                      $spCtx.Load($listroleassgnment.Member)
                      $spCtx.Load($listroleassgnment.RoleDefinitionBindings)
                      $spCtx.ExecuteQuery()

                    foreach($listroledefinition in $listroleassgnment.RoleDefinitionBindings)
                         {
                          $spCtx.Load($listroledefinition)
                          $spCtx.ExecuteQuery()
                          Add-Content  $logFilePath " $($listroleassgnment.Member.Title):$( $listroledefinition.Name)"
                        
                        
                         }
                  
                      } 
                   }
           
          }
          #write-host "Fetching libraries of $($sSite.Title) completed" 

        if($listunique -eq $false)
            {

            #write-host "Site has no libraries with unique permissions" 
            Add-Content  $logFilePath "`n `n `r`n  Site has no libraries with unique permissions"
           
             }
             }
    catch 
      { 
      #write-host $_.Exception.Message   
      }
    
    finally
    {
       $spCtx.Dispose() 
    }

 }
        
    #Fetching url of all the sites from XML
    foreach($sSiteColUrl in $ConfigFile.Settings.FetchGroups.SiteURL)
         { 
         try
           {
            #write-host "...."$sSiteColUrl
           
            $spCtx = New-Object Microsoft.SharePoint.Client.ClientContext($sSiteColUrl)              
            $spCtx.Credentials = $credentials
            
            #Root  Site 
            $spRootWebSite = $spCtx.Web
           
            $spCtx.Load($spRootWebSite) 
            $spCtx.ExecuteQuery() 
           
         
           #Call the method   Get-SPAllSharePointUsersInGroups to fetch the groups and list of the web
            Get-SPAllSharePointUsersInGroups -sSite $spRootWebSite 
              
            #Collecction of Sites under the Root Web Site 
            $sWebs = $spRootWebSite.Webs
            $spCtx.Load($sWebs) 
            $spCtx.ExecuteQuery() 
            #Call the method   Get-SPAllSharePointUsersInGroups to fetch the groups and list of the subsites
            foreach($web in $swebs)
                 
            { 
                Get-SPAllSharePointUsersInGroups -sSite $web 
            }

           }
           
          catch 
            { 
               #write-host $_.Exception.Message   
            } 
        
          }
                  

                  