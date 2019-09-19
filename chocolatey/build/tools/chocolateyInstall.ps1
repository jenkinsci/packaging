$toolsDir = Split-Path -parent $MyInvocation.MyCommand.Definition
. "$toolsDir\helpers.ps1"

$pp = Get-PackageParameters

$arguments = @{
    packageName = $env:chocolateyPackageName
    file        = "$toolsDir\jenkins.msi"
    port        = if ($pp.Port) { $pp.Port } else { 8080 }
    serviceName = "Jenkins"
    destination = ""
    toolsDir    = $toolsDir
}

if (-not (Assert-TcpPortIsOpen $arguments.port)) {
    throw 'Please specify a different port number...'
}

Install-Jenkins $arguments
