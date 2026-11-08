<#
.SYNOPSIS
    Delete a VM Switch based on user selection.
#>

$vmswitches = @(Get-VMSwitch | Sort-Object Name)

if ($vmswitches.Count -eq 0) {
	Write-Host "No virtual switches found."
	exit
}

Write-Host "Select the vSwitch to delete:"
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
$confirmation = Read-Host "Delete '$($selectedSwitch.Name)'? (y/N)"
if ($confirmation -match '^(y|yes)$') {
	Remove-VMSwitch -Name $selectedSwitch.Name -Force
}





