# Copies the addon (Lua, TOC, Media, LICENSE) into a WoW AddOns folder for
# local testing. Development files (tools, tests, docs) are left out, like in
# a release zip. Files in the installed copy that the repo no longer has (a
# removed texture, a renamed Lua file) are deleted, so the copy matches the
# repo exactly.
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

# Everything the install is meant to hold, as paths relative to the addon.
function Rel($base, $path) { $path.Substring($base.Length).TrimStart('\', '/').ToLowerInvariant() }
$keep = @{}
Get-ChildItem (Join-Path $root "*.lua") -File | ForEach-Object { $keep[$_.Name.ToLowerInvariant()] = $true }
$keep["license"] = $true
$keep["skindeep.toc"] = $true
Get-ChildItem (Join-Path $root "Media") -Recurse -File | ForEach-Object { $keep[(Rel $root $_.FullName)] = $true }

# Delete what the repo no longer has, then any folders left empty.
$removed = 0
Get-ChildItem $dest -Recurse -File | ForEach-Object {
    $rel = Rel $dest $_.FullName
    if (-not $keep.ContainsKey($rel)) {
        Remove-Item -LiteralPath $_.FullName -Force
        Write-Host "Removed $rel (not in the repo)"
        $removed++
    }
}
Get-ChildItem $dest -Recurse -Directory | Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
    if (-not (Get-ChildItem -LiteralPath $_.FullName -Force)) { Remove-Item -LiteralPath $_.FullName -Force }
}

Write-Host "Installed SkinDeep to $dest ($removed old files removed). /reload in game to pick it up."
