#Helper.ps1 
# for testing of CVServiceMAPAPI Scripts

Import-Module $PSScriptRoot\..\CVServiceMapAPI -Force -Verbose

# Change these values
$VMNames = @("somevm1", "somevm2")
$SubscriptionName = "ChangeMe" 

# Lookup OMS Workspaces , if only 1 use it , otherewise list and then can hard code values yourself 
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
        $OMSWorkspaces | Select Name, ResourceGroupName | Out-String 
        Break 
    }

$LocalEndTime = (Get-Date).AddDays(-2) 
$LocalStartTime = (Get-Date).AddDays(-4)

# Change here to decide which bits to run
$DoServiceMapRAW = $true 
$DoServiceMapMachineLiveNess = $false 
$DoServiceMapConnectionsRAW = $false
$DoServiceMapMachineSummaryRAW = $false 
$DoServiceMapMachineSummary = $false
$DoServiceMapSummary = $false
$DoServiceMap = $false 
$DoServiceMapConnections = $false
$DoMachineByNameWithDate = $false 

If ($DoServiceMapRAW)
{

     $uriSuffix = "/MachineGroups?api-version=2015-11-01-preview" 
        $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                       -ResourceGroupName $ResourceGroupName `
                                       -SubscriptionName $SubscriptionName `
                                       -URISuffix $uriSuffix `
                                       -ReturnType JSON        
                                       

        $JSONOutputFileName = "C:\temp\ServiceMap\MachineGroups.json"
        $ret | Out-File -FilePath $JSONOutputFileName
        Code $JSONOutputFileName
    
}


If ($DoServiceMapMachineLiveNess)
    {
        # Lookup "unfriendly" ServiceMap MachineName based on VMName
        $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -VMName $VMName -SubscriptionName $SubscriptionName

        $uriSuffix = "/machines/$MachineName/liveness?api-version=2015-11-01-preview"
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


If ($DoServiceMapMachineSummary)
    {
        $LocalTimestamp = (Get-Date).AddDays(-10)

        Get-CVServiceMapMachinesSummary -OMSWorkspaceName $OMSWorkspaceName `
                                        -ResourceGroupName $ResourceGroupName `
                                        -SubscriptionName $SubscriptionName `
                                        -LocalTimeStamp $LocalTimestamp | Export-CSV -Path "c:\temp\MachineNames.csv" -Force -NoTypeInformation
        . "c:\temp\MachineNames.csv"
    }

If ($DoServiceMapSummary)
    {
        Get-CVServiceMapSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -LocalStartTime $LocalStartTime -LocalEndTime $LocalEndTime
    }

If($DoServiceMap)
    {
        Get-CVServiceMap -GetMethod Custom -SubscriptionName $SubscriptionName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -MapType map:machine-group-dependency
    }

If($DoServiceMapConnections)
    {
        $ret = Get-CVServiceMapMachineList -SubscriptionName $SubscriptionName `
                                                -OMSWorkspaceName $OMSWorkspaceName `
                                                -ResourceGroupName $ResourceGroupName `
                                                -ListType Connections `
                                                -VMNames $VMNames `
                                                -LocalStartTime $LocalStartTime `
                                                -LocalEndTime $LocalEndTime
        $ret | fl
        #$ret.properties | convertto-json -Depth 100 | Out-File "c:\temp\ServiceMap\Connections.json"
        #code "c:\temp\ServiceMap\Connections.json"
    }

If($DoMachineByNameWithDate)
    {

        # Change these
   
        $LocalStartTime = (Get-Date).AddDays(-5)
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


