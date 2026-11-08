<#
.SYNOPSIS
    Create the SYNC VM Switch based on the .env file.
#>

$CurrentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = [Security.Principal.WindowsPrincipal]::new($CurrentIdentity)
if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Administrator privileges are required. Please run this script again as Administrator."
    exit 1
}

$CurrentDir = $PSScriptRoot
while ($CurrentDir -and -not (Test-Path (Join-Path $CurrentDir ".env"))) {
    $CurrentDir = Split-Path -Parent $CurrentDir
}
$EnvFile = Join-Path $CurrentDir ".env"

if (-not (Test-Path $EnvFile)) { 
    Write-Error ".env not found in the repository root."
    exit 1 
}

$AdapterName = $null
$SwitchName = $null

foreach ($Line in Get-Content $EnvFile) {
    if ($Line -match "^\s*NetAdapterName\s*=\s*(.+)$") { $AdapterName = $Matches[1].Trim() }
    if ($Line -match "^\s*SyncvSwitchName\s*=\s*(.+)$") { $SwitchName = $Matches[1].Trim() }
}

if (-not (Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue)) {
    Write-Error "Physical network adapter '$AdapterName' not found or inactive."
    exit 1
}

if (-not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating Private VM Switch '$SwitchName' linked to '$AdapterName'..." -ForegroundColor Green
    New-VMSwitch -Name $SwitchName -SwitchType private

    Write-Host "Private VM Switch created successfully!" -ForegroundColor Cyan
} else {
    Write-Host "Private VM Switch '$SwitchName' already exists." -ForegroundColor Yellow
}