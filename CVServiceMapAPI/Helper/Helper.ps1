﻿
<# Helper.ps1 

Helper / Unit type tests for Service Map APO calls 

v1.00 Andy Ball 22/2/2017 Base Version
#>

$ErrorActionPreference = "Stop"
# Import-Module C:\Workarea\Repos\CVServiceMapAPI\CVServiceMapAPI\CVServiceMapAPI -Force -Verbose
Import-Module C:\Users\Aball\Source\Repos\CVServiceMap\CVServiceMapAPI\CVServiceMapAPI -Verbose -Force 


# Change these values
$VMNames = @("SomeServer")
$VMName = "Someserver"

$SubscriptionName = "Live"
Write-Host "Selecting Subscription = $SubscriptionName"
Select-AzureRmSubscription -SubscriptionName $SubscriptionName

Write-Host "Getting workspaces"
$OMSWorkspaces = $null 
$OMSWorkspaces = Get-AzureRmOperationalInsightsWorkspace 

If (@($OMSWorkspaces).Count -eq 1)
    {
       $OMSWorkspaceName = $OMSWorkspaces[0].Name 
       $ResourceGroupName = $OMSWorkspaces[0].ResourceGroupName
       Write-Host "Using Workspace = $OMSWorkspaceName in RG = $ResourceGroupName"
    }
Else
    {
        If ($OMSWorkspaces -eq $null)
            {
                Write-Host "No OMS Workspaces found in Subscription = $SubscriptionName"
            }
        Else
            {
                $OMSWorkspaces | Select Name, ResourceGroupName | Out-String 
            }
        Break 
    }

$LocalEndTime = (Get-Date)
$LocalStartTime = (Get-Date).AddMinutes(-60)


$DoMissingADGroup = $true 
$DoServiceMapRAW = $false
$DoServiceMapLiveness = $false 
$DoServiceMapMachineLiveNess = $false
$DoServiceMapMachineSummary = $false
$DoServiceMapSummary = $false
$DoServiceMap = $false
$DoServiceMapAll = $false
$DoServiceMapConnections = $false
$DoServiceMapPorts = $false
$DoServiceMapProcesses = $false

$DoMachineByNameWithDate = $false 

$DoServiceMapLivenessRAW = $False
$DoServiceMapConnectionsRAW = $false
$DoServiceMapMachineSummaryRAW = $false 
$DoServiceMapMachineGroupsRAW = $false
$DoGetConnectionsFromProcess = $false



If ($DoMissingADGroup)
{
    Write-Host ("*** Running DoMissingADGroup @ " + (Get-Date)) -ForegroundColor Magenta
    $ADGroupName = "ServiceMapDependencyAgent-1.0"
    $PingMissingComputers = $true 

    $Results = Get-CVServiceMapMissingByADGroup -OMSWorkspaceName $OMSWorkspaceName `
                                            -ResourceGroupName $ResourceGroupName `
                                            -SubscriptionName $SubscriptionName `
                                            -ADGroupName $ADGroupName `
                                            -PingMissingComputers $PingMissingComputers `
                                            -Verbose

    $Results | Sort ComputerName | FT 
    $Results | Group-Object -Property Found 


}

If ($DoGetConnectionsFromProcess)
    {
        $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -VMName $VMName
        $MachineName 
        $ResourceName = "MicrosoftDependencyAgent:5d088927:a582f539:0:28ca2366"

        $uri = "/machines/$machinename/processes" + "?api-version=2015-11-01-preview" 
        $res = Get-CVServiceMapWrapper  -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -URISuffix $uri -RESTMethod GET -ReturnType PSObject
   

        $ProcessName = "p-9658bb1959ff2a532feb37d73ed33c56207584f5"

        # $ProcessName =  "p-a0968afbe7eb4c53459461d3f5a14dbf3581ded0"
        $uri = "/machines/$machinename/Processes/$ProcessName/Connections" + "?api-version=2015-11-01-preview" 
        
        $Connections = Get-CVServiceMapWrapper  -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -URISuffix $uri -RESTMethod GET -ReturnType PSObject
        $Connections

        #$res | ConvertTo-Json -Depth 100 | Out-File "c:\temp\Process.json" 
        #code  "c:\temp\Process.json" 
        Break
    }

If ($DoServiceMapRAW)
{

     # $uriSuffix = "/machines/$VMName/liveness?api-version=2015-11-01-preview" 
     $uriSuffix = "/machines?api-version=2015-11-01-preview" 
        $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -URISuffix $uriSuffix `
                                       -ReturnType JSON        
                                       

        $JSONOutputFileName = "C:\temp\ServiceMap\MachineGroups.json"
        $ret | Out-File -FilePath $JSONOutputFileName
        Code $JSONOutputFileName
    
}

