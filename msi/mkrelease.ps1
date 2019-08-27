[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [String] $JenkinsVersion,
    [string] $MSBuildPath = '',
    [bool] $UseTracing = $false,
    [String] $ProductName = '',
    [String] $ProductSummary = '',
    [String] $ProductVendor = '',
    [String] $ArtifactName = '',
    [String] $BannerBmp = '',
    [String] $DialogBmp = '',
    [String] $InstallerIco = ''
)

if($UseTracing) { Set-PSDebug -Trace 1 }

$ErrorActionPreference = "Stop"

Function Get-Jenkins([String] $JenkinsVersion, [String] $outputPath='.') {
    $isLts = $JenkinsVersion.Split('.').Length -gt 2

    $warUrl = "http://mirrors.jenkins.io/war/${JenkinsVersion}/jenkins.war"
    $warSha256Url = "http://mirrors.jenkins.io/war/${JenkinsVersion}/jenkins.war.sha256"

    if($isLts) {
        $warUrl = "http://mirrors.jenkins.io/war-stable/${JenkinsVersion}/jenkins.war"
        $warSha256Url = "http://mirrors.jenkins.io/war-stable/${JenkinsVersion}/jenkins.war.sha256"
    }

    $localWar = (Join-Path $outputPath 'jenkins.war')
    $localSha256 = (Join-Path $outputPath 'jenkins.war.sha256')

    Invoke-WebRequest -Uri $warSha256Url -OutFile $localSha256
    $specifiedHash = (Get-Content $localSha256 | %{ $_.Split(' ')[0]; }).ToLower()

    if(Test-Path $localWar) {
        $computedHash = (Get-FileHash -Algorithm SHA256 -Path $localWar).Hash.ToString().ToLower()
        if($specifiedHash -ne $computedHash) {
            Write-Host "Existing WAR file does not match required SHA hash"
            Remove-Item -Force $localWar
        }
    }

    if(-not (Test-Path $localWar)) {
        Invoke-WebRequest -Uri $warUrl -OutFile $localWar
        $computedHash = (Get-FileHash -Algorithm SHA256 -Path $localWar).Hash.ToString().ToLower()
    }

    if($computedHash -ne $specifiedHash) {
        Write-Error 'Hashes for jenkins.war does not match!'
        exit 1
    }
}

Add-Type -Assembly System.IO.Compression.FileSystem

if(!(Test-Path tmp)) {
    New-Item -ItemType Directory -Path tmp -Force -Confirm:$false | Out-Null
} else {
    Get-ChildItem tmp\* -Exclude jenkins.war | Remove-Item -Force
}

if(!(Test-Path './msiext-1.5/WixExtensions/WixCommonUiExtension.dll')) {
    Invoke-WebRequest -Uri "https://github.com/dblock/msiext/releases/download/1.5/msiext-1.5.zip" -OutFile (Join-Path $PSScriptRoot 'msiext-1.5.zip') -UseBasicParsing
    [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $PSScriptRoot 'msiext-1.5.zip'), $PSScriptRoot)
}

$currDir = Split-Path -parent $MyInvocation.MyCommand.Definition

Write-Host "Retrieving Jenkins WAR file $JenkinsVersion"
Get-Jenkins $JenkinsVersion (Join-Path $currDir 'tmp')

Write-Host "Extracting components"
if($UseTracing) { Set-PSDebug -Trace 0 }
# get the components we need from the war file

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'jenkins.war'))
$zip.Entries | Where-Object {$_.Name -like "jenkins-core-${JenkinsVersion}.jar"} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "core.jar"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'core.jar'))
$zip.Entries | Where-Object {$_.Name -like 'jenkins.exe'} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "jenkins.exe"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($currDir, 'tmp', 'core.jar'))
$zip.Entries | Where-Object {$_.Name -like 'jenkins.xml'} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($currDir, "tmp", "jenkins.xml"), $true)}
$zip.Dispose()
if($UseTracing) { Set-PSDebug -Trace 1 }

Write-Host "Restoring packages before build"
# restore the Wix package
.\nuget restore -PackagesDirectory packages

Write-Host "Building MSI"
if($MSBuildPath -ne '') {
    if($MSBuildPath.ToLower().EndsWith('msbuild.exe')) {
        $MSBuildPath = [System.IO.Path]::GetDirectoryName($MSBuildPath)
    }
    $env:PATH = $env:PATH + ";" + $MSBuildPath
}

msbuild jenkins.wixproj /p:Configuration=Release /p:DisplayVersion=$JenkinsVersion /p:ProductName="${ProductName}" /p:ProductSummary="${ProductSummary}" /p:ProductVendor="${ProductVendor}" /p:ArtifactName="${ArtifactName}" /p:BannerBmp="${BannerBmp}" /p:DialogBmp="${DialogBmp}" /p:InstallerIco="${InstallerIco}"

Get-ChildItem .\bin\Release -Filter *.msi -Recurse |
    Foreach-Object {
        # sign the file
        if((Test-Path env:PKCS12_FILE) -and (Test-Path env:PKCS12_PASSWORD_FILE)) {
            Write-Host "Signing installer"
            # always diable tracing here
            Set-PSDebug -Trace 0
            signtool sign /v /f $env:PKCS12_FILE /p (Get-Content $env:PKCS12_PASSWORD_FILE) /t http://timestamp.verisign.com/scripts/timestamp.dll /d "Jenkins Automation Server ${JenkinsVersion}" /du "https://jenkins.io" $_.FullName
            if($UseTracing) { Set-PSDebug -Trace 1 }
        }

    $sha256 = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash.ToString().ToLower()
    Set-Content -Path "$($_.FullName).sha256" -Value "$sha256 $($_.Name)" -Force
}

if ($UseTracing) { Set-PSDebug -Trace 0 }
