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
  - ShowAllVmsStatus param is a bit flawed : 
    - Only shows in current Subscription where OMS is 
    - Only shows active machines so if machine switched off , may show as Not installed
  
  Backlog 
  --------
      
  Change Log
  ----------
  v1.00 Andy Ball 17/02/2017 Base Version
  v1.01 Andy Ball 19/02/2017 Add timestamp field /param 
  v1.02 Andy Ball 21/02/2017 Add MachineId to output
  v1.03 Andy Ball 22/02/2017 Add ShowsAllVMsStatus param 
  v1.04 Andy Ball 25/02/2017 Change timestamp call so timestamp={utcdate} so it works
  v1.05 Andy Ball 26/02/2017 Switch back to original Subscription that had focus when entered, if we end up in a different 
 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Looks in current Subsription if null

 .Parameter ShowAllVMsStatus
 False by default, if true does a Get-AzureRMVM in $SubscriptionName to attempt to show Servers where no Service Map data. See limitations above

 .Parameter LocalTimeStamp
 When specified gets info for this date time. Pass local time , will be converted to UTC time into API

 .Example
  $ret = Get-CVServiceMapMachineSummary -OMSWorkspaceName "MyWorkspaceName" -ResourceGroupName "ItsRGName" 
  $ret | ft 
 

#>
Function Get-CVServiceMapMachineSummary
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName , 
            [Parameter(Mandatory = $false, Position = 3)]  [boolean] $ShowAllVMsStatus = $false , 
            [Parameter(Mandatory = $false, Position = 4)]  [string[]] $VMsStatusSubscriptionNames, 
            [Parameter(Mandatory = $false, Position = 5)]  [string] $LocalTimeStamp 

        )
        

    $Resultset = @()

    # do this so we can switch back at end
    $OriginalSubscriptionName = (Get-AzureRmContext).Subscription.SubscriptionName

    $TimeStampSuffix = ""
    If([string]::IsNullOrWhiteSpace($LocalTimeStamp) -eq $false)
        {
            $UTCTimeStamp = Get-CVJSONDateTime -MyDateTime $LocalTimeStamp -ConvertToUTC $true
            $TimeStampSuffix = "&timestamp=" + $UTCTimeStamp
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
    
    
    $Resultset = $ret.value | Select @{Name = "ComputerName" ; Expression = {$_.Properties.ComputerName}}, 
                          @{Name = "LocalTimestamp" ; Expression = {$LocalTimeStamp}}, 
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
                        @{Name = "OS" ; Expression = {$_.Properties.operatingSystem.fullName}} ,
                        @{Name = "MachineId" ; Expression = {$_.id}}


    # Create a row for each VM in Subscription that doesnt appear in ServiceMap results 
    If ($ShowAllVMsStatus)
        {
            $AllVms = @()
            # ie if not specified use the OMS Workspace Subscription to look for VMs
            If ([string]::IsNullOrWhiteSpace($VMsStatusSubscriptions))
                {
                    $VMStatusSubscriptions = $SubscriptionName
                }

            ForEach ($SubscriptionName in $VMsStatusSubscriptionNames)
                {
                    $ThisSubsVms = @()
                    Write-Host "Switching to $SubscriptionName to Get Vms"
                    $Sub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
                    
                    Write-Host "Running Get-AzureRMVM so can check for inactive / non-installed machines."
                    $ThisSubsVms = Get-AzureRMVM 
                    $VMsWithoutServiceMap = $ThisSubsVms | Where {$_.Name -notin $Resultset.ComputerName}
                    ForEach ($MissingVM in $VMsWithoutServiceMap)
                        {
                            $ResultSet += $Host | Select @{Name = "ComputerName" ; Expression = {$MissingVM.Name}}, 
                                  @{Name = "timestamp" ; Expression = {"N\A"}}, 
                                @{Name = "MachineName" ; Expression = {"N\A"}}, 
                                @{Name = "FirstIPAddress" ; Expression = {"N\A"}}, 
                                @{Name = "UTCBootTime" ; Expression = {"N\A"}} , 
                                @{Name = "TimeZoneDiff" ; Expression = {"N\A"}},
                                @{Name = "AgentVersion" ; Expression = {"Not installed"}},
                                @{Name = "AgentRevision" ; Expression = {"Not Installed"}}, 
                                @{Name = "AgentRebootStatus" ; Expression = {"N\A"}},
                                @{Name  = "VMType" ;  Expression = {"N\A"}},
                                @{Name  = "MemoryMB" ;  Expression = {"N\A"}},
                                @{Name  = "CPUs" ;  Expression = {"N\A"}},
                                @{Name = "OS" ; Expression = {"N\A"}} ,
                                @{Name = "MachineId" ; Expression = {"N\A"}}
                        }
                }
        }

    
    # Switch back to original SubscriptionName if current not same 
    $CurrentSubscriptionName =  (Get-AzureRmContext).Subscription.SubscriptionName
    If ($CurrentSubscriptionName -ne $OriginalSubscriptionName)
        {
            Write-Host "reSelecting SubscriptionName = $OriginalSubscriptionName (from $CurrentSubscriptionName)"
            $Sub = Select-AzureRmSubscription -SubscriptionName $OriginalSubscriptionName
        }
    # Finally return
    $Resultset | Sort ComputerName
}

