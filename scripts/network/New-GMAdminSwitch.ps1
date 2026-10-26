#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

$ErrorActionPreference = "Stop"

$Name = "GM-ADMIN"

$Switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue

if ($Switch) {
    Write-Host "[OK] $Name already exists." -ForegroundColor Green
}
else {
    Write-Host "[CREATE] Creating $Name..." -ForegroundColor Cyan

    New-VMSwitch `
        -Name $Name `
        -SwitchType Internal |
        Out-Null
}

Get-VMSwitch -Name $Name |
    Format-Table Name, SwitchType