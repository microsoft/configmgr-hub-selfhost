Write-host 'Extension downloader starting...'

$root = $env:Build.SourcesDirectory + "\configmgr-hub-selfhost\objects\consoleextension\";

$jsonFiles = gci -Path $root -file *.json

ForEach-Object -InputObject $jsonFile -Process{

    Write-Host "Processing console extension json file " $_;

    $objectInfo = Get-Content $_  | ConvertFrom-Json;
    $itemDir = $root + ".\objects\ConsoleExtension\" + $objectInfo.itemId + "\";
    
    write-host $objectInfo;
    $file = $itemDir + $objectInfo.itemId + ".cab";
    
    mkdir $itemDir;
    
    Write-Host "Downloading cab from " + $objectInfo.downloadLocation;
     Invoke-WebRequest -Uri $objectInfo.downloadLocation -OutFile $file;
     expand $file $itemDir -F:*
}