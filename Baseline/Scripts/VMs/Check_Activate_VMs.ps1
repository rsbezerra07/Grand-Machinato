# Check available VMs and their status
$AvailableVMs = Get-VM

if (-not $AvailableVMs) {
    Write-Host "No Hyper-V virtual machines were found." -ForegroundColor Yellow
    exit 0
}

$AvailableVMs |
    Select-Object Name, State, Status, Uptime |
    Format-Table -AutoSize

# Keep prompting until at least one valid entry is provided
do {
    $VMsToStart = Read-Host "Enter the names of the VMs to start (comma-separated)"

    $VMsToStartArray = @(
        $VMsToStart -split ',' |
            ForEach-Object { $_.Trim() } |
            Where-Object {
                -not [string]::IsNullOrWhiteSpace($_)
            } |
            Select-Object -Unique
    )

    if ($VMsToStartArray.Count -eq 0) {
        Write-Host "Enter at least one VM name." -ForegroundColor Yellow
    }
} while ($VMsToStartArray.Count -eq 0)

foreach ($VMName in $VMsToStartArray) {
    $VM = Get-VM -Name $VMName -ErrorAction SilentlyContinue

    if (-not $VM) {
        Write-Host "VM not found: $VMName" -ForegroundColor Red
        continue
    }

    if ($VM.State -eq "Running") {
        Write-Host "VM '$VMName' is already running." -ForegroundColor Yellow
        continue
    }

    if ($VM.State -ne "Off") {
        Write-Host `
            "VM '$VMName' cannot be started because its current state is '$($VM.State)'." `
            -ForegroundColor Yellow

        continue
    }

    try {
        Start-VM -VM $VM -ErrorAction Stop

        Write-Host "VM '$VMName' started successfully." -ForegroundColor Green
    }
    catch {
        Write-Host `
            "Failed to start VM '$VMName': $($_.Exception.Message)" `
            -ForegroundColor Red
    }
}

# Display updated VM status
Write-Host "`nCurrent VM status:" -ForegroundColor Cyan

Get-VM |
    Select-Object Name, State, Status, Uptime |
    Format-Table -AutoSize