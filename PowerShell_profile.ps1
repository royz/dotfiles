oh-my-posh init pwsh --config "$HOME\royz-posh-theme.json" | Invoke-Expression
# oh-my-posh init pwsh --config "$HOME\amro.omp.json" | Invoke-Expression

Import-Module -Name Terminal-Icons
Import-Module -Name z

# Enable prediction
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows

# print github access token from env var
function gh-pat {
    echo $env:GITHUB_PAT
}

# generate secret of given length. default length is 32
function secret($length = 32) {
    $bytes = [math]::Ceiling($length * 3 / 4) # Adjust for Base64 encoding overhead
    openssl rand -base64 $bytes | ForEach-Object { $_.Substring(0, $length) }
}

function which($binName){
    $cmd = Get-Command $binName -ErrorAction SilentlyContinue
    if ($cmd) {
        $cmd.Source
    } else {
        Write-Error "which: no $binName in PATH"
    }
}

# search history with substring
function prev($search) {
    Get-Content (Get-PSReadlineOption).HistorySavePath | ? { $_ -like "*$search*" }
}

# Initialize TypeScript project
function ts-init {
  pnpm init
  pnpm add -D typescript @types/node tsx tsdown

  # Create a basic tsconfig.json
  $tsconfig = @{
    "compilerOptions" = @{
      "target" = "ESNext"
      "module" = "ESNext"
      "moduleResolution" = "bundler"
      "strict" = $true
      "esModuleInterop" = $true
      "skipLibCheck" = $true
      "forceConsistentCasingInFileNames" = $true
      "types" = @("node")
    }
  }
  $tsconfigPath = Join-Path (Get-Location) "tsconfig.json"
  $tsconfig | ConvertTo-Json -Depth 10 | Out-File -FilePath $tsconfigPath -Encoding UTF8

  # Create src/index.ts
  New-Item -ItemType Directory -Name src | Out-Null
  "console.log('Hello, World!')" | Out-File -FilePath (Join-Path (Get-Location) "src\index.ts") -Encoding UTF8

  # Create tsdown.config.ts
  @"
import { defineConfig } from 'tsdown'

export default defineConfig({
  entry: ['src/index.ts'],
  clean: true,
})
"@ | Out-File -FilePath (Join-Path (Get-Location) "tsdown.config.ts") -Encoding UTF8

  # Update package.json: set type=module and add scripts
  $pkgJsonPath = Join-Path (Get-Location) "package.json"
  $pkgJson = Get-Content $pkgJsonPath -Raw | ConvertFrom-Json
  $pkgJson | Add-Member -MemberType NoteProperty -Name "type" -Value "module" -Force
  if (-not $pkgJson.PSObject.Properties['scripts']) {
    $pkgJson | Add-Member -MemberType NoteProperty -Name "scripts" -Value ([PSCustomObject]@{}) -Force
  }
  # Remove pre-existing "test" script added by pnpm init
  if ($pkgJson.scripts.PSObject.Properties['test']) {
    $pkgJson.scripts.PSObject.Properties.Remove('test')
  }
  $pkgJson.scripts | Add-Member -MemberType NoteProperty -Name "start" -Value "tsx src/index.ts" -Force
  $pkgJson.scripts | Add-Member -MemberType NoteProperty -Name "dev"   -Value "tsx watch src/index.ts" -Force
  $pkgJson.scripts | Add-Member -MemberType NoteProperty -Name "build" -Value "tsdown" -Force
  $pkgJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $pkgJsonPath -Encoding UTF8

  Write-Host "TypeScript project initialized." -ForegroundColor Green
}

function watch ($file) {
  $ext = [System.IO.Path]::GetExtension($file)

  if ($ext -eq ".py") {
    uvx --from watchdog watchmedo shell-command --patterns="*.py" --recursive --command="uv run $file" .
  } elseif ($ext -eq ".ts") {
    npx tsx watch $file
  } else {
    Write-Error "Unsupported file extension: $ext"
  }
}

function crm {
  Set-Location C:\Users\Rajorshi\projects\perforia\perforia-crm
  code .
  Start-Process "http://localhost:3000"
  pnpm run dev
}

function sudo-ps($scriptPath) {
  sudo powershell -ExecutionPolicy Bypass -File $scriptPath
}

