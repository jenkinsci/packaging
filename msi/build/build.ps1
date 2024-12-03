[CmdletBinding()]
Param(
    [String] $War = $env:WAR,
    [string] $MSBuildPath = '',
    [bool] $UseTracing = $false,
    [String] $ProductName = $env:PRODUCTNAME,
    [String] $ProductSummary = $env:SUMMARY,
    [String] $ProductVendor = $env:VENDOR,
    [String] $ArtifactName = $env:ARTIFACTNAME,
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
$zip = [IO.Compression.ZipFile]::OpenRead($War)
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
} else {
    # try to find it with vswhere
    $MSBuildPath = & 'C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe' -products * -latest -requires Microsoft.Component.MSBuild -find MSBuild\**\Bin\MSBuild.exe
    if(($MSBuildPath -ne '') -and $MSBuildPath.ToLower().EndsWith('msbuild.exe')) {
        $MSBuildPath = [System.IO.Path]::GetDirectoryName($MSBuildPath)
    }
    $env:PATH = $env:PATH + ";" + $MSBuildPath
}

Copy-Item -Force -Path .\Update-JenkinsVersion.ps1 -Destination tmp
# Sign the Update-JenkinsVersion.ps1 script if we have PKCS files
if((-not ([System.String]::IsNullOrWhiteSpace($env:PKCS12_FILE)) -and (Test-Path $env:PKCS12_FILE)) -and (-not [System.String]::IsNullOrWhiteSpace($env:SIGN_STOREPASS))) {
    Write-Host "Signing Update-JenkinsVersion.ps1"
    # always disable tracing
    Set-PSDebug -Trace 0

    $retries = 10
    $i = $retries
    # Create an array of timestamp servers that includes each of the known timestamp servers duplicated $retries times so that the list won't be exhausted during retry
    # Start with digicert because we purchased the code signing certificate from digicert
    $timestampservers = "http://timestamp.digicert.com", "http://rfc3161timestamp.globalsign.com/advanced", "http://timestamp.sectigo.com/", "http://timestamp.verisign.com/scripts/timstamp.dll" * $retries
    for(; $i -gt 0; $i--) {
        $Error.Clear() # clear out errors
        # Pop first entry from timestamp server array, use it as timestamp server for this attempt
        $timestamp, $timestampservers = $timestampservers
        # Submit SHA256 digest to RFC 3161 timestamp server
        $store_password = ConvertTo-SecureString "${env:SIGN_STOREPASS}" -AsPlainText -Force
        $cert = Get-PfxCertificate -FilePath "${env:PKCS12_FILE}" -Password $store_password
        Set-AuthenticodeSignature -Certificate $cert -FilePath .\tmp\Update-JenkinsVersion.ps1 -TimestampServer $timestamp -HashAlgorithm SHA256 -ErrorAction SilentlyContinue
        if($Error.Count -eq 0) {
            break
        } else {
            Start-Sleep -Seconds 15
        }
    }
    
    if($i -le 0) {
        Write-Error "Set-AuthenticodeSignature did not complete successfully after $retries tries"
        exit -1
    }

    if($UseTracing) { Set-PSDebug -Trace 1 }

    Write-Host "Checking the signature"
    $signature = Get-AuthenticodeSignature .\tmp\Update-JenkinsVersion.ps1
    if($signature.Status -ne 'Valid') {
        Write-Error "Signature is not valid for Update-JenkinsVersion.ps1!"
        exit -1
    }
}


msbuild "jenkins.wixproj" /p:Stable="${isLts}" /p:WAR="${War}" /p:Configuration=Release /p:DisplayVersion=$JenkinsVersion /p:ProductName="${ProductName}" /p:ProductSummary="${ProductSummary}" /p:ProductVendor="${ProductVendor}" /p:ArtifactName="${ArtifactName}" /p:BannerBmp="${BannerBmp}" /p:DialogBmp="${DialogBmp}" /p:InstallerIco="${InstallerIco}"

Get-ChildItem .\bin\Release -Filter *.msi -Recurse |
    Foreach-Object {
        if((-not ([System.String]::IsNullOrWhiteSpace($env:PKCS12_FILE)) -and (Test-Path $env:PKCS12_FILE)) -and (-not [System.String]::IsNullOrWhiteSpace($env:SIGN_STOREPASS))) {
            Write-Host "Signing installer: $($_.FullName)"
            # always disable tracing here
            Set-PSDebug -Trace 0
            $retries = 10
            $i = $retries
            # Create an array of timestamp servers that includes each of the known timestamp servers duplicated $retries times so that the list won't be exhausted during retry
            # Start with digicert because we purchased the code signing certificate from digicert
            $timestampservers = "http://timestamp.digicert.com", "http://rfc3161timestamp.globalsign.com/advanced", "http://timestamp.sectigo.com/", "http://timestamp.verisign.com/scripts/timstamp.dll" * $retries
            for(; $i -gt 0; $i--) {
                # Pop first entry from timestamp server array, use it as timestamp server for this attempt
                $timestamp, $timestampservers = $timestampservers
                # Submit SHA256 digest to RFC 3161 timestamp server
                $p = Start-Process -Wait -PassThru -NoNewWindow -FilePath "signtool.exe" -ArgumentList "sign /v /f `"${env:PKCS12_FILE}`" /p ${env:SIGN_STOREPASS} /tr $timestamp /td SHA256 /fd SHA256 /d `"Jenkins Automation Server ${JenkinsVersion}`" /du `"https://jenkins.io`" $($_.FullName)"
                $p.WaitForExit()
                # we will retry up to $retries times until we get a good exit code
                if($p.ExitCode -eq 0) {
                    break
                } else {
                    Start-Sleep -Seconds 15
                }
            }
            
            if($i -le 0) {
                Write-Error "signtool did not complete successfully after $retries tries"
                exit -1
            }
            
            if($UseTracing) { Set-PSDebug -Trace 1 }

            Write-Host "Checking the signature"
            # It will print the entire certificate chain with details
            signtool verify /v /pa /all $_.FullName
        }

    $sha256 = (Get-FileHash -Algorithm SHA256 -Path $_.FullName).Hash.ToString().ToLower()
    Set-Content -Path "$($_.FullName).sha256" -Value "$sha256 $($_.Name)" -Force
    $env:MSI_SHA256 = $sha256
}

if ($UseTracing) { Set-PSDebug -Trace 0 }
