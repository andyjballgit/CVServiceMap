<# 
 .Synopsis
  for given array of VMNames param , shows Processes that VMs Is using from current live data  

 .Description
 API Call - https://docs.microsoft.com/en-us/rest/api/servicemap/machines#Machines_ListProcesses
  
 Prequisites
 -----------
 #ie.
 AzureRM Modules - tested on 3.4 
 Get-CVAzureRESTAuthHeader func

 Returns 
 -------
 ie 

 Limitations and Known Issues
 ----------------------------
 Only does current Live data, cant do date range

 Backlog 
 --------
 

 Change Log
 ----------
 v1.00 Andy Ball 18/02/2017 Base Version
 

 .Parameter OMSWorkspaceName

 .Parameter ResourceGroupName

 .Parameter SubscriptionName

 .VMNames 
 Array of VMNames 

 .Example
 ToDo

 .Example
 A bit more complicated here

 .Example
 Mind blowing example here

#>

Function Get-CVServiceMapMachineProcesses
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $true, Position = 3)]  [string[]] $VMNames 

         )

    $ErrorActionPreference = "Stop"
    # return this 
    $Resultset = @()
    $VMsCount = @($VMNames).Count
    $CurrentVMNum = 1 

    #Get all Machines here so we can use it as a lookup table of ComputerName to Service Map Machine Name 
    Write-Host "Getting All Machines for lookup table"
    $AllMachines = Get-CVServiceMapMachinesSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName

    ForEach ($VMName in $VMNames)
    {
        # get ServiceMapMachineName 
        # $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -VMName $VMName
        
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

        $uriSuffix = "/machines/$MachineName/processes?api-version=2015-11-01-preview&live=true" 
        $ret = Get-CVServiceMapWrapper -URISuffix $uriSuffix -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName
        #ToDo handle better / may get empty {} resultset ?  
        If ($ret -eq $null)
            {
                Break 
            }
    
        # Roll throw
        ForEach($Process in $ret.value)
            {
                $MonitoringState = $null
  
                $MonitoringState = $Process.properties.monitoringState

                $Resultset += $Process | Select @{Name = "VMName" ; Expression = {$VMName}},
                                             @{Name = "MonitoringState" ; Expression = {$_.properties.monitoringState}}, 
                                             @{Name = "DisplayName" ; Expression = {$_.properties.displayName}},
                                             @{Name = "StartTime" ; Expression = {$_.properties.startTime}},
                                             @{Name = "FirstPID" ; Expression = {$_.properties.details.firstPid}}, 
                                             @{Name = "CompanyName" ; Expression = {$_.properties.details.companyName}} , 
                                             @{Name = "ProductName" ; Expression = {$_.properties.details.productName}} , 
                                             @{Name = "ProductVersion" ; Expression = {$_.properties.details.productVersion}},
                                             @{Name = "RunAsUser" ; Expression = {$_.properties.user.userDomain + "\" + $_.properties.user.userName}},
                                             @{Name = "CommandLine" ; Expression = {$_.properties.details.CommandLine}} 

            }

         $CurrentVMNum++
    }

    $Resultset | Sort VMName, DisplayName, StartTime, FirstPID
}