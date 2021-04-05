# ===================================================================
#
#   Detects if this submission is a console submission
#   and if so gets a list of full paths to files for the extension for verification.
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

    # return the list of json files changed between the source and destination branches.
    $changed = git diff $srcCommit $destCommit --name-only | where-object { $_ -like "objects/ConsoleExtension/*.json"};

    write-host "Changed extension json:" $changed

    return $changed;
}

# ===================================================================
#
#   Main entry point.
#
# ===================================================================

function Main
{
    $artifactsLocation = $Env:SYSTEM_ARTIFACTSDIRECTORY;
    $consoleExValidatorLocation = $artifactsLocation + "\lib\net40\Microsoft.ConfigurationManager.ConsoleExtensionCommon.dll";
    $itemsRootDirectory = $Env:BUILD_REPOSITORY_LOCALPATH;
    $consoleExsDirectory = $itemsRootDirectory + "\" + "objects\consoleextension";
    $extensionJson = get-ChangedExtensions;
    
    Write-Host 'Using validator from ' $consoleExValidatorLocation;
    
    if ($null -ne $extensionJson)
    {
        $extensionName = [System.IO.Path]::GetFileNameWithoutExtension($extensionJson);
        $extensionCabPath = $consoleExsDirectory + "\" + $extensionName + "\" + $extensionName + ".cab";
        
        #Initialize objects
        [Reflection.Assembly]::LoadFile($consoleExValidatorLocation)
        $objectFactory = new-object Microsoft.ConfigurationManager.ConsoleExtension.SystemFunctions.SystemObjectFactory
        $validator = new-object -TypeName Microsoft.ConfigurationManager.ConsoleExtension.ConsoleExtensionValidator -ArgumentList $objectFactory

        #Start validation
        Try
        {
            $expandedCabFolder = [System.IO.Path]::GetFileNameWithoutExtension($extensionCabPath);
            Write-Host 'Verifying the signiture of the cab file...'
            $validator.VerifyExtensionCabSigniture($file);
            Write-Host 'Verifying the contents of the cab file...'
            $validator.VerifyExtensionCabContent(-join($consoleExsDirectory, "\", $expandedCabFolder));
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


Write-Host 'Running console extension validation...'
Write-Host "=================================================="

Main;

Write-Host "Console extension validation finished.";
Write-Host "=================================================="
