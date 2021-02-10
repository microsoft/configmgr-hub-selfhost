Write-host 'Extension downloader starting...'

$root = "C:\users\msilvey\source\repos\configmgr-hub-selfhost\";
$jsonFile = $root + "objects\consoleextension\10101.json"

$objectInfo = Get-Content $jsonFile  | ConvertFrom-Json;
$itemDir = $root + ".\objects\ConsoleExtension\" + $objectInfo.itemId + "\";

write-host $objectInfo;
$file = $itemDir + $objectInfo.itemId + ".cab";

mkdir $itemDir;

 Invoke-WebRequest -Uri $objectInfo.downloadLocation -OutFile $file;
 expand $file $itemDir -F:*