$EnvFile = Join-Path $PSScriptRoot "..\..\.env"

if (-not (Test-Path $EnvFile)) {
    throw ".env not found: $EnvFile"
}

Get-Content $EnvFile | ForEach-Object {
    $Line = $_.Trim()

    if (-not $Line -or $Line.StartsWith("#")) {
        return
    }

    $Name, $Value = $Line -split "=", 2

    if ($Name -and $Value) {
        Set-Item `
            -Path "Env:$($Name.Trim())" `
            -Value $Value.Trim()
    }
}