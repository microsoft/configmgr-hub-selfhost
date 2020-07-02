#=============================================================================================================================
#
# Script Name:     Dis_SMBv1.ps1
# Creation Date:   05/16/2018
# Author:          Eric C. Mattoon (ermatt)
#
#   Version:       01.00.0003
#   Version Date:  05/16/2018
# 
# Description:     Purpose of this script is to disable SMBv1:
#
#                  First check if SMBv2 &/or SMBv3 is turned on:
#                       1) If it is not, enable it so we don't lose the connection
#                       2) Otherwise we are good to disable
#
#=============================================================================================================================

#Initialize whether SMBv1 & SMBv2 are turned on for the current machine

$smbv1Found = Get-SmbServerConfiguration | Select -ExpandProperty EnableSMB1Protocol
$smbv2Found = Get-SmbServerConfiguration | Select -ExpandProperty EnableSMB2Protocol

# If we find SMBv1
if($smbv1Found){
    # Check to see if SMBv2 is on or not, we don't want to cut off connectivity to the box
    # If SMBv2 is on, we can safely shut off SMBv1
    if($smbv2Found){
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    }
    # Otherwise we need to turn on SMBv2 before we turn off SMBv1
    else{
        Set-SmbServerConfiguration -EnableSMB2Protocol $true -Force
        Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    }
}
else{
    # Don't do anything, SMBv1 is off after all...
}

$smbv1Found = Get-SmbServerConfiguration | Select -ExpandProperty EnableSMB1Protocol
$smbv2Found = Get-SmbServerConfiguration | Select -ExpandProperty EnableSMB2Protocol

$output = "SMBv1 = $smbv1Found, SMBv2 = $smbv2Found"

return $output