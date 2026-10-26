#Requires -RunAsAdministrator
#Requires -Modules Hyper-V

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Carrega as variáveis do arquivo .env.
$EnvironmentLoader = Join-Path `
    -Path $PSScriptRoot `
    -ChildPath "..\..\common\Import-GMEnvironment.ps1"

if (-not (Test-Path -LiteralPath $EnvironmentLoader)) {
    throw "Environment loader not found: $EnvironmentLoader"
}

. $EnvironmentLoader

$Name = "GM-FW01"
$VmRoot = $env:GM_VM_ROOT
$IsoPath = $env:GM_PFSENSE_ISO

# Valida as variáveis carregadas do .env.
if ([string]::IsNullOrWhiteSpace($VmRoot)) {
    throw "GM_VM_ROOT is not defined in .env."
}

if ([string]::IsNullOrWhiteSpace($IsoPath)) {
    throw "GM_PFSENSE_ISO is not defined in .env."
}

$VmPath = Join-Path `
    -Path $VmRoot `
    -ChildPath $Name

$VhdPath = Join-Path `
    -Path $VmPath `
    -ChildPath "OS.vhdx"

# Adaptadores e vSwitches existentes conectados ao firewall.
$Networks = [ordered]@{
    "WAN"   = "GM-WAN"
    "SRV"   = "GM-SRV"
    "IT"    = "GM-IT"
    "HR"    = "GM-HR"
    "SAL"   = "GM-SAL"
    "MKT"   = "GM-MKT"
    "PXE"   = "GM-PXE"
    "ADMIN" = "GM-ADMIN"
    "OSS"   = "GM-OSS"
}

# Não sobrescreve uma VM existente.
if (Get-VM -Name $Name -ErrorAction SilentlyContinue) {
    throw "$Name already exists."
}

# Não sobrescreve um disco virtual existente.
if (Test-Path -LiteralPath $VhdPath) {
    throw "Virtual disk already exists: $VhdPath"
}

# Valida a mídia antes de criar a VM.
if (-not (Test-Path -LiteralPath $IsoPath)) {
    throw "ISO not found: $IsoPath"
}

# Valida todos os vSwitches antes de criar qualquer recurso.
foreach ($SwitchName in $Networks.Values) {
    $Switch = Get-VMSwitch `
        -Name $SwitchName `
        -ErrorAction SilentlyContinue

    if (-not $Switch) {
        throw "vSwitch not found: $SwitchName"
    }
}

