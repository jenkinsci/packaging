[CmdletBinding()]
Param(
    [String] $War = $env:WAR,
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

if([String]::IsNullOrWhiteSpace($War)) {
    Write-Error "Missing jenkins WAR path"
    exit 1
}

$ErrorActionPreference = "Stop"

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Add-Type -Assembly System.IO.Compression.FileSystem

$tmpDir = Join-Path $PSScriptRoot "tmp"

if(!(Test-Path $tmpDir)) {
    New-Item -ItemType Directory -Path $tmpDir -Force -Confirm:$false | Out-Null
} else {
    Get-ChildItem tmp\* | Remove-Item -Force
}

if(!(Test-Path (Join-Path $PSScriptRoot 'msiext-1.5/WixExtensions/WixCommonUiExtension.dll'))) {
    Invoke-WebRequest -Uri "https://github.com/dblock/msiext/releases/download/1.5/msiext-1.5.zip" -OutFile (Join-Path $PSScriptRoot 'msiext-1.5.zip') -UseBasicParsing
    [IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $PSScriptRoot 'msiext-1.5.zip'), $PSScriptRoot)
}

Write-Host "Extracting components"
if($UseTracing) { Set-PSDebug -Trace 0 }
# get the components we need from the war file

$maniFestFile = Join-Path $tmpDir "MANIFEST.MF"
$zip = [IO.Compression.ZipFile]::OpenRead($env:WAR)
$zip.Entries | Where-Object {$_.Name -like 'MANIFEST.MF'} | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $maniFestFile, $true)}

$JenkinsVersion = $(Get-Content $maniFestFile | Select-String -Pattern "^Jenkins-Version:\s*(.*)" | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
Write-Host "JenkinsVersion = $JenkinsVersion"

$zip.Entries | Where-Object {$_.Name -like "jenkins-core-${JenkinsVersion}.jar"} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($tmpDir, "core.jar"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($tmpDir, 'core.jar'))
$zip.Entries | Where-Object {$_.Name -like 'jenkins.exe'} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($tmpDir, "jenkins.exe"), $true)}
$zip.Dispose()

$zip = [IO.Compression.ZipFile]::OpenRead([System.IO.Path]::Combine($tmpDir, 'core.jar'))
$zip.Entries | Where-Object {$_.Name -like 'jenkins.xml'} | ForEach-Object {[System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, [System.IO.Path]::Combine($tmpDir, "jenkins.xml"), $true)}
$zip.Dispose()
if($UseTracing) { Set-PSDebug -Trace 1 }

$isLts = $JenkinsVersion.Split('.').Length -gt 2

Write-Host "Restoring packages before build"
# restore the Wix package
& "./nuget.exe" restore -PackagesDirectory "packages"

Write-Host "Building MSI"
if($MSBuildPath -ne '') {
    if($MSBuildPath.ToLower().EndsWith('msbuild.exe')) {
        $MSBuildPath = [System.IO.Path]::GetDirectoryName($MSBuildPath)
    }
    $env:PATH = $env:PATH + ";" + $MSBuildPath
}

msbuild "jenkins.wixproj" /p:Stable="${isLts}" /p:WAR="${War}" /p:Configuration=Release /p:DisplayVersion=$JenkinsVersion /p:ProductName="${ProductName}" /p:ProductSummary="${ProductSummary}" /p:ProductVendor="${ProductVendor}" /p:ArtifactName="${ArtifactName}" /p:BannerBmp="${BannerBmp}" /p:DialogBmp="${DialogBmp}" /p:InstallerIco="${InstallerIco}"

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
    $env:MSI_SHA256 = $sha256
}

if ($UseTracing) { Set-PSDebug -Trace 0 }
