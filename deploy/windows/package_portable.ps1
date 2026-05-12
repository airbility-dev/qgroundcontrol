#Requires -Version 5.1
<#
.SYNOPSIS
    QGroundControl Windows Portable Package Creator

.DESCRIPTION
    Linux AppImage 와 동일한 개념의 Windows 단일 실행 파일을 생성합니다.
    NSIS 기반: 실행하면 %TEMP%\QGroundControl 에 자동 압축 해제 후 바로 실행됩니다.
    설치 불필요, 단일 .exe 파일로 어디서든 실행 가능 (USB, 네트워크 드라이브 등).

.PARAMETER BuildDir
    QGroundControl 빌드 출력 디렉터리 (기본값: <repo>\build\Release)

.PARAMETER OutputDir
    패키지 출력 디렉터리 (기본값: <repo>\dist)

.PARAMETER QtDir
    Qt 설치 경로 (기본값: CMakeCache.txt 에서 자동 감지)

.PARAMETER SkipWinDeployQt
    windeployqt 실행 생략 (이미 실행된 경우)

.PARAMETER SkipStaging
    staging 디렉터리 재구성 생략 (이미 생성된 경우)

.EXAMPLE
    cd C:\Dev\qgc_v508\qgroundcontrol
    .\deploy\windows\package_portable.ps1

.EXAMPLE
    .\deploy\windows\package_portable.ps1 -SkipWinDeployQt -SkipStaging
#>

