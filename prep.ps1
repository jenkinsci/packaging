
Set-Location $PSScriptRoot

if(-not (Test-Path -Path $env:WAR)) {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    Remove-Item -Force -Path 'jv.exe','README.md','LICENSE','jenkins-version-windows-amd64.zip' | Out-Null
    $latestJson = (Invoke-WebRequest -Uri "https://api.github.com/repos/jenkins-infra/jenkins-version/releases/latest" -UseBasicParsing).Content | ConvertFrom-Json
    Invoke-WebRequest -Uri ("https://github.com/jenkins-infra/jenkins-version/releases/download/{0}/jenkins-version-windows-amd64.zip" -f $latestJson.name) -OutFile (Join-Path $PSScriptRoot "jenkins-version-windows-amd64.zip") -UseBasicParsing
    [System.IO.Compression.ZipFile]::ExtractToDirectory((Join-Path $PSScriptRoot 'jenkins-version-windows-amd64.zip'), $PSScriptRoot)
    & .\jv.exe download
    Remove-Item -Force -Path 'jv.exe','README.md','LICENSE','jenkins-version-windows-amd64.zip'
}