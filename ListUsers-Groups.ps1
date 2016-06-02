param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: List Users-Groups"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss)"

add-pssnapin microsoft.sharepoint.powershell 
$url ="https://bp1amsapt264.cloudapp.net/apps/wellintegrity/"
#i:05.t|bp-id-provider|username@bp.com
# get all users in the site, this includes iwindows users
try
{
    $users = get-spuser -web $url -Limit ALL
    "Login,Display Name, Email, Type" |  Out-File ListUsers-Groups.csv -Append 
    foreach($useriteration in $users)
    {
    	if($useriteration.IsDomainGroup)
    	{
    		$userlogin = $useriteration.UserLogin + ",`"" + $useriteration.Displayname + "`"," + $useriteration.email + ",Group"
    	}
    	else
    	{
    		$userlogin = $useriteration.UserLogin + ",`"" + $useriteration.Displayname + "`"," + $useriteration.email + ",User"
    	}
    	Write-Host $userlogin
    	$userlogin |  Out-File ListUsers-Groups.csv -Append 
    	
    }
}
catch
{
     $ErrorMessage = $_.Exception.Message
     Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}

Remove-pssnapin microsoft.sharepoint.powershell


