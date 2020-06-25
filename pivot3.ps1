param( [string]$wmiquery, [string] $select )

$wmiquery = $wmiquery.Replace('#s',' ').Replace('#q','''').Replace('#k',':').Replace('#c',',').Replace('##','#')
$select = $select.Replace('#s',' ').Replace('#q','''').Replace('#k',':').Replace('#c',',').Replace('##','#')

# Parse the select parameter 
$propertyFilter = @()

foreach($p in $select.Split(','))
{
    $p = $p.Split(':')

    if( $p[1] -ne 'Device' )
    {
        $propertyFilter+= $p[0]
    }
}

#Create the result set
$results = New-Object System.Collections.Generic.List[Object]

#deal with one-offs that don't work well over WMI
if( $wmiquery -eq 'Autostart' )
{
    foreach($runOnce in (get-item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run').GetValueNames())
    {
        $hash = @{ Command = (get-item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run').GetValue($runOnce).ToString() }
        $results.Add( $hash )
    }
}
elseif( $wmiquery -eq 'SMBConfig' )
{
    # Get Smb Config
    $smbConfig = Get-SmbServerConfiguration | Select-object -Property $propertyFilter

    #Add to results list
    $results.Add($smbConfig)
}
elseif( $wmiquery -eq 'Users' )
{
    $users = New-Object System.Collections.Generic.List[String]

    foreach( $user in (get-WmiObject -class Win32_LoggedOnuser | Select Antecedent))
    {
        $parts = $user.Antecedent.Split("""")
        
        # If this is not a built-in account
        if(( $parts[1] -ne "Window Manager" ) -and (($parts[1] -ne $env:COMPUTERNAME) -or (($parts[3] -notlike "UMFD-*")) -and ($parts[3] -notlike "DWM-*")))
        {
            # add to list
            $users.Add($parts[1] + "\" + $parts[3])            
        }
    }
   
    # Create unique set of users
    $users | sort-object -Unique | foreach-object { $results.Add(@{ UserName = $_ }) }         
}
elseif( $wmiquery -eq 'IPConfig' )
{
    $ipconfigs = (Get-NetIPConfiguration)

    foreach( $ipconfig in $ipconfigs )
    {
        $hash = @{
            InterfaceAlias = $ipconfig.InterfaceAlias
            Name = $ipconfig.NetProfile.Name
            InterfaceDescription = $ipconfig.InterfaceDescription
            Status = $ipconfig.NetAdapter.Status
            IPV4Address = $ipconfig.IPv4Address.IPAddress
            IPV6Address = $ipconfig.IPv6Address.IPAddress
            IPV4DefaultGateway = $ipconfig.IPv4DefaultGateway.NextHop
            IPV6DefaultGateway = $ipconfig.IPv6DefaultGateway.NextHop
            DNSServerList = ($ipconfig.DNSServer.ServerAddresses -join "; ")
        }
    
        $results.add($hash)
    }
}
elseif( $wmiquery -eq 'Connections' )
{
    $netstat = "$Env:Windir\system32\netstat.exe"
    $rawoutput = & $netstat -f
    $netstatdata = $rawoutput[3..$rawoutput.count] | ConvertFrom-String | select p2,p3,p4,p5 | where p5 -eq 'established' | select P4  

    foreach( $data in $netstatdata)
    {        
        #Add to results list
        $hash = @{ Server = $data.P4.Substring(0,$data.P4.LastIndexOf(":")) }
        $results.Add($hash )
    }        
}
elseif( $wmiquery -eq 'Updates' )
{
    $Session =  [activator]::CreateInstance([type]::GetTypeFromProgID("Microsoft.Update.Session",$null))
    $Searcher = $Session.CreateUpdateSearcher()

    # Search for any uninstalled updates
    $MissingUpdates = $Searcher.Search("DeploymentAction=* and IsInstalled=0 and Type='Software'")  
    
    if ($MissingUpdates.Updates.Count -gt 0) 
    {
        foreach( $Update in $MissingUpdates.Updates )
        {   
            $KBArticleIDs = ""
            foreach( $KB in $Update.KBArticleIDs)
            {
                if( $KBAticleIDs.Length -gt 0 )
                {
                    $KBArticleIDs = $KBArticleIDs + ","
                }

                $KBArticleIDs = $KBArticleIDs + "KB$KB"
            }
            
            $SecurityBulletinIDs = ""
            foreach( $BulletinID in $Update.SecurityBulletinIDs)
            {
                if( $SecurityBulletinIDs.Length -gt 0 )
                {
                    $SecurityBulletinIDs = $SecurityBulletinIDs + ","
                }

                $SecurityBulletinIDs = $SecurityBulletinIDs + $BulletinID
            }

            $Categories = ""
            foreach( $Category in $Update.Categories)
            {
                if( $Categories.Length -gt 0 )
                {
                    $Categories = $Categories + ","
                }

                $Categories = $Categories + $Category.Name
            }

            #Add to results list
            $hash = @{                 
                Title = $Update.Title
                UpdateID = $Update.Identity.UpdateID
                KBArticleIDs = $KBArticleIDs
                SecurityBulletinIDs = $SecurityBulletinIDs                                
                Categories = $Categories                
            }
                
            $results.Add($hash)            
        }
    } 
}
elseif( $wmiquery -eq 'AppCrash' )
{
    $crashes = get-eventlog -LogName Application  -After (Get-Date).AddDays(-7) -InstanceId 1000 -Source 'Application Error'

    foreach ($crash in $crashes)  
    {
        $hash = @{
                FileName = $crash.ReplacementStrings[0]
                Version = $crash.ReplacementStrings[1]
                ReportId = $crash.ReplacementStrings[12]
                DateTime = $crash.TimeGenerated.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
        } 
    
        $results.Add($hash)        
    }
}
elseif( $wmiquery -eq 'Administrators' )
{
    Try
    {
        $admins = (get-localgroupmember Administrators)
        foreach( $admin in $admins )
        {
            $hash = @{
                ObjectClass = $admin.ObjectClass
                Name = $admin.Name
                PrincipalSource = $admin.PrincipalSource
            }

            $results.Add($hash)        
        }
    }
    Catch
    {
    }
}
elseif ($wmiquery.StartsWith("File(") )
{
    $first = $wmiquery.IndexOf("'")+1
    $last = $wmiquery.LastIndexOf("'")
    
    $fileSpec = [System.Environment]::ExpandEnvironmentVariables( $wmiquery.Substring($first, $last-$first))
   
    foreach( $file in (Get-Item -ErrorAction SilentlyContinue -Path $filespec))
    {
        $fileHash = ""

        Try
        {
            $fileHash = (get-filehash -ErrorAction SilentlyContinue -Path $file).Hash 
        }
        Catch
        {
        }

         $hash = @{
            FileName = $file.FullName
            Mode = $file.Mode
            LastWriteTime = $file.LastWriteTimeUtc.ToString("yyyy-MM-dd HH:mm:ss")
            Size = $file.Length
            Version = $file.VersionInfo.ProductVersion
            Hash = $fileHash
         }

         $results.Add($hash)

    }
}
elseif ($wmiquery.StartsWith("EventLog(") )
{
    $first = $wmiquery.IndexOf("'")+1
    $last = $wmiquery.LastIndexOf("'")    
    $logName = $wmiquery.Substring($first, $last-$first)
    
    try
    {
        $events = get-eventlog -LogName $logName -Newest 50 
    
        foreach ($event in $events)  
        {
            $hash = @{
                    DateTime = $event.TimeGenerated.ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
                    EntryType = $event.EntryType
                    Source = $event.Source
                    EventID = $Event.EventID
                    Message = $Event.Message
            } 
    
            $results.Add($hash)        
        }
    }
    Catch
    {
    }
}
elseif ($wmiquery.StartsWith("CcmLog(") )
{
    $first = $wmiquery.IndexOf("'")+1
    $last = $wmiquery.LastIndexOf("'")    
    $logFileName = $wmiquery.Substring($first, $last-$first)

    $ccmlogdir = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\CCM\Logging\@Global' -Name LogDirectory).LogDirectory
    $logPath = (join-path $ccmlogdir ($logFileName+".log"))

    #verify format of file name
    if(( $logFileName -match '[\w\d-_@]+' ) -and ([System.IO.File]::Exists($logPath)))
    {        
        $lines = (get-content -path $logpath -Tail 50)

        [regex]$ccmLog = '<!\[LOG\[(?<logtext>.*)\]LOG\]!><\s*time\s*\=\s*"(?<time>\d\d:\d\d:\d\d)[^"]+"\s+date\s*\=\s*"(?<date>[^"]+)"\s+component\s*\=\s*"(?<component>[^"]*)"\s+context\s*\=\s*"(?<context>[^"]*)"\s+type\s*\=\s*"(?<type>[^"]+)"\s+thread\s*\=\s*"(?<thread>[^"]+)"\s+file\s*\=\s*"(?<file>[^"]+)"\s*>'

        foreach( $line in $lines )
        {
            $m = $ccmLog.Match($line)

            if( $m.Success -eq $true )
            {
                $hash = @{
                    LogText = $m.Groups["logtext"].Value
                    DateTime = ([DateTime]($m.Groups["date"].Value +' '+ $m.Groups["time"].Value)).ToUniversalTime()
                    Component = $m.Groups["component"].Value
                    Context = $m.Groups["context"].Value
                    Type = $m.Groups["type"].Value
                    Thread = $m.Groups["thread"].Value
                    File = $m.Groups["file"].Value
                }

                $results.Add($hash)
            }   
        }
    }
}
elseif ($wmiquery.StartsWith("Registry(") )
{
    $first = $wmiquery.IndexOf("'")+1
    $last = $wmiquery.LastIndexOf("'")
    $regSpec =  $wmiquery.Substring($first, $last-$first)
   
    $result = New-Object System.Collections.Generic.List[Object]

    foreach( $regKey in (Get-Item -ErrorAction SilentlyContinue -Path $regSpec) )
    {
        foreach( $regValue in $regKey.Property )
        {
            $hash = @{
                Property = $regValue
                Value = $regKey.GetValue($regValue).ToString()
            }

            $results.Add($hash)
        }
    }
}
else
{
    $namespace = "root/cimv2"

    # if there is a namespace
    if( ($wmiquery.StartsWith("root/")) -and ($wmiquery.Contains(":")))
    {
        $seperator = $wmiquery.IndexOf(":")
        $namespace =  $wmiquery.Substring(0, $seperator)
        $wmiquery = $wmiquery.Substring($seperator+1)
    }

    # Execute the query
    $wmiresult = (get-wmiobject -query $wmiquery -Namespace $namespace) 

    # create result set
    $result = New-Object System.Collections.Generic.List[Object]

    foreach( $obj in $wmiresult )
    {
        $hash = @{}

        foreach( $prop in $propertyFilter )
        {            
           if(  $obj.Properties[$prop].Type -eq "DateTime" )
           {
             $hash[$prop] = [System.Management.ManagementDateTimeconverter]::ToDateTime($obj[$prop]).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss")
           }
           else
           {
             $hash[$prop] = $obj[$prop]
           }
        }

        $results.Add($hash)
    }
}

#format the result as an xml 
$sb = New-Object System.Text.StringBuilder
$sw = New-Object System.IO.StringWriter($sb)
$writer = New-Object System.Xml.XmlTextWriter($sw)

$writer.WriteStartDocument()
$writer.WriteStartElement("result")

foreach( $obj in $results )
{
    $writer.WriteStartElement("e")
        
    foreach( $prop in $propertyFilter )
    {
        $Value = $obj."$prop"
                
        if( $Value -ne $null)
        {
            $writer.WriteAttributeString("$prop", $Value.ToString() )
        }            
    }

    $writer.WriteEndElement()

}

$writer.WriteEndElement()
$writer.WriteEndDocument()
$writer.Flush()
$writer.Close()

$writer.Close()
$sw.Dispose()

$Bytes = [System.Text.Encoding]::Unicode.GetBytes($sb.ToString())

if( $Bytes.Length -lt 4096 ) 
{
    return [Convert]::ToBase64String($Bytes)
}
else
{
    # Otherwise compress
    [System.IO.MemoryStream] $output = New-Object System.IO.MemoryStream
    $gzipStream = New-Object System.IO.Compression.GzipStream $output, ([IO.Compression.CompressionMode]::Compress)
    $gzipStream.Write( $Bytes, 0, $Bytes.Length )
    $gzipStream.Close()
    $output.Close()

    return [Convert]::ToBase64String($output.ToArray())
}