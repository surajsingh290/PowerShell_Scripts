param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")


Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: ClonePermissionsAllUsers"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss)"

Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
 
#Function to copy user permissions 
Function Copy-UserPermissions($SourceUserID, $TargetUserID, [Microsoft.SharePoint.SPSecurableObject]$Object)
{
    try
    {
    #Determine the given Object type and Get URL of it
	Switch($Object.GetType().FullName)
	{
		"Microsoft.SharePoint.SPWeb"  { $ObjectType = "Site" ; $ObjectURL = $Object.URL; $web = $Object }
		"Microsoft.SharePoint.SPListItem"
		{ 
			if($Object.Folder -ne $null)
			{
			 $ObjectType = "Folder" ; $ObjectURL = "$($Object.Web.Url)/$($Object.Url)"; $web = $Object.Web
			}
			else
			{
			$ObjectType = "List Item"; $ObjectURL = "$($Object.Web.Url)/$($Object.Url)" ; $web = $Object.Web
			}
		}
		#Microsoft.SharePoint.SPList, Microsoft.SharePoint.SPDocumentLibrary, Microsoft.SharePoint.SPPictureLibrary,etc
		default { $ObjectType = "List/Library"; $ObjectURL = "$($Object.ParentWeb.Url)/$($Object.RootFolder.URL)"; $web = $Object.ParentWeb }
	}
 
	#Get Source and Target Users
	$SourceUser = $Web.EnsureUser($SourceUserID)
	$TargetUser = $Web.EnsureUser($TargetUserID)
 
	#Get Permissions of the Source user on given object - Such as: Web, List, Folder, ListItem
	$SourcePermissions = $Object.GetUserEffectivePermissionInfo($SourceUser)
 
	#Iterate through each permission and get the details
	foreach($SourceRoleAssignment in $SourcePermissions.RoleAssignments)
	{
		#Get all permission levels assigned to User account directly or via SharePOint Group
		$SourceUserPermissions=@()
		foreach ($SourceRoleDefinition in $SourceRoleAssignment.RoleDefinitionBindings)
		{
		   #Exclude "Limited Accesses"
		   if($SourceRoleDefinition.Name -ne "Limited Access")
		   {
				  $SourceUserPermissions += $SourceRoleDefinition.Name
		   }
		}
  
		#Check Source Permissions granted directly or through SharePoint Group
		if($SourceUserPermissions)
		{
			if($SourceRoleAssignment.Member -is [Microsoft.SharePoint.SPGroup])   
			{
				$SourcePermissionType = "'Member of SharePoint Group - " + $SourceRoleAssignment.Member.Name +"'"
     
				#Add Target User to the Source User's Group
				#Get the Group
				$Group = [Microsoft.SharePoint.SPGroup]$SourceRoleAssignment.Member
      
				#Check if user is already member of the group - If not, Add to group
				if( ($Group.Users | where {$_.UserLogin -eq $TargetUserID}) -eq $null )
				{
				  #Add User to Group
				  $Group.AddUser($TargetUser)
				  Write-Host "Added to Group: $Group.Name"
				  "Added to Group: $Group.Name" | Out-File $OutputReport -Append
				}     
			}
			else
			{
				$SourcePermissionType = "Direct Permission"
     
				#Add Each Direct permission (such as "Full Control", "Contribute") to Target User
				foreach($NewRoleDefinition in $SourceUserPermissions)
				{    
				  #Role assignment is a linkage between User object and Role Definition
				  $NewRoleAssignment = New-Object Microsoft.SharePoint.SPRoleAssignment($TargetUser)
				  $NewRoleAssignment.RoleDefinitionBindings.Add($web.RoleDefinitions[$NewRoleDefinition])
					  
				  $object.RoleAssignments.Add($NewRoleAssignment)
				  $object.Update()     
				}      
			}
			$SourceUserPermissions = $SourceUserPermissions -join ";" 
			Write-Host "***$($ObjectType) Permissions Copied: $($SourceUserPermissions) at $($ObjectURL) via $($SourcePermissionType)***"
			"***$($ObjectType) Permissions Copied: $($SourceUserPermissions) at $($ObjectURL) via $($SourcePermissionType)***" | Out-File $OutputReport -Append
		}   
	} 
}
    catch
    {
         $ErrorMessage = $_.Exception.Message
         Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
    }
}
 