If($DoServiceMapLiveness)
    {

     Write-Host ("*** Running DoServiceMapLiveness @ " + (Get-Date)) -ForegroundColor Magenta
     $ret = Get-CVServiceMapMachineLiveness -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -LocalStartTime $LocalStartTime -LocalEndTime $LocalEndTime
     $ret

    }

If ($DoServiceMapMachineSummary)
    {

        Write-Host ("*** Running DoServiceMapMachineSummary @ " + (Get-Date)) -ForegroundColor Magenta
        $LocalTimestamp = (Get-Date).AddDays(-10)
        $VMStatusSubscriptionNames = @("Converted Windows Azure MSDN - Visual Studio Ultimate")
        Get-CVServiceMapMachineSummary -OMSWorkspaceName $OMSWorkspaceName `
                                        -ResourceGroupName $ResourceGroupName `
                                        -SubscriptionName $SubscriptionName `
                                        -ShowAllVMsStatus $true `
                                        -VMsStatusSubscriptionNames $VMStatusSubscriptionNames `
                                        -LocalTimeStamp $LocalTimestamp | Export-CSV -Path "c:\temp\MachineNames.csv" -Force -NoTypeInformation
        . "c:\temp\MachineNames.csv"
    }

If ($DoServiceMapSummary)
    {
        Write-Host ("*** Running DoServiceMapSummary @ " + (Get-Date)) -ForegroundColor Magenta
        $ret = Get-CVServiceMapSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -LocalStartTime $LocalStartTime -LocalEndTime $LocalEndTime 
        $ret 
    }

If($DoServiceMap)
    {
       Write-Host ("*** Running DoServiceMap @ " + (Get-Date)) -ForegroundColor Magenta
       $ret = Get-CVServiceMap -VMName $VMNames -SubscriptionName $SubscriptionName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -MapType map:single-Machine-dependency -LocalStartTime $LocalStartTime -LocalEndTime $LocalEndTime
       $ret | ConvertTo-JSON -Depth 100 | Out-File "c:\temp\ServiceMap\ServiceMap.json"
       Code "c:\temp\ServiceMap\ServiceMap.json"
    }

If($DoServiceMapAll)
    {
       Write-Host ("*** Running DoServiceMapAll @ " + (Get-Date)) -ForegroundColor Magenta
       $ret = Get-CVServiceMap -SubscriptionName $SubscriptionName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -MapType map:single-Machine-dependency 
       $ret | ConvertTo-JSON -Depth 100 | Out-File "c:\temp\ServiceMap\ServiceMapAll.json"
       Code "c:\temp\ServiceMap\ServiceMapAll.json"
    }


If($DoServiceMapConnections)
    {
        Write-Host ("*** Running DoServiceMapConnections @ " + (Get-Date)) -ForegroundColor Magenta
        $ret = Get-CVServiceMapMachineList -SubscriptionName $SubscriptionName `
                                                -OMSWorkspaceName $OMSWorkspaceName `
                                                -ResourceGroupName $ResourceGroupName `
                                                -ListType Connections `
                                                -VMNames $VMNames `
                                                -LocalStartTime $LocalStartTime `
                                                -LocalEndTime $LocalEndTime
        $ret | ft
        #ret.properties | convertto-json -Depth 100 | Out-File "c:\temp\ServiceMap\Connections.json"
        # code "c:\temp\ServiceMap\Connections.json"
        $ret | Export-CSV -Path "c:\temp\Connections.csv" -Force -NoTypeInformation 
    }

If($DoServiceMapPorts)
    {
        Write-Host ("*** Running DoServiceMapPorts @ " + (Get-Date)) -ForegroundColor Magenta
        $ret = Get-CVServiceMapMachineList -SubscriptionName $SubscriptionName `
                                                -OMSWorkspaceName $OMSWorkspaceName `
                                                -ResourceGroupName $ResourceGroupName `
                                                -ListType Ports `
                                                -VMNames $VMNames `
                                                -LocalStartTime $LocalStartTime `
                                                -LocalEndTime $LocalEndTime
        $ret | ft
        $ret | Export-CSV -Path "c:\temp\Ports.csv" -Force -NoTypeInformation 
        #$ret.properties | convertto-json -Depth 100 | Out-File "c:\temp\ServiceMap\Connections.json"
        #code "c:\temp\ServiceMap\Connections.json"
    }

If($DoServiceMapProcesses)
    {
        Write-Host ("*** Running DoServiceMapProcesses @ " + (Get-Date)) -ForegroundColor Magenta
        $ret = Get-CVServiceMapMachineList -SubscriptionName $SubscriptionName `
                                                -OMSWorkspaceName $OMSWorkspaceName `
                                                -ResourceGroupName $ResourceGroupName `
                                                -ListType Processes `
                                                -VMNames $VMNames `
                                                -LocalStartTime $LocalStartTime `
                                                -LocalEndTime $LocalEndTime
        $ret | fl
        #$ret.properties | convertto-json -Depth 100 | Out-File "c:\temp\ServiceMap\Connections.json"
        #code "c:\temp\ServiceMap\Connections.json"
        
        $ret | export-csv -Path "c:\temp\Process.csv" -Force -NoTypeInformation
        . "c:\temp\Process.csv"

    }



If($DoMachineByNameWithDate)
    {
        Write-Host ("*** Running DoServiceMapMachineSummary @ " + (Get-Date)) -ForegroundColor Magenta
        # Change these $LocalStartTime = (Get-Date).AddDays(-5)
        $LocalEndTime = Get-Date 

        # Lookup "unfriendly" ServiceMap MachineName based on VMName
        $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -VMName $VMName -SubscriptionName $SubscriptionName

        # call API
        $uriSuffix = "/machines/$MachineName/processes?api-version=2015-11-01-preview" 
        $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -ReturnType JSON `
                                       -URISuffix $uriSuffix `
                                       -LocalStartTime $LocalStartTime `
                                       -LocalEndTime $LocalEndTime 
                               

        $ret 
    }



