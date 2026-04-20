$dotfilesProfile = Join-Path $PSScriptRoot "..\PowerShell_profile.ps1"
$dotfilesProfile = [System.IO.Path]::GetFullPath($dotfilesProfile)

$profilePaths = @(
    "$HOME\Documents\PowerShell\Microsoft.PowerShell_profile.ps1",
    "$HOME\Documents\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
)

foreach ($profilePath in $profilePaths) {
    $dir = Split-Path $profilePath
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $content = "`$PROFILE = `"$dotfilesProfile`"`n. `$PROFILE"
    Set-Content -Path $profilePath -Value $content -Encoding UTF8
}