function new-vm($name) {
  sudo powershell -ExecutionPolicy Bypass -File "C:\Users\Rajorshi\projects\personal\scripts\powershell\create-hyper-v-vm-from-vhdx.ps1" -VMName $name
}

function install-mantine {
  pnpm add @mantine/core @mantine/hooks @mantine/form @mantine/dates dayjs @mantine/charts recharts @mantine/notifications @mantine/carousel embla-carousel@^8.5.2 embla-carousel-react@^8.5.2 @mantine/modals @mantine/nprogress
  pnpm add -D postcss postcss-preset-mantine postcss-simple-vars

  $postCssConfig = @"
  module.exports = {
    plugins: {
      'postcss-preset-mantine': {},
      'postcss-simple-vars': {
        variables: {
          'mantine-breakpoint-xs': '36em',
          'mantine-breakpoint-sm': '48em',
          'mantine-breakpoint-md': '62em',
          'mantine-breakpoint-lg': '75em',
          'mantine-breakpoint-xl': '88em',
        },
      },
    },
  };
"@

  $postCssConfigPath = Join-Path (Get-Location) "postcss.config.cjs"
  $postCssConfig | Out-File -FilePath $postCssConfigPath -Encoding UTF8

  $vscodeDir = Join-Path (Get-Location) ".vscode"
  if (-not (Test-Path $vscodeDir)) {
    New-Item -ItemType Directory -Path $vscodeDir | Out-Null
  }

  $extensionsJsonPath = Join-Path $vscodeDir "extensions.json"
  $newRecommendations = @("vunguyentuan.vscode-postcss", "vunguyentuan.vscode-css-variables")

  if (Test-Path $extensionsJsonPath) {
    $extensionsJson = Get-Content $extensionsJsonPath -Raw | ConvertFrom-Json
    if (-not $extensionsJson.recommendations) {
      $extensionsJson | Add-Member -MemberType NoteProperty -Name "recommendations" -Value @()
    }
    foreach ($rec in $newRecommendations) {
      if ($extensionsJson.recommendations -notcontains $rec) {
        $extensionsJson.recommendations += $rec
      }
    }
    $extensionsJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $extensionsJsonPath -Encoding UTF8
  } else {
    [PSCustomObject]@{ recommendations = $newRecommendations } | ConvertTo-Json -Depth 10 | Out-File -FilePath $extensionsJsonPath -Encoding UTF8
  }

  $settingsJsonPath = Join-Path $vscodeDir "settings.json"
  $cssLookupFiles = @("**/*.css", "**/*.scss", "**/*.sass", "**/*.less", "node_modules/@mantine/core/styles.css")

  if (Test-Path $settingsJsonPath) {
    $settingsJson = Get-Content $settingsJsonPath -Raw | ConvertFrom-Json
    $settingsJson | Add-Member -MemberType NoteProperty -Name "cssVariables.lookupFiles" -Value $cssLookupFiles -Force
    $settingsJson | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsJsonPath -Encoding UTF8
  } else {
    [PSCustomObject]@{ "cssVariables.lookupFiles" = $cssLookupFiles } | ConvertTo-Json -Depth 10 | Out-File -FilePath $settingsJsonPath -Encoding UTF8
  }
}

function winutil-update {
  cd C:\Users\Rajorshi\projects\personal\winutil
  git pull
  . .\Compile.ps1
}

function winutil {
  if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
      Start-Process pwsh -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"C:\Users\Rajorshi\projects\personal\winutil\windev.ps1`"" -Verb RunAs
  } else {
      . C:\Users\Rajorshi\projects\personal\winutil\windev.ps1
  }
}

# Install dependencies based on the package manager used in the current project
function i {
    # Check for package manager files in the current directory
    if (Test-Path "pnpm-lock.yaml") {
        pnpm install
    }
    elseif (Test-Path "yarn.lock") {
        yarn install
    }
    elseif (Test-Path "bun.lockb") {
        bun install
    }
    elseif (Test-Path "deno.json") {
        deno task install
    }
    elseif (Test-Path "package-lock.json") {
        npm install
    }
    else {
        Write-Host "No recognized package manager lock file found. Installing using pnpm..."
        pnpm install
    }
}

function reload {
    . $PROFILE
}

