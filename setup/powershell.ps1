# Bootstrap: when piped via "irm ... | iex", MyCommand.Path is empty.
# Clone or update the repo, then re-run the real script from disk.
if (-not $MyInvocation.MyCommand.Path) {
    $repoUrl = "https://github.com/royz/dotfiles.git"
    $repoDir = Join-Path $HOME "dotfiles"

    if (Test-Path (Join-Path $repoDir ".git")) {
        Write-Host "Updating dotfiles repo..."
        git -C $repoDir pull
    } else {
        Write-Host "Cloning dotfiles repo..."
        git clone $repoUrl $repoDir
    }

    & (Join-Path $repoDir "setup\powershell.ps1")
} else {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $dotfilesProfile = Join-Path $scriptDir "..\PowerShell_profile.ps1"
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
}
