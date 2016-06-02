param ($path)

$logFilePath =$("$path\LOGS\PowershellLogs.txt")

#Add-Content $logFilePath "Path is $($path)"
if(-not(Get-PSSnapin | where { $_.Name -eq "Microsoft.SharePoint.PowerShell"}))
{
	Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue 
}
Add-Content $logFilePath "`n -----------------------------------"
Add-Content $logFilePath "`n Script Name: Deploy Room Timer Job SOM"
Add-Content $logFilePath "`n Begin Execution : $(Get-Date -f dd_MM_yyyy_hhmmss) `n"

$xmlFilePath = $("$path\PSConfig.xml")
[xml]$ConfigFile = Get-Content $xmlFilePath
$RootDir = Split-Path -Parent $path 

try
{
	$ConfigFile = [xml](get-content $xmlFilePath)
	Add-Content $logFilePath "`n XML file loaded successfully"
}
catch
{
	$ErrorMessage = $_.Exception.Message
	Add-Content $logFilePath "`n Exception Occured :::::: $($ErrorMessage)" 
}
    
     
################ Wait Timer Function ##########################################################################

  
 function wait4timer($solutionName)
 {   
     $solution = Get-SPSolution | where-object {$_.Name -eq $solutionName}   
     if ($solution -ne $null)    
     {       
         ##Write-Host "Waiting to finish soultion timer job" -ForegroundColor Green     
         while ($solution.JobExists -eq $true )         
         {              
             ##Write-Host "Please wait...Either a Retraction/Deployment is happening" -ForegroundColor DarkYellow          
             sleep 2           
         }               
  
         ##Write-Host "Finished the solution timer job" -ForegroundColor Green 
          
     }
 } 

################End of Wait Timer Function ##########################################################################


try
{
      	# Get the WebApplicationURL
        $MyWebApplicationUrl = $ConfigFile.Settings.DeployRoomTimerJob.webAppUrl
	Add-Content $logFilePath "`n MyWebApplicationUrl :::: $($MyWebApplicationUrl)" 

        #Feature ID of The Timer Job
        $FeatureID= $ConfigFile.Settings.DeployRoomTimerJob.TimerJobFeatureId  
        $TimerJobPath= $ConfigFile.Settings.DeployRoomTimerJob.TimerJobPath
  
	foreach($Mywsp in $ConfigFile.Settings.DeployRoomTimerJob.SolutionName)
	{    
         	# Get the Solution Name
         	$MywspName = $Mywsp.Attributes['Name'].value
	Add-Content $logFilePath "`n Solution Name :::: $($MywspName)" 

          
         	# Get the Path of the Solution
         	#$MywspFullPath = $RootDir+ $TimerJobPath+ $MywspName
         	$MywspFullPath = $TimerJobPath + $MywspName

	Add-Content $logFilePath "`n Solution Path :::: $($MywspFullPath)" 

  
		if (Test-Path -path $MywspFullPath -PathType Leaf)
		{
         		# Try to get the Installed Solutions on the Farm.
         		$MyInstalledSolution = Get-SPSolution | Where-Object Name -eq $MywspName
          		
         		# Verify whether the Solution is installed on the Target Web Application
         		if($MyInstalledSolution -ne $null)
         		{
             			if($MyInstalledSolution.DeployedWebApplications.Count -gt 0)
             			{
                 			wait4timer $MywspName 
  
                 			# Solution is installed in atleast one WebApplication.  Hence, uninstall from all the web applications.
                 			# We need to unInstall from all the WebApplicaiton.  If not, it will throw error while Removing the solution
                 			Uninstall-SPSolution $MywspName  -AllWebApplications:$true -confirm:$false
  
                 			# Wait till the Timer jobs to Complete
                 			wait4timer $MywspName 
  
                 			##Write-Host "Remove the Solution from the Farm" -ForegroundColor Green
                 			# Remove the Solution from the Farm
                 			Override-SPSolution $MywspName -Confirm:$false -Force
  
                 			sleep 3
             			}
             			else
             			{
                 			wait4timer $MywspName
  
                 			# Solution not deployed on any of the Web Application.  Go ahead and Remove the Solution from the Farm
                 			Remove-SPSolution $MywspName -Confirm:$false
  
                 			sleep 3
             			}
         		}
  			
         		#wait4timer $MywspName
  
         		# Add Solution to the Farm
         		Add-SPSolution -LiteralPath "$MywspFullPath"
      
         		# Install Solution to the WebApplication
         		install-spsolution -Identity $MywspName  -GACDeployment:$true 
  
         		# Let the Timer Jobs get finishes      
         		wait4timer $MywspName   
  
         		##Write-Host "Successfully Deployed to the WebApplication" -ForegroundColor Green
	Add-Content $logFilePath "`n Successfully Deployed to the WebApplication" 

		}
		else
		{
			##Write-Host "$xmlContentTypesFilePath not found." -BackgroundColor Yellow -ForegroundColor Black
	Add-Content $logFilePath "`n Path Not Found !!!" 

		}
	}
         
       	##############Activate Wb App Feature ###############
       
       	$Feature = Get-SPFeature -Identity $FeatureID -ErrorAction SilentlyContinue
        If ($Feature.Scope -eq [Microsoft.SharePoint.SPFeatureScope]::WebApplication)
        {
            	$Feature = Get-SPFeature -Identity $FeatureID -WebApplication $MyWebApplicationUrl -ErrorAction SilentlyContinue
            	Enable-SPFeature -Identity $FeatureID -Url $MyWebApplicationUrl  -Confirm:$false 
        }
        ElseIf ($Feature.Scope -eq [Microsoft.SharePoint.SPFeatureScope]::Site)
        {
            	$Feature = Get-SPFeature -Identity $FeatureID -Site $MyWebApplicationUrl -ErrorAction SilentlyContinue
            	Enable-SPFeature -Identity $FeatureID -Url $MyWebApplicationUrl  -Confirm:$false 
        }
       
       
       	########End of Web App Feature#########################

       	#######Reset OWSTimer###################################
       	$farm = Get-SPFarm
       	$farm.TimerService.Instances | foreach { $_.Stop(); $_.Start(); }
       	################################################################          
     	
}
catch
{
       ##Write-Host "Exception Occuerd on DeployWSP : " $Error[0].Exception.Message -ForegroundColor Red 
	Add-Content $logFilePath "`n Exception Occuerd on DeployWSP" 

}
     
     
     