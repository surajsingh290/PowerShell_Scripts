param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Group Conversion"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss)"

add-pssnapin microsoft.sharepoint.powershell 
$url ="http://bp1amsapt254:39202/angola/ext_Blk31"
$users = get-spuser -web $url -Limit ALL

foreach($spUser in $users)
{
    try
    {
        $userlogin = $spUser.UserLogin
    
        if($spUser.IsDomainGroup)
                {
                    $convertGroup = $true
					if(-not $spUser.DisplayName.ToUpper().Contains("ALL USERS (BP-ID-PROVIDER)"))
                    {
                        $groupName=$spUser.Name
						if($userlogin.ToUpper().Contains("DSC\"))
						{
							#BP1 User 
							$bp1Group = "bp1" + $groupName
							#Converted User
							$convertedGroup = "c:0-.t|bp-id-provider|" + $groupName
							#Find if BP1 User Exist
							$bp1GroupUserObj = Get-SPUser -web $url -Limit ALL | Where-Object {$_.UserLogin -like $bp1Group}
							#Find if Converted User Exist
							$convertedGroupUserObj = Get-SPUser -web $url -Limit ALL | Where-Object {$_.UserLogin -like $convertedGroup}
							
							if(($bp1GroupUserObj -ne $null) -or  ($convertedGroupUserObj -ne $null))
							{
								$convertGroup = $false
							}
						}
						
						if($groupName -and $convertGroup)
						{
										
										Move-SPUser -IgnoreSID -Confirm:$false -Identity $spUser -NewAlias "c:0-.t|bp-id-provider|$groupName"
										Add-Content $logFilePath "User converted to claim with c:0-.t|bp-id-provider|$($groupName)"
						}
						else
						{
										Add-Content $logFilePath "`n No group name available to convert to claim for $($userlogin)"
						}
					}
					else
                    {

						Add-Content $logFilePath "`n No group name available to convert to claim for $($userlogin)"
					}
                }
                else
                {
                        Add-Content $logFilePath "`n Probably a user login so no change made to $($userlogin)"
                }
    }
    catch
    {
         $ErrorMessage = $_.Exception.Message
         Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
    }
}
Remove-pssnapin microsoft.sharepoint.powershell