#Requires -RunAsAdministrator

#=============================================================================================================================
#
# Script Name:     DogfoodOfficeLogFilesANDRegistry.ps1
# Creation Date:   09/17/2019
# Last change by:  Eric C. Mattoon (ermatt)
#
#   Version:       01.00.0001
#   Version Date:  09/18/2019
# 
# Description:     Purpose of this script is to install the log files and set registry setting
#
# Notes:           Logs will reside in path 
#                  v .0001 added registry bit
#
#=============================================================================================================================


# Define Variables
$appDataPath = [System.Environment]::ExpandEnvironmentVariables("%LOCALAPPDATA%")
$destLogPath = "$appDataPath\Microsoft\Office\16.0\Telemetry"
$srcLogPath = "\\sccmsql01\Dogfood\Admin\Scripts\Content\DFOffLog\*.tbl"

$reg = [WMIClass]"ROOT\DEFAULT:StdRegProv"
$offKey = "HKLM:\SOFTWARE\Microsoft\Office\16.0"
$logKey = "Software\Policies\Microsoft\Office\16.0\OSM"
$path = "HKCU:\Software\Policies\Microsoft"
$keyVal = "EnableLogging"
$keyValVal = "1"

$errMsg = "","",""

# Main script

If (-not (Test-Path $offKey)){
    Return "Office 16.0 not installed, nothing to do."
	exit 0
}  

If (Test-Path $destLogPath){
    #Probably should check for the tables here, but for now assume they are there if path exists
    #But for now just continue
    Return "Log files exist, nothing to do"
	exit 0
}
Else{
    #Create the path, copy the files
    New-Item -ItemType Directory -Path $destLogPath -Force
    Copy-Item -Path $srcLogPath -Destination $destLogPath -Recurse -Force
    Return "Copied files to path"
	exit 0
}