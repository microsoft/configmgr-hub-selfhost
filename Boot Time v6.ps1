
function GetWinLogonPhase($startTime,$phaseName)
{
    $startMessageTime = ''
    $endMessageTime = ''

    foreach( $msg in (Get-WinEvent -ErrorAction SilentlyContinue -Oldest -FilterHashTable @{ LogName = "Microsoft-Windows-Winlogon/Operational"; StartTime = $startTime }) )
    {

        # we hit a logon -- stop counting
        if( $msg.Id -eq 1 )
        {
            if( $endMessageTime -eq '' )
            {
                $endMessageTime = $msg.TimeCreated
            }

            break
        }

        if( $msg.Message.Contains($phaseName) )
        {
            if( $startMessageTime -eq '' -and $msg.Id -eq 811 )
            {
                $startMessageTime = $msg.TimeCreated
            }

            if( $startMessageTime -ne '' -and $msg.Id -eq 812 )
            {
                $endMessageTime = $msg.TimeCreated
            }            
        } 
        elseif( $startMessageTime -ne '' )
        {
            # moved on to a new phase
            $endMessageTime = $msg.TimeCreated
            break
        }
    }

    if( $startMessageTime -eq '' )
    {
        return 0
    }
    else
    {
        return ($endMessageTime - $startMessageTime).TotalSeconds
    }
}