try {
    Write-Host ""
    Write-Host `
        "[CREATE] Creating VM directory..." `
        -ForegroundColor Cyan

    New-Item `
        -ItemType Directory `
        -Path $VmPath `
        -Force |
        Out-Null

    Write-Host `
        "[CREATE] Creating $Name..." `
        -ForegroundColor Cyan

    # Cria a VM com o primeiro adaptador conectado à WAN.
    New-VM `
        -Name $Name `
        -Generation 2 `
        -MemoryStartupBytes 2GB `
        -NewVHDPath $VhdPath `
        -NewVHDSizeBytes 16GB `
        -Path $VmRoot `
        -SwitchName "GM-WAN" |
        Out-Null

    Set-VMProcessor `
        -VMName $Name `
        -Count 2

    Set-VMMemory `
        -VMName $Name `
        -DynamicMemoryEnabled $false

    Set-VMFirmware `
        -VMName $Name `
        -EnableSecureBoot Off

    # Localiza o adaptador pelo vSwitch.
    # Não depende do nome padrão localizado do Windows.
    $WanAdapter = Get-VMNetworkAdapter -VMName $Name |
        Where-Object {
            $_.SwitchName -eq "GM-WAN"
        } |
        Select-Object -First 1

    if (-not $WanAdapter) {
        throw "WAN adapter connected to GM-WAN was not found."
    }

    # Rename-VMNetworkAdapter recebe o adaptador pelo pipeline.
    $WanAdapter |
        Rename-VMNetworkAdapter `
            -NewName "WAN"

    # Adiciona os adaptadores das redes internas.
    foreach ($AdapterName in $Networks.Keys) {
        if ($AdapterName -eq "WAN") {
            continue
        }

        $SwitchName = $Networks[$AdapterName]

        Write-Host `
            "[CREATE] Adding $AdapterName -> $SwitchName" `
            -ForegroundColor Cyan

        Add-VMNetworkAdapter `
            -VMName $Name `
            -Name $AdapterName `
            -SwitchName $SwitchName
    }

    # Ativa MAC Address Spoofing em todos os adaptadores.
    Write-Host `
        "[CONFIG] Enabling MAC Address Spoofing on all adapters..." `
        -ForegroundColor Cyan

    Get-VMNetworkAdapter -VMName $Name |
        Set-VMNetworkAdapter `
            -MacAddressSpoofing On

    # Monta a ISO do pfSense.
    Write-Host `
        "[CONFIG] Mounting pfSense ISO..." `
        -ForegroundColor Cyan

    Add-VMDvdDrive `
        -VMName $Name `
        -Path $IsoPath

    $DvdDrive = Get-VMDvdDrive -VMName $Name |
        Where-Object {
            $_.Path -eq $IsoPath
        } |
        Select-Object -First 1

    if (-not $DvdDrive) {
        throw "DVD drive containing the pfSense ISO was not found."
    }

    # Define o DVD como primeiro dispositivo de inicialização.
    Set-VMFirmware `
        -VMName $Name `
        -FirstBootDevice $DvdDrive

    # Obtém novamente os adaptadores após todas as alterações.
    $CreatedAdapters = Get-VMNetworkAdapter -VMName $Name

    # Valida adaptadores, switches e MAC spoofing.
    foreach ($AdapterName in $Networks.Keys) {
        $ExpectedSwitch = $Networks[$AdapterName]

        $Adapter = $CreatedAdapters |
            Where-Object {
                $_.Name -eq $AdapterName
            } |
            Select-Object -First 1

        if (-not $Adapter) {
            throw "Network adapter was not created: $AdapterName"
        }

        if ($Adapter.SwitchName -ne $ExpectedSwitch) {
            $Message = (
                "Adapter {0} is connected to {1}, but {2} was expected." -f
                $AdapterName,
                $Adapter.SwitchName,
                $ExpectedSwitch
            )

            throw $Message
        }

        if ($Adapter.MacAddressSpoofing -ne "On") {
            throw (
                "MAC Address Spoofing is not enabled on adapter: " +
                $AdapterName
            )
        }
    }

    Write-Host ""
    Write-Host `
        "[OK] $Name created successfully." `
        -ForegroundColor Green

    Write-Host ""
    Write-Host `
        "Virtual machine:" `
        -ForegroundColor Cyan

    Get-VM -Name $Name |
        Format-Table `
            Name,
            State,
            Generation,
            ProcessorCount,
            MemoryStartup `
            -AutoSize

    Write-Host `
        "Network adapters:" `
        -ForegroundColor Cyan

    Get-VMNetworkAdapter -VMName $Name |
        Sort-Object Name |
        Format-Table `
            Name,
            SwitchName,
            MacAddress,
            MacAddressSpoofing `
            -AutoSize

    Write-Host `
        "DVD drive:" `
        -ForegroundColor Cyan

    Get-VMDvdDrive -VMName $Name |
        Format-Table `
            ControllerNumber,
            ControllerLocation,
            Path `
            -AutoSize
}
catch {
    $FailureMessage = $_.Exception.Message

    Write-Host ""
    Write-Host `
        "[ERROR] $FailureMessage" `
        -ForegroundColor Red

    # Remove o registro da VM se a criação ficou incompleta.
    if (Get-VM -Name $Name -ErrorAction SilentlyContinue) {
        Write-Host `
            "[ROLLBACK] Removing incomplete VM $Name..." `
            -ForegroundColor Yellow

        Stop-VM `
            -Name $Name `
            -TurnOff `
            -ErrorAction SilentlyContinue

        Remove-VM `
            -Name $Name `
            -Force `
            -ErrorAction SilentlyContinue
    }

    # Remove somente o disco da tentativa incompleta.
    if (Test-Path -LiteralPath $VhdPath) {
        Write-Host `
            "[ROLLBACK] Removing incomplete virtual disk..." `
            -ForegroundColor Yellow

        Remove-Item `
            -LiteralPath $VhdPath `
            -Force `
            -ErrorAction SilentlyContinue
    }

    # Remove o diretório da VM somente se estiver vazio.
    if (Test-Path -LiteralPath $VmPath) {
        $RemainingItems = @(
       
                -LiteralPath $VmPath `
                -Force `
                -ErrorAction SilentlyContinue
        )

        if ($RemainingItems.Count -eq 0) {
            Remove-Item `
                -LiteralPath $VmPath `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }

    throw $FailureMessage
}