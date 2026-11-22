# Check available VMs and their status
$AvailableVMs = Get-VM

if (-not $AvailableVMs) {
    Write-Host "No Hyper-V virtual machines were found." -ForegroundColor Yellow
    exit 0
}

$AvailableVMs |
    Select-Object Name, State, Status, Uptime |
    Format-Table -AutoSize

# Keep prompting until at least one non-empty name is entered
do {
    $VMsToRename = Read-Host "Enter the names of the VMs to rename (comma-separated)"

    $VMsToRenameArray = @(
        $VMsToRename -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
            Select-Object -Unique
    )

    if ($VMsToRenameArray.Count -eq 0) {
        Write-Host "Enter at least one VM name." -ForegroundColor Yellow
    }
} while ($VMsToRenameArray.Count -eq 0)

foreach ($VMName in $VMsToRenameArray) {
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

    if (-not $VM) {
        Write-Host "VM not found: $VMName" -ForegroundColor Red
        continue
    }

    do {
        $NewName = (Read-Host "Enter the new name for VM '$VMName'").Trim()

        if ([string]::IsNullOrWhiteSpace($NewName)) {
            Write-Host "The new VM name cannot be empty." -ForegroundColor Yellow
            continue
        }

        if ($NewName -eq $VMName) {
            Write-Host "The new name must be different from the current name." -ForegroundColor Yellow
            $NewName = $null
            continue
        }

        if (Get-VM -Name $NewName -ErrorAction SilentlyContinue) {
            Write-Host "A VM named '$NewName' already exists. Choose another name." -ForegroundColor Yellow
            $NewName = $null
        }
    } while ([string]::IsNullOrWhiteSpace($NewName))

    try {
        Rename-VM -VM $VM -NewName $NewName -ErrorAction Stop
        Write-Host "Renamed '$VMName' to '$NewName'." -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to rename '$VMName': $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nCurrent VM names:" -ForegroundColor Cyan

Get-VM |
    Select-Object Name, State, Status, Uptime |
    Format-Table -AutoSize