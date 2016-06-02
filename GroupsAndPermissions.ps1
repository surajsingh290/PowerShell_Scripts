
#----------------------------------------------------------------------------- 
# Filename : ELC.Origins.GroupsAndPermissions.ps1 
#----------------------------------------------------------------------------- 
# Author : Infosys
#----------------------------------------------------------------------------- 
# Includes function to update sites Master Page and theme properties


function CreateSecurityGroup([Parameter(Mandatory=$true)]$groupTitle,[Parameter(Mandatory=$true)]$permissionLevel,[Parameter(Mandatory=$true)]$groupOwner,[Parameter(Mandatory=$true)]$clientContext)
{
    WriteLog "------------------------------------------------------------------" "White"
    WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Creation of Security Groups Started" "Green"
    WriteLog "------------------------------------------------------------------" "White"

    try
    {
        #Load web, groups of web

        $web = $clientContext.Web
        $groups = $web.SiteGroups
        $clientContext.Load($web)
        $clientContext.Load($groups)
        $clientContext.ExecuteQuery()

		$ownerGroup = $groups | where {$_.LoginName.Contains($groupOwner)}

        #Check if target group already exists

        $group = $groups | where {$_.Title -eq $groupTitle}

        if($group -ne $null)
        {
           WriteLog  ("Group "+ $groupTitle + " already exists.") "Red"
        }
        else
        {
            #region Create new group
            #Create group instance
            $groupCreationInfo = New-Object Microsoft.SharePoint.Client.GroupCreationInformation 

            #Assign properties to new group
            $groupCreationInfo.Title = $groupTitle 

            #Add new group to web
            $newGroup=$groups.Add($groupCreationInfo)
            $clientContext.Load($newGroup)
            $clientContext.ExecuteQuery()
            #endregion  

            #region Associate permission level to group
            $roleDefinitionBindingColl =  New-Object Microsoft.SharePoint.Client.RoleDefinitionBindingCollection($clientContext)
            #Get role level to be added in newly created group
            $permissions = $permissionLevel.Split(",");
            foreach($permissionName in $permissions) {
                $roledef = $web.RoleDefinitions.GetByName($permissionName)
                $roleDefinitionBindingColl.Add($roledef)
            }

            #Add role definition and group binding in web         
            $roleAssign=$clientContext.Web.RoleAssignments.Add($newGroup,$roleDefinitionBindingColl) 
            $clientContext.ExecuteQuery()   

			$siteGroups = $web.SiteGroups
			$clientContext.Load($siteGroups)
			$clientContext.ExecuteQuery()

			$newGroup=$siteGroups | where {$_.LoginName -eq $groupTitle}
			$clientContext.Load($newGroup)
			$clientContext.ExecuteQuery()

			$newGroup.Owner = $ownerGroup
			$newGroup.Update()
			$clientContext.ExecuteQuery()
                
            WriteLog  "Success: $($groupTitle)" "Green"
            #endregion
        }
   }
   catch
    {
        WriteLog "Error message: $($_.Exception.Message)" "Red"
		
    }
     WriteLog "------------------------------------------------------------------" "White"
     WriteLog "$(Get-Date -f dd_MM_yyyy_hhmmss): Creation of Security Groups completed.." "Green"
     WriteLog "------------------------------------------------------------------" "White"
}

