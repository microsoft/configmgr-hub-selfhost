#Requires -RunAsAdministrator

#=============================================================================================================================
#
# Script Name:     CopyClientLogs.ps1
# Creation Date:   4/06/2018
# Author:          Eric C. Mattoon (ermatt)
#
#   Version:       01.00.0006
#   Version Date:  03/12/2019
# 
#   Description:   This PowerShell script will copy the logs in the %windir%\CCM\logs, %windir%ccmsetup\logs and
#                  %ProgramFiles%\Microsoft Policy Platform\PolicyPlatformClient.log folders/file to a share on SCCMSQL01
#                  that is accessibleto all product group members. The Security Group CMDF_SQL_Read_OnPremise has as its 
#                  members SCCM Engineering FTE WW & SCCMEngineering Vendor WW as of script Version Date.
#
#   NOTES:         Script for managing Configuration Manager Dogfood OPC, DFD, DFE, DFS. This script will copy logs to an accessible
#                  share on SCCMSQL01. The share is\\sccmsql01\DogfoodClientLogs\DogfoodClient_Logs. Originally re-adapted from
#                  CopyCrashDumpsFolderContents.ps1
#
#                  .1003  This version changes the foldername to include a datetime stamp. It does not account for AM/PM just HH:MM
#                  .1104  Adds function Set-Owner and calls it against ccmsetup folder since we just re-ACL'd that sometime in 1810
#                         and I could no longer get ccmestup.log files...
#                  .1005  Deleted the function it did not work... found another workaround
#                  .1006  Add %windir%\ccm\systemtemp\*.bak to the files collected
#
#=============================================================================================================================

#=============================================================================================================================
#
#  Initialization Section
#
#=============================================================================================================================

# Set up the variables

$fileFound = "False"
$logsSrc1 = "$env:windir\ccm\logs"
$logsSrc2 = "c:\windows\ccmsetup\logs\*.*"
$logsSrc3 = "$env:ProgramFiles\Microsoft Policy Platform\PolicyPlatformClient.log"
$logsSrc4 = "$env:windir\ccm\systemtemp\*.bak"

# Computername + date/time inf
$datestr = (Get-Date).ToString("yyyyMMdd_hhmm")
$foldername = $env:COMPUTERNAME + "_" + $datestr


# Set the Destination Folder
$destinationFolder = "\\sccmsql01\DogfoodClientLogs\DogfoodClient_Logs\$foldername"

#=============================================================================================================================
#
#  Function Section
#
#=============================================================================================================================

  # Function did not work

 
#=============================================================================================================================
#
#  Main Processing Section
#
#=============================================================================================================================
          

# If they are there, copy them, otherwise do nothing

if($logsSrc1){Copy-Item $logsSrc1 $destinationFolder\CCM_Logs\ -Recurse -Force}
if($logsSrc2){Copy-Item $logsSrc2 $destinationFolder -Force}
if($logsSrc3){Copy-Item $logsSrc3 $destinationFolder\PolicyPlatformClient.log -Force}
if($logsSrc4){Copy-Item $logsSrc4 $destinationFolder\systemtemp\*.bak -Force}

# End of script  