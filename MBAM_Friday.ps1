param
(
    [string]$PolicyFilePath
)

$RegistryEdited = "Passed"
$MBAMKey = 'HKLM\SOFTWARE\Microsoft\MBAM'
$MBAMPolicyKey = 'HKLM\SOFTWARE\Policies\Microsoft\FVE'
$MDOPBitLockerManagement = 'HKLM\SOFTWARE\Policies\Microsoft\FVE\MDOPBitLockerManagement'
$PolicyAdmxFileDestination = $env:SystemRoot+"\PolicyDefinitions\"
$PolicyAdmlFileDestination = $env:SystemRoot+"\PolicyDefinitions\en-US\"

if((-not(Test-Path $env:SystemRoot\PolicyDefinitions\BitLocker*.admx)) -or (-not(Test-Path $env:SystemRoot\PolicyDefinitions\BitLocker*.admx)))
{   
    Copy-Item $PolicyFilePath -Filter *.admx -Destination $PolicyAdmxFileDestination –Recurse -ErrorAction Stop
    Copy-Item $PolicyFilePath -Filter *.adml -Destination $PolicyAdmlFileDestination –Recurse -ErrorAction Stop
}
else
{
     echo "Bitlocker adml and admx files already exists"  
 
}

if((-not(Test-Path $env:SystemRoot\PolicyDefinitions\BitLocker*.admx)) -or (-not(Test-Path $env:SystemRoot\PolicyDefinitions\BitLocker*.admx)))
{
    echo "*.adml and *.admx Failed to copy"  
}

if(Test-Path HKLM:\SOFTWARE\Microsoft\MBAM)
{
    Set-ItemProperty -path "Registry::$MBAMKey" -Name "MBAMPolicyEnforced" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMKey" -Name "OSVolumeProtectorPolicy" -Type "DWORD" -Value "1"  
    Set-ItemProperty -path "Registry::$MBAMKey" -Name "NoStartupDelay" -Type "DWORD" -Value "1"
}
else
{
    $RegistryEdited = "Failed"
}

if(!(Test-Path HKLM:\SOFTWARE\Policies\Microsoft\FVE) )
{
    New-Item -Path "Registry::$MBAMPolicyKey" -ItemType RegistryKey -Force
    New-Item -Path "Registry::$MDOPBitLockerManagement" -ItemType RegistryKey -Force
}


if (Test-Path HKLM:\SOFTWARE\Policies\Microsoft\FVE)
{
    if(!(Test-Path HKLM:\SOFTWARE\Policies\Microsoft\FVE\MDOPBitLockerManagement) )
    {
        New-Item -Path "Registry::$MDOPBitLockerManagement" -ItemType RegistryKey
    } 
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "AutoUnlockFixedDataDrive" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "FddEnforcePolicyPeriod" -Type "DWORD" -Value "0"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "ShouldEncryptFixedDataDrive" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "UseFddEnforcePolicy" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "UseMBAMServices" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "KeyRecoveryServiceEndPoint" -Type "ExpandString" -Value "http://sccmdfcas.redmond.corp.microsoft.com:80/MBAMRecoveryAndHardwareService/CoreService.svc"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "KeyRecoveryOptions" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "ClientWakeupFrequency" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "UseStatusReportingService" -Type "DWORD" -Value "0"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "ShouldEncryptOSDrive" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "OSDriveProtector" -Type "DWORD" -Value "4"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "UseOsEnforcePolicy" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "OsEnforcePolicyPeriod" -Type "DWORD" -Value "0"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "StatusReportingFrequency" -Type "DWORD" -Value "720"
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "StatusReportingServiceEndpoint" -Type "ExpandString" -Value ""
    Set-ItemProperty -path "Registry::$MDOPBitLockerManagement" -Name "UseKeyRecoveryService" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "EnableBDEWithNoTPM" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "DisallowStandardUserPINReset" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "UsePartialEncryptionKey" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "UsePIN" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "UseAdvancedStartup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "UseTPM" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "UseTPMKey" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "UseTPMPIN" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "UseTPMKeyPIN" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "MinimumPIN" -Type "DWORD" -Value "5"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSPassphrase" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSPassphraseComplexity" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSPassphraseLength" -Type "DWORD" -Value "8"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSPassphraseASCIIOnly" -Type "DWORD" -Value "0"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "ActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RequireActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "ActiveDirectoryInfoToStore" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSRecovery" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSManageDRA" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSRecoveryPassword" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSRecoveryKey" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSActiveDirectoryInfoToStore" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSRequireActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVPassphrase" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVEnforcePassphrase" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVPassphraseComplexity" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVPassphraseLength" -Type "DWORD" -Value "8"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVRecovery" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVManageDRA" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVRecoveryPassword" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVRecoveryKey" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVActiveDirectoryInfoToStore" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "FDVRequireActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RDVRecovery" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RDVManageDRA" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RDVRecoveryPassword" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RDVRecoveryKey" -Type "DWORD" -Value "2"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RDVActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RDVActiveDirectoryInfoToStore" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "RDVRequireActiveDirectoryBackup" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "EnableNonTPM" -Type "DWORD" -Value "1"
    Set-ItemProperty -path "Registry::$MBAMPolicyKey" -Name "OSEnablePrebootInputProtectorsOnSlates" -Type "DWORD" -Value "1"
}
else
{
    $RegistryEdited = "Failed"
}

ECHO $RegistryEdited