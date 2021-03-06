﻿<# 
 .Synopsis
 Generic function that calls either _ListPorts, _ListConnections or List_Processes depending on the ListType Param.
 .Description
 API Call - https://docs.microsoft.com/en-us/rest/api/servicemap/machines#Machines_ListPorts
  
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
 v1.00 Andy Ball 18/02/2017 Base Version
 v1.02 Andy Ball 19/02/2017 Fix minor bugs with counting VMs 
 v1.03 Andy Ball 19/02/2017 Add list type , LocalStart/Endtime params
 v1.04 Andy Ball 26/02/2017 Output list of Machines 
 v1.05 Andy Ball 08/03/2017 Add Persistent key which is used between Ports, Connections etc  to link together

 .Parameter OMSWorkspaceName
 ToDo
 
 .Parameter ResourceGroupName
 a
 
 .Parameter SubscriptionName
 a
 
 .Parameter VMNames
 a
 
 .Parameter ListType
 either Live (or inventory , not implemented yet)

 .Parameter LocalStartTime
 when using ListType = Live

 .Parameter LocalEndTime
 when using ListType = Live

 .Example
 ToDo 

 .Example
 A bit more complicated here

 .Example
 Mind blowing example here

#>

Function Get-CVServiceMapMachineList
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $false, Position = 3)]  [string[]] $VMNames, 
            [Parameter(Mandatory = $true, Position = 4)]  [string] [ValidateSet("Ports", "Processes", "Connections")] $ListType = "Connections",
            [Parameter(Mandatory = $false, Position = 5)]  [string] [ValidateSet("Live")] $ResourceType  = "Live", 
            [Parameter(Mandatory = $false, Position = 6)]  [datetime] $LocalStartTime, 
            [Parameter(Mandatory = $false, Position = 7)]  [datetime] $LocalEndTime
            
         )

    $ErrorActionPreference = "Stop"
    # return this 
    $Resultset = @()

    #Get all Machines here so we can use it as a lookup table of ComputerName to Service Map Machine Name 
    Write-Host "Getting All Machines for lookup table"
    $AllMachines = Get-CVServiceMapMachineSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName

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
            $Now = Get-Date
            $LocalEndTime = $Now 
            $LocalStartTime = $Now.AddMinutes(-10)
        }  
    # Convert to JSON / UTC
    $UTCStartTime = Get-CVJSONDateTime -MyDateTime $LocalStartTime -ConvertToUTC $true 
    $UTCStartTime = Get-CVJSONDateTime -MyDateTime $LocalEndTime -ConvertToUTC $true 
        
   
    ForEach ($VMName in $VMNames)
    {
        Write-Host "Processing $VMName ($CurrentVMNum of $VMsCount)" -ForegroundColor Green
        $MachineName = $null 
        $VMNameRecord = $null 

        $VMNameRecord =  $AllMachines | Where {$_.ComputerName -eq $VMName}
        # Barf if lookup fails, Get-CVServiceMapMachineName outputs the warning
        If ($VMNameRecord -eq $null)
            {
                Write-Warning "`tCant find VMName = $VMName in List of All Service Map Machines:"
                $AllMachines | Out-String
                Break
            }

        $MachineName = $VMNameRecord.MachineName

        $uriSuffix = "/machines/$MachineName/" + $ListType.ToLower() + "?api-version=2015-11-01-preview&live=true&" + $UTCStartTime + "&" + $UTCEndTime  
        $ret = Get-CVServiceMapWrapper -URISuffix $uriSuffix `
                                       -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -AzureRestHeader $AuthHeader


        #ToDo handle better / may get empty {} resultset ?  
        If ($ret -eq $null)
            {
                Break 
            }
    
        # Roll through all the returned resources 
        ForEach($Resource in $ret.value)
            {
                $MonitoringState = $null
                $MonitoringState = $Resource.properties.monitoringState

                # Add to resultset depending on ListType
                Switch($ListType)
                    {
                        "Ports"
                            {
                                $Resultset += $Resource | Select @{Name = "VMName" ; Expression = {$VMName}},
                                             @{Name = "MonitoringState" ; Expression = {$_.properties.monitoringState}}, 
                                             @{Name = "DisplayName" ; Expression = {$_.properties.displayName}},
                                             @{Name = "IPAddress" ; Expression = {$_.properties.ipAddress}},
                                             @{Name = "PortNumber" ; Expression = {$_.properties.PortNumber}}, 
                                             @{Name = "MachineName" ; Expression = {$MachineName}},
                                             @{Name = "persistantKey" ; Expression = {$_.properties.details.persistentkey}}
                            }

                        "Connections"
                            {
                                $Resultset +=  $Resource| Select @{Name = "VMName" ; Expression = {$VMName}},
                                                                 @{Name = "MonitoringState" ; Expression = {$MonitoringState}}, 
                                                                 @{Name = "SourceName" ; Expression = {$_.properties.source.name}} , 
                                                                 @{Name = "SourceType" ; Expression = {$_.properties.source.kind}} , 
                                                                 @{Name = "DestinationName" ; Expression = {$_.properties.destination.name}}, 
                                                                 @{Name = "DestinationType" ; Expression = {$_.properties.destination.kind}}, 
                                                                 @{Name = "ServerPortType" ; Expression = {$_.properties.ServerPort.kind}}, 
                                                                 @{Name = "ServerPort" ; Expression = {$_.properties.ServerPort.properties.portNumber}}, 
                                                                 @{Name = "DestIPAddresses" ; Expression = {$_.properties.ServerPort.properties.ipAddress}} , 
                                                                 @{Name = "FailureState" ; Expression = {$_.properties.FailureState}},
                                                                 @{Name = "persistantKey" ; Expression = {$_.properties.details.persistentkey}}

                                                                  

                             }

                        "Processes"
                            {
                                $Resultset += $Resource | Select @{Name = "VMName" ; Expression = {$VMName}},
                                                                 @{Name = "MonitoringState" ; Expression = {$_.properties.monitoringState}}, 
                                                                 @{Name = "DisplayName" ; Expression = {$_.properties.displayName}},
                                                                 @{Name = "StartTime" ; Expression = {$_.properties.startTime}},
                                                                 @{Name = "FirstPID" ; Expression = {$_.properties.details.firstPid}}, 
                                                                 @{Name = "CompanyName" ; Expression = {$_.properties.details.companyName}} , 
                                                                 @{Name = "ProductName" ; Expression = {$_.properties.details.productName}} , 
                                                                 @{Name = "ProductVersion" ; Expression = {$_.properties.details.productVersion}},
                                                                 @{Name = "RunAsUser" ; Expression = {$_.properties.user.userDomain + "\" + $_.properties.user.userName}},
                                                                 @{Name = "poolid" ; Expression = {$_.properties.details.poolid}},
                                                                 @{Name = "InternalName" ; Expression = {$_.properties.details.InternalName}},
                                                                 @{Name = "ExecutableName" ; Expression = {$_.properties.ExecutableName}},
                                                                 @{Name = "persistantKey" ; Expression = {$_.properties.details.persistentkey}},
                                                                 @{Name = "CommandLine" ; Expression = {$_.properties.details.CommandLine}}
                                                                 
                            }

                        "Default"
                            {
                                throw "$ListType not expected"
                            }

            }

        }
    
        
        $CurrentVMNum++
    } #ForEach VM

    #
    $Resultset # | Sort MachineName, IPAddress, PortNumber 
}