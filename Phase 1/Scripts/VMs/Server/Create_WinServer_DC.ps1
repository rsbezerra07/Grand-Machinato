<#
.SYNOPSIS
    Creates the Windows Server DC VM with LAN adapter tagged for VLAN 10.
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


# Windows Server DC VM configuration
$VMName = $Config['WinServerDCVMName']
$VMPath = $Config['WinServerDCVMPath']
$ISOPath = $Config['WinServerDCISOPath']


# Network configuration
$LANVMSwitchName = $Config['LANvSwitchName']
$VLANID = 10


# Validate required configuration
$RequiredConfig = [ordered]@{
    WinServerDCVMName  = $VMName
    WinServerDCVMPath  = $VMPath
    WinServerDCISOPath = $ISOPath
    LANvSwitchName     = $LANVMSwitchName
}

foreach ($Entry in $RequiredConfig.GetEnumerator()) {
    if ([string]::IsNullOrWhiteSpace([string]$Entry.Value)) {
        Write-Error ".env must define $($Entry.Key)."
        exit 1
    }
}


# Validate ISO
if (-not (Test-Path -LiteralPath $ISOPath -PathType Leaf)) {
    Write-Error "Windows Server installer ISO not found: $ISOPath"
    exit 1
}


# Validate LAN Hyper-V virtual switch
if (-not (Get-VMSwitch -Name $LANVMSwitchName -ErrorAction SilentlyContinue)) {
    Write-Error "Hyper-V virtual switch not found: $LANVMSwitchName"
    exit 1
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


# Virtual disk
$VHDPath = Join-Path $VMPath "$VMName.vhdx"


try {
    Write-Host "Creating Windows Server DC VM: $VMName" -ForegroundColor Cyan


    # Create Generation 2 VM attached to the LAN switch
    New-VM `
        -Name $VMName `
        -MemoryStartupBytes 4GB `
        -Generation 2 `
        -NewVHDPath $VHDPath `
        -NewVHDSizeBytes 60GB `
        -Path $VMPath `
        -SwitchName $LANVMSwitchName | Out-Null


    # Configure CPU
    Set-VM `
        -Name $VMName `
        -ProcessorCount 4


    # Configure Dynamic Memory
    Set-VMMemory `
        -VMName $VMName `
        -DynamicMemoryEnabled $true `
        -MinimumBytes 4GB `
        -StartupBytes 4GB `
        -MaximumBytes 6GB


    # Get the initial network adapter
    $NetworkAdapter = Get-VMNetworkAdapter -VMName $VMName

    if (@($NetworkAdapter).Count -ne 1) {
        throw "Expected one network adapter, but found $(@($NetworkAdapter).Count)."
    }


    # Rename the initial network adapter to LAN
    Rename-VMNetworkAdapter `
        -VMNetworkAdapter $NetworkAdapter `
        -NewName "LAN"


    # Configure the LAN adapter as an access port on VLAN 10
    Set-VMNetworkAdapterVlan `
        -VMName $VMName `
        -VMNetworkAdapterName "LAN" `
        -Access `
        -VlanId $VLANID


    # Enable MAC address spoofing
    Set-VMNetworkAdapter `
        -VMName $VMName `
        -Name "LAN" `
        -MacAddressSpoofing On


    # Disable Secure Boot 
    Set-VMFirmware `
        -VMName $VMName `
        -EnableSecureBoot Off


    # Mount Windows Server installation ISO
    Add-VMDvdDrive `
        -VMName $VMName `
        -Path $ISOPath


    # Get the DVD drive
    $DVD = Get-VMDvdDrive -VMName $VMName

    if (-not $DVD) {
        throw "The Windows Server installation DVD drive could not be found."
    }


    # Put DVD first in the Generation 2 boot order
    Set-VMFirmware `
        -VMName $VMName `
        -FirstBootDevice $DVD


    # Display success information
    Write-Host ""
    Write-Host "VM '$VMName' was created successfully." -ForegroundColor Green

    Write-Host ""
    Write-Host "Virtual machine configuration:" -ForegroundColor Cyan
    Write-Host "VM Name:          $VMName"
    Write-Host "VM Path:          $VMPath"
    Write-Host "VHD:              $VHDPath"
    Write-Host "VHD Size:         60 GB"
    Write-Host "ISO:              $ISOPath"
    Write-Host "Generation:       2"
    Write-Host "Processors:       4"
    Write-Host "Startup Memory:   4 GB"
    Write-Host "Minimum Memory:   4 GB"
    Write-Host "Maximum Memory:   6 GB"
    Write-Host "Dynamic Memory:   Enabled"
    Write-Host "LAN Switch:       $LANVMSwitchName"
    Write-Host "VLAN:             $VLANID"
    Write-Host "MAC Spoofing:     Enabled"
    Write-Host "Secure Boot:      Enabled"
    Write-Host "Virtual TPM:      Enabled"


    # Display network adapter configuration
    Write-Host ""
    Write-Host "Network adapter:" -ForegroundColor Cyan

    Get-VMNetworkAdapter -VMName $VMName |
        Select-Object `
            Name,
            SwitchName,
            MacAddress,
            MacAddressSpoofing |
        Format-Table -AutoSize


    # Display VLAN configuration
    Write-Host ""
    Write-Host "VLAN configuration:" -ForegroundColor Cyan

    Get-VMNetworkAdapterVlan `
        -VMName $VMName `
        -VMNetworkAdapterName "LAN" |
        Format-Table -AutoSize


    # Display memory configuration
    Write-Host ""
    Write-Host "Memory configuration:" -ForegroundColor Cyan

    Get-VMMemory -VMName $VMName |
        Select-Object `
            DynamicMemoryEnabled,
            Minimum,
            Startup,
            Maximum |
        Format-Table -AutoSize


    # Display security configuration
    Write-Host ""
    Write-Host "VM security configuration:" -ForegroundColor Cyan

    Get-VMSecurity -VMName $VMName |
        Format-List


    # Display firmware configuration
    Write-Host ""
    Write-Host "Firmware configuration:" -ForegroundColor Cyan

    Get-VMFirmware -VMName $VMName |
        Select-Object `
            SecureBoot,
            SecureBootTemplate,
            BootOrder |
        Format-List
}
catch {
    Write-Error "Failed to create VM '$VMName': $($_.Exception.Message)"
    exit 1
}