<# 
 .Synopsis
 For givenn ComputerName (NetbiosName) returns ServiceMap machine name so can be used in other API Calls

 .Description
    
  Prequisites
  -----------
  AzureRM Modules - tested on 3.4 
  Get-AzureRESTAuthHeader func

  Returns 
  -------
  ServiceMap MachineName

  Limitations and Known Issues
  ----------------------------
  
  Backlog 
  --------
      
  Change Log
  ----------
  v1.00 Andy Ball 17/02/2017 Base Version

 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Looks in current Subsription if null

 .Parameter VMName
 ComputerName you want to look up 

 .Example
 Get-CVServiceMapMachineName -OMSWorkspaceName "OMSWorkspaceName" -ResourceGroupName "RGName"  -VMName "CV-SQL-001"

 

#>
Function Get-CVServiceMapMachineName
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName ,
            [Parameter(Mandatory = $true, Position = 3)]  [string] $VMName 
        )

    $MachineName = $null
    If([string]::IsNullOrWhiteSpace($SubscriptionName))
        { 
            $AllMachines =  Get-CVServiceMapMachinesSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName
        }
    Else
        {
            $AllMachines =  Get-CVServiceMapMachinesSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName
        }


    $MachineNameRecord = $AllMachines | Where {$_.ComputerName -eq $VMName}
    If ($MachineNameRecord -eq $null)
        {
            Write-warning "Cannot find ComputerName = $ComputerName in OMSWorkspaceName = $OMSWorkspaceName , ResourceGroupName = $ResourceGroupName"
            $ret | Select ComputerName | Out-String 
        }
    Else
        {
            $MachineName = $MachineNameRecord.MachineName
        }

    $MachineName
}


