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
    $cabFilesToValidated = Get-ChildItem $consoleExsDirectory -filter "*.cab";
    Write-Host 'Using validator from ' $consoleExValidatorLocation;
    Write-Host 'Cab files that have been downloaded:'
    Write-Host $cabFilesToValidated

    #Initialize objects
    [Reflection.Assembly]::LoadFile($consoleExValidatorLocation)
    $objectFactory = new-object Microsoft.ConfigurationManager.ConsoleExtension.SystemFunctions.SystemObjectFactory
    $validator = new-object -TypeName Microsoft.ConfigurationManager.ConsoleExtension.ConsoleExtensionValidator -ArgumentList $objectFactory

    #Start validation
    foreach($file in $cabFilesToValidated)
    {
        Try
        {
            $expandedCabFolder = [System.IO.Path]::GetFileNameWithoutExtension($file);
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
}


Write-Host 'Running console extension validation...'
Write-Host "=================================================="

Main;

Write-Host "Console extension validation finished.";
Write-Host "=================================================="
