param([string]$value)
$registryPath = "HKLM:\Software\DEMO\"
$Name = "Demo_Key"
New-ItemProperty -Path $registryPath -Name $name -Value $value -PropertyType String -Force