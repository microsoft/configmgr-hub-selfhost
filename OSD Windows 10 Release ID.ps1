﻿If (Get-ItemProperty "HKLM:Software\Microsoft\Windows NT\CurrentVersion" -Name ReleaseID -ErrorAction 0) {(Get-Item "HKLM:Software\Microsoft\Windows NT\CurrentVersion").GetValue('ReleaseID')}
   ELSE { Write-Host "Not a Windows 10 or Server 2016 Device" }