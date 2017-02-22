<# 
 .Synopsis
  Generates a Service Map Map , currently returns as Recordset with VMName, and then raw ServiceMap Object , so can be dumped to JSON / explored.

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
  v1.02 Andy Ball 20/02/2017 Change JSON payload to MachineId
  v1.03 Andy Ball 21/02/2017 Changet to actually use .Id for MachineId (was incorrectly using MachineName)
  v1.04 Andy Ball 22/02/2017 Remove param , add progress when rolling through VMs
 
 .Parameter OMSWorkspaceName
  Name of OMS Workspace 

 .Parameter ResourceGroupName
  ResourceGroupName of OMS workspace

 .Parameter SubscriptionName
 Subscription where OMS is located. Looks in current Subsription if null

 .Parameter GetMethod 
 Custom (default)  - glue together based on call Connections, Ports, Processes
 Microsoft         - having issues getting native API Call working  https://docs.microsoft.com/en-us/rest/api/servicemap/maps

 .Parameter MapType
 either "map:single-Machine-dependency" (default) or  "map:machine-group-dependency" (this is not currently implemented in Service Maps)


 .Example
 Named Subscription , uses default MapType which is map:single-Machinedependency
 Get-ServiceMap -OMSWorkspaceName "MyWorkspace" -ResourceGroupName "MyOMSWorkspaceRG" -SubscriptionName "Dev" -Verbose
 
 .Example
 Dump as JSON , will be around 3mbyte of JSON Per Server
 
 $SubscriptionName = "MySub"
 $OMSWorkspaceName = "OMSWorkspace"
 $ResourceGroupName = "RGWhereOMSIs"

 $ret = Get-CVServiceMap -SubscriptionName $SubscriptionName -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -MapType map:single-Machine-dependency
 $ret | ConvertTo-JSON -Depth 100 | Out-File "c:\temp\ServiceMap\ServiceMapAll.json"
 Code "c:\temp\ServiceMap\ServiceMapAll.json"

#>

Function Get-CVServiceMap
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName  	,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName ,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName, 
            [Parameter(Mandatory = $false, Position = 3)]  [string[]] $VMNames, 
            [Parameter(Mandatory = $false, Position = 5)]  [string] [ValidateSet("map:single-Machine-dependency",  "map:machine-group-dependency")] $MapType = "map:single-Machine-dependency"

        )

    $ErrorActionPreference = "Stop"
    $EndTime = Get-Date
   
    #Barf because not actually implemented yet by MS 22 feb 2017
    If ($MapType -eq "map:machine-group-dependency")
        {
            Throw "Documented in API but not yet implented yet"
            Break
        }
      
    $StartTime = $EndTime.AddMinutes(-10)

    $strEndTime = Get-CVJSONDateTime -MyDateTime $EndTime
    $strStartTime = Get-CVJSONDateTime -MyDateTime $StartTime
    

    # ToDo Refactor
    If ([string]::IsNullOrWhiteSpace($VMNames))
        {

            Write-Verbose "VMNames param is null , getting all active VMs"
            $AllMachines = Get-CVServiceMapMachinesSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName
            $VMNames = @()
            ForEach($VMName in $AllMachines.ComputerName)
                {
                    $VMNames += $VMName
                }
        } 


    $Resultset = @()
    $VMsCount = @($VMNames).Count
    $CurrentVMNum = 1 

    $AllMachines = Get-CVServiceMapMachinesSummary -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName
    ForEach($VMName in $VMNames)
                {
                    $ret = $null 
                    Write-Host "Processing $VMName ($CurrentVMNum of $VMsCount)" -ForegroundColor Green 
                    $MachineName = $null
                    $MachineNameRecord = $null 
                     
                    $MachineNameRecord = $AllMachines | Where {$_.ComputerName -eq $VMName}
                    If ($MachineNameRecord -eq $null)
                        {
                            Write-Warning "`tCannot find $VMName in ServiceMap"
                        }
                    Else
                        {
                            $MachineName = $MachineNameRecord.MachineName 
                            $objBody = $Host | Select @{Name = "kind" ; Expression = {$MapType}} , 
                                                      @{Name = "machineId"; Expression = {$MachineNameRecord.MachineId}},
                                                      @{Name = "startTime" ; Expression = {$strStartTime}}, 
                                                      @{Name = "endTime" ; Expression = {$strEndTime}}
                                                     
                            $JSONBody = $objBody | ConvertTo-Json 
                            Write-Verbose -Message $JSONBody

                            $uriSuffix = "/generateMap?api-version=2015-11-01-preview" 
                            Write-Host ("Generating Service Map type = $MapType, With machineId = $MachinName from $StartTime to $EndTime @ " + (Get-Date))
                            
                            try
                                {
                                    $ret = Get-CVServiceMapWrapper -URISuffix $uriSuffix -OMSWorkspaceName $OMSWorkspaceName -ResourceGroupName $ResourceGroupName -SubscriptionName $SubscriptionName -RESTMethod POST -Body $JSONBody 
                                }
                            catch
                                {

                                    $MyError = $Error[0]
                                    Write-Host ""
                                }

                        }

                      $Resultset +=  $Host | Select @{Name = "VMName" ; Expression = {$VMName}}, 
                                                    @{Name = "Ret" ; Expression = {$ret}} 

                       $CurrentVMNum++
                }


    $Resultset
}

