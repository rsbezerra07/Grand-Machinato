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

function Read-PositiveNumber {
    param(
        [Parameter(Mandatory)]
        [string] $Prompt
    )

    do {
        $InputValue = Read-Host $Prompt
        [double] $Number = 0

        $IsValid = [double]::TryParse(
            $InputValue,
            [ref] $Number
        ) -and
        $Number -gt 0

        if (-not $IsValid) {
            Write-Host(
                'Enter a number greater than zero.'
            ) -ForegroundColor Yellow
        }
    } until ($IsValid)

    return $Number
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

function Read-ExistingFilePath {
    param(
        [Parameter(Mandatory)]
        [string] $Prompt,

        [Parameter(Mandatory)]
        [string[]] $AllowedExtensions
    )

    do {
        $PathValue = (
            Read-Host $Prompt
        ).Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($PathValue)) {
            Write-Host(
                'A file path is required.'
            ) -ForegroundColor Yellow

            continue
        }

        if (-not [System.IO.Path]::IsPathRooted($PathValue)) {
            Write-Host(
                'Enter a fully qualified path, such as D:\VMs\Disk.vhdx.'
            ) -ForegroundColor Yellow

            continue
        }

        if (-not (Test-Path -LiteralPath $PathValue -PathType Leaf)) {
            Write-Host(
                "The file does not exist: $PathValue"
            ) -ForegroundColor Yellow

            continue
        }

        $Extension = [System.IO.Path]::GetExtension(
            $PathValue
        ).ToLowerInvariant()

        if ($Extension -notin $AllowedExtensions) {
            Write-Host(
                "Allowed file types: {0}" -f
                ($AllowedExtensions -join ', ')
            ) -ForegroundColor Yellow

            continue
        }

        return [System.IO.Path]::GetFullPath($PathValue)
    } while ($true)
}

function Read-NewVhdxPath {
    param(
        [Parameter(Mandatory)]
        [string] $DefaultDirectory,

        [Parameter(Mandatory)]
        [string] $DefaultFileName
    )

    do {
        Write-Host(
            "`nDefault storage directory: $DefaultDirectory"
        ) -ForegroundColor DarkGray

        $Directory = (
            Read-Host(
                'Enter the directory for the new VHDX, or press Enter to use the default'
            )
        ).Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($Directory)) {
            $Directory = $DefaultDirectory
        }

        if (-not [System.IO.Path]::IsPathRooted($Directory)) {
            Write-Host(
                'Enter a fully qualified directory path.'
            ) -ForegroundColor Yellow

            continue
        }

        try {
            $Directory = [System.IO.Path]::GetFullPath($Directory)
        }
        catch {
            Write-Host(
                'The directory path is not valid.'
            ) -ForegroundColor Yellow

            continue
        }

        $FileName = (
            Read-Host(
                "Enter the VHDX file name, or press Enter to use '$DefaultFileName'"
            )
        ).Trim().Trim('"')

        if ([string]::IsNullOrWhiteSpace($FileName)) {
            $FileName = $DefaultFileName
        }

        if (
            [System.IO.Path]::GetExtension($FileName) -ne '.vhdx'
        ) {
            $FileName = "$FileName.vhdx"
        }

        $InvalidFileNameCharacters = (
            [System.IO.Path]::GetInvalidFileNameChars()
        )

        if ($FileName.IndexOfAny($InvalidFileNameCharacters) -ge 0) {
            Write-Host(
                'The VHDX file name contains invalid characters.'
            ) -ForegroundColor Yellow

            continue
        }

        $FullPath = Join-Path `
            -Path $Directory `
            -ChildPath $FileName

        if (Test-Path -LiteralPath $FullPath) {
            Write-Host(
                "A file or folder already exists at: $FullPath"
            ) -ForegroundColor Yellow

            continue
        }

        return [pscustomobject]@{
            Directory = $Directory
            FileName  = $FileName
            FullPath  = $FullPath
        }
    } while ($true)
}

