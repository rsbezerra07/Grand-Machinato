$ErrorActionPreference = 'Stop'

function Read-MenuSelection {
    param(
        [Parameter(Mandatory)]
        [string] $Prompt,

        [Parameter(Mandatory)]
        [int] $Minimum,

        [Parameter(Mandatory)]
        [int] $Maximum
    )

    do {
        $InputValue = Read-Host $Prompt
        $Selection = 0

        $IsValid = [int]::TryParse($InputValue, [ref] $Selection) -and
                   $Selection -ge $Minimum -and
                   $Selection -le $Maximum

        if (-not $IsValid) {
            Write-Host(
                "Enter a number from {0} through {1}." -f
                $Minimum,
                $Maximum
            ) -ForegroundColor Yellow
        }
    } until ($IsValid)

    return $Selection
}

function Read-YesNo {
    param(
        [Parameter(Mandatory)]
        [string] $Prompt,

        [bool] $DefaultYes = $false
    )

    $Suffix = if ($DefaultYes) { '[Y/n]' } else { '[y/N]' }

    do {
        $Answer = (Read-Host "$Prompt $Suffix").Trim().ToLowerInvariant()

        if ([string]::IsNullOrWhiteSpace($Answer)) {
            return $DefaultYes
        }

        switch ($Answer) {
            'y'   { return $true }
            'yes' { return $true }
            'n'   { return $false }
            'no'  { return $false }
            default {
                Write-Host "Enter Y or N." -ForegroundColor Yellow
            }
        }
    } while ($true)
}