function activate {
    # Check for common virtual environment directory names
    $venvDirs = @('venv', 'env', '.venv', '.env', 'virtualenv')
        
    # Look for any existing virtual environment directory
    foreach ($dir in $venvDirs) {
        if (Test-Path -Path $dir -PathType Container) {
            # Check if the activation script exists
            if (Test-Path -Path "$dir\Scripts\activate.ps1") {
                Write-Host "Activating Python virtual environment in $dir"
                & "$dir\Scripts\activate.ps1"
                return
            }
        }
    }

    Write-Host "No Python virtual environment found in current directory" -ForegroundColor Yellow
}

# Chris Titus Tech windows utilities script
function ctt {
  sudo
  irm "https://christitus.com/win" | iex
}

function git-clone {
  param(
    [Parameter(Mandatory=$true)]
    [string]$repo,
    [string]$destination
  )

  if ($destination) {
    git clone "git@github.com:royz/$repo.git" $destination
  } else {
    git clone "git@github.com:royz/$repo.git"
  }
}

function wake-nas {
    param (
        [string]$MacAddress = "9C:6B:00:96:D3:CA",
        [string]$Broadcast = "192.168.0.255",  # Adjust if your network uses a different subnet
        [int]$Port = 9
    )

    # Convert MAC address string to byte array
    $macBytes = $MacAddress -split "[:-]" | ForEach-Object { [byte]("0x$_") }

    # Build the magic packet
    $packet = [byte[]](,0xFF * 6 + ($macBytes * 16))

    # Create UDP client and send the packet
    $udpClient = New-Object System.Net.Sockets.UdpClient
    $udpClient.Connect($Broadcast, $Port)
    $udpClient.Send($packet, $packet.Length) | Out-Null
    $udpClient.Close()

    Write-Host "Magic packet sent to ${MacAddress} via ${Broadcast}:${Port}"
}

function npnuke {
  npx npkill -D -y
}

function ConvertSonyLogToRec709 {
    param (
        [Parameter(Mandatory = $true)]
        [string]$SourceVideo
    )

    # ========= EDIT THESE IF NEEDED =========
    $DestinationFolder = "N:\wedding\color-corrected"
    $LutFolder = "E:\LUTs"
    # ======================================

    if (!(Test-Path $SourceVideo)) {
        Write-Error "Source video not found: $SourceVideo"
        return
    }

    if (!(Test-Path $DestinationFolder)) {
        New-Item -ItemType Directory -Path $DestinationFolder | Out-Null
    }

    # ------------------------------------------------
    # Detect transfer characteristics (LOG / HDR / SDR)
    # ------------------------------------------------
    $Transfer = ffprobe -v error -select_streams v:0 `
        -show_entries stream=color_transfer `
        -of default=noprint_wrappers=1:nokey=1 `
        "$SourceVideo"

    $Transfer = $Transfer.Trim().ToLower()
    Write-Host "`n🎥 Detected transfer: $Transfer"

    $UseLut = $true
    $HdrToneMap = $false

    if ($Transfer -in @("smpte2084", "arib-std-b67")) {
        # HDR PQ / HLG
        $UseLut = $false
        $HdrToneMap = $true
        Write-Host "🌈 HDR detected → skipping LUT, tone-mapping to Rec.709"
    }
    elseif ($Transfer -eq "bt709") {
        # Already SDR
        $UseLut = $false
        Write-Host "🎞 SDR detected → skipping LUT"
    }
    else {
        # LOG or unspecified (Sony LOG often shows empty)
        Write-Host "📉 LOG / flat footage detected → LUT will be applied"
    }

    # ------------------------------------------------
    # LUT selection (only if LOG)
    # ------------------------------------------------
    if ($UseLut) {
        $Luts = @(
            @{ Name = "LC-709 (Recommended – natural, wedding safe)"; File = "1_SGamut3CineSLog3_To_LC-709.cube" },
            @{ Name = "LC-709 Type A (Cinematic, Alexa-style)";      File = "2_SGamut3CineSLog3_To_LC-709TypeA.cube" },
            @{ Name = "Cine+709 (Punchy, higher contrast)";          File = "4_SGamut3CineSLog3_To_Cine+709.cube" }
        )

        Write-Host "`nSelect LUT to apply:" -ForegroundColor Cyan
        for ($i = 0; $i -lt $Luts.Count; $i++) {
            Write-Host "[$($i + 1)] $($Luts[$i].Name)"
        }

        $Choice = Read-Host "Enter number (1-$($Luts.Count))"
        if ($Choice -notmatch '^\d+$' -or $Choice -lt 1 -or $Choice -gt $Luts.Count) {
            Write-Error "Invalid selection."
            return
        }

        $SelectedLut = $Luts[$Choice - 1]
        $LutPath = Join-Path $LutFolder $SelectedLut.File

        if (!(Test-Path $LutPath)) {
            Write-Error "LUT not found: $LutPath"
            return
        }

        # FFmpeg-safe LUT path (Windows filter quirk)
        # E:\LUTs\file.cube → E\:/LUTs/file.cube
        $LutPathFFmpeg = ($LutPath -replace '\\', '/')
        $LutPathFFmpeg = $LutPathFFmpeg -replace '^([A-Za-z]):', '$1\:'

        Write-Host "🎨 LUT: $($SelectedLut.Name)"
    }

    # ------------------------------------------------
    # Build video filter chain
    # ------------------------------------------------
    if ($UseLut) {
        $VideoFilter = "scale=in_range=full:out_range=tv," +
                       "lut3d='$LutPathFFmpeg'," +
                       "scale=1920:1080:flags=lanczos," +
                       "fps=30000/1001"
    }
    elseif ($HdrToneMap) {
        $VideoFilter = "zscale=t=bt709:m=bt709:r=tv," +
                       "scale=1920:1080:flags=lanczos," +
                       "fps=30000/1001"
    }
    else {
        $VideoFilter = "scale=1920:1080:flags=lanczos," +
                       "fps=30000/1001"
    }

    # ------------------------------------------------
    # Output
    # ------------------------------------------------
    $FileName = [System.IO.Path]::GetFileNameWithoutExtension($SourceVideo)
    $OutputPath = Join-Path $DestinationFolder "$FileName`_rec709_1080p30.mp4"

    Write-Host "🎬 Converting..."

    ffmpeg -y -i "$SourceVideo" `
        -vf "$VideoFilter" `
        -c:v libx264 -profile:v high -level 4.2 -pix_fmt yuv420p `
        -crf 18 -preset slow `
        -color_range tv -colorspace bt709 -color_primaries bt709 -color_trc bt709 `
        -c:a aac -b:a 192k `
        "$OutputPath"

    if ($LASTEXITCODE -ne 0) {
        Write-Error "❌ FFmpeg failed."
        return
    }

    Write-Host "✅ Done:"
    Write-Host "   $OutputPath"
}