function Get-FreeScsiLocation {
    param(
        [Parameter(Mandatory)]
        [string] $VMName,

        [Parameter(Mandatory)]
        [int] $ControllerNumber
    )

    $UsedLocations = @(
        Get-VMHardDiskDrive -VMName $VMName |
            Where-Object {
                $_.ControllerType -eq 'SCSI' -and
                $_.ControllerNumber -eq $ControllerNumber
            } |
            Select-Object -ExpandProperty ControllerLocation

        Get-VMDvdDrive -VMName $VMName |
            Where-Object {
                $_.ControllerType -eq 'SCSI' -and
                $_.ControllerNumber -eq $ControllerNumber
            } |
            Select-Object -ExpandProperty ControllerLocation
    )

    foreach ($Location in 0..63) {
        if ($Location -notin $UsedLocations) {
            return $Location
        }
    }

    return $null
}

function Stop-VMForConfiguration {
    param(
        [Parameter(Mandatory)]
        [string] $VMName,

        [int] $TimeoutSeconds = 180
    )

    $VM = Get-VM -Name $VMName

    if ($VM.State -eq 'Off') {
        return
    }

    Write-Host(
        "`nVM '$VMName' is currently '$($VM.State)'."
    ) -ForegroundColor Yellow

    $AllowShutdown = Read-YesNo `
        -Prompt 'Shut down the VM before adding the device?'

    if (-not $AllowShutdown) {
        throw (
            'Operation canceled because the VM was not shut down.'
        )
    }

    Write-Host(
        "Requesting shutdown of '$VMName'..."
    ) -ForegroundColor Cyan

    Stop-VM -VM $VM -ErrorAction Stop

    $Stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    do {
        Start-Sleep -Seconds 3
        $VM = Get-VM -Name $VMName

        Write-Host(
            "Waiting for shutdown. Current state: $($VM.State)"
        ) -ForegroundColor DarkGray
    } while (
        $VM.State -ne 'Off' -and
        $Stopwatch.Elapsed.TotalSeconds -lt $TimeoutSeconds
    )

    $Stopwatch.Stop()

    if ($VM.State -ne 'Off') {
        throw (
            "VM '$VMName' did not shut down within " +
            "$TimeoutSeconds seconds. No device was added."
        )
    }

    Write-Host(
        "VM '$VMName' is now off."
    ) -ForegroundColor Green
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

    @(
        for (
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
    ) |
        Format-Table -AutoSize

    $VMSelection = Read-MenuSelection `
        -Prompt 'Select the VM number' `
        -Minimum 1 `
        -Maximum $AvailableVMs.Count

    $SelectedVM = $AvailableVMs[$VMSelection - 1]
    $VMName = $SelectedVM.Name
    $InitialState = $SelectedVM.State
    $VMWasStopped = $false

    Write-Host(
        "`nSelected VM: $VMName"
    ) -ForegroundColor Cyan

    # ------------------------------------------------------------
    # 2. Find and select a SCSI controller
    # ------------------------------------------------------------
    $ScsiControllers = @(
        Get-VMScsiController -VMName $VMName |
            Sort-Object ControllerNumber
    )

    if ($ScsiControllers.Count -eq 0) {
        Write-Host(
            "VM '$VMName' has no SCSI controller."
        ) -ForegroundColor Yellow

        return
    }

    Write-Host(
        "`nAvailable SCSI controllers:"
    ) -ForegroundColor Cyan

    @(
        for (
            $Index = 0;
            $Index -lt $ScsiControllers.Count;
            $Index++
        ) {
            $Controller = $ScsiControllers[$Index]

            $FreeLocation = Get-FreeScsiLocation `
                -VMName $VMName `
                -ControllerNumber $Controller.ControllerNumber

            [pscustomobject]@{
                ControllerNumber = $Controller.ControllerNumber
                FreeLocation     = if ($null -ne $FreeLocation) {
                    $FreeLocation
                }
                else {
                    '<Full>'
                }
            }
        }
    ) |
        Format-Table -AutoSize

    $ControllerSelection = Read-MenuSelection `
        -Prompt 'Select the SCSI controller number' `
        -Minimum 1 `
        -Maximum $ScsiControllers.Count

    $SelectedController = $ScsiControllers[
        $ControllerSelection - 1
    ]

    $ControllerNumber = $SelectedController.ControllerNumber

    $ControllerLocation = Get-FreeScsiLocation `
        -VMName $VMName `
        -ControllerNumber $ControllerNumber

    if ($null -eq $ControllerLocation) {
        throw (
            "SCSI controller $ControllerNumber has no free locations."
        )
    }

    Write-Host(
        "Using SCSI controller $ControllerNumber, " +
        "location $ControllerLocation."
    ) -ForegroundColor Cyan

    # ------------------------------------------------------------
    # 3. Select the device to add
    # ------------------------------------------------------------
    Write-Host(
        "`nSelect the device to add:"
    ) -ForegroundColor Cyan

    Write-Host '1. Create and attach a new VHDX'
    Write-Host '2. Attach an existing VHD or VHDX'
    Write-Host '3. Add a DVD drive with an existing ISO'

    $DeviceSelection = Read-MenuSelection `
        -Prompt 'Select an option' `
        -Minimum 1 `
        -Maximum 3

    if (
        $DeviceSelection -eq 3 -and
        $SelectedVM.Generation -ne 2
    ) {
        throw (
            "VM '$VMName' is Generation " +
            "$($SelectedVM.Generation). A DVD drive cannot be added " +
            'to its SCSI controller by this script.'
        )
    }

    $DeviceDescription = $null
    $AttachedPath = $null
    $CreatedNewVhdx = $false

    # ------------------------------------------------------------
    # 4. Gather device configuration
    # ------------------------------------------------------------
    switch ($DeviceSelection) {
        1 {
            $VMHost = Get-VMHost
            $DefaultDirectory = $VMHost.VirtualHardDiskPath

            if ([string]::IsNullOrWhiteSpace($DefaultDirectory)) {
                $DefaultDirectory = Join-Path `
                    -Path $SelectedVM.Path `
                    -ChildPath 'Virtual Hard Disks'
            }

            $SafeVMName = $VMName -replace '[^\w\-. ]', '_'
            $DefaultFileName = "$SafeVMName-Data.vhdx"

            $NewVhdx = Read-NewVhdxPath `
                -DefaultDirectory $DefaultDirectory `
                -DefaultFileName $DefaultFileName

            Write-Host(
                "`nSelect the VHDX allocation type:"
            ) -ForegroundColor Cyan

            Write-Host '1. Dynamic'
            Write-Host '2. Fixed'

            $VhdTypeSelection = Read-MenuSelection `
                -Prompt 'Select the VHDX type' `
                -Minimum 1 `
                -Maximum 2

            $SizeGB = Read-PositiveNumber `
                -Prompt 'Enter the VHDX maximum size in GB'

            [uint64] $SizeBytes = [math]::Round(
                $SizeGB * 1GB
            )

            $VhdType = if ($VhdTypeSelection -eq 1) {
                'Dynamic'
            }
            else {
                'Fixed'
            }

            Write-Host(
                "`nNew VHDX configuration:"
            ) -ForegroundColor Cyan

            [pscustomobject]@{
                VM                 = $VMName
                Path               = $NewVhdx.FullPath
                Type               = $VhdType
                MaximumSizeGB      = $SizeGB
                ControllerNumber   = $ControllerNumber
                ControllerLocation = $ControllerLocation
            } |
                Format-List

            $Confirmation = Read-Host(
                "Type ADD to create and attach this VHDX to VM '$VMName'"
            )

            if ($Confirmation -cne 'ADD') {
                Write-Host(
                    'Operation canceled. No changes were made.'
                ) -ForegroundColor Yellow

                return
            }
        }

        2 {
            $AttachedPath = Read-ExistingFilePath `
                -Prompt 'Enter the full path to the existing VHD or VHDX' `
                -AllowedExtensions @(
                    '.vhd',
                    '.vhdx'
                )

            Write-Host(
                "`nExisting virtual disk configuration:"
            ) -ForegroundColor Cyan

            [pscustomobject]@{
                VM                 = $VMName
                Path               = $AttachedPath
                ControllerNumber   = $ControllerNumber
                ControllerLocation = $ControllerLocation
            } |
                Format-List

            $Confirmation = Read-Host(
                "Type ADD to attach this disk to VM '$VMName'"
            )

            if ($Confirmation -cne 'ADD') {
                Write-Host(
                    'Operation canceled. No changes were made.'
                ) -ForegroundColor Yellow

                return
            }
        }

        3 {
            $AttachedPath = Read-ExistingFilePath `
                -Prompt 'Enter the full path to the existing ISO file' `
                -AllowedExtensions @(
                    '.iso'
                )

            Write-Host(
                "`nDVD drive configuration:"
            ) -ForegroundColor Cyan

            [pscustomobject]@{
                VM                 = $VMName
                ISOPath            = $AttachedPath
                ControllerNumber   = $ControllerNumber
                ControllerLocation = $ControllerLocation
            } |
                Format-List

            $Confirmation = Read-Host(
                "Type ADD to add this DVD drive to VM '$VMName'"
            )

            if ($Confirmation -cne 'ADD') {
                Write-Host(
                    'Operation canceled. No changes were made.'
                ) -ForegroundColor Yellow

                return
            }
        }
    }

    # ------------------------------------------------------------
    # 5. Shut down the VM before changing its configuration
    # ------------------------------------------------------------
    if ((Get-VM -Name $VMName).State -ne 'Off') {
        Stop-VMForConfiguration -VMName $VMName
        $VMWasStopped = $true
    }

    # Recheck the location after shutdown
    $ControllerLocation = Get-FreeScsiLocation `
        -VMName $VMName `
        -ControllerNumber $ControllerNumber

    if ($null -eq $ControllerLocation) {
        throw (
            "SCSI controller $ControllerNumber has no free locations."
        )
    }

    # ------------------------------------------------------------
    # 6. Create or attach the selected device
    # ------------------------------------------------------------
    switch ($DeviceSelection) {
        1 {
            if (-not (Test-Path -LiteralPath $NewVhdx.Directory)) {
                New-Item `
                    -ItemType Directory `
                    -Path $NewVhdx.Directory `
                    -Force |
                    Out-Null
            }

            Write-Host(
                "`nCreating $VhdType VHDX..."
            ) -ForegroundColor Cyan

            if ($VhdTypeSelection -eq 1) {
                New-VHD `
                    -Path $NewVhdx.FullPath `
                    -SizeBytes $SizeBytes `
                    -Dynamic `
                    -ErrorAction Stop |
                    Out-Null
            }
            else {
                New-VHD `
                    -Path $NewVhdx.FullPath `
                    -SizeBytes $SizeBytes `
                    -Fixed `
                    -ErrorAction Stop |
                    Out-Null
            }

            $CreatedNewVhdx = $true
            $AttachedPath = $NewVhdx.FullPath
            $DeviceDescription = 'new virtual hard disk'

            try {
                Add-VMHardDiskDrive `
                    -VMName $VMName `
                    -ControllerType SCSI `
                    -ControllerNumber $ControllerNumber `
                    -ControllerLocation $ControllerLocation `
                    -Path $AttachedPath `
                    -ErrorAction Stop
            }
            catch {
                if (
                    $CreatedNewVhdx -and
                    (Test-Path -LiteralPath $AttachedPath)
                ) {
                    Write-Host(
                        'Attachment failed. Removing the newly created VHDX.'
                    ) -ForegroundColor Yellow

                    Remove-Item `
                        -LiteralPath $AttachedPath `
                        -Force `
                        -ErrorAction SilentlyContinue
                }

                throw
            }
        }

        2 {
            Add-VMHardDiskDrive `
                -VMName $VMName `
                -ControllerType SCSI `
                -ControllerNumber $ControllerNumber `
                -ControllerLocation $ControllerLocation `
                -Path $AttachedPath `
                -ErrorAction Stop

            $DeviceDescription = 'existing virtual hard disk'
        }

        3 {
            Add-VMDvdDrive `
                -VMName $VMName `
                -ControllerNumber $ControllerNumber `
                -ControllerLocation $ControllerLocation `
                -Path $AttachedPath `
                -ErrorAction Stop |
                Out-Null

            $DeviceDescription = 'DVD drive'
        }
    }

    # ------------------------------------------------------------
    # 7. Verify the attachment
    # ------------------------------------------------------------
    if ($DeviceSelection -in 1, 2) {
        $AddedDevice = Get-VMHardDiskDrive `
            -VMName $VMName `
            -ControllerType SCSI `
            -ControllerNumber $ControllerNumber `
            -ControllerLocation $ControllerLocation `
            -ErrorAction SilentlyContinue
    }
    else {
        $AddedDevice = Get-VMDvdDrive -VMName $VMName |
            Where-Object {
                $_.ControllerType -eq 'SCSI' -and
                $_.ControllerNumber -eq $ControllerNumber -and
                $_.ControllerLocation -eq $ControllerLocation
            }
    }

    if (-not $AddedDevice) {
        throw (
            'Verification failed: the new device was not found at ' +
            "SCSI controller $ControllerNumber, location " +
            "$ControllerLocation."
        )
    }

    if (
        -not [string]::IsNullOrWhiteSpace($AttachedPath) -and
        $AddedDevice.Path -ne $AttachedPath
    ) {
        throw (
            'Verification failed: the attached path does not match ' +
            'the requested path.'
        )
    }

    Write-Host(
        "`nThe $DeviceDescription was added successfully."
    ) -ForegroundColor Green

    Write-Host(
        'Verification successful:'
    ) -ForegroundColor Green

    $AddedDevice |
        Select-Object `
            ControllerType,
            ControllerNumber,
            ControllerLocation,
            Path |
        Format-List

    # ------------------------------------------------------------
    # 8. Show all current SCSI devices
    # ------------------------------------------------------------
    Write-Host(
        "`nCurrent SCSI devices for '$VMName':"
    ) -ForegroundColor Cyan

    $CurrentHardDisks = @(
        Get-VMHardDiskDrive -VMName $VMName |
            Where-Object ControllerType -eq 'SCSI' |
            Select-Object @{
                Name       = 'Type'
                Expression = {
                    'Hard Disk'
                }
            }, ControllerNumber, ControllerLocation, Path
    )

    $CurrentDvdDrives = @(
        Get-VMDvdDrive -VMName $VMName |
            Where-Object ControllerType -eq 'SCSI' |
            Select-Object @{
                Name       = 'Type'
                Expression = {
                    'DVD Drive'
                }
            }, ControllerNumber, ControllerLocation, @{
                Name       = 'Path'
                Expression = {
                    if ($_.Path) {
                        $_.Path
                    }
                    else {
                        '<No media mounted>'
                    }
                }
            }
    )

    $CurrentDevices = @(
        $CurrentHardDisks
        $CurrentDvdDrives
    )

    if ($CurrentDevices.Count -gt 0) {
        $CurrentDevices |
            Sort-Object `
                ControllerNumber,
                ControllerLocation,
                Type |
            Format-Table -AutoSize -Wrap
    }
    else {
        Write-Host(
            'No SCSI devices are currently attached.'
        ) -ForegroundColor Yellow
    }

    # ------------------------------------------------------------
    # 9. Optionally restart the VM
    # ------------------------------------------------------------
    if ($VMWasStopped) {
        $StartAgainPrompt = if ($InitialState -eq 'Running') {
            'The VM was running before this operation. Start it again?'
        }
        else {
            'Do you want to start the VM now?'
        }

        if (
            Read-YesNo `
                -Prompt $StartAgainPrompt `
                -DefaultYes ($InitialState -eq 'Running')
        ) {
            Start-VM `
                -Name $VMName `
                -ErrorAction Stop

            $FinalVM = Get-VM -Name $VMName

            Write-Host(
                "VM '$VMName' was started. " +
                "Current state: $($FinalVM.State)"
            ) -ForegroundColor Green
        }
        else {
            Write-Host(
                "VM '$VMName' remains powered off."
            ) -ForegroundColor Yellow
        }
    }

    # ------------------------------------------------------------
    # 10. Show final VM status
    # ------------------------------------------------------------
    Write-Host(
        "`nFinal VM status:"
    ) -ForegroundColor Cyan

    Get-VM -Name $VMName |
        Select-Object `
            Name,
            Generation,
            State,
            Status,
            Uptime |
        Format-Table -AutoSize
}
catch {
    Write-Host(
        "`nOperation failed: $($_.Exception.Message)"
    ) -ForegroundColor Red
}