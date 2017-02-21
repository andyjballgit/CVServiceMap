<# 
 .Synopsis
 Returns Summary information about All ServiceMap MAchines in Given OMS Workspace / Resource Group

 .Description
  API Call - https://docs.microsoft.com/en-us/rest/api/servicemap/machines#Machines_Get
  
  Prequisites
  -----------
  AzureRM Modules - tested on 3.4 
  Get-CVAzureRESTAuthHeader func


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
  v1.01 Andy Ball 19/02/2017 Add timestamp field /param 
  v1.02 Andy Ball 21/02/2017 Add MachineId to output
  
 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Looks in current Subsription if null

 .Parameter LocalTimeStamp
 When specified gets info for this date time. Pass local time , will be converted to UTC time into API

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
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName , 
            [Parameter(Mandatory = $false, Position = 3)]  [string] $LocalTimeStamp 

        )

    # ie silly date in the past so we get everything , 
    # ToDo not 100% sure how date works , maybe should just do offset from Now().UTC>AddHours(-2) or something ..
    # $uriSuffix = "/machines/?api-version=2015-11-01-preview&live=false&timestamp=2017-02-17T09:57:56.9366303Z"

    $TimeStampSuffix = ""
    If([string]::IsNullOrWhiteSpace($LocalTimeStamp) -eq $false)
        {
            $UTCLocalTimeStamp = Get-CVJSONDateTime -MyDateTime $LocalTimeStamp -ConvertToUTC $true
            $TimeStampSuffix = "&" + $UTCLocalTimeStamp
        }
         

    $uriSuffix = "/machines/?api-version=2015-11-01-preview" + $TimeStampSuffix

    If([string]::IsNullOrWhiteSpace($SubscriptionName))
        { 
            $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -URISuffix $uriSuffix
        }
    Else
        {
            $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -URISuffix $uriSuffix
        }
    $ret.value | Select @{Name = "ComputerName" ; Expression = {$_.Properties.ComputerName}}, 
                        @{Name = "MachineId" ; Expression = {$_.id}},
                        @{Name = "timestamp" ; Expression = {$_.Properties.timestamp}}, 
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

