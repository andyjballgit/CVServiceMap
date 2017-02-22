<# 
 .Synopsis
  Generic Wrapper script for Azure Service Map REST API so can test / experiement with various API Calls and also called by other specific functions in the Module to avoid repeat code

 .Description
 appends specified URISuffix param to below 
 https://management.azure.com/subscriptions/{subscriptionid}/resourceGroups/{resourcegroupname}/providers/Microsoft.OperationalInsights/workspaces/{OMSworkspaceName}/features/serviceMap
 
 See below for API Details : 
 https://docs.microsoft.com/en-us/rest/api/servicemap/
  
 Prequisites
 -----------
 AzureRM Modules - tested on 3.4 
 Get-CVAzureRESTAuthHeader func
 
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
 v1.03 Andy Ball 18/02/2017 Add RESTMethod and Body params / logic so can do POSTS 
 v1.04 Andy Ball 19/02/2017 Add AuthRESTHeader param so that option of passing it in , rather than having to call Get-CVAzureRESTAuthHeader
 v1.05 Andy Ball 19/02/2017 Add LocalStart / End time params 
 v1.06 Andy Ball 19/02/2017 Fix bug where wasn't picking up SubscriptionId 
 v1.07 Andy Ball 21/02/2017 Change so that passes TenantId into Get-CVAzureRESTAuthHeader

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

 .Parameter AzureRestHeader 
 Null by default, so will call Get-CVAzureRESTAuthHeader. 
 If not null will use this for REST Authorisation header , idea being if you are doing lots of calls to Get-ServiceMapWrapper (ie when looping through VMs) , only have to call 
 Get-CVAzureRESTAuthHeader once. 
 
 .Parameter LocalStartTime
 Time to search from in your local time zone
 If not specifed does the last 10 mins

 .Parameter LocalEndTime
 Time to search to in your local time zone
 If not specifed does the last 10 mins

 .Example
 Change params , will get process info for given VM going back 5 days until now (cos LocalEndTime is get-date)

 $VMName = "CV-SOME-VM"
 $OMSWorkspaceName = "MYOMSWORKSPACE"
 $ResourceGroupName = "WorkSpaceRG"
 $SubscriptionName = "Bizspark" 

 # 5 days ago
 $LocalStartTime = (Get-Date).AddDays(-5)
 $LocalEndTime = Get-Date 

 # Lookup "unfriendly" ServiceMap MachineName based on VMName
 $MachineName = Get-CVServiceMapMachineName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -VMName $VMName -SubscriptionName $SubscriptionName

 # call API
 $uriSuffix = "/machines/$MachineName/processes?api-version=2015-11-01-preview" 
 $ret = Get-CVServiceMapWrapper -OMSWorkspaceName $OMSWorkspaceName `
                               -ResourceGroupName $ResourceGroupName `
                               -SubscriptionName $SubscriptionName `
                               -ReturnType JSON `
                               -URISuffix $uriSuffix `
                               -LocalStartTime $LocalStartTime `
                               -LocalEndTime $LocalEndTime 

 
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
            [Parameter(Mandatory = $false, Position = 4)]  [string] [ValidateSet("PUT", "GET", "POST")] $RESTMethod = "GET", 
            [Parameter(Mandatory = $false, Position = 5)]  [string] $Body, 
            [Parameter(Mandatory = $false, Position = 6)] [string] [Validateset ("PSObject", "JSON")] $ReturnType = "PSObject", 
            [Parameter(Mandatory = $false, Position = 7)] [string] $AzureRestHeader,
            [Parameter(Mandatory = $false, Position = 8)] [datetime] $LocalStartTime,
            [Parameter(Mandatory = $false, Position = 9)] [datetime] $LocalEndTime
             


        )

    $ErrorActionPreference = "Stop"
    $VMCount = "N\A"
    
    # ie assume we haven't got
    $StartEndTimeSuffix = ""

    If ( [string]::IsNullOrWhiteSpace($LocalStartTime) -eq $false -OR ([string]::IsNullOrWhiteSpace($LocalEndTime) -eq $false))
        {
            If ($LocalStartTime -gt $LocalEndTime)
                {
                    Write-Warning "LocalStartTime ($LocalStartTime) is greater than LocalEndTime ($LocalEndTime). Quitting"
                    break
                }
            Else
                {
                    $StartEndTimeSuffix = "&" + (Get-CVJSONDateTime -MyDateTime $LocalStartTime -ConvertToUTC $true) + "&" + (Get-CVJSONDateTime -MyDateTime $LocalEndTime -ConvertToUTC $true)
                }

        }
    # Switch to correct sub if required
    $CurrentSub = (Get-AzureRMContext).Subscription
    $CurrentSubscriptionName = $CurrentSub.SubscriptionName
    If ( (([string]::IsNullOrWhiteSpace($SubscriptionName) -eq $false)) -AND ($SubscriptionName -ne $CurrentSubscriptionName))
        {
            Write-Host "Switching to Subscription Name = $SubscriptionName (From $CurrentSubscriptionName)"
            $CurrentSub = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
            $SubscriptionID = $CurrentSub.Subscription.SubscriptionId
            $TenantId = $CurrentSub.Subscription.TenantId
        }
    Else
        {
            Write-Host "Running in Current Subscription Name = $CurrentSubscriptionName"
            $SubscriptionID = $CurrentSub.SubscriptionId
            $TenantId = $CurrentSub.TenantId 
        }
    # Build up the URI for REST Call 
  
    $TenantId = $CurrentSub.TenantId
    Write-Verbose "SubscriptionId = $SubscriptionId, TenantId = $TenantId"
    $baseuri = "https://management.azure.com/subscriptions/$SubscriptionID/resourceGroups/$ResourceGroupName/providers/Microsoft.OperationalInsights/workspaces/$OMSWorkspaceName/features/serviceMap"
    
    # glue together finally uri , StartEndTimeSuffix is blank if those params are not passed in
    $uri = $baseuri + $URISuffix + $StartEndTimeSuffix
     
    Write-Verbose "uri = $uri" 

    # Create standard Azure Auth header if not passed in as param
    If ([string]::IsNullOrWhiteSpace($AzureRestHeader))
        {
            $AzureRestHeader = Get-CVAzureRESTAuthHeader -AADTenantID $TenantId
        }
    
    $Header = @{'Authorization' = ($AzureRestHeader)}

    # Finally call and format for output
    If ([string]::IsNullOrWhiteSpace($Body) -eq $true)
        {
            $res = Invoke-RestMethod -Method $RESTMethod -Uri $uri -Headers $Header -Debug -Verbose 
        }
    
    Else
        {
           Write-Host "Get-CVServiceMapWrapper : Posting Body:`r`n$Body"
           try 
           {
            $res = Invoke-RestMethod -Method $RESTMethod -Uri $uri -Headers $Header -Debug -Verbose -Body $Body -ContentType "application/JSON" -ErrorVariable $MyError
            }
        Catch
            {

                $MyError  = $_
                Write-Warning "Error`r`n$MyError"
                Break
                Write-Host ""
            }
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