If ($DoServiceMapLiveNessRAW)
    {
        Write-Host ("*** Running $DoServiceMapLiveNessRAW @ " + (Get-Date)) -ForegroundColor Magenta
        # Lookup "unfriendly" ServiceMap MachineName based on VMName
        $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -VMName $VMName -SubscriptionName $SubscriptionName

        #$EndTime = Get-CVJSONDateTime -MyDateTime $LocalEndTime -ConvertToUTC $true 
        #$StartTime = Get-CVJSONDateTime -MyDateTime $LocalStartTime -ConvertToUTC $true 

        $uriSuffix = "/machines/$MachineName/liveness?api-version=2015-11-01-preview&startTime=$StartTime&endTime=$EndTime"
        $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -URISuffix $uriSuffix `
                                       -ReturnType JSON `
                                       -LocalStartTime $LocalStartTime `
                                       -LocalEndTime $LocalEndTime 
                                       
        $ret
        
        #$JSONOutputFileName = "C:\temp\ServiceMap\ConnectionsRaw.json"
        #$ret | Out-File -FilePath $JSONOutputFileName
        #Code $JSONOutputFileName
    
    }

If ($DoServiceMapMachineSummaryRAW)
    {
        $uriSuffix = "/machines/?api-version=2015-11-01-preview&live=false&timestamp=2017-02-17T09:57:56.9366303Z"
        $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -URISuffix $uriSuffix `
                                       -ReturnType JSON

        $JSONOutputFileName = "C:\temp\ServiceMap\MachineInfo.json"
        $ret | Out-File -FilePath $JSONOutputFileName
        Code $JSONOutputFileName
    }


If ($DoServiceMapConnectionsRAW)
    {
        # Lookup "unfriendly" ServiceMap MachineName based on VMName
        $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -VMName $VMName -SubscriptionName $SubscriptionName

        $uriSuffix = "/machines/$MachineName/connections?api-version=2015-11-01-preview" 
        $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -URISuffix $uriSuffix `
                                       -ReturnType JSON `
                                       -LocalStartTime $LocalStartTime `
                                       -LocalEndTime $LocalEndTime 
                                       

        $JSONOutputFileName = "C:\temp\ServiceMap\ConnectionsRaw.json"
        $ret | Out-File -FilePath $JSONOutputFileName
        Code $JSONOutputFileName
    }

If ($DoServiceMapMachineGroupsRAW)
    {
      $uriSuffix = "/machineGroups?api-version=2015-11-01-preview" 
        $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -URISuffix $uriSuffix `
                                       -ReturnType JSON 

        $re
                                              

    }