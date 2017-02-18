﻿<# 
 .Synopsis
 For a given DateTime param, returns in JSON friendly format 2017-02-18T17:23:37.033

 .Description
 Bit of workaround as when doing a ConvertTo-JSON end up with 2 fields in there 

 {
    "value":  "\/Date(1487441052493)\/",
    "DisplayHint":  2,
    "DateTime":  "18 February 2017 18:04:12"
}
 
  
 Prequisites
 -----------

 Returns 
 -------
 

 Limitations and Known Issues
 ----------------------------
 UK Date format ! 

 Backlog 
 --------

 Change Log
 ----------
 v1.00 Andy Ball 18/02/2017 Base Version
 

 .Parameter MyDateTime
 Defaults to Get-Date if not passed

 .Example
 returns current date/time in JSON Format
 Get-CVJSONDateTime


 .Example
 Returns given date/time in JSON Format from date of 10 days ago 
 $MyDateTime = (Get-Date).AddDays(-10)
 Get-CVJSONDateTime -MyDateTime $MyDateTime
 
#>

Function Get-CVJSONDateTime
{
    Param
        (
            [Parameter(Mandatory = $false, Position = 0)] [datetime] $MyDateTime = (Get-Date)
        )
    $ShortDateString = $MyDateTime.ToShortDateString()
    $strDateTime =  $ShortDateString.Substring(6,4)  + "-" +
                    $ShortDateString.Substring(3,2) + "-" +
                    $ShortDateString.Substring(0,2) + "T" +
                    $MyDateTime.TimeOfDay.ToString().Substring(0, $MyDateTime.timeofday.ToString().length -4) + "Z"
   
   $strDateTime 
}