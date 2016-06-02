###############################################################################     Generated for SharePoint 2013 Practice Accelerator#     This script will set up Search in a 4 Server environment#     and has been designed accordingly. Your environment may differ.#     This script should be tested thouroughly before putting into production#     Microsoft confers no rights.#     This script will only work if no Search Instance has been provisioned on#     the Farm. if you have run the wizard to provision Service Applications, #     you already have a default Search Topology created. You should refer to#     TechNet Articles on how to manage existing Search Topology - #     http://technet.microsoft.com/EN-US/library/jj862356.aspx ##############################################################################Set-ExecutionPolicy unrestrictedClear-Host
# Start Loading SharePoint Snap-in$snapin = (Get-PSSnapin -name Microsoft.SharePoint.PowerShell -EA SilentlyContinue)IF ($snapin -ne $null){write-host -f Green "SharePoint Snap-in is loaded... No Action taken"}ELSE  {write-host -f Yellow "SharePoint Snap-in not found... Loading now"Add-PSSnapin Microsoft.SharePoint.PowerShellwrite-host -f Green "SharePoint Snap-in is now loaded"}# END Loading SharePoint Snapin$hostA = Get-SPEnterpriseSearchServiceInstance
$hostB = Get-SPEnterpriseSearchServiceInstance
$hostC = Get-SPEnterpriseSearchServiceInstance
$hostD = Get-SPEnterpriseSearchServiceInstance

$searchName = "Fabricam Search Service"
$searchDB = "SP_Services_Search_DB"$searchAcct = "ITLINFOSYS\Suraj_Singh05"
$searchAcctCred = convertto-securestring "ssingh@5" -asplaintext -force
$searchManagedAcct = Get-SPManagedAccount | Where {$_.username-eq 'ITLINFOSYS\Suraj_Singh05'}
$searchAppPoolName = "Search Services Application Pool"
IF((Get-spserviceapplicationPool | Where {$_.name -eq "Search Services Application Pool"}).name -ne "Search Services Application Pool"){$searchAppPool = New-SPServiceApplicationPool -Name $searchAppPoolName -Account $searchManagedAcct}############################################ DO NOT MODIFY BELOW ##########################################
## Start Search Service Instances
Write-Host "Starting Search Service Instances..."
# Server 1
IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostA).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostA 
Write-Host "Starting Search Service Instance on" $hostA.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostA).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostA.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostA.Server.Name  }

#Server 2
IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostB).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostB 
Write-Host "Starting Search Service Instance on" $hostB.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostB).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostB.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostB.Server.Name  }


#Server 3
IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostC).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostC 
Write-Host "Starting Search Service Instance on" $hostC.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostC).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostC.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostC.Server.Name  }


#Server 4
IF((Get-SPEnterpriseSearchServiceInstance -Identity $hostD).Status -eq 'Disabled'){
Start-SPEnterpriseSearchServiceInstance -Identity $hostD 
Write-Host "Starting Search Service Instance on" $hostD.Server.Name
Do { Start-Sleep 5;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchServiceInstance -Identity $hostD).Status -eq 'Online')
Write-Host -ForegroundColor Green "Search Service Instance Started on" $hostD.Server.Name
} ELSE { Write-Host -f Green "Search Service Instance is already running on" $hostD.Server.Name  }


## Start Query and Site Settings Service Instance
Write-Host "
Starting Search Query and Site Settings Service Instance on" $hostA.server.Name "and" $hostB.server.Name
Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $hostA.server.Name
Do { Start-Sleep 3;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance | Where {$_.Server.Name -eq $hostA.server.Name}).status -ne 'Online')
Write-Host -ForegroundColor Green "
    Query and Site Settings Service Instance Started on" $hostA.Server.Name

Start-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance $hostB.server.Name
Do { Start-Sleep 3;
Write-host -NoNewline "."  } 
While ((Get-SPEnterpriseSearchQueryAndSiteSettingsServiceInstance | Where {$_.Server.Name -eq $hostB.server.Name}).status -ne 'Online')
Write-Host -ForegroundColor Green "
    Query and Site Settings Service Instance Started on" $hostB.Server.Name


