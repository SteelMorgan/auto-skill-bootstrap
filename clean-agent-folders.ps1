param(
  [switch]$Apply,
  [switch]$AllowReparsePoints
)

$ErrorActionPreference = 'Stop'

# HARD-CODED ROOT (DO NOT CHANGE AT RUNTIME)
$Root = 'D:\My Projects\FrameWork Global\Test project'

function Is-ReparsePoint([string]$Path) {
  try {
    $item = Get-Item -LiteralPath $Path -Force -ErrorAction Stop
    return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
  } catch {
    return $false
  }
}

if (-not (Test-Path -LiteralPath $Root)) {
  throw "Root path not found: $Root"
}

$resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
if ($resolvedRoot.Length -lt 4) {
  throw "Refusing to run on suspicious root: $resolvedRoot"
}

$names = @('.agent', '.agents', '.claude', '.continue', '.gemini', '.kiro', '.opencode')
$targets = $names | ForEach-Object { Join-Path $resolvedRoot $_ }

Write-Host "Root (absolute): $resolvedRoot"
Write-Host "Mode: $(if ($Apply) { 'APPLY' } else { 'DRY-RUN' })"
Write-Host "Targets (absolute):"
$targets | ForEach-Object { Write-Host "  - $_" }
Write-Host ""

foreach ($dir in $targets) {
  if (-not (Test-Path -LiteralPath $dir)) {
    Write-Host "Skip (missing): $dir"
    continue
  }

  if ((Is-ReparsePoint $dir) -and -not $AllowReparsePoints) {
    Write-Host "Skip (reparse point): $dir  (use -AllowReparsePoints to override)"
    continue
  }

  $items = Get-ChildItem -LiteralPath $dir -Force -ErrorAction SilentlyContinue
  if (-not $items -or $items.Count -eq 0) {
    Write-Host "Empty: $dir"
    continue
  }

  Write-Host "Clean: $dir  (items: $($items.Count))"
  foreach ($it in $items) {
    Remove-Item -LiteralPath $it.FullName -Force -Recurse -ErrorAction Continue -WhatIf:(!$Apply)
  }
}

Write-Host ""
Write-Host "Done."
