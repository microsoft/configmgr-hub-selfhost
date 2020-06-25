# Added by ermatt 2/21/2020 for remia

#Force Sensor evaluation action on clients

$strAction = "C4EAA67D-DD9A-0000-0000-000000000000"
try {
Invoke-WmiMethod -ComputerName $env:computername -Namespace root\ccm -Class SMS_Client -Name TriggerSchedule -ArgumentList $strAction -ErrorAction Stop | Out-Null
write-host "Sensor Triggered"
}
catch {
write-host "$env:computername`: $_" -ForegroundColor Red
}


# Expected return string: Sensor Triggered