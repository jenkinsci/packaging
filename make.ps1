[CmdletBinding()]
Param(
    [Parameter(Position=1)]
    [String] $target = "package"
)

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
    Push-Location ./msi/build
    try {
        & ./build.ps1
    } finally {
        Pop-Location
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

function Publish() {
    $publishers = @(
        (Get-Item function:Publish-Msi)
    )
        
    $publishers | ForEach-Object {
        & $_
    }
}

function New-Package() {
    $packagers = @(
        (Get-Item function:New-Msi)
    )
    $packagers | ForEach-Object {
        & $_
    }
}

switch -wildcard ($target) {
    # release targets
    "package"       { New-Package }
    "msi"           { New-Msi }
    "clean"         { Clean }

    default { Write-Error "No target '$target'" ; Exit -1 }
}
