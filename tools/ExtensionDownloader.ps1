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
    # Environment variable has the two commits in it 
    # Example: "Merge 6c518ff333489f994c5e45d564536000897f8f09 into 3f3f2bc641079f5ba8da312216acef3db..."
    $segments = ($env:BUILD_SOURCEVERSIONMESSAGE).ToString().Split(' ');

    $srcCommit = $segments[1];
    $destCommit = $segments[3].TrimEnd('.');
    
    write-host "Comparing commits:" $srcCommit  "," $destCommit;

    # return  the list of json files changed between the source and destination branches.
    $changed = git diff $srcCommit $destCommit --name-only | where-object { $_ -like "objects/ConsoleExtension/*.json"};

    write-host "Changed extension json:" $changed

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
        Write-host "Running on agent machine: true";

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

function print-objectJson
{
    param($objectJson);

    write-host "itemId:" $objectJson.itemId;
    write-host "downloadLocation:" $objectJson.downloadLocation;
    write-host "Cab Sha:" $objectJson.sha;
    write-host "CodeSignPolicyFile:" $objectJson.codeSignPolicyFile;
}

# ===================================================================
#
#   Main entry point.
#
# ===================================================================
function Main
{
    print-EnvironmentVariables;

    $extensionJson = get-ChangedExtensions;

   if($null -ne $extensionJson)
    {
        $extensionRootDirectory = (get-BuildRootDirectory); 

        write-host "Repository root:" $extensionRootDirectory;

        foreach($json in $extensionJson)
        {
            $jsonFile = $extensionRootDirectory + "\" + $json;

            Write-Host "Processing extension json:" $jsonFile;

            $objectInfo = Get-Content $jsonFile | ConvertFrom-Json;
            
            print-objectJson -objectJson $objectInfo;

            ${env:CONFIGMGR_CODESIGNPOLICYFILE} = ${env:Build_SourcesDirectory} + "\objects\ConsoleExtension\" + $objectInfo.codeSignPolicyFile;
            
            print-EnvironmentVariables;

            $itemDir = $extensionRootDirectory + "\objects\consoleextension\" + $objectInfo.itemId;
            $cabFile = $itemDir + "\" + $objectInfo.itemId + ".cab"

            $r = mkdir $itemDir;
    
            if((Test-Path $cabFile) -eq $False )
            {
                Write-Host "Downloading cab:" $objectInfo.downloadLocation "to:" $itemDir;
                Invoke-WebRequest -Uri $objectInfo.downloadLocation -OutFile $cabFile;
            }
    
            write-host "Recursively searching for cab files.."
            searchAndExpand -directory $itemDir

            print-Summary;
        }
    }
    else {
        write-host "No extensions submitted to this branch.";
    }
}

function print-Summary
{
    param($directory)

    $itemCount = gci -path $directory -recurse | 
    Measure-object -Property length | 
    select-object count;

    write-host "Expanded files count:" $itemCount.Count;
}

function print-EnvironmentVariables
{
    write-host "Environment variables:";
    get-childitem env:
}

Write-host 'Extension downloader starting...'
Write-Host "=================================================="

Main;

Write-Host "Extension downloader finished";
Write-Host "=================================================="