#Requires -Modules Hyper-V

$Expected = @{
    "GM-SRV"   = "Private"
    "GM-IT"    = "Private"
    "GM-HR"    = "Private"
    "GM-SAL"   = "Private"
    "GM-MKT"   = "Private"
    "GM-PXE"   = "Private"
    "GM-OSS"   = "Private"
    "GM-ADMIN" = "Internal"
    "GM-WAN"   = "External"
}

foreach ($Name in $Expected.Keys) {

    $Switch = Get-VMSwitch -Name $Name -ErrorAction SilentlyContinue

    if (-not $Switch) {
        Write-Host "[FAIL] $Name does not exist." -ForegroundColor Red
    }
    elseif ($Switch.SwitchType -ne $Expected[$Name]) {
        Write-Host "[FAIL] $Name should be $($Expected[$Name]), but it is $($Switch.SwitchType)." -ForegroundColor Red
    }
    else {
        Write-Host "[OK] $Name - $($Switch.SwitchType)" -ForegroundColor Green
    }
}