#region Functions
<# 
 .Synopsis
  Gets Summary of number of VMs that have Service Map for given OMSWorkspaceName /ResourceGroupName / Subscription

 .Description
 API Call : https://docs.microsoft.com/en-us/rest/api/servicemap/summaries
  
  Prequisites
  -----------
  AzureRM Modules - tested on 3.4 
  Get-CVAzureRESTAuthHeader func


  Returns 
  -------
  summary 


  Limitations and Known Issues
  ----------------------------
  - Only counts VMs in current Subscription, may have multiple subscriptions under given tenant / OMS workspace. 
  
  Backlog 
  --------
  - tidy up subscription validation into common routine / func
    
  Change Log
  ----------
  v1.00 Andy Ball 17/02/2017 Base Version
  v1.01 Andy Ball 18/02/2017 Change to use wrapper func / standardise 
 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Looks in current Subsription if null

 .GetVMCount 
 If true (Default) will get a count of VMs in current subscription, ie so can get feel for coverage of Service Map

 .Example
 Named Subscription 
 Get-ServiceMapSummary -OMSWorkspaceName "MyWorkspace" -ResourceGroupName "MyOMSWorkspaceRG" -SubscriptionName "Dev" -Verbose
 
 .Example
 Current Subscription 
 Get-ServiceMapSummary -OMSWorkspaceName "MyWorkspace" -ResourceGroupName "MyOMSWorkspaceRG" -Verbose

 .Example
 Current Subscription , dont bother getting VMCount
 Get-ServiceMapSummary -OMSWorkspaceName "MyWorkspace" -ResourceGroupName "MyOMSWorkspaceRG" -GetVMCount $false 

#>

Function Get-CVServiceMapSummary
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $false, Position = 3)]  [boolean] $GetVMCount = $true 
        )

    
    $ErrorActionPreference = "Stop"
    $VMCount = "N\A"

    If ($GetVMCount)
        {
            Write-Verbose "Running Get-AzureRMVM to get current VMCount"
            $VMs = Get-AzureRMVM 
            $VMCount = @($VMs).Count.ToString()
        }

    $URISuffix = "/summaries/machines?api-version=2015-11-01-preview"
    $res = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -URISuffix $URISuffix -RESTMethod GET -ReturnType PSObject
    # Finally call and format for output
    # $res = Invoke-RestMethod -Method GET -Uri $uri -Headers $Header -Debug -Verbose
    $res.properties | Select StartTime, EndTime, Total, Live, 
                        @{Name = "WindowsServers" ; Expression = {$_.os.windows}}, 
                        @{Name = "LinuxServers" ; Expression = {$_.os.linux}}, 
                        @{Name = "VMsinSubscription" ; Expression = {$VMCount}}
}

