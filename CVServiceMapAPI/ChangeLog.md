## 26.02.2017 Version 0.19
* Bug fixes

## 22.02.2017 Version 0.18
* Start/Endtime working in Get-SVServiceMapWrapper

## 21.02.2017 Version 0.18
* remove Get-ServiceMapPorts/Machines as handled by generic func Get-ServiceMapMachineList
 
## 21.02.2017 Version 0.17
* Update Get-CVServiceMap so handles multiple VMs properly
* Change Get-CVServiceMapMachinesSummary so has option to list VMs without active ServiceMap client

## 21.02.2017 Version 0.16 
* Fix bug with Get-ServiceMap not working , as was using MachineName, not ID in API Call.

## 20.02.2017 Version 0.15 
* Add Helper.ps1 for running / testing the various funcs

## 19.02.2017 Version 0.14
* Fix bug in Get-CVServiceMapWrapper where not picking up correct SubscriptionId

## 19.02.2017 Version 0.13
* Add Start/EndTime to calling funcs but not working

## 19.02.2017 Version 0.12
* Get-CVServiceMapWrapper added StartDate and EndDate params

## 19.02.2017 Version 0.11
* Get-CVServiceMapWrapper update so option of passing the Azure Auth Header to speed up when making many calls (ie looping through all Vms)


## 18.02.2017 Version 0.10
* Add Get-ServiceMapList generic function for MachineName API Calls 

## 18.02.2017 Version 0.09
* Add Get-CVServiceMap (currently broken)
* Add Get-CVServiceMapMachinePorts/Processes
* Update Get-CVServiceMapWrapper to handle POST
* Add Helper\FunctionHeader.ps1


## 18.02.2017 Version 0.08
* Fix Subscription bug in Get-CVServiceMapWrapper 
* Put good example in the help for above
* Setup as Module

## 17.02.2017 Version 0.07
* Add Get-CVServiceMapMachineName func

## 17.02.2017 Version 0.06
* Add Returntype param to so can return as JSON when exploring the API

## 17.02.2017 Version 0.05
* Add Get-CVServiceMapMachinesSummary gives Summary of all machines in Service Map

## 17.02.2017 Version 0.04
* Add Get-CVServiceMapWrapper to allow easy explore / ad-hoc running of the API

## 17.02.2017 Version 0.03
* Tidy up output for Get-CVServiceMapSummary

## 17.02.2017 Version 0.02
* Test Sync

## 17.02.2017 Version 0.01
* Initial Check-in