function searchAndExpand {
    param($directory)

    if((Test-Path $directory) -eq $true)
    {
        write-host "Searching directory" $directory "for cab files to expand.";

        $cabFiles = Get-ChildItem -path $directory -file *.cab -recurse;
        
        foreach($cabFile in $cabFiles)
        {
            $cabDir = $directory + "\_" + $cabFile.Name

            write-host "Expanding cab file" $cabFile.Name " to directory"  $cabDir;

            mkdir $cabDir;
            expand $cabFile.FullName $cabDir -F:*;
            searchAndExpand -directory $cabDir;
        }
    }
}

Write-host 'Extension downloader starting...'

dir env:

$buildRoot = $Env:BUILD_REPOSITORY_LOCALPATH

if(!$buildRoot)
{
    Set-Location -Path ..;
    $buildRoot = (get-location);
}

write-host "Repository local path:" + $buildRoot;

$root = $buildRoot + "\objects\consoleextension\";

write-host "Root directory for extensions:" $root;
$jsonFiles = gci -Path $root -file *.json

write-host "Json files to enumerate:" $jsonFiles

foreach($jsonFile in $jsonFiles)
{
    Write-Host "Processing console extension json file" $jsonFile;

    $objectInfo = Get-Content $jsonFile.FullName  | ConvertFrom-Json;
    $itemDir = $root + $objectInfo.itemId;
    
    write-host $objectInfo;
    $file = $itemDir + "\" + $objectInfo.itemId + ".cab";
    
    mkdir $itemDir;
    
    if((Test-Path $file) -eq $False )
    {
        Write-Host "Downloading cab from" $objectInfo.downloadLocation;
        Invoke-WebRequest -Uri $objectInfo.downloadLocation -OutFile $file;
    }
    
    write-host "Recursively searching for cab files.."
    searchAndExpand -directory $itemDir
}