Function Clone-SPUser($SourceUserID, $TargetUserID, $WebAppURL,$SiteURL)
{
    try
    {
	###Check Whether the Source Users is a Farm Administrator ###
	Write-host "Scanning Site Collections..."
	
	  
	### Drill down to Site Collections, Webs, Lists & Libraries, Folders and List items ###
	#Get all Site collections of given web app
	$SiteCollections = Get-SPSite -WebApplication $WebAppURL -Limit All
 
	#Convert UserID Into Claims format - If WebApp is claims based! Domain\User to i:0#.w|Domain\User
    #if( (Get-SPWebApplication $WebAppURL).UseClaimsAuthentication)
    #{
	#	$SourceUserID = (New-SPClaimsPrincipal -identity $SourceUserID -identitytype 1).ToEncodedString()
	#	$TargetUserID = (New-SPClaimsPrincipal -identity $TargetUserID -identitytype 1).ToEncodedString()
    #}
  
	#Loop through all site collections 
    foreach($Site in $SiteCollections)
    {
		Write-host "Scanning $site..."
        if($SiteURL -ne "" -and  $Site.Url.ToLower() -ne $SiteURL.ToLower())
		{continue}
		
        #Prepare the Target user 
		$TargetUser = $Site.RootWeb.EnsureUser($TargetUserID)

		Write-host "Scanning Site Collection Administrators Group for:" $site.Url
		###Check Whether the User is a Site Collection Administrator
		foreach($SiteCollAdmin in $Site.RootWeb.SiteAdministrators)
		{
			if($SiteCollAdmin.LoginName.EndsWith($SourceUserID,1))
			{
				#Make the user as Site collection Admin
				$TargetUser.IsSiteAdmin = $true
				$TargetUser.Update()
				Write-host "***Added to Site Collection Admin Group***"
			}     
		}
   
		#Get all webs
		$WebsCollection = $Site.AllWebs
		#Loop throuh each Site (web)
		foreach($Web in $WebsCollection)
		{
			if($Web.HasUniqueRoleAssignments -eq $True)
            {
				Write-host "Scanning Site:" $Web.Url
     
				#Call the function to Copy Permissions to TargetUser
				Copy-UserPermissions $SourceUserID $TargetUserID $Web   
			} 
     
			#Check Lists with Unique Permissions
			Write-host "Scanning Lists on $($web.url)..."
			foreach($List in $web.Lists)
			{
				if($List.HasUniqueRoleAssignments -eq $True -and ($List.Hidden -eq $false))
                {
					#Call the function to Copy Permissions to TargetUser
					Copy-UserPermissions $SourceUserID $TargetUserID $List
				}
     
				#Check Folders with Unique Permissions
				$UniqueFolders = $List.Folders | where { $_.HasUniqueRoleAssignments -eq $True }                    
				#Get Folder permissions
				foreach($folder in $UniqueFolders)
				{
					#Call the function to Copy Permissions to TargetUser
                    Copy-UserPermissions $SourceUserID $TargetUserID $folder     
				}
     
				#Check List Items with Unique Permissions
				$UniqueItems = $List.Items | where { $_.HasUniqueRoleAssignments -eq $True }
                #Get Item level permissions
                foreach($item in $UniqueItems)
				{
					#Call the function to Copy Permissions to TargetUser
					Copy-UserPermissions $SourceUserID $TargetUserID $Item 
				}
			}
		}
	}
	Write-Host "Permission are copied successfully!"
  
}
    catch
    {
         $ErrorMessage = $_.Exception.Message
         Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
    }
}

#Define variables for processing
#***IMPORTANT *** DO NOT INCLUDE / AT THE END OF THE URL***
$WebAppURL = "https://bp1amsapt264.cloudapp.net"
$SiteCollURL  = "https://bp1amsapt264.cloudapp.net/apps/wellintegrity"
#Provide input for source and Target user Ids
$SourceUser = "c:0-.t|bp-id-provider|NT AUTHORITY\Authenticated Users"
$TargetUser = "c:0!.s|trusted%3abp-id-provider"
$OutputReport = "OutputReport.txt"
#Call the function to clone user access rights
Clone-SPUser $SourceUser $TargetUser $WebAppURL $SiteCollURL