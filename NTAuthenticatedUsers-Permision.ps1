param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name:NTAuthenticatedUsers-Permision"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss)"


Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue
  
Function GetUserAccessReport($WebAppURL, $SearchUser, $SiteURL)
{
try
{
	#Output Report location
	$OutputReport = $("$path\UserAccessReport.csv")
	#delete the file, If already exist!
	if (Test-Path $OutputReport)
	{
		Remove-Item $OutputReport
	}
 
 
	Add-Content $logFilePath "`n Scanning Site Collections..."
	#Get All Site Collections of the WebApp
	$SiteCollections = Get-SPSite -WebApplication $WebAppURL -Limit All
     
	#Loop through all site collections
	foreach($Site in $SiteCollections)
	{
	 if($SiteURL -ne "" -and  $site.Url.ToLower() -ne $SiteURL.ToLower())
		{continue}
	 Add-Content $logFilePath "`n Scanning Site Collection: $($site.Url)"
	 #Check Whether the Search User is a Site Collection Administrator
	foreach($SiteCollAdmin in $Site.RootWeb.SiteAdministrators)
	{
		if($SiteCollAdmin.LoginName -eq $SearchUser)
		{
			"$($Site.RootWeb.Url) `t Site `t $($Site.RootWeb.Title)`t Site Collection Administrator `t Site Collection Administrator" | Out-File $OutputReport -Append
		}     
	}
    
	#Loop throuh all Sub Sites
	foreach($Web in $Site.AllWebs)
	{
		if($Web.HasUniqueRoleAssignments -eq $True)
		{
			Add-Content $logFilePath "`n Scanning Site: $($Web.Url)"
     
			#Get all the users granted permissions to the list
			foreach($WebRoleAssignment in $Web.RoleAssignments )
			{
                 #Is it a User Account?
				if($WebRoleAssignment.Member.userlogin)   
				{
					#Is the current user is the user we search for?
					if($WebRoleAssignment.Member.LoginName -eq $SearchUser)
					{
					   #Write-Host  $SearchUser has direct permissions to site $Web.Url
					   #Get the Permissions assigned to user
						$WebUserPermissions=@()
						foreach ($RoleDefinition  in $WebRoleAssignment.RoleDefinitionBindings)
						{
							$WebUserPermissions += $RoleDefinition.Name +";"
						}
						#write-host "with these permissions: " $WebUserPermissions
           
						#Send the Data to Log file
						"$($Web.Url) `t Site `t $($Web.Title)`t Direct Permission `t $($WebUserPermissions)" | Out-File $OutputReport -Append
					}
				}
				#Its a SharePoint Group, So search inside the group and check if the user is member of that group
				else 
				{
					foreach($user in $WebRoleAssignment.member.users)
					{
						#Check if the search users is member of the group
						if($user.LoginName -eq $SearchUser)
						{
							#Write-Host  "$SearchUser is Member of " $WebRoleAssignment.Member.Name "Group"
							#Get the Group's Permissions on site
							$WebGroupPermissions=@()
							foreach ($RoleDefinition  in $WebRoleAssignment.RoleDefinitionBindings)
							{
								$WebGroupPermissions += $RoleDefinition.Name +";"
							}
							#write-host "Group has these permissions: " $WebGroupPermissions
			
							#Send the Data to Log file
							"$($Web.Url) `t Site `t $($Web.Title)`t Member of $($WebRoleAssignment.Member.Name) Group `t $($WebGroupPermissions)" | Out-File $OutputReport -Append
						}
					}
				}
			}
		} 
      
		###*****  Check Lists with Unique Permissions *******###
		foreach($List in $Web.lists)
		{
			if($List.HasUniqueRoleAssignments -eq $True -and ($List.Hidden -eq $false))
			{
				Add-Content $logFilePath "`n Scanning List: $($List.RootFolder.Url)"
				#Get all the users granted permissions to the list
				foreach($ListRoleAssignment in $List.RoleAssignments )
				{
				 #Is it a User Account?
					if($ListRoleAssignment.Member.userlogin)   
					{
						#Is the current user is the user we search for?
						if($ListRoleAssignment.Member.LoginName -eq $SearchUser)
						{
							#Write-Host  $SearchUser has direct permissions to List ($List.ParentWeb.Url)/($List.RootFolder.Url)
							#Get the Permissions assigned to user
							$ListUserPermissions=@()
							foreach ($RoleDefinition  in $ListRoleAssignment.RoleDefinitionBindings)
							{
								$ListUserPermissions += $RoleDefinition.Name +";"
							}
							#write-host "with these permissions: " $ListUserPermissions
		   
							#Send the Data to Log file
							"$($List.ParentWeb.Url)/$($List.RootFolder.Url) `t List `t $($List.Title)`t Direct Permissions `t $($ListUserPermissions)" | Out-File $OutputReport -Append
						}
					}
					#Its a SharePoint Group, So search inside the group and check if the user is member of that group
					else 
					{
						foreach($user in $ListRoleAssignment.member.users)
						{
							if($user.LoginName -eq $SearchUser)
							{
								#Write-Host  "$SearchUser is Member of " $ListRoleAssignment.Member.Name "Group"
								#Get the Group's Permissions on site
								$ListGroupPermissions=@()
								foreach ($RoleDefinition  in $ListRoleAssignment.RoleDefinitionBindings)
								{
									$ListGroupPermissions += $RoleDefinition.Name +";"
								}
								#write-host "Group has these permissions: " $ListGroupPermissions
			
								#Send the Data to Log file
								"$($Web.Url) `t Site `t $($List.Title)`t Member of $($ListRoleAssignment.Member.Name) Group `t $($ListGroupPermissions)" | Out-File $OutputReport -Append
							}
						}
					}
				}
			}
		}
	}
}
      
 Add-Content $logFilePath "`n  Access Rights Report Generated!"
}
catch
{
     $ErrorMessage = $_.Exception.Message
     Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}
}  
 
#Call the function to Check User Access
#********IMPORTANT- Please exclude / at the end of the URL in the parameter sent"
GetUserAccessReport "https://gpo.bpglobal.com" "c:0-.t|bp-id-provider|NT AUTHORITY\Authenticated Users" "https://gpo.bpglobal.com/sites/kz01"