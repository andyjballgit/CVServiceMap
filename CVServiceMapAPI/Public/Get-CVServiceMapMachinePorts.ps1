<# 
 .Synopsis
  Single line , succinct summary of what func does

 .Description
 API Call - https://docs.microsoft.com/en-us/rest/api/servicemap/machines#Machines_ListPorts
  
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
 ie if had to shortcut / do a shonky 

 Backlog 
 --------
 May include above , but generally improvements , expanding functionality 

 Change Log
 ----------
 v1.00 Andy Ball 17/02/2017 Base Version
 

 .Parameter Param1

 .Parameter Param2

 .Example
 Put simplest example here 

 .Example
 A bit more complicated here

 .Example
 Mind blowing example here

#>

Function Get-CVServiceMapMachinePorts
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

        $uriSuffix = "/machines/$MachineName/ports?api-version=2015-11-01-preview" 
        $ret = Get-CVServiceMapWrapper -URISuffix $uriSuffix -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName
        #ToDo handle better / may get empty {} resultset ?  
        If ($ret -eq $null)
            {
                Break 
            }
    
        # Roll throw
        ForEach($Port in $ret.value)
            {
                $MonitoringState = $null
  
                $MonitoringState = $Port.properties.monitoringState

                <# doh this is redundant as is always the Machine you are checking
                # ie if monitored , means that it ServiceMap installed, so lets get its real name 
                If ($MonitoringState -eq "monitored")
                    {
                        # find the Target VM 
                        $MachineName = $Port.properties.machine.name
                        $VMNameRecord =  $AllMachines | Where {$_.MachineName -eq $MachineName}
                        If($VMNameRecord -ne $null)
                            {
                                $VMName = $VMNameRecord.ComputerName
                            }
                    }
                #>
                $Resultset += $Port | Select @{Name = "VMName" ; Expression = {$VMName}},
                                             @{Name = "MonitoringState" ; Expression = {$_.properties.monitoringState}}, 
                                             @{Name = "DisplayName" ; Expression = {$_.properties.displayName}},
                                             @{Name = "IPAddress" ; Expression = {$_.properties.ipAddress}},
                                             @{Name = "PortNumber" ; Expression = {$_.properties.PortNumber}}, 
                                             @{Name = "MachineName" ; Expression = {$MachineName}}
            }

         $CurrentVMNum++
    }

    $Resultset | Sort MachineName, IPAddress, PortNumber 
}