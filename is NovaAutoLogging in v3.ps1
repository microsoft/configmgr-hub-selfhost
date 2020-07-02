﻿
$ComputerLocalHost = Get-Content env:computername
$UserProperty = @{n="User";e={(New-Object System.Security.Principal.SecurityIdentifier $_.ReplacementStrings[1]).Translate([System.Security.Principal.NTAccount])}}
$TypeProperty = @{n="Action";e={if($_.EventID -eq 7001) {"Logon"}}}
$TimeProperty = @{n="Time";e={$_.TimeGenerated}}
$MachineNameProperty = @{n="MachinenName";e={$_.MachineName}}
$Found = "No Interactive Logins" 
$Since = Get-Date 4/01/18

$Results = Get-EventLog System -InstanceID 7001 -Source Microsoft-Windows-Winlogon  -ComputerName $ComputerLocalHost -After $Since

foreach($Result in $Results)
{
  $test = $Result | select $UserProperty, $TypeProperty,$TimeProperty,$MachineNameProperty 
  $User=$test.User 

  if($test.User -like "*novaauto*")
  {
    $Found = "Last Login " +$Test.time
    break
  }   
  Else 
  {  
    $Found = "No Logins" 
  }
}
$Found
