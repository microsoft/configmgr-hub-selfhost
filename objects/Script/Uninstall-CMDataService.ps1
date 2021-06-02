param ($InstallationMode)
$ccmPath=[System.Environment]::ExpandEnvironmentVariables("%windir%\ccm")
$SensorPath = $ccmPath+'\CMDataService.exe'

if($InstallationMode -eq 'Install')
{

    # Stop Service if already running
    Stop-Service 'MEM Data Service' -Force -ErrorAction SilentlyContinue
            
    # copy content 
    $contentPath = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent
    write-output $contentPath
    write-output $ccmPath

    Copy-Item -force (join-path $contentPath "SensorBatteryTask.exe") -Destination $ccmPath 
    Copy-Item (join-path $contentPath "CMDataService.exe") -Destination $ccmPath -Force

    # Create service if it doesn't already exist
    $service = Get-Service -Name "MEM Data Service" -ErrorAction SilentlyContinue
    if ($service.Length -eq 0) 
    {
        $params = @{
            Name = "MEM Data Service"
            BinaryPathName = $SensorPath
            DisplayName = "MEM Data Service"
            StartupType = "Automatic"
            Description = "This is a MEM Data Service"
        }
        New-Service @params
    }
    
    # Start the service 
    Start-Service -Name "MEM Data Service"
}
elseif($InstallationMode -eq 'Uninstall')
{
    $dotNetkey = "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\.NETFramework"
    $dotNetValue = "InstallRoot"
    $dotNetPath = (Get-ItemProperty -Path $dotNetkey -Name $dotNetValue).$dotNetValue

    $dotNetVersion = "v1"
    $path = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\.NETFramework |ForEach-Object {
        $keys = ($_.Name).Split('\')
        $subkeyName = $keys[$keys.Length-1]
        if($subKeyName -match '^v' -and $dotNetVersion -lt $subKeyName) {$dotNetVersion = $subKeyName}
        } 

    $InstallUtilPath = $dotNetPath+$dotNetVersion
    $SensorPath = $ccmPath+'\CMDataService.exe'
    $command = $InstallUtilPath+'\InstallUtil.exe'+' /uninstall '+""""+$SensorPath+""""


    Invoke-Command -ScriptBlock { iex $command } 

}