| Cmdlet       | Summary           |
|------------- |-------------------|
| Get-CVAzureRESTAuthHeader|Generates an Authentication Token / Header that can then be used when calling Azure REST API's. See Examples Section for how to use with Invoke-RESTMethod|
| Get-CVJSONDateTime|For a given DateTime param, returns in JSON friendly format 2017-02-18T17:23:37.033|
| Get-CVMarkDownFileForCmdLets|For a given wildcard will generate a Markdown table / file of Name , Synopsis. Markdown is used in Git for rich documentation..|
| Get-CVServiceMap|:-( No Synopsis, fix it !|
| Get-CVServiceMapMachineList|Generic function that calls either _ListPorts, _ListConnections or List_Processes depending on the ListType Param
.
Description
API Call - https://docs.microsoft.com/en-us/rest/api/servicemap/machines#Machines_ListPorts
 
Prequisites
-----------
#ie.
AzureRM Modules - tested on 3.4 
Get-CVAzureRESTAuthHeader func

Returns 
-------
List of type of resource specified 

Limitations and Known Issues
----------------------------


Backlog 
--------

Change Log
----------
v1.00 Andy Ball 18/02/2017 Base Version
v1.02 Andy Ball 19/02/2017 Fix minor bugs with counting VMs 
v1.03 Andy Ball 19/02/2017 Add list type , LocalStart/Endtime params|
| Get-CVServiceMapMachineName|For givenn ComputerName (NetbiosName) returns ServiceMap machine name so can be used in other API Calls|
| Get-CVServiceMapMachinesSummary|:-( No Synopsis, fix it !|
| Get-CVServiceMapSummary|:-( No Synopsis, fix it !|
| Get-CVServiceMapWrapper|:-( No Synopsis, fix it !|

