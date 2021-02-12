# ===================================================================
#
# Creates a directory named after the cab file 
# and expands the cab into that directdory. 
#
# ===================================================================
function searchAndExpand {
    param($directory)

    if((Test-Path $directory) -eq $true)
    {
        write-host "Searching directory" $directory "for cab files to expand.";

        (gci -path $directory *.cab -recurse) | foreach{
            $expandedDirectory = expandCabFile -dir $directory -cab $_;
            searchAndExpand -directory $expandedDirectory[0].FullName;
        }
    }
}

# ===================================================================
#
# Creates a directory named after the cab file 
# and expands the cab into that directdory. 
#
# ===================================================================
function expandCabFile
{
    param
    (
        $dir,
        $cab
    )

    $cabDir = $dir + "\_" + $cab.Name
    write-host "Expanding cab file:" $cab "to directory" $cabDir;

    mkdir $cabDir;
    expand $cab.FullName $cabDir -F:*;
    return $cabDir;
}

# ===================================================================
#
#   Detects if this submission is a console submission
#   and if so downloads the extension for verification.
#
# ===================================================================
function get-ChangedExtensions
{
    param
    (
        $srcBranch,
        $destBranch
    )
    
    write-host "Getting list of changed extensions";

    # return  the list of json files changed between the source and destination branches.
    $changed = git diff $srcBranch $destBranch --name-only | where-object { $_ -like "objects/ConsoleExtension/*.json"};

    write-host $changed

    return $changed;
}

# ===================================================================
#
#   Gets the build root directory based on the execution environment.
#
# ===================================================================
function get-BuildRootDirectory
{
    if($null -NE $Env:AGENT_NAME)
    {
        Write-host "running on agent machine ";

        $buildRoot = $Env:BUILD_REPOSITORY_LOCALPATH;

        return $buildRoot.ToString();
    }
    else
    {
        write-host "Test run, using local build environment.";
        Set-Location -Path ..;
        return (get-location).Path.ToString();
    }
}



# ===================================================================
#
#   Main entry point.
#
# ===================================================================
function Main
{
    get-EnvironmentVariables;

    $extensionJson = get-ChangedExtensions -srcBranch "remotes/origin/msilvey/pipeline" -destBranch "remotes/origin/master";

   if($null -ne $extensionJson)
    {
        $extensionRootDirectory = (get-BuildRootDirectory); 

        write-host "ConsoleExtension directory:" + $extensionRootDirectory;

        foreach($json in $extensionJson)
        {
            $jsonFile = $extensionRootDirectory + "\" + $json;

            Write-Host "Processing console extension json file" $jsonFile;

            $objectInfo = Get-Content $jsonFile | ConvertFrom-Json;
            
            write-host $objectInfo;
            $itemDir = $extensionRootDirectory + "\objects\consoleextension\" + $objectInfo.itemId;
            $cabFile = $itemDir + "\" + $objectInfo.itemId + ".cab"

            mkdir $itemDir;
    
            if((Test-Path $cabFile) -eq $False )
            {
                Write-Host "Downloading cab from" $objectInfo.downloadLocation;
                Invoke-WebRequest -Uri $objectInfo.downloadLocation -OutFile $cabFile;
            }
    
            write-host "Recursively searching for cab files.."
            searchAndExpand -directory $itemDir
        }
    }
    else {
        write-host "No extensions submitted to this branch.";
    }
}

function print-EnvironmentVariables
{
    write-host env:
}

Write-host 'Extension downloader starting...'
Write-Host "=================================================="

Main;

Write-Host "Extension downloader finished";
Write-Host "=================================================="