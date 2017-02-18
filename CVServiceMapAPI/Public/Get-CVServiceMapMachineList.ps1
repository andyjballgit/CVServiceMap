<# 
 .Synopsis
 Generic function that calls either _ListPorts, _ListConnections or List_Processes depending on the ListType Param
 .
 Description
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
 

 .Parameter OMSWorkspaceName

 .Parameter ResourceGroupName

 .Parameter SubscriptionName

 .Parameter VMNames

 .Parameter ListType

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
            [Parameter(Mandatory = $true, Position = 4)]  [string] [ValidateSet("Ports", "Processes", "Connections")] $ListType = "Connections"
            
         )

    $ErrorActionPreference = "Stop"
    # return this 
    $Resultset = @()
    $VMsCount = @($VMNames).Count
    [int] $CurrentVMNum = 1

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

        $uriSuffix = "/machines/$MachineName/" + $ListType.ToLower() + "?api-version=2015-11-01-preview" 
        $ret = Get-CVServiceMapWrapper -URISuffix $uriSuffix -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName
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
                                             @{Name = "MachineName" ; Expression = {$MachineName}}
                            }

                        "Connections"
                            {
                                $Resultset +=  $Resource| Select @{Name = "VMName" ; Expression = {$VMName}},
                                                                 @{Name = "SourceName" ; Expression = {$_.properties.source.name}} , 
                                                                 @{Name = "SourceType" ; Expression = {$_.properties.source.kind}} , 
                                                                 @{Name = "DestinationName" ; Expression = {$_.properties.destination.name}}, 
                                                                 @{Name = "DestinationType" ; Expression = {$_.properties.destination.kind}}, 
                                                                 @{Name = "ServerPortType" ; Expression = {$_.properties.ServerPort.kind}}, 
                                                                 @{Name = "ServerPort" ; Expression = {$_.properties.ServerPort.properties.portNumber}}, 
                                                                 @{Name = "DestIPAddresses" ; Expression = {$_.properties.ServerPort.properties.ipAddress}} , 
                                                                 @{Name = "FailureState" ; Expression = {$_.properties.FailureState}}

                                                                  

                             }

                        "Processes"
                            {
                                $Resultset += $Resource | Select @{Name = "MonitoringState" ; Expression = {$_.properties.monitoringState}}, 
                                                                 @{Name = "DisplayName" ; Expression = {$_.properties.displayName}},
                                                                 @{Name = "StartTime" ; Expression = {$_.properties.startTime}},
                                                                 @{Name = "FirstPID" ; Expression = {$_.properties.details.firstPid}}, 
                                                                 @{Name = "CompanyName" ; Expression = {$_.properties.details.companyName}} , 
                                                                 @{Name = "ProductName" ; Expression = {$_.properties.details.productName}} , 
                                                                 @{Name = "ProductVersion" ; Expression = {$_.properties.details.productVersion}},
                                                                 @{Name = "RunAsUser" ; Expression = {$_.properties.user.userDomain + "\" + $_.properties.user.userName}},
                                                                 @{Name = "CommandLine" ; Expression = {$_.properties.details.CommandLine}}     
                            }

                        "Default"
                            {
                                throw "$ListType not expected"
                            }

            }

         $CurrentVMNum++
    }
    
    } #ForEach VM

    #
    $Resultset # | Sort MachineName, IPAddress, PortNumber 
}