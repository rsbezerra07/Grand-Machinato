<#
.SYNOPSIS
    Rename a VM Switch based on user selection.
#>

$vmswitches = @(Get-VMSwitch | Sort-Object Name)

if ($vmswitches.Count -eq 0) {
	Write-Host "No virtual switches found."
	exit
}

Write-Host "Select the vSwitch to rename:"
for ($i = 0; $i -lt $vmswitches.Count; $i++) {
	Write-Host ("{0}: {1}" -f ($i + 1), $vmswitches[$i].Name)
}

$selection = Read-Host "Enter the number (or press Enter to cancel)"
if ([string]::IsNullOrWhiteSpace($selection)) {
	Write-Host "Cancelled."
	exit
}

$index = 0
if (-not [int]::TryParse($selection, [ref]$index) -or
	$index -lt 1 -or $index -gt $vmswitches.Count) {
	Write-Error "Invalid selection."
	exit 1
}

$selectedSwitch = $vmswitches[$index - 1]
$newName = Read-Host "Enter the new name for '$($selectedSwitch.Name)' (or press Enter to cancel)"
if ([string]::IsNullOrWhiteSpace($newName)) {
	Write-Host "Cancelled."
	exit
}

$confirmation = Read-Host "Rename '$($selectedSwitch.Name)' to '$newName'? (y/N)"
if ($confirmation -match '^(y|yes)$') {
	Rename-VMSwitch -Name $selectedSwitch.Name -NewName $newName
}


Write-Host "Virtual switch renamed successfully!" -ForegroundColor Green

Get-VMSwitch


