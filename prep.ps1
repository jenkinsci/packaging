
Set-Location $PSScriptRoot

if(-not (Test-Path -Path $env:WAR)) {
    $latestJson = (Invoke-WebRequest -Uri "https://api.github.com/repos/jenkins-infra/jenkins-version/releases/latest").Content | ConvertFrom-Json
    Invoke-WebRequest -Uri "https://github.com/jenkins-infra/jenkins-version/releases/download/${latestJson.name}/jenkins-version-windows-amd64.zip" -OutFile (Join-Path $PSScriptRoot "jenkins-version-windows-amd64.zip") -UseBasicParsing
    [IO.Compression.ZipFile]::ExtractToDirectory('jenkins-version-windows-amd64.zip', $PSScriptRoot)
    & .\jv.exe download
    Remove-Item -Force -Path 'jv.exe','README.md','LICENSE','jenkins-version-windows-amd64.zip'
}