[CmdletBinding()]
param(
    [string]$BuildDir       = "",
    [string]$OutputDir      = "",
    [string]$QtDir          = "",
    [switch]$SkipWinDeployQt,
    [switch]$SkipStaging
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$ScriptDir = $PSScriptRoot
$RepoRoot  = (Resolve-Path (Join-Path $ScriptDir "..\..")).Path

if (-not $BuildDir)  { $BuildDir  = Join-Path $RepoRoot "build\Release" }
if (-not $OutputDir) { $OutputDir = Join-Path $RepoRoot "dist" }

$AppName        = "QGroundControl"
$VersionTag     = "v5.0.8"
$InstallDirName = "${AppName}_${VersionTag}"
$ExeName        = "$AppName.exe"
$StageDir       = Join-Path $OutputDir "staging"

function Write-Step { param([string]$Msg) Write-Host "`n==> $Msg" -ForegroundColor Cyan }
function Write-Ok   { param([string]$Msg) Write-Host "    [OK] $Msg" -ForegroundColor Green }
function Write-Warn { param([string]$Msg) Write-Host "    [!!] $Msg" -ForegroundColor Yellow }
function Write-Fail { param([string]$Msg) Write-Host "    [FAIL] $Msg" -ForegroundColor Red; exit 1 }

# ---------------------------------------------------------------------------
# 1. 사전 확인
# ---------------------------------------------------------------------------
Write-Step "Step 1/6: Pre-check"

if (-not (Test-Path (Join-Path $BuildDir $ExeName))) {
    Write-Fail "Build output not found: $BuildDir\$ExeName`nPlease build first."
}
Write-Ok "Build output: $BuildDir"

# ---------------------------------------------------------------------------
# 2. Qt / windeployqt 탐색
# ---------------------------------------------------------------------------
Write-Step "Step 2/6: Locate Qt"

if (-not $QtDir) {
    $CacheFile = Join-Path $RepoRoot "build\CMakeCache.txt"
    if (Test-Path $CacheFile) {
        $Line = Select-String -Path $CacheFile -Pattern "^Qt6_DIR:PATH=" | Select-Object -First 1
        if ($Line) {
            $QtCmakeDir = ($Line.Line -split "=", 2)[1].Trim()
            $QtDir = (Resolve-Path (Join-Path $QtCmakeDir "../../..")).Path
        }
    }
}

if (-not $QtDir) {
    $Candidates = @(
        "C:\Qt\6.8.3\msvc2022_64",
        "D:\Qt\6.8.3\msvc2022_64",
        "$env:USERPROFILE\Qt\6.8.3\msvc2022_64"
    )
    foreach ($C in $Candidates) { if (Test-Path $C) { $QtDir = $C; break } }
}

if (-not $QtDir) { Write-Fail "Qt not found. Use -QtDir to specify the path." }
Write-Ok "Qt: $QtDir"

$WinDeployQt = Join-Path $QtDir "bin\windeployqt.exe"
if (-not (Test-Path $WinDeployQt)) { Write-Fail "windeployqt.exe not found: $WinDeployQt" }
Write-Ok "windeployqt: $WinDeployQt"

# ---------------------------------------------------------------------------
# 3. 스테이징 디렉터리 구성
# ---------------------------------------------------------------------------
Write-Step "Step 3/6: Build staging directory"

if (-not $SkipStaging) {
    if (Test-Path $StageDir) { Remove-Item $StageDir -Recurse -Force }
    New-Item -ItemType Directory -Path $StageDir -Force | Out-Null

    Write-Ok "Copying Release directory (~500 MB)..."
    $RobocopyArgs = @(
        $BuildDir, $StageDir,
        "/E",
        "/XF", "*.pdb", "*.lib", "*.exp",
        "/NFL", "/NDL", "/NJH", "/NJS",
        "/MT:8"
    )
    & robocopy @RobocopyArgs | Out-Null
    if ($LASTEXITCODE -ge 8) { Write-Fail "robocopy failed (exit code: $LASTEXITCODE)" }
    Write-Ok "Copy complete"
} else {
    if (-not (Test-Path $StageDir)) { Write-Fail "Staging dir not found: $StageDir. Run without -SkipStaging first." }
    Write-Warn "Skipping staging (-SkipStaging)"
}

# ---------------------------------------------------------------------------
# 4. windeployqt
# ---------------------------------------------------------------------------
if (-not $SkipWinDeployQt) {
    Write-Step "Step 4/6: windeployqt (collect Qt DLLs + QML plugins)"
    $WinDeployArgs = @(
        "--release",
        "--qmldir", $RepoRoot,
        "--no-patchqt",
        "--no-translations",
        (Join-Path $StageDir $ExeName)
    )
    & $WinDeployQt @WinDeployArgs
    if ($LASTEXITCODE -ne 0) { Write-Fail "windeployqt failed" }
    Write-Ok "windeployqt complete"
} else {
    Write-Step "Step 4/6: windeployqt"
    Write-Warn "Skipping windeployqt (-SkipWinDeployQt)"
}

# ---------------------------------------------------------------------------
# 5. NSIS 확인 / 설치
# ---------------------------------------------------------------------------
Write-Step "Step 5/6: NSIS check"

function Find-NSIS {
    $Cmd = Get-Command "makensis.exe" -ErrorAction SilentlyContinue
    $Paths = @(
        "C:\Program Files\NSIS\makensis.exe",
        "C:\Program Files (x86)\NSIS\makensis.exe",
        "$env:LOCALAPPDATA\NSIS\makensis.exe",
        "$env:LOCALAPPDATA\NSIS\Bin\makensis.exe"
    )
    if ($Cmd) { $Paths += $Cmd.Source }
    foreach ($P in $Paths) { if ($P -and (Test-Path $P)) { return $P } }
    return $null
}

$MakeNsis = Find-NSIS

if (-not $MakeNsis) {
    Write-Host "    NSIS not found. Downloading and extracting portable NSIS..."
    $NsisTmp = Join-Path $env:TEMP "nsis-setup.exe"
    $NsisDir = Join-Path $env:LOCALAPPDATA "NSIS"
    New-Item -ItemType Directory -Path $NsisDir -Force | Out-Null

    # Download real NSIS installer (follow redirects)
    $Client = New-Object System.Net.WebClient
    $Client.Headers.Add("User-Agent", "Mozilla/5.0")
    $Client.DownloadFile("https://sourceforge.net/projects/nsis/files/NSIS%203/3.12/nsis-3.12-setup.exe/download", $NsisTmp)

    # Extract with 7-zip (no admin needed)
    $SevenZ = "C:\Program Files\7-Zip\7z.exe"
    if (-not (Test-Path $SevenZ)) { Write-Fail "7-zip not found. Install 7-zip first." }
    & $SevenZ x $NsisTmp -o"$NsisDir" -y | Out-Null
    Remove-Item $NsisTmp -Force -ErrorAction SilentlyContinue

    $MakeNsis = Find-NSIS
    if (-not $MakeNsis) { Write-Fail "NSIS extraction failed. Install NSIS from https://nsis.sourceforge.io/ and retry." }
    Write-Ok "NSIS extracted to: $NsisDir"
}
Write-Ok "NSIS makensis: $MakeNsis"

# ---------------------------------------------------------------------------
# 6. NSIS 포터블 스크립트 생성 및 빌드
# ---------------------------------------------------------------------------
Write-Step "Step 6/6: Build portable installer with NSIS"

New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null

$NsiScript = Join-Path $OutputDir "portable_installer.nsi"
$PortableExe = Join-Path $OutputDir "$AppName-portable.exe"

# NSIS 스크립트:
#   - 압축 방식: LZMA Solid (AppImage 수준 압축률)
#   - 설치 경로: %TEMP%\QGroundControl (쓰기 권한 항상 있음)
#   - UAC: 불필요 (시스템 쓰기 없음)
#   - 종료 시 임시 폴더 유지 (재실행 속도 향상)
$StageNative = $StageDir -replace "/", "\"
$PortableExeNative = $PortableExe -replace "/", "\"
$IconPath = Join-Path $ScriptDir "WindowsQGC.ico"
$HasIcon = Test-Path $IconPath

$IconLines = ""
if ($HasIcon) {
    $IconNative = $IconPath -replace "/", "\"
    $IconLines = "!define MUI_ICON `"$IconNative`"`r`n!define MUI_UNICON `"$IconNative`""
}


# 빌드 시각을 버전 스탬프로 사용 (재빌드 시 재압축 해제 트리거)
$BuildVer = Get-Date -Format 'yyyyMMddHHmmss'

$NsiContent = @"
Unicode true
SetCompressor /SOLID /FINAL lzma

Name "$AppName"
OutFile "$PortableExeNative"
RequestExecutionLevel user

; Show progress window during extraction
ShowInstDetails show

$IconLines

InstallDir "`$TEMP\$InstallDirName"

; Skip re-extraction if this build version is already extracted
Function .onInit
  IfFileExists "`$INSTDIR\$ExeName" 0 do_extract
  IfFileExists "`$INSTDIR\.__ver" 0 do_extract
  FileOpen `$R0 "`$INSTDIR\.__ver" r
  FileRead `$R0 `$R1
  FileClose `$R0
  StrCmp "`$R1" "$BuildVer" 0 do_extract
    ExecShell "" "`$INSTDIR\$ExeName"
    Abort
  do_extract:
FunctionEnd

Section
  SetDetailsPrint none
  SetOutPath "`$INSTDIR"
  File /r /x "$AppName.pdb" /x "$AppName.lib" /x "$AppName.exp" "$StageNative\*.*"
  FileOpen `$R0 "`$INSTDIR\.__ver" w
  FileWrite `$R0 "$BuildVer"
  FileClose `$R0
  ExecShell "" "`$INSTDIR\$ExeName"
SectionEnd
"@

[System.IO.File]::WriteAllText($NsiScript, $NsiContent, [System.Text.UTF8Encoding]::new($true))
Write-Ok "NSIS script: $NsiScript"

Write-Host "    Compiling NSIS installer (this takes a few minutes)..."
# Run makensis from its own directory so it resolves internal includes/plugins correctly
$NsisBinDir = Split-Path $MakeNsis
Push-Location $NsisBinDir
& $MakeNsis $NsiScript
$NsisExit = $LASTEXITCODE
Pop-Location
if ($NsisExit -ne 0) { Write-Fail "NSIS compilation failed (exit $NsisExit)" }

if (-not (Test-Path $PortableExe)) { Write-Fail "Output exe not found: $PortableExe" }

Remove-Item $NsiScript -Force -ErrorAction SilentlyContinue

$SizeMB = (Get-Item $PortableExe).Length / 1MB

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "  Portable package created!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "  File : $PortableExe"
Write-Host ("  Size : {0:F1} MB" -f $SizeMB)
Write-Host ""
Write-Host "  How to use:" -ForegroundColor Yellow
Write-Host "    1. Copy $AppName-portable.exe to any Windows PC"
Write-Host "    2. Double-click to run  (no installation required)"
Write-Host "       - Extracts silently to %TEMP%\$InstallDirName"
Write-Host "       - $ExeName starts automatically"
Write-Host ""
Write-Host "  Staging folder (uncompressed, also distributable as ZIP):"
Write-Host "    $StageDir"
Write-Host ""
