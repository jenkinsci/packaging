Get-Content .\$env:BRAND | Select-String -Pattern "^export"| ForEach-Object {
    $array= $_[0].ToString().split("=")
    [System.Environment]::SetEnvironmentVariable($array[0].Replace("export ",""), $array[1])
}

Get-Content .\$env:BUILDENV | Select-String -Pattern "^export"| ForEach-Object {
    $array= $_[0].ToString().split("=")
    [System.Environment]::SetEnvironmentVariable($array[0].Replace("export ",""), $array[1])
}

# I couldn't find how interpolate MSIDIR="/packages/binary/windows$($env:RELEASELINE)"
Set-Variable -Name MSIDIR -Value "$env:MSIDIR$env:RELEASELINE"

Write-Host "Copying binaries to $MSIDIR"

if(!(Test-Path $MSIDIR)) {
  New-Item -ItemType Directory -Path $MSIDIR
}

Get-ChildItem -Path '.\msi\build\bin\Release\en-US\*' -File -Include *.msi,*.msi.sha256 | Copy-Item -Destination $MSIDIR

Get-ChildItem -Path $MSIDIR
