# Introduction
21st Feb 2017
 
CVServiceMap - Project with real world examples of how to use Azure Service Map Rest APIs. 

Main goal is to explore / understand API / automation functionality / feedback to Product Group as quickly as possible, so code / error checking may not be Production quality :-)

Short term as will be redundant/superceded by Microsoft Powershell cmdlets when released. 

# Release Status
Beta(ish) ! 

# Reference
Service Map - https://docs.microsoft.com/en-us/azure/operations-management-suite/operations-management-suite-service-map

API Ref - https://docs.microsoft.com/en-us/rest/api/servicemap/

# Pre-requisites
* Powershell 5.0 
* Azure RM Cmdlets

# Research/Dont get ?
*  Machine Groups / Server Groups thought were non managed machines but API has option to create ? 
https://docs.microsoft.com/en-us/azure/operations-management-suite/operations-management-suite-service-map#client-groups

*  Machine Groups list comes back blank, Client Groups has no list all type functionality
* https://docs.microsoft.com/en-us/rest/api/servicemap/maps why is it using Body unlike most other API's , given quite simple , start, end , kind / type

# Backlog in priority order
* Use $ComputerName instead of $VMName ?
* Timestamp not working in Get-CVServiceMapSummary
* Add Liveness option to Get-CVServiceMapMachinesSummary
* Tidyup output between Write-Verbose/ Write-Host 
* Reporting - Powerbi / Relational ? 
* Some dupe code / refactoring (#ToDo Refactor)
* Get/Search OMSWorkspace for current / given subscription so can call funcs without params if only 1 exists . Get-AzureRmOperationalInsightsWorkspace
* Way of dumping Powershell funcs dependencies / call stack for documenation

# Concepts and Learnings
* Service Map Machine / Server names are some sort of unique key , so need to lookup
* Ports will show Ports Active on named machine, returns IP Address, but that is IP Address of itself - either 127.0.0.1 or its Internal Address as opposed to remote machine
* SCOM Integration - https://docs.microsoft.com/en-us/azure/log-analytics/log-analytics-om-agents
* Transmits approx 25mbytes a day , every 15 seconds - https://docs.microsoft.com/en-us/azure/operations-management-suite/operations-management-suite-service-map-configure#data-collection
* Get OMS workspaces / What is enabled : Get-AzureRmOperationalInsightsWorkspace | Get-AzureRmOperationalInsightsIntelligencePacks | Sort Name

# Issues spotted
* Stuff listed twice https://docs.microsoft.com/en-us/rest/api/servicemap/machines#Machines_ListMachineGroupMembership
* Bitness field x64 / x86 is redundant surely cos only supported on x64
* CONFIRMED that doc for Generate ServiceMap is wrong - missing MachineName error, MS fixing

# Functions



| Cmdlet       | Summary           |
|------------- |-------------------|
| Get-CVAzureRESTAuthHeader|Generates an Authentication Token / Header that can then be used when calling Azure REST API's. See Examples Section for how to use with Invoke-RESTMethod.|
| Get-CVJSONDateTime|For a given DateTime param, returns in JSON friendly format 2017-02-18T17:23:37.033|
| Get-CVMarkDownFileForCmdLets|For a given wildcard will generate a Markdown table / file of Name , Synopsis. Markdown is used in Git for rich documentation..|
| Get-CVServiceMap|Generates a Service Map Map , currently returns as Recordset with VMName, and then raw ServiceMap Object , so can be dumped to JSON / explored.|
| Get-CVServiceMapMachineList|Generic function that calls either _ListPorts, _ListConnections or List_Processes depending on the ListType Param.|
| Get-CVServiceMapMachineLiveness|Returns the "liveness" of specified VM(s) for the given start/Endtime (if specfied, if not last 10 mins). liveness means that it was up and running and delivering ServiceMap data during the time period.|
| Get-CVServiceMapMachineName|For givenn ComputerName (NetbiosName) returns ServiceMap machine name so can be used in other API Calls|
| Get-CVServiceMapMachineSummary|Returns Summary information about All ServiceMap MAchines in Given OMS Workspace / Resource Group|
| Get-CVServiceMapSummary|Gets Summary of number of VMs that have Service Map for given OMSWorkspaceName /ResourceGroupName / Subscription|
| Get-CVServiceMapWrapper|Generic Wrapper script for Azure Service Map REST API so can test / experiement with various API Calls and also called by other specific functions in the Module to avoid repeat code|

