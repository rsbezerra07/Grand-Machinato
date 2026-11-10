# Check available VMs and their status
$AvailableVMs = Get-VM

if (-not $AvailableVMs) {
    Write-Host "No Hyper-V virtual machines were found." -ForegroundColor Yellow
    exit 0
}

$AvailableVMs |
    Select-Object Name, State, Status, Uptime |
    Format-Table -AutoSize

# Keep prompting until at least one valid VM name is provided
do {
    $VMsToStop = Read-Host "Enter the names of the VMs to stop (comma-separated)"

    $VMsToStopArray = @(
        $VMsToStop -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Select-Object -Unique
    )

    if ($VMsToStopArray.Count -eq 0) {
        Write-Host "Enter at least one VM name." -ForegroundColor Yellow
    }
} while ($VMsToStopArray.Count -eq 0)

# Select shutdown method
Write-Host ""
Write-Host "Select the shutdown method:" -ForegroundColor Cyan
Write-Host "  1 - Safe shutdown"
Write-Host "  2 - Force power off" -ForegroundColor Red
Write-Host "  Q - Cancel"

do {
    $ShutdownMethod = (Read-Host "Enter your choice").Trim().ToUpperInvariant()

    if ($ShutdownMethod -notin @("1", "2", "Q")) {
        Write-Host "Enter 1, 2, or Q." -ForegroundColor Yellow
    }
} while ($ShutdownMethod -notin @("1", "2", "Q"))

if ($ShutdownMethod -eq "Q") {
    Write-Host "Operation cancelled. No VMs were changed." -ForegroundColor Yellow
    exit 0
}

# Require explicit confirmation for force power-off
if ($ShutdownMethod -eq "2") {
    Write-Host ""
    Write-Host "WARNING: Force power-off is equivalent to disconnecting power." `
        -ForegroundColor Red
    Write-Host "Unsaved data may be lost and guest filesystems may be damaged." `
        -ForegroundColor Red

    $Confirmation = Read-Host "Type FORCE OFF to continue"

    if ($Confirmation -cne "FORCE OFF") {
        Write-Host "Operation cancelled. No VMs were changed." `
            -ForegroundColor Yellow
        exit 0
    }
}

foreach ($VMName in $VMsToStopArray) {
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

    if (-not $VM) {
        Write-Host "VM not found: $VMName" -ForegroundColor Red
        continue
    }

    if ($VM.State -eq "Off") {
        Write-Host "VM '$VMName' is already off." -ForegroundColor Yellow
        continue
    }

    try {
        switch ($ShutdownMethod) {
            "1" {
                Write-Host "Requesting a safe shutdown of '$VMName'..." `
                    -ForegroundColor Cyan

                Stop-VM `
                    -VM $VM `
           -Confirm:$false `
                    -ErrorAction Stop

                Write-Host "Safe shutdown requested for '$VMName'." `
                    -ForegroundColor Green
            }

            "2" {
                Write-Host "Forcibly powering off '$VMName'..." `
                    -ForegroundColor Red

                Stop-VM `
                    -VM $VM `
                    -TurnOff `
                    -Confirm:$false `
                    -ErrorAction Stop

                Write-Host "VM '$VMName' was forcibly powered off." `
                    -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host `
            "Failed to stop VM '$VMName': $($_.Exception.Message)" `
            -ForegroundColor Red
    }
}

# Display updated status
Write-Host "`nCurrent VM status:" -ForegroundColor Cyan

Get-VM |
    Select-Object Name, State, Status, Uptime |
    Format-Table -AutoSize