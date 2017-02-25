<# 
 .Synopsis
 Returns the "liveness" of specified VM(s) for the given start/Endtime (if specfied, if not last 10 mins). liveness means that it was up and running and delivering ServiceMap data during the time period. 
 .Description
 API Call - https://docs.microsoft.com/en-us/rest/api/servicemap/machines#Machines_GetLiveness

 Prequisites
 -----------
 #ie.
 AzureRM Modules - tested on 3.4 
 Get-CVAzureRESTAuthHeader func

 Returns 
 -------
 List of type of resource specified 

 Limitations and Known Issues
 ----------------------------
 

 Backlog 
 --------
 
 Change Log
 ----------
 v1.00 Andy Ball 25/02/2017 Base Version


 .Parameter OMSWorkspaceName
 OMS Workspace name where Service Map is queries
 
 .Parameter ResourceGroupName
 ResourceGroup where OMS is hosted 
 
 .Parameter SubscriptionName
 SubscriptionName where OMS Is hosted 
 
 .Parameter VMNames
 VMNames to check 
 
 .Parameter LocalStartTime
 when using ListType = Live

 .Parameter LocalEndTime
 when using ListType = Live

 .Example 
  Return for all ServiceMap Machines in the last 10 mins - ie default if no local StartTIme

  $OMSWorkspace = "MyOMSWorkspaceName"
  $ResourceGroupName = "ItsResourceGroup£"
  $SubscriptionName = "Bizspark"

  $ret = Get-CVServiceMapMachineLiveness -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName 
  $ret

 .Example
  $OMSWorkspace = "MyOMSWorkspaceName"
  $ResourceGroupName = "ItsResourceGroup"
  $SubscriptionName = "Bizspark"

  $LocalEndTime = Get-Date 
  $LocalStartTime = $LocalEndTime.AddDays(-1)
  
  $ret = Get-CVServiceMapMachineLiveness -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -LocalStartTime $LocalStartTime -LocalEndTime = $LocalEndTime
  $ret


  

 .Example
 Mind blowing example here

#>

Function Get-CVServiceMapMachineLiveness
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $false, Position = 3)]  [string[]] $VMNames, 
            [Parameter(Mandatory = $false, Position = 6)]  [datetime] $LocalStartTime, 
            [Parameter(Mandatory = $false, Position = 7)]  [datetime] $LocalEndTime
            
         )

    $ErrorActionPreference = "Stop"
    # return this 
    $Resultset = @()

    #ToDo Refactor ? 



    #Get all Machines here so we can use it as a lookup table of ComputerName to Service Map Machine Name 
    Write-Host "Getting All Machines for lookup table"
    $AllMachines = Get-CVServiceMapMachinesSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName

    If ([string]::IsNullOrWhiteSpace($VMNames))
        {
            $VMNames = @()
            ForEach($VMName in $AllMachines.ComputerName)
                {
                    $VMNames += $VMName
                }
        } 

    $VMsCount = @($VMNames).Count
    [int] $CurrentVMNum = 1

    # Get here so we don't have to call per VM 
    $AuthHeader = Get-CVAzureRESTAuthHeader 

    # ie if not past set to the default
    If (([string]::IsNullOrWhiteSpace($LocalEndTime)) -AND ([string]::IsNullOrWhiteSpace($LocalStartTime)))
        {
            Write-Verbose "Using default 10 mins"
            $Now = Get-Date
            $LocalEndTime = $Now 
            $LocalStartTime = $Now.AddMinutes(-10)
        }  
    Else
        {
            # 25th Feb 2017 we have a range so need to check not > 60 mins otherwise will get "invalid time range" as currently 60 mins the max
            $Timespan = New-TimeSpan -Start $LocalStartTime -End $LocalEndTime
            If($Timespan.TotalSeconds -gt 3600)
                {
                    Write-Warning "Error : Maximum difference between LocalStartTime($LocalStartTime) And LocalEndTime($LocalEndTime) is 60 mins. Quitting"
                    Break
                }
        }
        
   
    ForEach ($VMName in $VMNames)
    {
        Write-Host "Processing $VMName ($CurrentVMNum of $VMsCount)" -ForegroundColor Green
        $MachineName = $null 
        $VMNameRecord = $null 

        $VMNameRecord =  $AllMachines | Where {$_.ComputerName -eq $VMName}
        # Barf if lookup fails, Get-CVServiceMapMachineName outputs the warning
        If ($VMNameRecord -eq $null)
            {
                Write-Warning "`tCant find VMName = $VMName in List of All Service Map Machines"
                Break
            }

        $MachineName = $VMNameRecord.MachineName
        
        $uriSuffix = "/machines/$MachineName/liveness?api-version=2015-11-01-preview"
        $ret = Get-CVServiceMapWrapper -URISuffix $uriSuffix `
                                       -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -AzureRestHeader $AuthHeader `
                                       -LocalStartTime $LocalStartTime `
                                       -LocalEndTime $LocalEndTime

        #ToDo handle better / may get empty {} resultset ?  
        If ($ret -eq $null)
            {
                Break 
            }
    
        $Resultset += $ret | Select @{Name = "VMName" ; Expression = {$VMName}}, 
                                    @{Name = "MachineName" ; Expression = {$MachineName}},
                                    *

        
    
        
        $CurrentVMNum++
    } #ForEach VM

    #
    $Resultset # | Sort MachineName, IPAddress, PortNumber 
}