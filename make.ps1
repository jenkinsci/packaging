[CmdletBinding()]
Param(
    [Parameter(Position=1)]
    [String] $target = "package"
)

# TODO: Remove when MSI code signing certificate is available
echo "Not packaging Windows components until code signing certificate is available"
echo "Exiting make.ps1 early"
exit 0

# # refers to the definition of a release target
# BRAND:=./branding/test.mk
# include ${BRAND}

# # refers to the definition of the release process execution environment
# BUILDENV:=./env/test.mk
# include ${BUILDENV}

# # refers to whereabouts of code-signing keys
# CREDENTIAL:=./credentials/test.mk
# include ${CREDENTIAL}

# include ./setup.mk

# PACKAGE_BUILDER_VERSION:=0.1

# #######################################################

# clean:
# 	rm -rf ${TARGET}

$global:msiDone = $false
$global:chocolateyDone = $false

function Setup() {
    Get-ChildItem -Recurse -Include setup.ps1 -File | ForEach-Object {
        Push-Location (Split-Path -Parent $_)
        try {
            & $_
        } finally {
            Pop-Location
        }
    }
}
    
function New-Msi() {
    if(-not $global:msiDone) {
        Push-Location ./msi/build
        try {
            & ./build.ps1
            $global:msiDone = $true
        } finally {
            Pop-Location
        }
    }
}

function Publish-Msi() {
    New-Msi
    Push-Location ./msi/publish
    try {
        & ./publish.ps1
    } finally {
        Pop-Location
    }
}

function New-Chocolatey() {
    New-Msi
    if(-not $global:chocolateyDone) {
        Push-Location ./chocolatey/build
        try {
            & ./build.ps1
            $global:chocolateyDone = $true
        } finally {
            Pop-Location
        }
    }
}

function Publish-Chocolatey() {
    New-Chocolatey
    Push-Location ./chocolatey/publish
    try {
        & ./publish.ps1
    } finally {
        Pop-Location
    }
}

function Publish() {
    @(
        (Get-Item function:Publish-Msi)
    ) | ForEach-Object {
        & $_
    }
}

function New-Package() {
    @(
        (Get-Item function:New-Msi)
    ) | ForEach-Object {
        Write-Host $_.Name.Replace("New-", "") -BackgroundColor 'White' -ForegroundColor 'Black'
        & $_
        Write-Host "`n`n"
    }
}

Setup
switch -wildcard ($target) {
    # release targets
    "package"       { New-Package }
    "msi"           { New-Msi }
    "chocolatey"    { New-Chocolatey }
    "clean"         { Clean }

    default { Write-Error "No target '$target'" ; Exit -1 }
}
