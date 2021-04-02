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
    $cabFilesToValidated = Get-ChildItem $consoleExsDirectory;


    #Initialize objects
    [Reflection.Assembly]::LoadFile($consoleExValidatorLocation)
    $objectFactory = new-object Microsoft.ConfigurationManager.ConsoleExtension.SystemFunctions.SystemObjectFactory
    $validator = new-object -TypeName Microsoft.ConfigurationManager.ConsoleExtension.ConsoleExtensionValidator -ArgumentList $objectFactory

    #Start validation
    foreach($file in $cabFilesToValidated)
    {
        Try
        {
            $expandedCabLocation = [System.IO.Path]::GetFileNameWithoutExtension($file);
            $validator.VerifyExtensionCabSigniture($file);
            $validator.VerifyExtensionCabContent($consoleExsDirectory + "\" + "expandedCabLocation")
        }
        Catch
        {
            $ErrorMessage = $_.Exception.Message;
            
            Write-Error $ErrorMessage;
        }
    }
}


Write-host 'Running console extension validation...'
Write-Host "=================================================="

Main;

Write-Host "Console extension validation finished.";
Write-Host "=================================================="
