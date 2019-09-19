[CmdletBinding()]
Param(
    [String] $War = $env:WAR,
    [String] $SHA256Hash = $env:MSI_SHA256
)

if([String]::IsNullOrWhiteSpace($War)) {
    Write-Error "Missing jenkins WAR path"
    exit 1
}

if([String]::IsNullOrWhiteSpace($SHA256Hash)) {
    Write-Error "Missing MSI SHA256"
    exit 1
}

if(Test-Path "bin") {
    Remove-Item -Recurse -Force "bin"
}

Add-Type -Assembly System.IO.Compression.FileSystem

$tmpDir = Join-Path $PSScriptRoot "tmp"
mkdir -Force -Confirm:$false $tmpDir | Out-Null

$maniFestFile = Join-Path $tmpDir "MANIFEST.MF"
$zip = [IO.Compression.ZipFile]::OpenRead($env:WAR)
$zip.Entries | Where-Object {$_.Name -like 'MANIFEST.MF'} | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $maniFestFile, $true)}

$JenkinsVersion = $(Get-Content $maniFestFile | Select-String -Pattern "^Jenkins-Version:\s*(.*)" | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
Write-Host "JenkinsVersion = $JenkinsVersion"

$zip.Dispose()

$isLts = $JenkinsVersion.Split('.').Length -gt 2

$helperOutputFile = (Join-Path $PSScriptRoot (Join-Path "tools" "helpers.ps1"))
if (Test-Path $helperOutputFile) {
    Remove-Item -Force $helperOutputFile
}

$verificationOutputFile = (Join-Path $PSScriptRoot (Join-Path "legal" "VERIFICATION.txt"))
if (Test-Path $verificationOutputFile) {
    Remove-Item -Force $verificationOutputFile
}

$suffix = @("", "-stable")[$isLts]
$changelog = "changelog${suffix}"
$msiLoc = "windows${suffix}"
$releaseType = @("Weekly", "LTS")[$isLts]

$helpersFile = Get-Content (Join-Path $PSScriptRoot (Join-Path "templates" "helpers.ps1.in"))
$helpersFile = $helpersFile -replace "%MSI_LOC%", $msiLoc
$helpersFile = $helpersFile -replace "%CHECKSUM%", $SHA256Hash
Set-Content -Path $helperOutputFile -Value $helpersFile -Encoding Ascii

$verificationFile = Get-Content (Join-Path $PSScriptRoot (Join-Path "templates" "VERIFICATION.txt.in"))
$verificationFile = $verificationFile -replace "%MSI_LOC%", $msiLoc
$verificationFile = $verificationFile -replace "%CHECKSUM%", $SHA256Hash
$verificationFile = $verificationFile -replace "%VERSION%", $JenkinsVersion
Set-Content -Path $verificationOutputFile -Value $verificationFile -Encoding Ascii

if($null -eq (Get-Command choco.exe)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

mkdir -Confirm:$false bin | Out-Null
& choco pack --version="$JenkinsVersion" id="jenkins${suffix}" changelog="$changelog" releaseType="$releaseType" --out="bin"
