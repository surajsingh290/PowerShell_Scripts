param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Export User"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss)"

Add-PSSnapin "Microsoft.SharePoint.PowerShell" -erroraction 'silentlycontinue' 
$output = $("$path\Userwwws2.csv")
$Site = get-spsite "http://blrkec334360d:17727/sites/ABHI"
$Site1 = $site.Url
try
{
    foreach($web in $Site.AllWebs)
    {
        $SubSite = $web.Url        
        $groups = $web.Groups
        foreach ($grp in $groups) 
        {
            $WebGroups = $grp.name; 
            foreach ($user in $grp.users) 
            
            {
                $userInWebGroups = $user.Email
                $line = $SubSite+","+$WebGroups+","+$userInWebGroups
                $line | Out-File -FilePath $output -Append
                Add-Content $logFilePath "`n $($line)"
            } 
            
        }
        foreach($list in $web.lists)
        {
            $listName = $list.RootFolder                
            $Listmember = $list.permissions | select Member  
                                          
            foreach($m in $Listmember)
            {                        
                $n = $m -replace '@{Member=',''     
                $n1 = $n.Trim("}"," ")                                                                                                        
                $user = Get-SPUser -web $SubSite -Identity $n1 -erroraction 'silentlycontinue'                         
                $Email = $user.Email
                If($Email -ne $null)
                {                                              
                    $line = $SubSite+"/"+$listName+","+$Email
                    $line | out-file -filepath $output -append                        
                    Add-Content $logFilePath "`n $($line)"   
                }
                else
                {
                    $line = $SubSite+"/"+$listName+","+$n1
                    $line | out-file -filepath $output -append                        
                    Add-Content $logFilePath "`n $($line)" 
                }                    
               
            }
        }
    }
}
catch
{
     $ErrorMessage = $_.Exception.Message
     Add-Content $logFilePath "`n Exception :::::: $($ErrorMessage)"
}
     
