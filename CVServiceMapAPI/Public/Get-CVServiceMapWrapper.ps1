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
  v1.01 Andy Ball 17/02/2017 Add Returntype param

 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Looks in current Subsription if null

 .Parameter Returntype
 Either PSObject (Default) or JSON 

 .Example
 
 .Example


 .Example


#>

Function Get-CVServiceMapWrapper
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $true, Position = 2)]  [string] $URISuffix, 
            [Parameter(Mandatory = $false, Position = 2)]  [string] [Validateset ("PSObject", "JSON")] $ReturnType = "PSObject" 

        )
            
    $ErrorActionPreference = "Stop"
    $VMCount = "N\A"

    # Switch to correct sub if required
    $CurrentSub = (Get-AzureRMContext).Subscription
    $CurrentSubscriptionName = $CurrentSub.SubscriptionName
    If ( ([string]::IsNullOrWhiteSpace($SubscriptionName -eq $False)) -AND ($SubscriptionName -ne $CurrentSubscriptionName))
        {
            Write-Host "Switching to Subscription Name = $SubscriptionName (From $CurrentSubscriptionName)"
            $CurrentSub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
        }

    # Build up the URI for REST Call 
    $SubscriptionID = $CurrentSub.SubscriptionId
    $TenantId = $CurrentSub.TenantId
    Write-Verbose "SubscriptionId = $SubscriptionId, TenantId = $TenantId"
    $baseuri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$OMSWorkspaceName/features/serviceMap"
    
    $uri = $baseuri + $URISuffix
     
    Write-Verbose "uri = $uri" 

    # Create standard Azure Auth header 
    $Header = @{'Authorization' = (Get-LBEAzureRESTAuthHeader)}

    # Finally call and format for output
    $res = Invoke-RestMethod -Method GET -Uri $uri -Headers $Header -Debug -Verbose

    If ($ReturnType -eq "PSObject")
        {
            $res
        }
    Else
        {
            $res | ConvertTo-JSON -Depth 100 
        }
}



