<#
Builds the Moon Sweepers BepInEx pack from public source: Il2CppInterop (branch v108) goes into a local NuGet feed,
BepInEx (branch moonsweepers-pack) builds against it with its normal build, and the win-x64 IL2CPP distribution, which
takes doorstop, dobby and the .NET runtime from their official releases, is laid out as a Thunderstore package.

Needs Windows, git and a .NET SDK that builds net8.0. Run from anywhere; everything happens under -WorkDir. To build from
your own forks, pass -Owner with your GitHub account; the pack's website link and README follow it.
#>
param(
    [Parameter(Mandatory)][string]$WorkDir,
    [string]$PackVersion = '0.1.0',
    [string]$Owner = 'Andrew1431',
    [string]$BepInExSource = "https://github.com/$Owner/BepInEx.git",
    [string]$BepInExBranch = 'moonsweepers-pack',
    [string]$Il2CppInteropSource = "https://github.com/$Owner/Il2CppInterop.git",
    [string]$Il2CppInteropBranch = 'v108'
)
$ErrorActionPreference = 'Stop'
$suffix = 'moonsweepers.1'

function Run($exe) {
    & $exe @args
    if ($LASTEXITCODE -ne 0) { throw "$exe $args failed with exit code $LASTEXITCODE" }
}

New-Item -ItemType Directory -Force $WorkDir | Out-Null
$WorkDir = (Resolve-Path $WorkDir).Path
$interop = Join-Path $WorkDir 'Il2CppInterop'
$bepinex = Join-Path $WorkDir 'BepInEx'
$feed = Join-Path $WorkDir 'feed'
foreach ($dir in $interop, $bepinex, $feed) { if (Test-Path $dir) { Remove-Item $dir -Recurse -Force } }
New-Item -ItemType Directory $feed | Out-Null

Run git clone --quiet --branch $Il2CppInteropBranch $Il2CppInteropSource $interop
Run git clone --quiet --branch $BepInExBranch $BepInExSource $bepinex

# Il2CppInterop's global.json pins SDK 8; any SDK that builds its targets will do here.
Remove-Item (Join-Path $interop 'global.json') -Force
foreach ($project in 'Il2CppInterop.Common', 'Il2CppInterop.Generator', 'Il2CppInterop.Runtime', 'Il2CppInterop.HarmonySupport') {
    Run dotnet build (Join-Path $interop "$project\$project.csproj") -c Release "-p:VersionSuffix=$suffix" '-p:NoWarn=CS1591' '-clp:ErrorsOnly' -nologo
}
Get-ChildItem (Join-Path $interop 'bin\NuGet') -Filter '*.nupkg' | Copy-Item -Destination $feed

Push-Location $bepinex
try {
    Run dotnet nuget add source $feed --name moonsweepers-local --configfile nuget.config
    # BepInEx's build tool targets net8.0; let it run on a newer runtime if that's what is installed.
    $env:DOTNET_ROLL_FORWARD = 'Major'
    Run dotnet run --project build/Build.csproj -- --target MakeDist
}
finally {
    Remove-Item Env:DOTNET_ROLL_FORWARD -ErrorAction SilentlyContinue
    Pop-Location
}

$dist = Join-Path $bepinex 'bin\dist\Unity.IL2CPP-win-x64'
$package = Join-Path $WorkDir 'package'
if (Test-Path $package) { Remove-Item $package -Recurse -Force }
New-Item -ItemType Directory $package | Out-Null
Copy-Item $dist (Join-Path $package 'BepInExPack') -Recurse

$licenses = Join-Path $package 'licenses'
New-Item -ItemType Directory $licenses | Out-Null
Copy-Item (Join-Path $bepinex 'LICENSE') (Join-Path $licenses 'BepInEx-LICENSE.txt')
Copy-Item (Join-Path $interop 'LICENSE') (Join-Path $licenses 'Il2CppInterop-LICENSE.txt')

$manifest = [ordered]@{
    name           = 'BepInExPack_MoonSweepers'
    version_number = $PackVersion
    website_url    = "https://github.com/$Owner/BepInEx/tree/$BepInExBranch"
    description    = 'Unofficial BepInEx 6 IL2CPP pack for Moon Sweepers (Unity 6000.6, metadata v108). Built from public forks until upstream supports the game.'
    dependencies   = @()
}
[IO.File]::WriteAllText((Join-Path $package 'manifest.json'), ($manifest | ConvertTo-Json), (New-Object Text.UTF8Encoding $false))
$readme = [IO.File]::ReadAllText((Join-Path $bepinex 'MOONSWEEPERS-PACK.md')).Replace('Andrew1431', $Owner)
[IO.File]::WriteAllText((Join-Path $package 'README.md'), $readme, (New-Object Text.UTF8Encoding $false))

Add-Type -AssemblyName System.Drawing
$icon = New-Object Drawing.Bitmap 256, 256
$canvas = [Drawing.Graphics]::FromImage($icon)
$canvas.SmoothingMode = 'AntiAlias'
$canvas.Clear([Drawing.Color]::FromArgb(21, 24, 28))
$moon = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(205, 204, 196))
$crater = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(160, 160, 152))
$canvas.FillEllipse($moon, 38, 38, 180, 180)
$canvas.FillEllipse($crater, 80, 76, 44, 44)
$canvas.FillEllipse($crater, 146, 128, 30, 30)
$canvas.FillEllipse($crater, 92, 158, 22, 22)
$icon.Save((Join-Path $package 'icon.png'), [Drawing.Imaging.ImageFormat]::Png)
$moon.Dispose(); $crater.Dispose(); $canvas.Dispose(); $icon.Dispose()

$zip = Join-Path $WorkDir "BepInExPack_MoonSweepers-$PackVersion.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory($package, $zip)
"Built $zip"
