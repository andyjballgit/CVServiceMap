<# 
 .Synopsis
  For a given ADGroup Name, enumerates Members and checks to see if active in Service Map. Idea is that AD Group will contain Computer Accounts of Servers that should be in ServiceMap

 .Description
  
 Prequisites
 -----------
 #ie.
 AzureRM Modules - tested on 3.4 
 Get-CVServiceMapMachineList
 AD Cmdlets / RSAT 

 Returns 
 -------
 table of Group Members / whether Service Map Found (true , false)

 Limitations and Known Issues
 ----------------------------


 Backlog 
 --------
 

 Change Log
 ----------
 v1.00 Andy Ball 17/03/2017 Base Version
 

 .Parameter OMSWorkspaceName

 .Parameter ResourceGroupName 

 .Parameter SubscriptionName

 .Parameter ADGroupName 

 .Parameter PingMissingComputers

 .Example
 Get-CVServiceMapMissingByADGroup -OMSWorkspaceName "MyOMSWorkspaceName" -ResourceGroupName "ItsResourceGroup" -SubscriptionName "Live" -ADGroupName "ADGroup to check" -PingMissingComputers = $true 


#>

Function Get-CVServiceMapMissingByADGroup
{
    Param
        (
            [Parameter(Mandatory = $true, Position = 0)]  [string] $OMSWorkspaceName,
            [Parameter(Mandatory = $true, Position = 1)]  [string] $ResourceGroupName,
            [Parameter(Mandatory = $false, Position = 2)]  [string] $SubscriptionName,
            [Parameter(Mandatory = $true, Position = 3)]  [string] $ADGroupName, 
            [Parameter(Mandatory = $false, Position = 4)]  [boolean] $PingMissingComputers = $false, 
            [Parameter(Mandatory = $false, Position = 4)] [string] [Validateset ("PSObject", "JSON")] $ReturnType = "PSObject" 
        )

    $ErrorActionPreference = "Stop"
    $ResultSet = @()

    #1. Validate
	$ADModule = Get-Module ActiveDirectory -ListAvailable
	If ($ADModule -eq $null)
		{
			Write-Warning "Cannot Find Module ActiveDirectory. Quitting"	
			Break	
		}
    

    #2. GetComputer Accounts 
    Write-Host "Running Get-ADGroup $ADGroupName"
    $Group = Get-ADGroup $ADGroupName -properties *

    $GroupMembers = @()
    $Members = $Group.Members 
    ForEach ($Member in $Members)
        {
            $MemberFixed = $Member.Split(",")[0].Replace("CN=", "")
            $GroupMembers += $MemberFixed

        }

    $GroupMembersCount = @($GroupMembers).Count
    Write-Host "Group $ADGroupName has $GroupMembersCount member(s)"

    #3. Now get ServiceMapMembers 
    $ServiceMapMachines =  Get-CVServiceMapMachineSummary -OMSWorkspaceName $OMSWorkspaceName `
                                        -ResourceGroupName $ResourceGroupName `
                                        -SubscriptionName $SubscriptionName `
                                        -ShowAllVMsStatus $false 
              
    $CurrentGroupMemberNum = 1 

    ForEach($GroupMember in $GroupMembers)
        {
            $FoundRecord = $null 
            [boolean]$PingedOK = $null 

            Write-Host "Processing GroupMember = $GroupMember ($CurrentGroupMemberNum of $GroupMembersCount)" -ForegroundColor Green 
            $FoundRecord = $ServiceMapMachines | Where {$_.ComputerName -eq $GroupMember}
            If ($FoundRecord -ne $null)
                {
               
                    $Found = $true  
                    $PingedOK = "N\A"
                }
            Else
                {
                    $Found = $false 

                    If($PingMissingComputers)
                        {
                            Write-Host "`tNot Found in Service Map. Pinging"
                            $PingedOK = Test-Connection -ComputerName $GroupMember -Quiet
                            Write-Verbose "`t$Ping result = $PingedOK"

                        }
                    Else
                        {
                            $PingedOK = "N\A"
                        }
                }

            
           $ResultSet += $Host | Select  @{Name = "ComputerName" ; Expression = {$GroupMember}}, 
                                         @{Name = "Found" ; Expression = {$Found}}, 
                                         @{Name = "Pingable" ; Expression = {$PingedOK}}

           $CurrentGroupMemberNum++

        }                 

    $ResultSet


}


