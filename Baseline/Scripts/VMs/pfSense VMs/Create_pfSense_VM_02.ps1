<#
.SYNOPSIS
    Creates the pfSense 02 VM with WAN, Admin, LAN, and Sync adapters.
#>

# Require elevation
$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($CurrentIdentity)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Error "Administrator privileges are required. Run this script as Administrator."
    exit 1
}

# Find repository root containing .env
$CurrentDir = $PSScriptRoot

while ($CurrentDir -and -not (Test-Path -LiteralPath (Join-Path $CurrentDir ".env"))) {
    $ParentDir = Split-Path -Parent $CurrentDir

    # Prevent an infinite loop at the filesystem root
    if ([string]::IsNullOrWhiteSpace($ParentDir) -or
        $ParentDir -eq $CurrentDir) {
        $CurrentDir = $null
        break
    }

    $CurrentDir = $ParentDir
}

if (-not $CurrentDir) {
    Write-Error ".env not found in the repository root."
    exit 1
}

# Read .env
$EnvFile = Join-Path $CurrentDir ".env"
$Config = @{}

foreach ($Line in Get-Content -LiteralPath $EnvFile) {
    $TrimmedLine = $Line.Trim()

    # Ignore empty lines and comments
    if ([string]::IsNullOrWhiteSpace($TrimmedLine) -or
        $TrimmedLine.StartsWith("#")) {
        continue
    }

    if ($TrimmedLine -match '^([^=]+?)\s*=\s*(.*)$') {
        $Key = $Matches[1].Trim()
        $Value = $Matches[2].Trim().Trim('"', "'")
        $Config[$Key] = $Value
    }
}

# VM configuration
$VMName = $Config['pfSenseVM02Name']
$VMPath = $Config['pfSenseVM02Path']
$ISOPath = $Config['pfSenseISOPath']

# Virtual-switch configuration
$WANVMSwitchName = $Config['ExternalvSwitchName']
$AdminVMSwitchName = $Config['AdminvSwitchName']
$LANVMSwitchName = $Config['LANvSwitchName']
$SyncVMSwitchName = $Config['SyncvSwitchName']

$RequiredConfig = [ordered]@{
    pfSenseVM01Name     = $VMName
    pfSenseVM01Path     = $VMPath
    pfSenseISOPath      = $ISOPath
    ExternalvSwitchName = $WANVMSwitchName
    AdminvSwitchName    = $AdminVMSwitchName
    LANvSwitchName      = $LANVMSwitchName
    SyncvSwitchName     = $SyncVMSwitchName
}

foreach ($Entry in $RequiredConfig.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace($Entry.Value)) {
        Write-Error ".env must define $($Entry.Key)."
        exit 1
    }
}

# Define all VM adapters and their corresponding virtual switches
$NetworkAdapters = [ordered]@{
    WAN   = $WANVMSwitchName
    Admin = $AdminVMSwitchName
    LAN   = $LANVMSwitchName
    Sync  = $SyncVMSwitchName
}

# Validate ISO
if (-not (Test-Path -LiteralPath $ISOPath -PathType Leaf)) {
    Write-Error "Installer ISO not found: $ISOPath"
    exit 1
}

# Validate all Hyper-V virtual switches
foreach ($VMSwitchName in $NetworkAdapters.Values) {
    if (-not (Get-VMSwitch -Name $VMSwitchName -ErrorAction SilentlyContinue)) {
        Write-Error "Hyper-V virtual switch not found: $VMSwitchName"
        exit 1
    }
}

# Prevent accidental duplicate creation
if (Get-VM -Name $VMName -ErrorAction SilentlyContinue) {
    Write-Error "A VM named '$VMName' already exists."
    exit 1
}

# Ensure the parent storage directory exists
if (-not (Test-Path -LiteralPath $VMPath -PathType Container)) {
    New-Item `
        -ItemType Directory `
        -Path $VMPath `
        -Force | Out-Null
}

$VHDPath = Join-Path $VMPath "$VMName.vhdx"

try {
    Write-Host "Creating VM: $VMName" -ForegroundColor Cyan

    # Create the VM with its initial adapter connected to the WAN switch
    New-VM `
        -Name $VMName `
        -MemoryStartupBytes 2GB `
        -Generation 2 `
        -NewVHDPath $VHDPath `
        -NewVHDSizeBytes 16GB `
        -Path $VMPath `
        -SwitchName $WANVMSwitchName | Out-Null

    # Configure CPU and static memory
    Set-VM `
        -Name $VMName `
        -ProcessorCount 2 `
        -StaticMemory

    # Disable Secure Boot
    Set-VMFirmware `
        -VMName $VMName `
        -EnableSecureBoot Off

    # Rename the initial network adapter to WAN
    $InitialAdapter = Get-VMNetworkAdapter -VMName $VMName

    if (@($InitialAdapter).Count -ne 1) {
        throw "Expected one initial network adapter, but found $(@($InitialAdapter).Count)."
    }

    Rename-VMNetworkAdapter `
        -VMNetworkAdapter $InitialAdapter `
        -NewName "WAN"

    # Create the Admin, LAN, and Sync adapters
    foreach ($AdapterName in @("Admin", "LAN", "Sync")) {
        Add-VMNetworkAdapter `
            -VMName $VMName `
            -Name $AdapterName `
            -SwitchName $NetworkAdapters[$AdapterName]
    }

    # Enable MAC address spoofing on all four adapters
    foreach ($AdapterName in $NetworkAdapters.Keys) {
        Set-VMNetworkAdapter `
            -VMName $VMName `
            -Name $AdapterName `
            -MacAddressSpoofing On
    }

    # Mount installer ISO
    Add-VMDvdDrive `
        -VMName $VMName `
        -Path $ISOPath

    # Put the DVD drive first in the Generation 2 boot order
    $DVD = Get-VMDvdDrive -VMName $VMName

    Set-VMFirmware `
        -VMName $VMName `
        -FirstBootDevice $DVD

    Write-Host ""
    Write-Host "VM '$VMName' was created successfully." -ForegroundColor Green
    Write-Host "VHD:          $VHDPath"
    Write-Host "ISO:          $ISOPath"
    Write-Host "WAN switch:   $WANVMSwitchName"
    Write-Host "Admin switch: $AdminVMSwitchName"
    Write-Host "LAN switch:   $LANVMSwitchName"
    Write-Host "Sync switch:  $SyncVMSwitchName"

    Write-Host ""
    Write-Host "Network adapters:" -ForegroundColor Cyan

    Get-VMNetworkAdapter -VMName $VMName |
        Sort-Object Name |
        Select-Object Name, SwitchName, MacAddress, MacAddressSpoofing |
        Format-Table -AutoSize
}
catch {
    Write-Error "Failed to create VM '$VMName': $($_.Exception.Message)"
    exit 1
}