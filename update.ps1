param(
  [string]$NotesFile = "CHANGELOG.md",
  [switch]$AllowDirty,
  [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"

function Write-Info {
  param([string]$Message)
  Write-Host $Message
}

Set-Location -Path (Split-Path -Parent $MyInvocation.MyCommand.Path)

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "git bulunamadi."
}

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
  throw "gh (GitHub CLI) bulunamadi."
}

if (-not $AllowDirty) {
  $dirty = git status --porcelain
  if ($dirty) {
    throw "Calisma dizininde commitlenmemis degisiklikler var. Devam etmek icin -AllowDirty kullan."
  }
}

$versionLine = Get-Content pubspec.yaml | Where-Object { $_ -match '^version:' } | Select-Object -First 1
if (-not $versionLine) {
  throw "pubspec.yaml icinde version bulunamadi."
}

$version = ($versionLine -replace '^version:\s*', '').Trim()
if (-not $version) {
  throw "Version bilgisi bos."
}

$tag = "v$version"

if (-not $SkipBuild) {
  Write-Info "Release APK build basliyor..."
  flutter build apk --release
}

$apkPath = "build\app\outputs\flutter-apk\app-release.apk"
if (-not (Test-Path $apkPath)) {
  throw "APK bulunamadi: $apkPath"
}

$notes = ""
if (Test-Path $NotesFile) {
  $notes = Get-Content $NotesFile -Raw
} else {
  $notes = (git log -n 10 --pretty=format:"- %s") -join "`n"
}

if (-not $notes.Trim()) {
  $notes = "Release $tag"
}

$existingTag = git tag -l $tag
if (-not $existingTag) {
  git tag -a $tag -m "Release $tag"
}

git push origin $tag

$tmpNotes = Join-Path $env:TEMP "release-notes-$tag.md"
Set-Content -Path $tmpNotes -Value $notes

$releaseExists = $true
try {
  gh release view $tag --repo ConquerorX/versus | Out-Null
} catch {
  $releaseExists = $false
}

if ($releaseExists) {
  gh release edit $tag --repo ConquerorX/versus --notes-file $tmpNotes
  gh release upload $tag $apkPath --repo ConquerorX/versus --clobber
} else {
  gh release create $tag $apkPath --repo ConquerorX/versus --title "Release $tag" --notes-file $tmpNotes
}

Remove-Item -Force $tmpNotes

Write-Info "Release tamamlandi: $tag"
