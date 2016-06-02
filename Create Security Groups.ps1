	param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Create Security Groups CSOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

	$UserName= $ConfigFile.Settings.Credentials.UserName
	$Password= $ConfigFile.Settings.Credentials.Password
	$DomainName= $ConfigFile.Settings.Credentials.DomainName
	$credentials = New-Object System.Net.NetworkCredential($UserName, $Password, $DomainName)	
    #Write-Host "XML Loaded..." -ForegroundColor Green 
    #Adding the Client OM Assemblies  
    Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.dll" 
    Add-Type -Path "C:\Program Files\Common Files\Microsoft Shared\Web Server Extensions\15\ISAPI\Microsoft.SharePoint.Client.Runtime.dll" 
    Add-Content $logFilePath "`n Starting script" 

 function Set-PermissionsOnList()
{
    begin{
        try
        {     
      foreach($sitecol in  $ConfigFile.Settings.CreateGroups.sitecollection1)
      {
         Add-Content $logFilePath "`n Getting Context for $($sitecol.url)"
        foreach($doclibrary in $sitecol.doclib)
        {
          
            Add-Content $logFilePath "`n Creating Groups for $($doclibrary.name)"
            $context = New-Object Microsoft.SharePoint.Client.ClientContext($sitecol.url)
            $spCredentials = New-Object System.Net.NetworkCredential($sUserName,$sPassword,$sDomain)  
            $context.Credentials = $spCredentials
            $web = $context.Web 
            $context.Load($web) 
            $context.ExecuteQuery()
            #fetching site collection groups
            $SiteGroups=$web.SiteGroups
            $context.Load($SiteGroups) 
            $context.ExecuteQuery()
            #Break inheritance for the document library
            $List = $context.Web.Lists.GetByTitle($doclibrary.name)
            $context.Load($List)
            $context.ExecuteQuery()

            $list.BreakRoleInheritance($true, $false)
           
            
            Add-Content $logFilePath "`n adding controllers group to $($doclibrary.name)"
            $grpname=$doclibrary.name + "_Controllers"
            # Write-Host $spoGroupExists.Count
            
            $GroupExists = $SiteGroups | Where-Object {$_.Title -eq $grpname}
            #check if a group with same name already exists
          
             if($GroupExists)
             { 
             #Write-Host "Group $($grpname) already exists" -foregroundcolor black -backgroundcolor Blue
             Add-Content $logFilePath "`n Group $($grpname) already exists"
              } 
            
            else             #adding controllers group
                 {      $spoGroupCreationInfo1=New-Object Microsoft.SharePoint.Client.GroupCreationInformation 
                        $spoGroupCreationInfo1.Title=$doclibrary.name + "_Controllers"
                        $spoGroupCreationInfo1.Description="Controllers"
                        $spoGroup=$SiteGroups.Add($spoGroupCreationInfo1) 
                        $context.ExecuteQuery()
                        #Adding users to controllers group
                        Add-Content $logFilePath "`n adding users to controllers group to $($doclibrary.name)" 
                        foreach($sUserToAdd in $doclibrary.Controllers.user)
                        {
                        $spoUser = $context.Web.EnsureUser($sUserToAdd) 
                        $context.Load($spoUser) 
                        $spoUserToAdd=$spoGroup.Users.AddUser($spoUser) 
                        $context.Load($spoUserToAdd) 
                        $context.ExecuteQuery()
                        }
                         Add-Content $logFilePath "`n adding permissions to controllers group to $($doclibrary.name)"
                        #adding permissions to admins group
                        $roleType = [Microsoft.SharePoint.Client.RoleType]"Contributor"
                        $roleDefs = $web.RoleDefinitions
                        $context.Load($roleDefs)
                        $context.ExecuteQuery()
                    
                        $roleDef = $roleDefs | where {$_.RoleTypeKind -eq "Contributor"}
                        $collRdb = new-object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($context)
                        $collRdb.Add($roleDef)
                        $collRoleAssign = $list.RoleAssignments
                        $rollAssign = $collRoleAssign.Add($spoGroup, $collRdb)
                        $context.ExecuteQuery()
                    }
            Add-Content $logFilePath "`n addingReaders group to $($doclibrary.name)"
             
             $grpname=$doclibrary.name + "_Readers"
             $GroupExists = $SiteGroups | Where-Object {$_.Title -eq $grpname}
            #check if a group with same name already exists
            if($GroupExists)
              
              { 
             #Write-Host "Group $($grpname) already exists" -foregroundcolor black -backgroundcolor Blue
             Add-Content $logFilePath "`n Group $($grpname) already exists"
              } 
            else
                   {    $spoGroupCreationInfo2=New-Object Microsoft.SharePoint.Client.GroupCreationInformation 
                        $spoGroupCreationInfo2.Title=$doclibrary.name + "_Readers"
                        $spoGroupCreationInfo2.Description="readers"
                        $spoGroup=$SiteGroups.Add($spoGroupCreationInfo2) 
                        $context.ExecuteQuery() 
                         #Adding users to Readers group 
                         Add-Content $logFilePath "`n adding Readers to controllers group to $($doclibrary.name)" 
                        foreach($sUserToAdd in $doclibrary.readers.user)
                        {
                        $spoUser = $context.Web.EnsureUser($sUserToAdd) 
                        $context.Load($spoUser) 
                        $spoUserToAdd=$spoGroup.Users.AddUser($spoUser) 
                        $context.Load($spoUserToAdd) 
                        $context.ExecuteQuery()
                        }
                         #adding permissions to admins group
                        Add-Content $logFilePath "`n adding permissions to Readers group to $($doclibrary.name)"
                        $roleType = [Microsoft.SharePoint.Client.RoleType]"Reader"
                        $roleDefs = $web.RoleDefinitions
                        $context.Load($roleDefs)
                        $context.ExecuteQuery()
           
                        $roleDef = $roleDefs | where {$_.RoleTypeKind -eq "Reader"}
                        $collRdb = new-object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($context)
                        $collRdb.Add($roleDef)
                        $collRoleAssign = $list.RoleAssignments
                        $rollAssign = $collRoleAssign.Add($spoGroup, $collRdb)
                        $context.ExecuteQuery()
                    }

            Add-Content $logFilePath "`n adding Admins group to $($doclibrary.name)"
            
            $grpname=$doclibrary.name + "_Admins"
             $GroupExists = $SiteGroups | Where-Object {$_.Title -eq $grpname}
            #check if a group with same name already exists
            if($GroupExists)
              
              { 
             #Write-Host "Group $($grpname) already exists" -foregroundcolor black -backgroundcolor Blue
             Add-Content $logFilePath "`n Group $($grpname) already exists"
              } 
            else
                    {   $spoGroupCreationInfo3=New-Object Microsoft.SharePoint.Client.GroupCreationInformation
                        $spoGroupCreationInfo3.Title=$doclibrary.name + "_Admins"
                        $spoGroupCreationInfo3.Description="Admins"
                        $spoGroup=$SiteGroups.Add($spoGroupCreationInfo3) 
                        $context.ExecuteQuery()
                        #Adding users to Admins group
                         Add-Content $logFilePath "`n adding Users to controllers group to $($doclibrary.name)"
                        foreach($sUserToAdd in $doclibrary.admins.user)
                        {
                        $spoUser = $context.Web.EnsureUser($sUserToAdd) 
                        $context.Load($spoUser) 
                        $spoUserToAdd=$spoGroup.Users.AddUser($spoUser) 
                        $context.Load($spoUserToAdd) 
                        $context.ExecuteQuery()
                        }
                        #adding permissions to admins group
                        Add-Content $logFilePath "`n adding permissions to Administrators group to $($doclibrary.name)"
                        $roleType = [Microsoft.SharePoint.Client.RoleType]"Administrator"
                        $roleDefs = $web.RoleDefinitions
                        $context.Load($roleDefs)
                        $context.ExecuteQuery()
           
                        $roleDef = $roleDefs | where {$_.RoleTypeKind -eq "Administrator"}
                        $collRdb = new-object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($context)
                        $collRdb.Add($roleDef)
                        $collRoleAssign = $list.RoleAssignments
                        $rollAssign = $collRoleAssign.Add($spoGroup, $collRdb)
                        $context.ExecuteQuery()
                 }
            }
        }
        }
        catch
        {
            #Write-Host "Error while Creating Groups Error -->> "  + $_.Exception.Message 
			$ErrorMessage = $_.Exception.Message
            Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)"
        }
    }
   
}  

