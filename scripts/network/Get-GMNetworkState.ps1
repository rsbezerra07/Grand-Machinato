Get-VMSwitch |
    Where-Object { $_.Name -like "GM-*" } |
    Sort-Object Name |
    Format-Table Name, SwitchType