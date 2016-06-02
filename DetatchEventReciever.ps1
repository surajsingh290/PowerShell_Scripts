
param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}

$xmlFilePath = $("$path\PSConfig.xml")
  
$ConfigFile = [xml](get-content $xmlFilePath)
Add-Content $logFilePath "`n XML file loaded successfully"


foreach ($site in $ConfigFile.Settings.DetatchEventReceiver.Sites.site)
{
    #$siteUrl=$site.attributes['Url'].value
     
  #$siteUrl="http://chdsez301747d:1111/"   
    $SPsite = Get-SPSite -Identity $siteUrl
     $web = $SPsite.RootWeb
     $lists = $web.Lists
    
     $listCount =  $lists.Count   
     for($i= 0; $i -lt $listCount; $i++)
     {
        $list = $lists[$i];
        if($list.BaseTemplate -eq 1302)
        {        
            Write-Host $list.Title 
    
            $list.EventReceivers | Select name, type 
        
            $numberOfEventReceivers = $list.EventReceivers.Count
         
            if ($numberOfEventReceivers -gt 0)
            {
                for( $index = $numberOfEventReceivers -1; $index -gt -1; $index–-)
                {
                   $receiver = $list.EventReceivers[$index] ;
                   $name = $receiver.Name
                   $typ = $receiver.Type ;
    
                   foreach($receiver in $site.EventReceiver)
                   {
                        $EventRecieverName = $receiver.attributes['Name'].value 
         
                        if ($name -eq $EventRecieverName) 
                        {
                           $receiver.Delete()
                           Write-Host "Event receiver" $name " is deleted" -ForegroundColor Red
                        }
                    }
                }
           }
        }
    }
}
