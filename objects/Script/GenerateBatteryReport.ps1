$BatteryReportXML = '\\scfs\users\jyhlin\dataninja\power\BatteryReports\'+(Get-CIMInstance CIM_ComputerSystem).Name+'.xml'
powercfg /batteryreport /xml /output $BatteryReportXML
$BatteryReportHTML = '\\scfs\users\jyhlin\dataninja\power\BatteryReports\'+(Get-CIMInstance CIM_ComputerSystem).Name+'.html'
powercfg /batteryreport /output $BatteryReportHTML