<# 
 .Synopsis
  Generates a Service Map Map 

 .Description
  https://docs.microsoft.com/en-us/rest/api/servicemap/maps
  
  Prequisites
  -----------
  AzureRM Modules - tested on 3.4 
  Get-AzureRESTAuthHeader func


  Returns 
  -------
  Either single-machine-dependency or machine-group-dependency map  


  Limitations and Known Issues
  ----------------------------
  - Currently does last 10 minutes data only 
  
  Backlog 
  --------

    
  Change Log
  ----------
  v1.00 Andy Ball 17/02/2017 Base Version
  v1.01 Andy Ball 19/02/2017 Add GetMethod param so can use custom code to get the map 

 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Looks in current Subsription if null

 .Parameter GetMethod 
 Custom (default)  - glue together based on call Connections, Ports, Processes
 Microsoft         - having issues getting native API Call working  https://docs.microsoft.com/en-us/rest/api/servicemap/maps

 .MapType
 either "map:single-Machine-dependency" default "map:machine-group-dependency"


 .Example
 Named Subscription , uses default MapType which is map:single-Machinedependency
 Get-ServiceMap -OMSWorkspaceName "MyWorkspace" -ResourceGroupName "MyOMSWorkspaceRG" -SubscriptionName "Dev" -Verbose
 
 .Example


#>

Function Get-CVServiceMap
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $false, Position = 3)]  [string] [ValidateSet("Custom", "Microsoft")] $GetMethod = "Custom" ,
            [Parameter(Mandatory = $false, Position = 4)]  [string] [ValidateSet("map:single-Machine-dependency", "map:machine-group-dependency")] $MapType = "map:single-Machine-dependency"

        )

    
    $ErrorActionPreference = "Stop"
    $EndTime = [DateTime]::UtcNow
    $StartTime = $EndTime.AddMinutes(-10)

  
    # $Now = $EndTime
    # $strEndTime =  $now.Year.TOString() + "-0" + $now.Month.ToString() + "-" + $now.Day.ToString() + "T" + $NOW.TimeOfDay.ToString().Substring(0, $now.timeofday.ToString().length -4) + "Z"

    $strEndTime = Get-CVJSONDateTime -MyDateTime $EndTime
    $strStartTime = Get-CVJSONDateTime -MyDateTime $StartTime
    
    If ($GetMethod -eq "Microsoft")
        {
            $MachineName = "m-7309b470-4195-4ff5-9380-cbc9e6cc6e8e"

            $objBody = $Host | Select @{Name = "startTime" ; Expression = {$strStartTime}}, 
                                      @{Name = "endTime" ; Expression = {$strEndTime}}, 
                                      @{Name = "kind" ; Expression = {$MapType}} , 
                                      @{Name = "machine Name"; Expression = {$MachineName}}

                              
            $JSONBody = $objBody | ConvertTo-Json 
            Write-Verbose -Message $JSONBody

            $uriSuffix = "/generateMap?api-version=2015-11-01-preview" 
            #$uriSuffix = "/machines/$MachineName/generateMap?api-version=2015-11-01-preview"
            Write-Host ("Generating Service Map type = $MapType from $StartTime to $EndTime @ " + (Get-Date))
            $ret = Get-CVServiceMapWrapper -URISuffix $uriSuffix -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -RESTMethod POST -Body $JSONBody 
        }
    # Custom below 
    Else
        {
            Throw "not implemented yet"
        }

}

