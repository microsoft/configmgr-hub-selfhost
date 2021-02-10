Write-host 'Extension downloader starting...'

$jsonFiles = gci -Path "C:\users\msilvey\source\repos\configmgr-hub-selfhost\objects\ConsoleExtension\" -file *.json

write-host "Repository local path: " + $Env:BUILD_REPOSITORY_LOCALPATH;

$root = $env:BUILD_REPOSITORY_LOCALPATH + "\objects\consoleextension\";

write-host "Root directory for extensions: " $root;
$jsonFiles = gci -Path $root -file *.json

write-host "Json files to enumerate: " $jsonFiles

ForEach-Object -InputObject $jsonFiles -Process{

    Write-Host "Processing console extension json file " $_;

    $objectInfo = Get-Content $_.FullName  | ConvertFrom-Json;
    $itemDir = $root + $objectInfo.itemId + "\";
    
    write-host $objectInfo;
    $file = $itemDir + $objectInfo.itemId + ".cab";
    
    mkdir $itemDir;
    
    Write-Host "Downloading cab from " + $objectInfo.downloadLocation;
     Invoke-WebRequest -Uri $objectInfo.downloadLocation -OutFile $file;
     expand $file $itemDir -F:*
}