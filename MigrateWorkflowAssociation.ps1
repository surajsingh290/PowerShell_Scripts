Param ([string]$SrcUrl, [string]$TargetUrl, [string]$SrcList, [string]$TargetList, [string]$workflowName, [string]$workflowAssociationName, [string]$workflowAssociationTasksList, [string]$workflowAssociationHistoryList, [bool]$replaceExistingMatchingWorkflows)

# Check for the site url input parameter
if(!$SrcUrl -or !$TargetUrl -or !$SrcList -or !$workflowName  -or !$workflowAssociationTasksList -or !$workflowAssociationHistoryList)
{
    Write-Host ""
	Write-Host -ForegroundColor Red "Please specify the following parameters:";
	Write-Host ""
	Write-Host -ForegroundColor Yellow "Parameters:"
	Write-Host ""
	Write-Host -ForegroundColor Yellow "-SrcUrl ['Url of source web containg existing list workflow']"
	Write-Host ""
	Write-Host -ForegroundColor Yellow "-TargetUrl ['Url of target web for new/migrated list workflow']"
	Write-Host ""
	Write-Host -ForegroundColor Yellow "-SrcList ['Name of the list to associated with existing workflow']"
	Write-Host ""
	Write-Host -ForegroundColor Yellow "-TargetList (optional) ['Name of  list the new/migrated workflow is to be to associated with - SrcList Name assumed if omitted']"
	Write-Host ""
    Write-Host -ForegroundColor Yellow "-workflowName ['Name of the workflow (template)']"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "-workflowAssociationName (optional) ['Display Name of the workflow association - if omitted ALL workflows with matching -workflowName (workflow template) will be processed']"
	Write-Host ""
	Write-Host -ForegroundColor Yellow "-workflowAssociationTasksList ['Name of the Workflow Tasks list']"
    Write-Host ""
    Write-Host -ForegroundColor Yellow "-workflowAssociationHistoryList ['Name of the Workflow History list']"
	Write-Host ""
	Write-Host -ForegroundColor Yellow "-replaceExistingMatchingWorkflows (optional) ['Remove & Replace Existing Workflows on Target (Default: False)']"
	Write-Host ""
	
	Write-Host -ForegroundColor Yellow "Example:
	MigrateWorkflowAssociation.ps1 -SrcUrl 'http://sourceweb/' -SrcList 'Issues' -TargetUrl 'http://targetweb/' -TargetList 'Issues' -workflowName 'Three-state' -workflowAssociationName 'My Existing Workflow to be Transferred' -workflowAssociationTasksList 'Tasks' -workflowAssociationHistoryList 'Workflow History' -replaceExistingMatchingWorkflows $true
	"	
	Break
}
Write-Host ""
write-host "Parameters Received:"
write-host "-SrcUrl: "  -nonewline; write-host $SrcUrl
write-host "-SrcList: "  -nonewline; write-host $SrcList	
write-host "-TargetUrl: "  -nonewline; write-host $TargetUrl
write-host "-TargetList: "  -nonewline; write-host $TargetList
write-host "-workflowName: "  -nonewline; write-host $workflowName
write-host "-workflowAssociationName: "  -nonewline; write-host $workflowAssociationName
write-host "-workflowAssociationTasksList: "  -nonewline; write-host $workflowAssociationTasksList
write-host "-workflowAssociationHistoryList: "  -nonewline; write-host $workflowAssociationHistoryList
if(!$workflowAssociationName)
{
	write-host -ForegroundColor Yellow "No -workflowAssociationName Parameter Provided"
	write-host -ForegroundColor Yellow "All Workflows with matching -workflowName ($workflowName) will be processed"
}
write-host ""
write-host "Checking Source Web and Lists."
$srcSiteUrl = $SrcUrl
$targetSiteUrl = $TargetUrl
$site = Get-SPWeb $srcSiteUrl
$targetsite = Get-SPWeb $targetSiteUrl

[Guid]$crTemplateId = New-Object Guid
$srcListName = $SrcList
$targetListName = $TargetList
$wfTemplateName = $workflowName

$wfTaskListName = $workflowAssociationTasksList
$wfHistListName = $workflowAssociationHistoryList

$list = $site.Lists[$srcListName]
$wfTaskList = $site.Lists[$wfTaskListName]
$wfHistList = $site.Lists[$wfHistListName]

if (!$TargetList )
{
$listTarget = $targetsite.Lists[$srcListName]
} else 
{
$listTarget = $targetsite.Lists[$targetListName]
}

function Add-WorkflowAssociations($listTargetParam, $srcworkflowAssociationParam, $newworkflowAssociationParam ) {
	# Add the workflow association to the list
	$listTargetParam.WorkflowAssociations.Add($newworkflowAssociationParam);
	# Enable workflow  
	$newworkflowAssociationParam.Enabled = $srcworkflowAssociationParam.Enabled
	write-host -ForegroundColor Green ""
	write-host -ForegroundColor Green "WorkflowAssociation: '"$newworkflowAssociationParam.Name"' Added Successfully"
	write-host -ForegroundColor Green "To the list: " $listTargetParam.Title
	write-host -ForegroundColor Green "On the web: " $listTargetParam.ParentWeb.Title
	Write-Host -ForegroundColor Green "Url: " $listTargetParam.ParentWeb.Url
	write-host -ForegroundColor Green ""
}