function Pin-Pnpm {
    Write-Host "🔍 Checking installed pnpm version..."
    $pnpmVersion = pnpm -v 2>$null

    if (-not $pnpmVersion) {
        Write-Error "❌ pnpm is not installed or not in PATH."
        return
    }

    Write-Host "✅ Detected pnpm version: $pnpmVersion"

    $pkgJsonPath = Join-Path -Path (Get-Location) -ChildPath "package.json"

    if (-not (Test-Path $pkgJsonPath)) {
        Write-Error "❌ package.json not found in the current directory."
        return
    }

    Write-Host "📄 Reading package.json..."
    try {
        $pkgJson = Get-Content $pkgJsonPath -Raw | ConvertFrom-Json
    } catch {
        Write-Error "❌ Failed to parse package.json. Make sure it is valid JSON."
        return
    }

    if ($pkgJson.packageManager) {
        Write-Host "ℹ️ Existing packageManager field found: $($pkgJson.packageManager)"
        Write-Host "🔄 Updating to pnpm@$pnpmVersion..."
    } else {
        Write-Host "ℹ️ No packageManager field found. Adding pnpm@$pnpmVersion..."
    }

    $pkgJson.packageManager = "pnpm@$pnpmVersion"

    try {
        $pkgJson | ConvertTo-Json -Depth 10 | Set-Content $pkgJsonPath -Encoding UTF8
        Write-Host "✅ Successfully pinned pnpm version $pnpmVersion to package.json"
    } catch {
        Write-Error "❌ Failed to write package.json. Check file permissions."
    }
}

# Set aliases
Set-Alias -Name pn -value pnpm
Set-Alias -Name pm -value pnpm
Set-Alias -Name grep -Value Select-String
Set-Alias -Name rc -Value rclone
Set-Alias -Name ag -Value antigravity