﻿#region Functions
<# 
 .Synopsis
  Generic Wrapper script for Azure Service Map REST API so can test / experiement with various API Calls 

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
 
 .Example


 .Example


#>

Function Get-CVServiceMapWrapper
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $OMSResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $true, Position = 2)]  [string] $URISuffix
        )
            
    $ErrorActionPreference = "Stop"
    $VMCount = "N\A"

    # Switch to correct sub if required
    $CurrentSub = (Get-AzureRMContext).Subscription
    $CurrentSubscriptionName = $CurrentSub.SubscriptionName
    If ($SubscriptionName -ne $CurrentSubscriptionName)
        {
            Write-Host "Switching to Subscription Name = $SubscriptionName (From $CurrentSubscriptionName)"
            $CurrentSub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
        }

    # Build up the URI for REST Call 
    $SubscriptionID = $CurrentSub.SubscriptionId
    $TenantId = $CurrentSub.TenantId
    Write-Verbose "SubscriptionId = $SubscriptionId, TenantId = $TenantId"
    $baseuri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$OMSResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$OMSWorkspaceName/features/serviceMap"
    
    $uri = $baseuri + $URISuffix
     
    Write-Verbose "uri = $uri" 

    # Create standard Azure Auth header 
    $Header = @{'Authorization' = (Get-LBEAzureRESTAuthHeader)}

    # Finally call and format for output
    $res = Invoke-RestMethod -Method GET -Uri $uri -Headers $Header -Debug -Verbose
    $res.properties 
}