try {
    # ------------------------------------------------------------
    # 1. Find and select a VM
    # ------------------------------------------------------------

    $AvailableVMs = @(
        Get-VM |
            Sort-Object Name
    )

    if ($AvailableVMs.Count -eq 0) {
        Write-Host(
            'No Hyper-V virtual machines were found.'
        ) -ForegroundColor Yellow

        return
    }

    Write-Host "`nAvailable Hyper-V virtual machines:" `
        -ForegroundColor Cyan

    $VMTable = for ($Index = 0; $Index -lt $AvailableVMs.Count; $Index++) {
        $VM = $AvailableVMs[$Index]

        [pscustomobject]@{
            Number     = $Index + 1
            Name       = $VM.Name
            Generation = $VM.Generation
            State      = $VM.State
            Status     = $VM.Status
            Uptime     = $VM.Uptime
        }
    }

    $VMTable |
        Format-Table -AutoSize

    $VMSelection = Read-MenuSelection `
        -Prompt 'Select the VM number' `
        -Minimum 1 `
        -Maximum $AvailableVMs.Count

    $SelectedVM = $AvailableVMs[$VMSelection - 1]
    $VMName = $SelectedVM.Name
    $InitialState = $SelectedVM.State

    Write-Host "`nSelected VM: $VMName" -ForegroundColor Cyan

    # ------------------------------------------------------------
    # 2. Enumerate devices attached to SCSI controllers
    # ------------------------------------------------------------

    $ScsiHardDisks = @(
        Get-VMHardDiskDrive -VM $SelectedVM |
            Where-Object ControllerType -eq 'SCSI' |
            ForEach-Object {
                [pscustomobject]@{
                    DeviceType        = 'Hard Disk'
                    ControllerType     = $_.ControllerType
                    ControllerNumber   = $_.ControllerNumber
                    ControllerLocation = $_.ControllerLocation
                    Path               = $_.Path
                    DeviceObject       = $_
                }
            }
    )

    $ScsiDvdDrives = @(
        Get-VMDvdDrive -VMName $VMName |
            Where-Object ControllerType -eq 'SCSI' |
            ForEach-Object {
                [pscustomobject]@{
                    DeviceType        = 'DVD Drive'
                    ControllerType     = $_.ControllerType
                    ControllerNumber   = $_.ControllerNumber
                    ControllerLocation = $_.ControllerLocation
                    Path               = if ($_.Path) {
                        $_.Path
                    }
                    else {
                        '<No media mounted>'
                    }
                    DeviceObject       = $_
                }
            }
    )

    $ScsiDevices = @(
        $ScsiHardDisks
        $ScsiDvdDrives
    ) |
        Sort-Object ControllerNumber, ControllerLocation, DeviceType

    if ($ScsiDevices.Count -eq 0) {
        Write-Host(
            "VM '$VMName' has no removable devices attached to a SCSI controller."
        ) -ForegroundColor Yellow

        return
    }

    Write-Host "`nDevices attached to SCSI controllers:" `
        -ForegroundColor Cyan

    $DeviceTable = for ($Index = 0; $Index -lt $ScsiDevices.Count; $Index++) {
        $Device = $ScsiDevices[$Index]

        [pscustomobject]@{
            Number             = $Index + 1
            Type               = $Device.DeviceType
            Controller         = $Device.ControllerNumber
            Location           = $Device.ControllerLocation
            PathOrMountedMedia = $Device.Path
        }
    }

    $DeviceTable |
        Format-Table -AutoSize -Wrap

    # ------------------------------------------------------------
    # 3. Select a SCSI device
    # ------------------------------------------------------------

    $DeviceSelection = Read-MenuSelection `
        -Prompt 'Select the SCSI device number to remove' `
        -Minimum 1 `
        -Maximum $ScsiDevices.Count

    $SelectedDevice = $ScsiDevices[$DeviceSelection - 1]

    Write-Host "`nSelected device:" -ForegroundColor Cyan

    $SelectedDevice |
        Select-Object `
            DeviceType,
            ControllerType,
            ControllerNumber,
            ControllerLocation,
            Path |
        Format-List

    if ($SelectedDevice.DeviceType -eq 'Hard Disk') {
        Write-Host(
            'WARNING: If this is the operating-system disk, removing it may make the VM unbootable.'
        ) -ForegroundColor Red

        Write-Host(
            'The VHD/VHDX file will not be deleted, but it will be detached from the VM.'
        ) -ForegroundColor Yellow
    }

    $Confirmation = Read-Host(
        "Type REMOVE to detach this device from VM '$VMName'"
    )

    if ($Confirmation -cne 'REMOVE') {
        Write-Host 'Operation canceled. No changes were made.' `
            -ForegroundColor Yellow

        return
    }

    # ------------------------------------------------------------
    # 4. Shut down the VM when necessary
    # ------------------------------------------------------------

    $SelectedVM = Get-VM -Name $VMName

    if ($SelectedVM.State -ne 'Off') {
        Write-Host(
            "`nVM '$VMName' is currently '$($SelectedVM.State)'."
        ) -ForegroundColor Yellow

        $AllowShutdown = Read-YesNo `
            -Prompt 'Shut down the VM before removing the device?'

        if (-not $AllowShutdown) {
            Write-Host(
                'Operation canceled because the VM was not shut down.'
            ) -ForegroundColor Yellow

            return
        }

        if ($SelectedVM.State -eq 'Running') {
            Write-Host(
                "Requesting a graceful shutdown of '$VMName'..."
            ) -ForegroundColor Cyan

            Stop-VM -VM $SelectedVM -ErrorAction Stop
        }
        else {
            Write-Host(
                "The VM state is '$($SelectedVM.State)'. Attempting to stop it..."
            ) -ForegroundColor Yellow

            Stop-VM -VM $SelectedVM -ErrorAction Stop
        }

        $ShutdownTimeoutSeconds = 180
        $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

        do {
            Start-Sleep -Seconds 3
            $SelectedVM = Get-VM -Name $VMName

            Write-Host(
                "Waiting for shutdown. Current state: $($SelectedVM.State)"
            ) -ForegroundColor DarkGray
        } while (
            $SelectedVM.State -ne 'Off' -and
            $Stopwatch.Elapsed.TotalSeconds -lt $ShutdownTimeoutSeconds
        )

        $Stopwatch.Stop()

        if ($SelectedVM.State -ne 'Off') {
            throw (
                "VM '$VMName' did not shut down within " +
                "$ShutdownTimeoutSeconds seconds. No device was removed."
            )
        }

        Write-Host "VM '$VMName' is now off." -ForegroundColor Green
    }

    # ------------------------------------------------------------
    # 5. Re-query the target by controller coordinates
    # ------------------------------------------------------------

    if ($SelectedDevice.DeviceType -eq 'Hard Disk') {
        $DeviceToRemove = Get-VMHardDiskDrive `
            -VMName $VMName `
            -ControllerType SCSI `
            -ControllerNumber $SelectedDevice.ControllerNumber `
            -ControllerLocation $SelectedDevice.ControllerLocation `
            -ErrorAction SilentlyContinue
    }
    else {
        $DeviceToRemove = Get-VMDvdDrive `
            -VMName $VMName |
                Where-Object {
                    $_.ControllerType -eq 'SCSI' -and
                    $_.ControllerNumber -eq
                        $SelectedDevice.ControllerNumber -and
                    $_.ControllerLocation -eq
                        $SelectedDevice.ControllerLocation
                }
    }

    if (-not $DeviceToRemove) {
        throw (
            'The selected device could not be found after the VM was ' +
            'shut down. No device was removed.'
        )
    }

    # ------------------------------------------------------------
    # 6. Remove the selected device attachment
    # ------------------------------------------------------------

    if ($SelectedDevice.DeviceType -eq 'Hard Disk') {
        $DeviceToRemove |
            Remove-VMHardDiskDrive -Confirm:$false -ErrorAction Stop
    }
    else {
        $DeviceToRemove |
            Remove-VMDvdDrive -Confirm:$false -ErrorAction Stop
    }

    Write-Host(
        "`nThe selected $($SelectedDevice.DeviceType) was detached successfully."
    ) -ForegroundColor Green

    # ------------------------------------------------------------
    # 7. Verify the removal
    # ------------------------------------------------------------

    if ($SelectedDevice.DeviceType -eq 'Hard Disk') {
        $RemainingTarget = Get-VMHardDiskDrive `
            -VMName $VMName `
            -ControllerType SCSI `
            -ControllerNumber $SelectedDevice.ControllerNumber `
            -ControllerLocation $SelectedDevice.ControllerLocation `
            -ErrorAction SilentlyContinue
    }
    else {
        $RemainingTarget = Get-VMDvdDrive `
            -VMName $VMName |
                Where-Object {
                    $_.ControllerType -eq 'SCSI' -and
                    $_.ControllerNumber -eq
                        $SelectedDevice.ControllerNumber -and
                    $_.ControllerLocation -eq
                        $SelectedDevice.ControllerLocation
                }
    }

    if ($RemainingTarget) {
        throw 'Verification failed: the selected device is still attached.'
    }

    Write-Host(
        'Verification successful: the selected controller location is now empty.'
    ) -ForegroundColor Green

    Write-Host "`nRemaining SCSI devices for '$VMName':" `
        -ForegroundColor Cyan

    $RemainingHardDisks = @(
        Get-VMHardDiskDrive -VMName $VMName |
            Where-Object ControllerType -eq 'SCSI' |
            Select-Object @{
                Name       = 'Type'
                Expression = { 'Hard Disk' }
            }, ControllerNumber, ControllerLocation, Path
    )

    $RemainingDvdDrives = @(
        Get-VMDvdDrive -VMName $VMName |
            Where-Object ControllerType -eq 'SCSI' |
            Select-Object @{
                Name       = 'Type'
                Expression = { 'DVD Drive' }
            }, ControllerNumber, ControllerLocation, Path
    )

    $RemainingDevices = @(
        $RemainingHardDisks
        $RemainingDvdDrives
    )

    if ($RemainingDevices.Count -gt 0) {
        $RemainingDevices |
            Sort-Object ControllerNumber, ControllerLocation |
            Format-Table -AutoSize
    }
    else {
        Write-Host 'No SCSI devices remain attached.' `
            -ForegroundColor Yellow
    }

    # ------------------------------------------------------------
    # 8. Optionally start the VM again
    # ------------------------------------------------------------

    $StartAgainPrompt = if ($InitialState -eq 'Running') {
        'The VM was running before this operation. Start it again?'
    }
    else {
        'Do you want to start the VM now?'
    }

    if (Read-YesNo -Prompt $StartAgainPrompt) {
        Start-VM -Name $VMName -ErrorAction Stop

        $FinalVM = Get-VM -Name $VMName

        Write-Host(
            "VM '$VMName' was started. Current state: $($FinalVM.State)"
        ) -ForegroundColor Green
    }
    else {
        Write-Host "VM '$VMName' remains powered off." `
            -ForegroundColor Yellow
    }

    # ------------------------------------------------------------
    # 9. Show final result
    # ------------------------------------------------------------

    Write-Host "`nFinal VM status:" -ForegroundColor Cyan

    Get-VM -Name $VMName |
        Select-Object Name, Generation, State, Status, Uptime |
        Format-Table -AutoSize
}
catch {
    Write-Host(
        "`nOperation failed: $($_.Exception.Message)"
    ) -ForegroundColor Red
}