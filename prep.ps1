
Set-Location $PSScriptRoot

$PSVersionTable

if(-not (Test-Path -Path $env:WAR)) {
    curl -LO "https://github.com/jenkins-infra/jenkins-version/releases/download/latest/jenkins-version-windows-amd64.zip"
    [IO.Compression.ZipFile]::ExtractToDirectory('jenkins-version-windows-amd64.zip', $PSScriptRoot)
    & .\jv.exe download
    Remove-Item -Force -Path 'jv.exe','README.md','LICENSE','jenkins-version-windows-amd64.zip'
}