function Get-WorkflowAssociation($workflowassociation) { 
	write-host ""
	write-host "Get-WorkflowAssociation "
	write-host "Web: "  -nonewline; write-host $_.ParentWeb.Url
	write-host "List: "  -nonewline; write-host $_.ParentList.Title;
	write-host "WorkflowTemplate: "  -nonewline; write-host $_.BaseTemplate.Name
	write-host "WorkflowName: "  -nonewline; write-host $_.Name
	#write-host "Soap Xml:"; write-host $_.SoapXml
	write-host ""
	if(!$workflowAssociationName)
	{
		CreateWorkflowAssociation $targetsite $listTarget $_.BaseTemplate.Name $_.Name $_
	}
	elseif($workflowAssociationName -eq $_.Name)
	{
		CreateWorkflowAssociation $targetsite $listTarget $_.BaseTemplate.Name $_.Name $_
	}
}

function CreateWorkflowAssociation($web, $listTarget, $workflowName, $srcworkflowAssociationName, $srcworkflowAssociation)
{
	write-host "CreateWorkflowAssociation Parameters"
	write-host "web :" $web
	write-host "listTarget :" $listTarget
	write-host "workflowName :" $workflowName
	write-host "srcworkflowAssociationName :" $srcworkflowAssociationName
	#write-host "srcworkflowAssociation :" $srcworkflowAssociation
	write-host ""
	write-host ""
	write-host "Creating Workflow Association" 
    $workflowTemplate=$web.workflowtemplates.gettemplatebyname($workflowName, [System.Globalization.CultureInfo]::CurrentCulture);
    
    if(!$workflowTemplate)
    {
	   Write-Host -ForegroundColor Red "No workflow installed or activated with this workflowname : " $workflowName "on the web: "
       Write-Host -ForegroundColor Red "Name : " $web
	   Write-Host -ForegroundColor Red "Url  : " $web.Url
    }
    else
    {
        # Check if the site already has a workflow history list - if not, create it

            if(!$web.Lists[$wfHistListName])
            {
                $web.Lists.Add($wfHistListName, "A system library used to store workflow history information.", [Microsoft.SharePoint.SPListTemplateType]::WorkflowHistory);                
                $wfHistory = $web.Lists[$wfHistListName]
                $wfHistory.Hidden = $true
                $wfHistory.Update()
            }
             
            
            #Check if the site already has a workflow tasks list - if not, create it
            if(!$web.Lists[$wfTaskListName])
            {
                $web.Lists.Add($wfTaskListName, "This system library used to store workflow tasks information.", [Microsoft.SharePoint.SPListTemplateType]::Tasks);                
                $wfTasks = $web.Lists[$wfTaskListName]
                $wfTasks.Hidden = $true
                $wfTasks.Update()
            }
            
            $wfHistory = $web.Lists[$wfHistListName]
            $wfTasks = $web.Lists[$wfTaskListName]
            
			#Create new workflow association
            $newworkflowAssociation = [Microsoft.SharePoint.Workflow.SPWorkflowAssociation]::CreateListAssociation($workflowTemplate, $srcworkflowAssociationName, $wfTasks, $wfhistory)
			
			#Set workflow AssociationData and config from source workflow association
			$newworkflowAssociation.AssociationData = $srcworkflowAssociation.AssociationData
            $newworkflowAssociation.AllowManual = $srcworkflowAssociation.AllowManual
			$newworkflowAssociation.AutoStartChange = $srcworkflowAssociation.AutoStartChange
			$newworkflowAssociation.AutoStartCreate = $srcworkflowAssociation.AutoStartCreate
            
			# Optional debug info
			#write-host "ParentWeb: "  -nonewline; write-host $newworkflowAssociation.ParentWeb.Url
			#write-host "HistoryList: " -nonewline;  write-host $newworkflowAssociation.HistoryListTitle
			#write-host "HistoryListID: " -nonewline;  write-host $newworkflowAssociation.HistoryListId
			#write-host "TaskList: " -nonewline;  write-host $newworkflowAssociation.TaskListTitle
			#write-host "TaskListID: " -nonewline;  write-host $newworkflowAssociation.TaskListId
			
			write-host "New Workflow Association Created Succesfully with Following Attributes:"
			write-host ""
			$newworkflowAssociation
			write-host ""
			write-host "Associating New Workflow Association With Target List"
			write-host ""
            
			[guid]$wfId = New-Object Guid
            [bool]$wfFound = $false

            # Optional step if you want to remove the default Page Approval work association from your list
            #foreach ($wf in $listTarget.WorkflowAssociations) {
            #    if($wf.Name -eq "Page Approval"){
            #        Write-Host -Foreground Yellow "Removing Page Approval work flow association from the target list";
            #        $listTarget.WorkflowAssociations.Remove($wf.Id);
            #    }             
            #}
            
			if(!$workflowAssociationName)
			{
				write-host "-workflowAssociationName not provided"
				write-host "Checking for matches using -workflowName: $workflowName (Workflow Template Name)"
	            write-host ""
				foreach ($wf in $listTarget.WorkflowAssociations) {
	                if ($wf.Name -eq $newworkflowAssociation.Name) {
	                    $wfId = $wf.Id
	                    write-host -ForegroundColor Yellow "Workflow " $wf.Name " already exists on the target list:" $listTarget.Title
						write-host -ForegroundColor Yellow ""
	                    $wfFound = $true
	                }
	            }
					            
	            if ($wfFound -eq $true) {
					if($replaceExistingMatchingWorkflows)
					{
		               	write-host -ForegroundColor Yellow "-replaceExistingMatchingWorkflows true"
						# Remove exisiting workflow association
						$listTarget.WorkflowAssociations.Remove($wfId)
		                write-host -ForegroundColor Yellow "Removed workflow" $newworkflowAssociation.Name "from the list: " $listTarget.Title
		                write-host -ForegroundColor Yellow "on the web:"$web
				        Write-Host -ForegroundColor Yellow "Url: " $web.Url
		        		Write-Host -ForegroundColor Yellow ""
						
			          	Add-WorkflowAssociations $listTarget $srcworkflowAssociation $newworkflowAssociation
				    }
					else
					{
						write-host -ForegroundColor Yellow "Rerun MigrateWorkflowAssociation.ps1 using '-replaceExistingMatchingWorkflows true'" 
						write-host -ForegroundColor Yellow "or remove Workflow" $wf.Name "from target list:" $listTarget.Title  "manually" 
					}
				}
				else
				{
				  		Add-WorkflowAssociations $listTarget $srcworkflowAssociation $newworkflowAssociation
				}
            }
			else
			{
				write-host "-workflowAssociationName provided"
				write-host "Checking for matches using -workflowAssociationName: $workflowAssociationName"
	            write-host ""
				foreach ($wf in $listTarget.WorkflowAssociations) {
	                if ($wf.Name -eq $workflowAssociationName) {
	                    $wfId = $wf.Id
	                    write-host -ForegroundColor Yellow "Workflow " $wf.Name " already exists on the target list:" $listTarget.Title
	                    $wfFound = $true
	                }
	            }
					            
	            if ($wfFound -eq $true) {
					if($replaceExistingMatchingWorkflows)
					{
		                # Remove exisiting workflow association
						$listTarget.WorkflowAssociations.Remove($wfId)
		                write-host -ForegroundColor Yellow "Removed workflow" $newworkflowAssociation.Name "from the list: " $listTarget.Title 
		                write-host -ForegroundColor Yellow "on the web:"
		                Write-Host -ForegroundColor Yellow "Name : "$web
				        Write-Host -ForegroundColor Yellow "Url :  " $web.Url
		        
			          	Add-WorkflowAssociations $listTarget $srcworkflowAssociation $newworkflowAssociation
				    }
					else
					{
						write-host -ForegroundColor Yellow "Rerun MigrateWorkflowAssociation.ps1 using '-replaceExistingMatchingWorkflows true'"
						write-host -ForegroundColor Yellow "or remove Workflow" $wf.Name "from target list:" $listTarget.Title  "manually"
					}
				}
				else
				{
				  		Add-WorkflowAssociations $listTarget $srcworkflowAssociation $newworkflowAssociation
				}
			}
    }
}

write-host "Preparing to associate workflow with list."
#

if ($list -ne $null)
{
	write-host "List: "  -nonewline;  $list.Title
	$wfTemplate=$site.workflowtemplates.gettemplatebyname($wfTemplateName, [System.Globalization.CultureInfo]::CurrentCulture);
    
    if(!$wfTemplate)
    {
	   Write-Host -ForegroundColor Red "No workflow installed or activated with this workflowname : " $workflowName "on the web: "
       Write-Host -ForegroundColor Red "Name : " $site
	   Write-Host -ForegroundColor Red "Url  : " $site.Url
    }
	else
	{

		if ($wfTemplate.Name -eq $wfTemplateName) 
		{
			write-host "Template Name: "  -nonewline;  $wfTemplate.Name
			$wfTemplateId = $wfTemplate.Id
			write-host "Template ID: "  -nonewline; write-host $wfTemplateId
			
		}

		write-host "WorkflowAssociations: "  -nonewline;  $list.WorkflowAssociations.Count
		$list.WorkflowAssociations | foreach { Get-WorkflowAssociation($_) }
	}
	
}
else
{
	write-host "ERROR: Could not find source list, association will have to be made manually." -ForegroundColor red
}

#
$site.Dispose()
$targetsite.Dispose()