function GetBootInfo( $starttime )
{
    $kernal = (Get-WinEvent -Max 1 -Oldest -FilterHashTable @{ LogName = "System"; ProviderName='Microsoft-Windows-Kernel-General'; StartTime = $startTime; ID = 12 }).TimeCreated

    # if we did not find a kernal message (occurs sometimes due to time changes -- look backward)
    if( $kernal -eq '' )
    {
        $kernal = (Get-WinEvent -Max 1 -FilterHashTable @{ LogName = "System"; ProviderName='Microsoft-Windows-Kernel-General'; EndTime = $startTime; ID = 12 }).StartTime

        if( $kernal -ne '' )
        {
            $startTime = $kernal
        }
    }

    # Handle cases when time changes
    $kernelInitTime = ($kernal-$startTime).TotalSeconds
    if( $kernelInitTime -lt 0 )
    {
        $kernelInitTime = $null
    }

    $booted = (Get-WinEvent -Max 1 -Oldest -FilterHashTable @{ LogName = "System"; ProviderName='EventLog'; StartTime = $kernal; ID = 6005 }).TimeCreated

    
    #
    # Get informaiton about Winlogon
    #
    
    # Since we are looking at a different log with different retention we need to make sure it is as old as startup event
    $oldestWinLogonEvent = (Get-WinEvent -Max 1 -ErrorAction SilentlyContinue -Oldest -FilterHashTable @{ LogName = "Microsoft-Windows-Winlogon/Operational" }).TimeCreated 

    if( $oldestWinLogonEvent -le $startTime )
    {
        $winLogonStarted = (Get-WinEvent -Max 1 -ErrorAction SilentlyContinue -Oldest -FilterHashTable @{ LogName = "Microsoft-Windows-Winlogon/Operational"; StartTime = $startTime }).TimeCreated

        $criticalServicesStartTime = [Math]::Max( ($winLogonStarted - $booted).TotalSeconds, 0.0)
        $gpTime=(GetWinLogonPhase $kernal 'GPClient');    
        $windowsUpdateTime=(GetWinLogonPhase $kernal 'TrustedInstaller'); 
    }
    else
    {
        $criticalServicesStartTime = $null
        $gpTime=$null    
        $windowsUpdateTime=$null
    }


    #
    #look up time spent in Bios (available on UEFI machines)
    #
    $biosTime = (Get-ItemProperty -ErrorAction SilentlyContinue -Path 'HKLM:System\CurrentControlSet\Control\Session Manager\Power' -Name FwPOSTTime).FwPOSTTime / 1000.0

    if( $biosTime -eq 0 )
    {
        $biosTime = $null
    }

    #
    # Calcualte the time we were shutdown
    #
    $timeSpentShutdown = $null

    $lastEventBeforeShutdown = (Get-WinEvent -ErrorAction SilentlyContinue -Max 1 -FilterHashTable @{ LogName = "System"; EndTime = $kernal.AddSeconds(-1) })
    
    if( $lastEventBeforeShutdown.Count -eq 1 )
    {
        $timeSpentShutdown = ($startTime-$lastEventBeforeShutdown.TimeCreated).TotalSeconds
    }


    #
    #check if it was an unexpected shutdown
    #
    $badShutdown = (Get-WinEvent -ErrorAction SilentlyContinue -Oldest -FilterHashTable @{ LogName = "System"; ProviderName='Microsoft-Windows-Kernel-Power'; StartTime = $kernal; EndTime= $booted; ID = 41 }).Count

    if( $badShutdown -gt 0 )
    {
        $shutdownReason = "Unexepected"
    }
    else
    {
        $shutdownReason = "Unknown"


        $shutdownReasonEvent = (Get-WinEvent -ErrorAction SilentlyContinue -Oldest -Max 1 -FilterHashTable @{ LogName = "System"; ProviderName='User32'; EndTime = $startTime; ID = 1074 })
        
        if( $shutdownReasonEvent.Count -eq 1 -and $shutdownReasonEvent.Message.StartsWith('The process') )
        {        
            $processName = $shutdownReasonEvent.Message.Substring(12,$shutdownReasonEvent.Message.IndexOf('(')-13).Trim().Split("\")
            $shutdownReason = $processName[$processName.Length-1]
        }
    }

    return %{[PSCustomObject] @{
        StartupDateTime = $startTime.ToString("yyyy-MM-dd HH:mm:ss"); 

        # Bootup Timme
        BIOSTime=$biosTime; 
        KernelInitTime=$kernelInitTime; 
        SystemBootTime = ($booted-$kernal).TotalSeconds; 
        CriticalServicesStartTime = $criticalServicesStartTime;

        #winlogon time
        GPTime=$gpTime;    
        WindowsUpdateTime=$windowsUpdateTime; 
    
        #other
        TimeShutdown = $timeSpentShutdown; 
        ShutdownReason = $shutdownReason; 
    }}
}

function GetMedian( $data )
{
    $data = $data |sort

    if( $data.count -eq 0 )
    {
        return $null
    }
    elseif ($data.count%2) {
        #odd
        return $data[[math]::Floor($data.count/2)]
    }
    else {
        #even
        return ($data[$data.Count/2],$data[$data.count/2-1] |measure -Average).average
    }        
}

function GetMax( $data )
{
    return ($data | measure -Maximum).Maximum    
}


try
{

    # Find last time system was turned on
    $os = Get-WmiObject -Class win32_operatingsystem
    $startTime = $os.ConvertToDateTime($os.LastBootUpTime)
    $comp = Get-WmiObject -Class win32_ComputerSystem
    $results = @()

    # Get all reboots
    foreach( $reboot in (Get-WinEvent -Oldest -FilterHashTable @{ LogName = "System"; ProviderName='Microsoft-Windows-Kernel-General'; ID = 12 }))
    {
        $results += GetBootInfo( $reboot.TimeCreated )
    }

    #return $results | format-table


    return %{[PSCustomObject] @{
            BootCount = $results.Count
            LastStartupDateTime = $results[$results.Count-1].StartupDateTime 
            LastShutdownReason = $results[$results.Count-1].ShutdownReason

            # Bootup Timme
            BIOSTime = GetMedian  ($results | where-object BIOSTime -ne $null).BIOSTime;        
            MedianSystemBootTime = GetMedian  ($results | where-object SystemBootTime -ne $null).SystemBootTime;
            MedianCriticalServicesStartTime = GetMedian  ($results | where-object CriticalServicesStartTime -ne $null).CriticalServicesStartTime;
            MaxSystemBootTime = GetMax  ($results | where-object SystemBootTime -ne $null).SystemBootTime;
            MaxCriticalServicesStartTime = GetMax  ($results | where-object CriticalServicesStartTime -ne $null).CriticalServicesStartTime;

            #winlogon time
            MedianGPTime=GetMedian  ($results | where-object GPTime -ne $null).GPTime;    
            MedianWindowsUpdateTime= GetMedian  ($results | where-object WindowsUpdateTime -ne $null).WindowsUpdateTime;
            MaxGPTime=GetMax ($results | where-object GPTime -ne $null).GPTime;    
            MaxWindowsUpdateTime= GetMax ($results | where-object WindowsUpdateTime -ne $null).WindowsUpdateTime;
    
            #other
            MedianTimeShutdown = GetMedian  ($results | where-object TimeShutdown -ne $null).TimeShutdown;    

            # OS Info
            OsBuildNumber = $os.BuildNumber;
            OsName = $os.Caption;
            Make = $comp.Manufacturer;
            Model = $comp.Model;
            DomainJoined = $comp.PartOfDomain
        }}
    }
    catch
    {
        return $_.Exception.Message
    }