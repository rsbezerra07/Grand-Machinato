#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

$ErrorActionPreference = "Stop"

$Name = "GM-WAN"

$Switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue

if ($Switch) {
    Write-Host "[OK] $Name already exists." -ForegroundColor Green
}
else {
    $Route = Get-NetRoute `
        -DestinationPrefix "0.0.0.0/0" `
        -AddressFamily IPv4 |
        Where-Object { $_.NextHop -ne "0.0.0.0" } |
        Sort-Object RouteMetric |
        Select-Object -First 1

    if (-not $Route) {
        throw "Could not find the WAN interface."
    }

    $Adapter = Get-NetAdapter `
        -InterfaceIndex $Route.InterfaceIndex `
        -ErrorAction Stop

    Write-Host "[INFO] WAN Interface: $($Adapter.Name)" -ForegroundColor Yellow
    Write-Host "[CREATE] Creating $Name..." -ForegroundColor Cyan

    New-VMSwitch `
        -Name $Name `
        -NetAdapterName $Adapter.Name `
        -AllowManagementOS $true |
        Out-Null
}

Get-VMSwitch -Name $Name |
    Format-Table Name, SwitchType, NetAdapterInterfaceDescription