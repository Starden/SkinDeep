# Copies the addon (Lua, TOC, Media, LICENSE) into a WoW AddOns folder for
# local testing. Development files (tools, tests, docs) are left out, like in
# a release zip.
#
#   powershell -ExecutionPolicy Bypass -File tools\install.ps1
#   powershell -ExecutionPolicy Bypass -File tools\install.ps1 -AddOns "E:\Games\WoW\_forever_\Interface\AddOns"
param(
    [string]$AddOns = "D:\World of Warcraft\_forever_\Interface\AddOns"
)
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
if (-not (Test-Path $AddOns)) { throw "AddOns folder not found: $AddOns" }
$dest = Join-Path $AddOns "SkinDeep"
New-Item -ItemType Directory -Force $dest | Out-Null

Copy-Item (Join-Path $root "*.lua") $dest -Force
Copy-Item (Join-Path $root "LICENSE") $dest -Force
Copy-Item (Join-Path $root "Media") $dest -Recurse -Force

# The packager stamps the version on release; local copies say "dev".
$toc = Get-Content (Join-Path $root "SkinDeep.toc") -Raw
$toc = $toc.Replace("@project-version@", "dev")
[System.IO.File]::WriteAllText((Join-Path $dest "SkinDeep.toc"), $toc)

Write-Host "Installed SkinDeep to $dest. /reload in game to pick it up."
