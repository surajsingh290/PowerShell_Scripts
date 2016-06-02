param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Content Type Publishing SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath

    #Write-Host "Starting script $ScriptName" -BackgroundColor Yellow -ForegroundColor Black


    
Function Main()
{
	try 
	{
		#Get the Target Web
		$CTHsiteUrl = $ConfigFile.Settings.ContentTypePublishingScript.CTHsiteUrl
		$CCsiteUrl = $ConfigFile.Settings.ContentTypePublishingScript.CCsiteUrl
		$CTHJob = $ConfigFile.Settings.ContentTypePublishingScript.CTHJob
		$CTSJob = $ConfigFile.Settings.ContentTypePublishingScript.CTSJob
		$ContentTypeGroup = $ConfigFile.Settings.ContentTypePublishingScript.ContentTypeGroup
		$SyndicationHubFeatureId = $ConfigFile.Settings.ContentTypePublishingScript.SyndicationHubFeatureId

		$site = new-object Microsoft.SharePoint.SPSite($CTHsiteUrl)
		$cts = $site.rootweb.ContentTypes
		$ctsCustom = $cts | where { $_.Group -eq $ContentTypeGroup}

			#Activate the "Content Type Syndication Hub" feature

			#Write-Host "Enable Content Type Syndication Hub Feature"
			if (![Microsoft.SharePoint.Taxonomy.ContentTypeSync.ContentTypePublisher]::IsContentTypeSharingEnabled($CTHsiteUrl))
			{
			Enable-SpFeature -Identity $SyndicationHubFeatureId -Url $CTHsiteUrl
			}
	
		#Write-Host "Enabled Content Type Syndication Hub Feature"
		Add-Content $logFilePath "`n Content Type Syndication Hub Feature Enabled"

			#Below code will "Publish" the Content Type. If already published "RePublish"
			$Publisher = New-Object Microsoft.SharePoint.Taxonomy.ContentTypeSync.ContentTypePublisher($site)
			Foreach($ContentType in $ctsCustom)
			{	
			#Write-Host "Publishing " $ContentType.Name
			$Publisher.Publish($ContentType)
			}

		$SPsite = Get-SPSite $CCsiteUrl

		#Write-Host "Refresh Content Types for site"
		Add-Content $logFilePath "`n Refresh Content Types for site"
		#Calling Publishing Function
		RemoveAllTimeStamps $SPsite
		#Write-Host "Content Types refreshed for site"
		Add-Content $logFilePath "`n Content Types refreshed for site"
		#Write-Host "Execute Timer Jobs"
		Add-Content $logFilePath "`n Execute Timer Jobs"
		$jobNames = @($CTHJob,$CTSJob)
		ExecuteTimerJobs $jobNames
		#Write-Host "Executed Timer Jobs"
		Add-Content $logFilePath "`n Executed Timer Jobs"
    }
    catch
    {
		$ErrorMessage = $_.Exception.Message
		Add-Content $logFilePath "`n Exception occured in main method :::::: $($ErrorMessage)"
    }
}
    
Function RemoveAllTimeStamps([Microsoft.SharePoint.SPSite] $site)
{   
	if ($site -eq $null) { return }
	$rootWeb = $site.RootWeb
	if ($rootWeb.Properties.ContainsKey('MetadataTimeStamp'))
	{
		$rootWeb.Properties['MetadataTimeStamp'] = [string]::Empty
		$rootWeb.Properties.Update()
	}
}

Function ExecuteTimerJobs( [string[]] $jobNames)
{
	try
	{
		Foreach($jobName in $jobNames)
		{
			#Write-Host "Executing Timer Job - " $jobName
			##Getting right job
			Add-Content $logFilePath "`n Executing Timer Job"
			$jobs = Get-SPTimerJob | ?{$_.displayname -match $jobName}
			foreach($job in $jobs)
			{
				#Write-Host "*****************" $job
				if($null -ne $job)
				{
					$startet = $job.LastRunTime
					#Write-Host -ForegroundColor Yellow -NoNewLine "Running" $job.DisplayName "Timer Job."
					Add-Content $logFilePath "`n Running"
					Start-SPTimerJob $job

					##Waiting until job has finished
					while (($startet) -eq $job.LastRunTime)
					{
						#Write-Host -NoNewLine -ForegroundColor Yellow "."
						Start-Sleep -Seconds 2
					}

					##Checking for error messages, assuming there will be errormessage if job fails
					if($job.ErrorMessage)
					{
						#Write-Host -ForegroundColor Red "Possible error in" $job.DisplayName "timer job:";
						#Write-Host "LastRunTime:" $lastRun.Status;
						#Write-Host "Errormessage:" $lastRun.EndTime;
					}
					else 
					{
						#Write-Host -ForegroundColor Green $job.DisplayName " Timer Job has completed.";
						Add-Content $logFilePath "`n Timer Job has completed."

					}
				}
				else 
				{
					#Write-Host -ForegroundColor Red "ERROR: Timer job " $job.DisplayName
				}
			}
		}

	}
	catch
	{
		$ErrorMessage = $_.Exception.Message
		Add-Content $logFilePath "`n Exception occured in  Executing TimerJobs :::::: $($ErrorMessage)"
	}

}

#Calling Main Method
Main