## Create Search Service Application
Write-Host "
Creating Search Service Application..."

$searchAppPool = Get-SPServiceApplicationPool -Identity "Search Services Application Pool"

IF ((Get-SPEnterpriseSearchServiceApplication).Status -ne 'Online'){
Write-Host "    Provisioning. Please wait..."
$searchApp = New-SPEnterpriseSearchServiceApplication -Name $searchName -ApplicationPool $searchAppPool -AdminApplicationPool $searchAppPool -DatabaseName $searchDB
DO {start-sleep 2;
write-host -nonewline "." } While ( (Get-SPEnterpriseSearchServiceApplication).status -ne 'Online')
Write-Host -f green "    
    Provisioned Search Service Application"
} ELSE {  write-host -f green "Search Service Application already provisioned."
$searchApp = Get-SPEnterpriseSearchServiceApplication
}



## Set Search Admin Component
Write-Host "Set Search Admin Component..."
$AdminComponent = $searchApp | Get-SPEnterpriseSearchAdministrationComponent | Set-SPEnterpriseSearchAdministrationComponent -SearchServiceInstance $hostA

## Get Initial Search Topology
Write-Host "Get Initial Search Topology..."
$initialTopology = Get-SPEnterpriseSearchTopology -SearchApplication $searchApp

## Create Clone Search Topology
Write-Host "Creating Clone Search Topology..."
$cloneTopology = New-SPEnterpriseSearchTopology -SearchApplication $searchApp -Clone -SearchTopology $initialTopology

## Host-A Components

Write-Host "Creating Host A Components (Admin, Crawl, Analytics, Content Processing, Index Partition)..."

$AdminTopology = New-SPEnterpriseSearchAdminComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$CrawlTopology = New-SPEnterpriseSearchCrawlComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$AnalyticsTopology = New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$ContentProcessingTopology = New-SPEnterpriseSearchContentProcessingComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology
$IndexTopology = New-SPEnterpriseSearchIndexComponent -SearchServiceInstance $hostA -SearchTopology $cloneTopology -IndexPartition 0

## Host-B Components
 
Write-Host "Creating Host B Components (Admin, Crawl, Analytics, Content Processing, Index Partition)..."

$AdminTopology = New-SPEnterpriseSearchAdminComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$CrawlTopology = New-SPEnterpriseSearchCrawlComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$AnalyticsTopology = New-SPEnterpriseSearchAnalyticsProcessingComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$ContentProcessingTopology = New-SPEnterpriseSearchContentProcessingComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology
$IndexTopology = New-SPEnterpriseSearchIndexComponent -SearchServiceInstance $hostB -SearchTopology $cloneTopology -IndexPartition 0

## Host-C Components

Write-Host "Creating Host C Components (Query)..."

$QueryTopology = New-SPEnterpriseSearchQueryProcessingComponent -SearchServiceInstance $hostC -SearchTopology $cloneTopology

## Host-D Components

Write-Host "Creating Host D Components (Query)..."

$QueryTopology = New-SPEnterpriseSearchQueryProcessingComponent -SearchServiceInstance $hostD -SearchTopology $cloneTopology

## Activate Clone Search Topology
Write-Host "Activating Clone Search Topology...Please wait. This will take some time"
Set-SPEnterpriseSearchTopology -Identity $cloneTopology

## Remove Initial Search Topology
Write-Host "Removing Initial Search Topology..."
$initialTopology = Get-SPEnterpriseSearchTopology -SearchApplication $searchApp | where {($_.State) -eq "Inactive"}
Remove-SPEnterpriseSearchTopology -Identity $initialTopology -Confirm:$false

## Create Search Service Application Proxy
Write-Host "Creating Search Service Application Proxy..."
$searchAppProxy = New-SPEnterpriseSearchServiceApplicationProxy -Name "$searchName Proxy" -SearchApplication $searchApp

Write-Host "$searchName created."