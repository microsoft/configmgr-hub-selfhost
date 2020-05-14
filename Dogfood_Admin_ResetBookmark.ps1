$bookmarks = Get-WMIObject -Query "Select * from CCM_SensorBookmark" -Namespace "root\ccm";
$bookmarks | Remove-WMIObject;