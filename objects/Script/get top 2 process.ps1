Get-Process | Group-Object ProcessName | ForEach-Object {
    $_ | Select-Object -ExpandProperty Group | Select-Object -First 2
}