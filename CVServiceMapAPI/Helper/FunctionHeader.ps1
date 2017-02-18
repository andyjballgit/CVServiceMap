<# 
 .Synopsis
  Single line , succinct summary of what func does

 .Description
 Expand out here if required
  
 Prequisites
 -----------
 #ie.
 AzureRM Modules - tested on 3.4 
 Get-AzureRESTAuthHeader func

 Returns 
 -------
 ie 

 Limitations and Known Issues
 ----------------------------
 ie if had to shortcut / do a shonky 

 Backlog 
 --------
 May include above , but generally improvements , expanding functionality 

 Change Log
 ----------
 v1.00 Andy Ball 17/02/2017 Base Version
 

 .Parameter Param1

 .Parameter Param2

 .Example
 Put simplest example here 

 .Example
 A bit more complicated here

 .Example
 Mind blowing example here

#>

Function Get-SomethingOrOther
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName,
            [Parameter(Mandatory = $true, Position = 3)]  [string] $URISuffix, 
            [Parameter(Mandatory = $false, Position = 4)] [string] [Validateset ("PSObject", "JSON")] $ReturnType = "PSObject" 
        )

    $SomethingOrOther = "Hello"
    
    #return it
    $SomethingOrOther 


}