#region Functions
<# 
 .Synopsis
  Gets Summary of number of VMs that have Service Map for given   

 .Description
  
  
  Prequisites
  -----------
  AzureRM Modules - tested on 3.4 
  Get-AzureRESTAuthHeader func


  Returns 
  -------
  summary 


  Limitations and Known Issues
  ----------------------------
  - Only counts VMs in current Subscription, may have multiple subscriptions under given tenant / OMS workspace. 
  
  Backlog 
  --------
  - tidy up subscription validation into common routine / func
  - How to enumerate existing machines ! 
    
  Change Log
  ----------
  v1.00 Andy Ball 17/02/2017 Base Version

 
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
            [Parameter(Mandatory = $true, Position = 1)]  [string] $OMSResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $false, Position = 3)]  [boolean] $GetVMCount = $true 
        )

    
    $ErrorActionPreference = "Stop"
    $VMCount = "N\A"

    # Switch to correct sub if required
    $CurrentSub = (Get-AzureRMContext).Subscription
    $CurrentSubscriptionName = $CurrentSub.SubscriptionName
    If ([string]::IsNullOrWhiteSpace($SubscriptionName) -AND ($SubscriptionName -ne $CurrentSubscriptionName))
        {
            Write-Host "Switching to Subscription Name = $SubscriptionName (From $CurrentSubscriptionName)"
            $CurrentSub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
        }

    # Build up the URI for REST Call 
    $SubscriptionID = $CurrentSub.SubscriptionId
    $TenantId = $CurrentSub.TenantId
    Write-Verbose "SubscriptionId = $SubscriptionId, TenantId = $TenantId"
    $uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$OMSResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$OMSWorkspaceName/features/serviceMap/summaries/machines?api-version=2015-11-01-preview"
     
    Write-Verbose "uri = $uri" 

    If ($GetVMCount)
        {
            Write-Verbose "Running Get-AzureRMVM to get current VMCount"
            $VMs = Get-AzureRMVM 
            $VMCount = @($VMs).Count.ToString()
        }
    # Create standard Azure Auth header 
    $Header = @{'Authorization' = (Get-LBEAzureRESTAuthHeader)}

    # Finally call and format for output
    $res = Invoke-RestMethod -Method GET -Uri $uri -Headers $Header -Debug -Verbose
    $res.properties | Select StartTime, EndTime, Total, Live, 
                        @{Name = "WindowsServers" ; Expression = {$_.os.windows}}, 
                        @{Name = "LinuxServers" ; Expression = {$_.os.linux}}, 
                        @{Name = "VMsinSubscription" ; Expression = {$VMCount}}
}

