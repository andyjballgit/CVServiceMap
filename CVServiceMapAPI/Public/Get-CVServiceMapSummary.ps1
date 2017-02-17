#region Functions
<# 
 .Synopsis
  Gets Summary of Service Mapp installation , number of Servers, using REST APIs from :  

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
  
  Backlog 
  --------
    
  Change Log
  ----------
  v1.00 Andy Ball 17/02/2017 Base Version

 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter Subscription
 Subscription where OMS is located. Looks in current Subsription if null

 .Example
 Named Subscription 
 Get-LBEServiceMapSummary -OMSWorkspaceName "MyWorkspace" -ResourceGroupName "MyOMSWorkspaceRG" -SubscriptionName "Dev" -Verbose
 
 .Example
 Current Subscription 
 Get-LBEServiceMapSummary -OMSWorkspaceName "MyWorkspace" -ResourceGroupName "MyOMSWorkspaceRG" -SubscriptionName "Dev" -Verbose

#>

Function Get-CVServiceMapSummary
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $OMSResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName
        )

    $CurrentSub = (Get-AzureRMContext).Subscription
    $CurrentSubscriptionName = $CurrentSub.SubscriptionName
    If ($SubscriptionName -ne $CurrentSubscriptionName)
        {
            Write-Host "Switching to Subscription Name = $SubscriptionName (From $CurrentSubscriptionName)"
            $CurrentSub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
        }

    $SubscriptionID = $CurrentSub.SubscriptionId
    $TenantId = $CurrentSub.TenantId
    Write-Verbose "SubscriptionId = $SubscriptionId, TenantId = $TenantId"
    
    $uri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$OMSResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$OMSWorkspaceName/features/serviceMap/summaries/machines?api-version=2015-11-01-preview"
     
    Write-Host "uri = $uri" -ForegroundColor Green

    # Create standard Azure Auth header 
    $Header = @{'Authorization' = (Get-LBEAzureRESTAuthHeader)}

    $res = Invoke-RestMethod -Method GET -Uri $uri -Headers $Header -Debug -Verbose
    $res 

}
