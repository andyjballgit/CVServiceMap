<# 
 .Synopsis
  Generic Wrapper script for Azure Service Map REST API so can test / experiement with various API Calls and also called by other specific functions in the Module to avoid repeat code

 .Description
 appends specified URISuffix param to below 
 https://management.azure.com/subscriptions/{subscriptionid}/resourceGroups/{resourcegroupname}/providers/Microsoft.OperationalInsights/workspaces/{OMSworkspaceName}/features/serviceMap
  
  
 Prequisites
 -----------
 AzureRM Modules - tested on 3.4 
 Get-AzureRESTAuthHeader func


 Returns 
 -------
  Output of Service Map REST API Call as either PSObect or JSON


 Limitations and Known Issues
 ----------------------------
  
 Backlog 
 --------
     
 Change Log
 ----------
  v1.00 Andy Ball 17/02/2017 Base Version
  v1.01 Andy Ball 17/02/2017 Add Returntype param
  v1.02 Andy Ball 18/02/2017 Fix major bug in Subscription switch logic and add detailed example
  v1.02 Andy Ball 18/02/2017 Add RESTMetohd and Body params / logic so can do POSTS 
 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Runs in current Subsription if null

 .Parameter URISuffix 
 gets appended to below to make up the uri that is called. Requires leading forward slash /
 https://management.azure.com/subscriptions/{subscriptionid}/resourceGroups/{resourcegroupname}/providers/Microsoft.OperationalInsights/workspaces/{OMSworkspaceName}/features/serviceMap

 .Parameter RESTMethod
 GET (default) or POST

 .Parameter RESTBody
 If RESTMethod POST then this can be used for sending the Body, JSON

 .Parameter Returntype
 Either PSObject (Default) or JSON. JSON is usefull when exploring output of an API call. 

 .Example
 This detailed example shows how get the unfriendly Machine name for a given VM then pass into Get-ServiceMapWrapper call the Ports function 
 and then dump to JSON and finally load up in Visual Studio Code so can explore the object

    # Change these
    $VMName = "CV-SQL-001"
    $OMSWorkspaceName = "MyOMSWorkspaceName"
    $ResourceGroupName = "OMSRG"
    $SubscriptionName = "TestSub" 

    # Lookup "unfriendly" ServiceMap MachineName based on VMName
    $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -VMName $VMName -SubscriptionName $SubscriptionName

    # call API
    $uriSuffix = "/machines/$MachineName/ports?api-version=2015-11-01-preview" 
    $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                                   -ResourceGroupName $ResourceGroupName `
                                   -SubscriptionName $SubscriptionName `
                                   -ReturnType JSON `
                                   -URISuffix $uriSuffix 

    # Dump to file and Load in visual studi code
    $FileName = "c:\temp\$VMName" + "_Ports.json"
    $ret | Out-File $FileName
    . code $FileName


 .Example


 .Example


#>
Function Get-CVServiceMapWrapper
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName,
            [Parameter(Mandatory = $false, Position = 2)] [string] $SubscriptionName,
            [Parameter(Mandatory = $true, Position = 3)]  [string] $URISuffix, 
            [Parameter(Mandatory = $false, Position = 4)]  [string] [ValidateSet("GET", "POST")] $RESTMethod = "GET", 
            [Parameter(Mandatory = $false, Position = 5)]  [string] $Body, 
            [Parameter(Mandatory = $false, Position = 6)] [string] [Validateset ("PSObject", "JSON")] $ReturnType = "PSObject" 
        )

    $ErrorActionPreference = "Stop"
    $VMCount = "N\A"

    # Switch to correct sub if required
    $CurrentSub = (Get-AzureRMContext).Subscription
    $CurrentSubscriptionName = $CurrentSub.SubscriptionName
    If ( (([string]::IsNullOrWhiteSpace($SubscriptionName) -eq $false)) -AND ($SubscriptionName -ne $CurrentSubscriptionName))
        {
            Write-Host "Switching to Subscription Name = $SubscriptionName (From $CurrentSubscriptionName)"
            $CurrentSub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
        }
    Else
        {
            Write-Host "Running in Current Subscription Name = $CurrentSubscriptionName"
        }
    # Build up the URI for REST Call 
    $SubscriptionID = $CurrentSub.SubscriptionId
    $TenantId = $CurrentSub.TenantId
    Write-Verbose "SubscriptionId = $SubscriptionId, TenantId = $TenantId"
    $baseuri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$OMSWorkspaceName/features/serviceMap"
    
    $uri = $baseuri + $URISuffix
     
    Write-Verbose "uri = $uri" 

    # Create standard Azure Auth header 
    $Header = @{'Authorization' = (Get-AzureRESTAuthHeader)}

    # Finally call and format for output
    If ([string]::IsNullOrWhiteSpace($Body) -eq $true)
        {
            $res = Invoke-RestMethod -Method $RESTMethod -Uri $uri -Headers $Header -Debug -Verbose 
        }
    
    Else
        {
           Write-Host "Get-CVServiceMapWrapper : Posting Body:`r`n$Body"
           $res = Invoke-RestMethod -Method $RESTMethod -Uri $uri -Headers $Header -Debug -Verbose -Body $Body -ContentType "application/JSON" 
        }
    
    
    If ($ReturnType -eq "PSObject")
        {
            $res
        }
    Else
        {
            $res | ConvertTo-JSON -Depth 100 
        }
}



