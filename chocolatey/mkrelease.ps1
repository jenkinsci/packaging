#!/usr/bin/pwsh
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String] $JenkinsVersion,
    [String] $SHA256Hash=''
)

$isLts = $JenkinsVersion.Split('.').Length -gt 2

if(Test-Path bin) {
    Remove-Item -Recurse -Force bin
}

$currDir = Split-Path -parent $MyInvocation.MyCommand.Definition

$helperOutputFile = (Join-Path $currDir (Join-Path "tools" "helpers.ps1"))
if (Test-Path $helperOutputFile) {
    Remove-Item -Force $helperOutputFile
}

$verificationOutputFile = (Join-Path $currDir (Join-Path "legal" "VERIFICATION.txt"))
if (Test-Path $verificationOutputFile) {
    Remove-Item -Force $verificationOutputFile
}

$suffix = @("", "-stable")[$isLts]
$changelog = "changelog${suffix}"
$zipLoc = "windows${suffix}"
$releaseType = @("Weekly", "LTS")[$isLts]

if($JenkinsVersion -eq "") {
    Write-Error "Missing version parameter!"
}

if($SHA256Hash -eq "") {
    $shaUrl = "http://mirrors.jenkins-ci.org/$($zipLoc)/jenkins-$($JenkinsVersion).msi.sha256"
    $shaFile = [System.IO.Path]::GetTempFileName()
    Invoke-WebRequest -Uri $shaUrl -OutFile $shaFile
    $shaContents = (Get-Content $shaFile)
    $SHA256Hash = ($shaContents -split "\s+")[0]
}

$helpersFile = Get-Content (Join-Path $currDir (Join-Path "templates" "helpers.ps1.in"))
$helpersFile = $helpersFile -replace "%ZIP_LOC%", $zipLoc
$helpersFile = $helpersFile -replace "%CHECKSUM%", $SHA256Hash
Set-Content -Path $helperOutputFile -Value $helpersFile -Encoding Ascii

$verificationFile = Get-Content (Join-Path $currDir (Join-Path "templates" "VERIFICATION.txt.in"))
$verificationFile = $verificationFile -replace "%ZIP_LOC%", $zipLoc
$verificationFile = $verificationFile -replace "%CHECKSUM%", $SHA256Hash
$verificationFile = $verificationFile -replace "%VERSION%", $JenkinsVersion
Set-Content -Path $verificationOutputFile -Value $verificationFile -Encoding Ascii

if($null -eq (Get-Command choco.exe)) {
    Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
}

mkdir -Confirm:$false bin | Out-Null
& choco pack --version="$JenkinsVersion" id="jenkins${suffix}" changelog="$changelog" releaseType="$releaseType" --out="bin"
