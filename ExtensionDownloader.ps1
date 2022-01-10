# ===================================================================
#
#   Run validation library in the ADO pipeline used by 
#   the Community hub for console extensions.
#
# ===================================================================
function RunValidation {
    param($consoleExsPath)

    $artifactsLocation = $Env:SYSTEM_ARTIFACTSDIRECTORY;
    $consoleExValidatorLocation = $artifactsLocation + "\lib\net40\Microsoft.ConfigurationManager.ConsoleExtensionCommon.dll";
    $itemsRootDirectory = $Env:BUILD_REPOSITORY_LOCALPATH;
    $consoleExsDirectory = Join-Path -Path $itemsRootDirectory -ChildPath $consoleExsPath;

    Write-Host 'Using validator from ' $consoleExValidatorLocation;

    if((Test-Path $consoleExsDirectory) -eq $true)
    {
        $extensionJson = get-ChangedExtensions $consoleExsPath;
    
        if ($null -ne $extensionJson)
        {
            $extensionName = [System.IO.Path]::GetFileNameWithoutExtension($extensionJson);
            $extensionCabPath = $consoleExsDirectory + "\" + $extensionName + "\" + $extensionName + ".cab";
            $expandedCabFolder = $consoleExsDirectory + "\" + $extensionName + "\_" + $extensionName + ".cab";
            Write-Host "Targeted Cab file: " $extensionCabPath;
            Write-Host "Expanded Cab location: " $expandedCabFolder;
        
            #Initialize objects
            [Reflection.Assembly]::LoadFile($consoleExValidatorLocation)
            $objectFactory = new-object Microsoft.ConfigurationManager.ConsoleExtension.SystemFunctions.SystemObjectFactory
            $validator = new-object -TypeName Microsoft.ConfigurationManager.ConsoleExtension.ConsoleExtensionValidator -ArgumentList $objectFactory

            #Starts validation
            Try
            {
                Write-Host 'Verifying the signature of the cab file...'
                $validator.VerifyExtensionCabSigniture($extensionCabPath);
                Write-Host 'Verifying the contents of the cab file...'
                $validator.VerifyExtensionCabContent($expandedCabFolder);
                Write-Host 'All validation succeeded'
            }
            Catch
            {
                $ErrorMessage = $_.Exception.Message;
                Write-Error $ErrorMessage;
            }
        }
        else
        {
            Write-Host "Did not find any changed console extension.";
        }
    }
    else
    {
        write-host "ERROR: Invalid Path for console extensions";
    }
}

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
        (gci -path $directory *.cab -recurse) | foreach {
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
#   and if so gets a list of full paths to files for the extension for verification.
#
# ===================================================================
function get-ChangedExtensions{
    param($consoleExsDirectory)

    # Environment variable has the two commits in it 
    # Example: "Merge 6c518ff333489f994c5e45d564536000897f8f09 into 3f3f2bc641079f5ba8da312216acef3db..."
    $segments = ($env:BUILD_SOURCEVERSIONMESSAGE).ToString().Split(' ');

    $srcCommit = $segments[1];
    $destCommit = $segments[3].TrimEnd('.');
    
    write-host "Comparing commits:" $srcCommit  "," $destCommit;

    $wildCardPath = $consoleExsDirectory + "/*.json";
    write-host $wildCardPath;
    $step1 = git diff $srcCommit $destCommit --name-only;
    write-host $step1;
    # return the list of json files changed between the source and destination branches.
    $changed = git diff $srcCommit $destCommit --name-only | where-object { $_ -like $wildCardPath};

    write-host "Changed extension json:" $changed;

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

# ===================================================================
#
#   Prints the properties of the supplied json object.
#
# ===================================================================
function print-objectJson
{
    param($objectJson);

    write-host "downloadLocation:" $objectJson.downloadLocation;
    write-host "FileHash:" $objectJson.FileHash;
    write-host "Hash-Algorithm:" $objectJson.HashAlgorithm;
    write-host "CodeSignPolicyFile:" $objectJson.codeSignPolicyFile;
}

# ===================================================================
#
#   Main entry point.
#
# ===================================================================
function DownloadAndExpand {
    param($consoleExsPath)

    print-EnvironmentVariables;

    $extensionJson = get-ChangedExtensions $consoleExsPath;

   if($null -ne $extensionJson)
    {
        Write-Host "##vso[task.setvariable variable=codeSignEnabled]true"
        
        $repoRootFolder = (get-BuildRootDirectory);
        $consoleExtensionFolder = Join-Path -Path $repoRootFolder -ChildPath $consoleExsPath

        write-host "Repository root:" $repoRootFolder;

        foreach($json in $extensionJson)
        {
            $jsonFile = $repoRootFolder + "\" + $json; # ...\objects\ConsoleExtension\Some Extension.json

            Write-Host "Processing extension json:" $jsonFile;

            $objectName = [System.IO.Path]::GetFileNameWithoutExtension($jsonFile);

            $objectInfo = Get-Content $jsonFile | ConvertFrom-Json;
            
            print-objectJson -objectJson $objectInfo;

            if ($objectInfo.HashAlgorithm -ne "SHA256")
            {
                $errMsg = "Extension json specified invalid hash algorithm: [" + $objectInfo.FileHash + "]";
                Write-Error $errMsg;
            }

            $policyFile  = $consoleExtensionFolder + $objectInfo.codeSignPolicyFile;
            Write-Host "##vso[task.setvariable variable=codeSignPolicyFile;]$policyFile"

            $itemDir = $consoleExtensionFolder + $objectName;
            $cabFile = $itemDir + "\" + $objectName + ".cab"

            # Ensure the folder has not been pre-created
            if (Test-Path $itemDir)
            {
                $errMsg = "Folder: " + $itemDir + " already exists. This is unexpected.";
                Write-Error errMsg;
                return;
            }

            $r = mkdir $itemDir;
    
            # Always download to ensure we are verifying the correct latest file
            if ((Test-Path $cabFile) -eq $True)
            {
                $errMsg = "File: " + $cabFile + " already exists. This is unexpected."; 
                Write-Error $errMsg;
                return;
            }
            
            Write-Host "Downloading cab:" $objectInfo.downloadLocation "to:" $itemDir;
            Invoke-WebRequest -Uri $objectInfo.downloadLocation -OutFile $cabFile;

            verifyFileHash -expectedHash $objectInfo.FileHash -fileToCheck $cabFile -algorithm $objectInfo.HashAlgorithm -ErrorAction Stop

            setupESRPScanningPrereqs -fileToCopy $cabFile

            write-host "Recursively searching for cab files.."
            searchAndExpand -directory $itemDir

            Write-Host "Generating code signing policy XML file: ["$policyFile"]. This make take awhile."
            generateCodeSignPolicyXML -scanFolder $itemDir -policyFile $policyFile

            print-Summary;
        }
    }
    else {
        write-host "No extensions submitted to this branch.";
    }
}

# ===================================================================
#
#   Generates a codesign policy XML file to be consumed by the CodeSign task, and saves the file path to an ENV variable for use by CodeSign task.
#
#   $scanFolder - Full path to the folder whose contents will be used to generate the policy file.
#   $policyFile - must be a full path to where the new policy XML file will be created
# ===================================================================
function generateCodeSignPolicyXML
{
    param($scanFolder, $policyFile);

    if ($policyFile -notmatch ".xml$")
    {
        Write-Error "$policyFile is not a valid policy file. XML files are supported."
    }
    else 
    {
        New-CIPolicy -ScanPath $scanFolder -UserPEs -Level LeafCertificate $policyFile

        if ((Test-Path $policyFile) -eq $false)
        {
            $errMsg = "Cannot find generated policy file: " + $policyFile
            Write-Error $errMsg;
        }

        Get-Content $policyFile
    }    
}

# ===================================================================
#
#   Creates a folder to be used for ESRP scan uploads, copies the specified file to the folder, and saves the folder to an ENV variable for use by ESRP scanning task.
#
# ===================================================================
function setupESRPScanningPrereqs
{
    param($fileToCopy);

    $scanFolder = (get-BuildRootDirectory) + "\ESRPScan";
    
    if (Test-Path $scanFolder)
    {
        Remove-Item -Recurse -Force -Path $scanFolder
    }

    md $scanFolder
    
    Write-Host "Copying '$fileToCopy' to '$scanFolder' for ESRP scanning."
    
    Copy-Item $fileToCopy -Destination $scanFolder
      
    Write-Host "##vso[task.setvariable variable=ESRPScanFolder]$scanFolder"
}

# ===================================================================
#
#   Gets the hash of the specified file and compares it to the expected hash
#
# ===================================================================
function verifyFileHash
{
    param($expectedHash, $fileToCheck, $algorithm);

    Write-Host "Verifying hash of file:" $fileToCheck;

    $actualHash =  Get-FileHash -Path $fileToCheck -Algorithm $algorithm;
    
    write-host "Algorithm:" $actualHash.Algorithm;
    write-host "Path:" $actualHash.Path;
    write-host "ExpectedHash: ["$expectedHash"] ActualHash ["$actualHash.Hash"].";

    if ($actualHash.Hash -ne $expectedHash)
    {
        Write-Error $message;
    }
}

# ===================================================================
#
#   prints a summary of the count of files in a directory.
#
# ===================================================================
function print-Summary
{
    param($directory)

    $itemCount = gci -path $directory -recurse | 
    Measure-object -Property length | 
    select-object count;

    write-host "Expanded files count:" $itemCount.Count;
}

# ===================================================================
#
#   writes the session environment variables to the output.
#
# ===================================================================
function print-EnvironmentVariables
{
    write-host "Environment variables:";
    get-childitem env:
}

$objectsExts = "objects/consoleextension";
$hubExts = "Communityhub/consoleextension";

Write-host 'Extension downloader running on ' + $objectsExts

DownloadAndExpand $objectsExts;

Write-host 'Extension downloader running on ' + $hubExts

DownloadAndExpand $hubExts;

Write-Host "=================================================="
Write-Host "Extension downloader finished";
Write-Host "=================================================="

Write-Host 'Running console extension validation on ' + $objectsExts

RunValidation $objectsExts;

Write-Host 'Running console extension validation on ' + $hubExts

RunValidation $hubExts;

Write-Host "=================================================="

Write-Host "Console extension validation finished.";
Write-Host "=================================================="