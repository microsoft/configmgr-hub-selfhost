#Load DLL
[Reflection.Assembly]::LoadFrom("\\scfs\users\bflegg\cmperftrack\CMPerfSummarizer.dll") | out-null

# Get Activities
$activityLog = [CMPerfSummarizer.ActivityLog]::new() 
$results = New-Object System.Collections.Generic.List[Object]

foreach( $activity in $activityLog.GetUsageInLastXHours(24))
{
    if( $activity.ActivityDuration.TotalSeconds -lt 60 )
    {
        continue
    }
    $foo = "bar"

    $appVersion = ""
    try
    {
        $appVersion = $activity.GetApplicationVersion() 
    }
    catch
    {
    }

    $hash = @{
        Name = $activity.ActivityName
        Version = $appVersion
        Duration = $activity.ActivityDuration.TotalMilliseconds
        EventCount = $activity.EventCount
        LaunchTime = $activity.GetApplicationLaunchTime().TotalMilliseconds
    }

    $results.add($hash)
}

return $results