function CreateSiteGroups ()
 {
 try
 {
 foreach($sitecol in  $ConfigFile.Settings.CreateGroups.sitecol)
      {
         Add-Content $logFilePath "`n Getting Context for $($sitecol.url)"
         $context = New-Object Microsoft.SharePoint.Client.ClientContext($sitecol.url)
            $spCredentials = New-Object System.Net.NetworkCredential($sUserName,$sPassword,$sDomain)  
            $context.Credentials = $spCredentials
            $web = $context.Web 
            $context.Load($web) 
            $context.ExecuteQuery()
            #fetching site collection groups
            $SiteGroups=$web.SiteGroups
            $context.Load($SiteGroups) 
            $context.ExecuteQuery()
            foreach($groupInfo in $sitecol.groupInfo)
            {
            $spoGroupCreationInfo=New-Object Microsoft.SharePoint.Client.GroupCreationInformation 
            
        $spoGroupCreationInfo.Title=$groupInfo.GroupToCreate 
        $spoGroupCreationInfo.Description=$groupInfo.GroupToCreateDescription 
        $spoGroup= $web.SiteGroups.Add($spoGroupCreationInfo) 
        $context.ExecuteQuery() 
        $spGroups=$context.Web.SiteGroups 
        $context.Load($spGroups)         
        #Getting the specific SharePoint Group where we want to add the user 
        $spGroup=$spGroups.GetByName($groupInfo.GroupToCreate); 
        $context.Load($spGroup)  
        foreach($user in  $groupInfo.user)
        {     
        #Ensuring the user we want to add exists 
        $spUser = $context.Web.EnsureUser($user) 
        $context.Load($spUser) 
        $spUserToAdd=$spGroup.Users.AddUser($spUser) 
        $context.Load($spUserToAdd) 
        $context.ExecuteQuery()
        }  
        }  
         

            }
            }
             catch
        {
            Write-Host "Error while Creating Groups Error -->> "  + $_.Exception.Message 
        }
    

 } 
     
            
Set-PermissionsOnList
CreateSiteGroups  