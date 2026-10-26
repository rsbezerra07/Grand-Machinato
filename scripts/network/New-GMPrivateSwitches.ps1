#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

$ErrorActionPreference = "Stop"

$PrivateSwitches = @(
    "GM-SRV",
    "GM-IT",
    "GM-HR",
    "GM-SAL",
    "GM-MKT",
    "GM-PXE",
    "GM-OSS"
)

foreach ($Name in $PrivateSwitches) {

    $Switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue

    if ($Switch) {
        Write-Host "[OK] $Name already exists." -ForegroundColor Green
        continue
    }

    Write-Host "[CREATE] Creating $Name..." -ForegroundColor Cyan

    New-VMSwitch `
        -Name $Name `
        -SwitchType Private |
        Out-Null
}

Write-Host ""
Write-Host "Private Switches:" -ForegroundColor Cyan

Get-VMSwitch |
    Where-Object { $_.Name -in $PrivateSwitches } |
    Sort-Object Name |
    Format-Table Name, SwitchType