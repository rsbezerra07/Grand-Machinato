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
        [int] $Selection = 0

        $IsValid = [int]::TryParse(
            $InputValue,
            [ref] $Selection
        ) -and
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

    $Suffix = if ($DefaultYes) {
        '[Y/n]'
    }
    else {
        '[y/N]'
    }

    do {
        $Answer = (
            Read-Host "$Prompt $Suffix"
        ).Trim().ToLowerInvariant()

        if ([string]::IsNullOrWhiteSpace($Answer)) {
            return $DefaultYes
        }

        switch ($Answer) {
            'y' {
                return $true
            }

            'yes' {
                return $true
            }

            'n' {
                return $false
            }

            'no' {
                return $false
            }

            default {
                Write-Host(
                    'Enter Y or N.'
                ) -ForegroundColor Yellow
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

    Write-Host(
        "`nAvailable Hyper-V virtual machines:"
    ) -ForegroundColor Cyan

    $VMDisplay = for (
        $Index = 0;
        $Index -lt $AvailableVMs.Count;
        $Index++
    ) {
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

    $VMDisplay |
        Format-Table -AutoSize

    $VMSelection = Read-MenuSelection `
        -Prompt 'Select the VM number to delete' `
        -Minimum 1 `
        -Maximum $AvailableVMs.Count

    $SelectedVM = $AvailableVMs[$VMSelection - 1]
    $VMName = $SelectedVM.Name

    # ------------------------------------------------------------
    # 2. Re-query the selected VM
    # ------------------------------------------------------------
    $SelectedVM = Get-VM `
        -Name $VMName `
        -ErrorAction Stop

    Write-Host(
        "`nSelected virtual machine:"
    ) -ForegroundColor Cyan

    $SelectedVM |
        Select-Object `
            Name,
            Generation,
            State,
            Status,
            Uptime,
            Path |
        Format-List

    # ------------------------------------------------------------
    # 3. Record attached virtual hard disks
    # ------------------------------------------------------------
    #
    # Remove-VM does NOT delete VHD/VHDX files.
    # Record the paths so the administrator knows what files will
    # remain after VM deletion.
    # ------------------------------------------------------------
    $AttachedDisks = @(
        Get-VMHardDiskDrive `
            -VMName $VMName `
            -ErrorAction SilentlyContinue |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_.Path)
            } |
            Select-Object `
                ControllerType,
                ControllerNumber,
                ControllerLocation,
                Path
    )

    Write-Host(
        "`nAttached virtual hard disks:"
    ) -ForegroundColor Cyan

    if ($AttachedDisks.Count -gt 0) {
        $AttachedDisks |
            Format-Table -AutoSize -Wrap
    }
    else {
        Write-Host(
            'No attached VHD/VHDX files were found.'
        ) -ForegroundColor Yellow
    }

    # ------------------------------------------------------------
    # 4. Check for checkpoints
    # ------------------------------------------------------------
    $Checkpoints = @(
        Get-VMSnapshot `
            -VMName $VMName `
            -ErrorAction SilentlyContinue
    )

    Write-Host(
        "`nCheckpoints:"
    ) -ForegroundColor Cyan

    if ($Checkpoints.Count -gt 0) {
        $Checkpoints |
            Select-Object `
                Name,
                CreationTime,
                SnapshotType |
            Format-Table -AutoSize

        Write-Host(
            'WARNING: This VM has checkpoints.'
        ) -ForegroundColor Red

        Write-Host(
            'Deleting the VM will also remove its checkpoints.'
        ) -ForegroundColor Yellow
    }
    else {
        Write-Host(
            'No checkpoints were found.'
        ) -ForegroundColor DarkGray
    }

    # ------------------------------------------------------------
    # 5. Display final warning
    # ------------------------------------------------------------
    Write-Host(
        "`n============================================================"
    ) -ForegroundColor Red

    Write-Host(
        'WARNING - VIRTUAL MACHINE DELETION'
    ) -ForegroundColor Red

    Write-Host(
        "You are about to delete VM '$VMName'."
    ) -ForegroundColor Red

    Write-Host(
        'The Hyper-V VM configuration will be deleted.'
    ) -ForegroundColor Yellow

    Write-Host(
        'Attached VHD/VHDX files will NOT be deleted by this script.'
    ) -ForegroundColor Green

    if ($Checkpoints.Count -gt 0) {
        Write-Host(
            'The VM checkpoints will also be removed.'
        ) -ForegroundColor Yellow
    }

    Write-Host(
        "============================================================"
    ) -ForegroundColor Red

    # ------------------------------------------------------------
    # 6. Require exact VM name for confirmation
    # ------------------------------------------------------------
    Write-Host(
        "`nTo confirm deletion, type the exact VM name:"
    ) -ForegroundColor Yellow

    Write-Host(
        $VMName
    ) -ForegroundColor White

    $Confirmation = Read-Host 'VM name'

    if ($Confirmation -cne $VMName) {
        Write-Host(
            'The VM name did not match.'
        ) -ForegroundColor Yellow

        Write-Host(
            'Operation canceled. No changes were made.'
        ) -ForegroundColor Yellow

        return
    }

    # ------------------------------------------------------------
    # 7. Obtain one final confirmation
    # ------------------------------------------------------------
    $FinalConfirmation = Read-YesNo `
        -Prompt "Permanently remove VM '$VMName' from Hyper-V?"

    if (-not $FinalConfirmation) {
        Write-Host(
            'Operation canceled. No changes were made.'
        ) -ForegroundColor Yellow

        return
    }

    # ------------------------------------------------------------
    # 8. Stop the VM when necessary
    # ------------------------------------------------------------
    $SelectedVM = Get-VM `
        -Name $VMName `
        -ErrorAction Stop

    if ($SelectedVM.State -ne 'Off') {
        Write-Host(
            "`nVM '$VMName' is currently '$($SelectedVM.State)'."
        ) -ForegroundColor Yellow

        $AllowShutdown = Read-YesNo `
            -Prompt 'Shut down the VM before deleting it?'

        if (-not $AllowShutdown) {
            Write-Host(
                'Operation canceled because the VM was not shut down.'
            ) -ForegroundColor Yellow

            return
        }

        Write-Host(
            "Requesting shutdown of '$VMName'..."
        ) -ForegroundColor Cyan

        Stop-VM `
            -VM $SelectedVM `
            -ErrorAction Stop

        # --------------------------------------------------------
        # Wait for VM to shut down
        # --------------------------------------------------------
        $ShutdownTimeoutSeconds = 180
        $Stopwatch = (
            [System.Diagnostics.Stopwatch]::StartNew()
        )

        do {
            Start-Sleep -Seconds 3

            $SelectedVM = Get-VM `
                -Name $VMName `
                -ErrorAction Stop

            Write-Host(
                "Waiting for shutdown. Current state: $($SelectedVM.State)."
            ) -ForegroundColor DarkGray
        } while (
            $SelectedVM.State -ne 'Off' -and
            $Stopwatch.Elapsed.TotalSeconds -lt
                $ShutdownTimeoutSeconds
        )

        $Stopwatch.Stop()

        if ($SelectedVM.State -ne 'Off') {
            throw (
                "VM '$VMName' did not shut down within " +
                "$ShutdownTimeoutSeconds seconds. " +
                'The VM was not deleted.'
            )
        }

        Write-Host(
            "VM '$VMName' is now off."
        ) -ForegroundColor Green
    }

    # ------------------------------------------------------------
    # 9. Re-query immediately before deletion
    # ------------------------------------------------------------
    $VMToDelete = Get-VM `
        -Name $VMName `
        -ErrorAction Stop

    if ($VMToDelete.State -ne 'Off') {
        throw (
            "VM '$VMName' is not powered off. " +
            'The VM was not deleted.'
        )
    }

    # ------------------------------------------------------------
    # 10. Delete the VM
    # ------------------------------------------------------------
    Write-Host(
        "`nDeleting virtual machine '$VMName'..."
    ) -ForegroundColor Cyan

    $VMToDelete |
        Remove-VM `
            -Force `
            -ErrorAction Stop

    # ------------------------------------------------------------
    # 11. Verify deletion
    # ------------------------------------------------------------
    $RemainingVM = Get-VM `
        -Name $VMName `
        -ErrorAction SilentlyContinue

    if ($RemainingVM) {
        throw (
            "Verification failed: VM '$VMName' still exists."
        )
    }

    Write-Host(
        "`nVirtual machine '$VMName' was deleted successfully."
    ) -ForegroundColor Green

    Write-Host(
        'Verification successful: the VM is no longer registered in Hyper-V.'
    ) -ForegroundColor Green

    # ------------------------------------------------------------
    # 12. Show VHD/VHDX files that were retained
    # ------------------------------------------------------------
    if ($AttachedDisks.Count -gt 0) {
        Write-Host(
            "`nThe following virtual hard disk files were NOT deleted:"
        ) -ForegroundColor Cyan

        @(
            foreach ($Disk in $AttachedDisks) {
            $DiskExists = Test-Path `
                -LiteralPath $Disk.Path `
                -PathType Leaf `
                -ErrorAction SilentlyContinue

            [pscustomobject]@{
                Path   = $Disk.Path
                Exists = $DiskExists
            }
            }
        ) |
            Format-Table -AutoSize -Wrap

        Write-Host(
            'Review these files manually before deleting any storage.'
        ) -ForegroundColor Yellow
    }

    # ------------------------------------------------------------
    # 13. Show remaining VMs
    # ------------------------------------------------------------
    Write-Host(
        "`nRemaining Hyper-V virtual machines:"
    ) -ForegroundColor Cyan

    $RemainingVMs = @(
        Get-VM |
            Sort-Object Name
    )

    if ($RemainingVMs.Count -gt 0) {
        $RemainingVMs |
            Select-Object `
                Name,
                Generation,
                State,
                Status,
                Uptime |
            Format-Table -AutoSize
    }
    else {
        Write-Host(
            'No Hyper-V virtual machines remain.'
        ) -ForegroundColor Yellow
    }
}
catch {
    Write-Host(
        "`nOperation failed: $($_.Exception.Message)"
    ) -ForegroundColor Red
}