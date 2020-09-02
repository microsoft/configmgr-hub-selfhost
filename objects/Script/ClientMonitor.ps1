$r1 = Get-WmiObject -Class Win32_Process -Filter "Name = 'CcmExec.exe'" | Select Name, HandleCount, WorkingSetSize

$r2 = Get-WmiObject -Class Win32_PerfRawData_PerfProc_Process -Filter "Name = 'CcmExec'" | Select PrivateBytes, VirtualBytes

New-Object -TypeName PSObject -Property @{
    Name = $r1.Name
    HandleCount = $r1.HandleCount
    WorkingSetSize = $r1.WorkingSetSize
    PrivateBytes = $r2.PrivateBytes
    VirtualBytes = $r2.VirtualBytes
} | Select Name, HandleCount, WorkingSetSize, PrivateBytes, VirtualBytes