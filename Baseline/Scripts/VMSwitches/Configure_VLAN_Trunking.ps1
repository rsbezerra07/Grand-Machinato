<#
.SYNOPSIS
    Configures MAC Address Spoofing and 802.1Q VLAN Trunking for the pfSense HA Cluster VMs using .env variables.
#>

# Dynamically locate the root .env file
$CurrentDir = $PSScriptRoot
while ($CurrentDir -and -not (Test-Path (Join-Path $CurrentDir ".env"))) {
    $CurrentDir = Split-Path -Parent $CurrentDir
}
$EnvFile = Join-Path $CurrentDir ".env"

if (-not (Test-Path $EnvFile)) {
    Write-Error ".env file not found in the repository root."
    exit 1
}

$LanSwitch = $null
$VM01Name  = $null
$VM02Name  = $null

# Parse variables from .env in the current scope so their assignments are
# visible to the validation and configuration code below.
foreach ($Line in Get-Content $EnvFile) {
    if ($Line -match "^\s*LANvSwitchName\s*=\s*(.+)$")  { $LanSwitch = $Matches[1].Trim() }
    if ($Line -match "^\s*pfSenseVM01Name\s*=\s*(.+)$") { $VM01Name  = $Matches[1].Trim() }
    if ($Line -match "^\s*pfSenseVM02Name\s*=\s*(.+)$") { $VM02Name  = $Matches[1].Trim() }
}

if (-not $LanSwitch -or -not $VM01Name -or -not $VM02Name) {
    Write-Error "Missing LANvSwitchName, pfSenseVM01Name, or pfSenseVM02Name in .env."
    exit 1
}

$PfsenseVMs = @($VM01Name, $VM02Name)

foreach ($VM in $PfsenseVMs) {
    if (-not (Get-VM -Name $VM -ErrorAction SilentlyContinue)) {
        Write-Warning "VM '$VM' not found in Hyper-V. Skipping..."
        continue
    }

    Write-Host "Configuring Hyper-V network adapters for '$VM'..." -ForegroundColor Cyan

    # Set the LAN vSwitch adapter to 802.1Q Trunk mode for VLANs 10-80
    Get-VMNetworkAdapter -VMName $VM | Where-Object { $_.SwitchName -eq $LanSwitch } | 
        Set-VMNetworkAdapterVlan -Trunk -NativeVlanId 0 -AllowedVlanIdList "10,20,30,40,50,60,70,80"
}

Write-Host "`nVerifying Trunk configuration on '$LanSwitch':" -ForegroundColor Green
Get-VMNetworkAdapter -VMName $PfsenseVMs | Where-Object { $_.SwitchName -eq $LanSwitch } | Get-VMNetworkAdapterVlan