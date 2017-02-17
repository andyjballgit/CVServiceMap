<# 
 .Synopsis
 Returns Summary information about All ServiceMap MAchines in Given OMS Workspace / Resource Group

 .Description
  
  
  Prequisites
  -----------
  AzureRM Modules - tested on 3.4 
  Get-AzureRESTAuthHeader func


  Returns 
  -------
  summary 
  ComputerName    FirstIPAddress UTCBootTime              TimeZoneDiff AgentVersion AgentRevision AgentRebootStatus VMType MemoryMB CPUs
   ------------    -------------- -----------              ------------ ------------ ------------- ----------------- ------ -------- ----

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

 .Example
  $ret = Get-CVServiceMapMachinesSummary -OMSWorkspaceName "MyWorkspaceName" -ResourceGroupName "ItsRGName" 
  $ret | ft 
 

#>
Function Get-CVServiceMapMachinesSummary
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName 
        )

    # ie silly date in the past so we get everything , 
    # ToDo not 100% sure how date works , maybe should just do offset from Now().UTC>AddHours(-2) or something ..
    $uriSuffix = "/machines/?api-version=2015-11-01-preview&live=false&timestamp=2017-02-17T09:57:56.9366303Z"

    If([string]::IsNullOrWhiteSpace($SubscriptionName))
        { 
            $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -URISuffix $uriSuffix
        }
    Else
        {
            $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -URISuffix $uriSuffix
        }
    $ret.value | Select @{Name = "ComputerName" ; Expression = {$_.Properties.ComputerName}}, 
                        @{Name = "MachineName" ; Expression = {$_.name}}, 
                        @{Name = "FirstIPAddress" ; Expression = {$_.Properties.networking.ipv4Interfaces[0].ipAddress}}, 
                        @{Name = "UTCBootTime" ; Expression = {$_.Properties.bootTime}} , 
                        @{Name = "TimeZoneDiff" ; Expression = {$_.Properties.timezone.fullName}},
                        @{Name = "AgentVersion" ; Expression = {$_.Properties.agent.dependencyAgentVersion}},
                        @{Name = "AgentRevision" ; Expression = {$_.Properties.agent.dependencyAgentRevision}}, 
                        @{Name = "AgentRebootStatus" ; Expression = {$_.Properties.agent.rebootStatus}},
                        @{Name  = "VMType" ;  Expression = {$_.Properties.virtualMachine.virtualMachineType}},
                        @{Name  = "MemoryMB" ;  Expression = {$_.Properties.resources.physicalMemory}},
                        @{Name  = "CPUs" ;  Expression = {$_.Properties.resources.cpus}},
                        @{Name = "OS" ; Expression = {$_.Properties.operatingSystem.fullName}} | Sort ComputerName

}

