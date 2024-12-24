<#
    .Synopsis
    Upgrades the version information in the register from the current Jenkins war file.
    .Description
    The purpose of this script is to update the version of Jenkins in the registry
    when the user may have upgraded the war file in place. The script probes the
    registry for information about the Jenkins install (path to war, etc.) and 
    then grabs the version information from the war to update the values in the
    registry so they match the version of the war file. 

    This will help with security scanners that look in the registry for versions
    of software and flag things when they are too low. The information in the 
    registry may be very old compared to what version of the war file is 
    actually installed on the system.
#>


# Self-elevate the script if required
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
    # We may be running under powershell.exe or pwsh.exe, make sure we relaunch the same one.
    $Executable = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    if ([int](Get-CimInstance -Class Win32_OperatingSystem | Select-Object -ExpandProperty BuildNumber) -ge 6000) {
        # Launching with RunAs to get elevation
        $CommandLine = "-File `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath $Executable -Verb Runas -ArgumentList $CommandLine
        Exit
    }
}

function New-TemporaryDirectory {
    $Parent = [System.IO.Path]::GetTempPath()
    do {
        $Name = [System.IO.Path]::GetRandomFileName()
        $Item = New-Item -Path $Parent -Name $Name -ItemType "Directory" -ErrorAction SilentlyContinue
    } while (-not $Item)
    return $Item.FullName
}

function Exit-Script($Message, $Fatal = $False) {
    $ExitCode = 0
    if($Fatal) {
        Write-Error $Message
    } else {
        Write-Host $Message
    }
    Read-Host "Press ENTER to continue"
    Exit $ExitCode
}

# Let's find the location of the war file...
$JenkinsDir = Get-ItemPropertyValue -Path HKLM:\Software\Jenkins\InstalledProducts\Jenkins -Name InstallLocation -ErrorAction SilentlyContinue

if (($Null -eq $JenkinsDir) -or [String]::IsNullOrWhiteSpace($JenkinsDir)) {
    Exit-Script -Message "Jenkins does not seem to be installed. Please verify you have previously installed using the MSI installer" -Fatal $True
}

$WarPath = Join-Path $JenkinsDir "jenkins.war"
if(-Not (Test-Path $WarPath)) {
    Exit-Script -Message "Could not find war file at location found in registry, please verify Jenkins installation" -Fatal $True
}

# Get the MANIFEST.MF file from the war file to get the version of Jenkins
$TempWorkDir = New-TemporaryDirectory
$ManifestFile = Join-Path $TempWorkDir "MANIFEST.MF"
$Zip = [IO.Compression.ZipFile]::OpenRead($WarPath)
$Zip.Entries | Where-Object { $_.Name -like "MANIFEST.MF" } | ForEach-Object { [System.IO.Compression.ZipFileExtensions]::ExtractToFile($_, $ManiFestFile, $True) }
$Zip.Dispose()

$JenkinsVersion = $(Get-Content $ManiFestFile | Select-String -Pattern "^Jenkins-Version:\s*(.*)" | ForEach-Object { $_.Matches } | ForEach-Object { $_.Groups[1].Value } | Select-Object -First 1)
Remove-Item -Path $ManifestFile

# Convert the Jenkins version into what should be in the registry
$VersionItems = $JenkinsVersion.Split(".") | ForEach-Object { [int]::Parse($_) }

# Use the same encoding algorithm as the installer to encode the version into the correct format 
$RegistryEncodedVersion = 0
$Major = $VersionItems[0]
if ($VersionItems.Length -le 2) {
    $Minor = 0
    if (($VersionItems.Length -gt 1) -and ($VersionItems[1] -gt 255)) {
        $Minor = $VersionItems[1]
        $RegistryEncodedVersion = $RegistryEncodedVersion -bor ((($Major -band 0xff) -shl 24) -bor 0x00ff0000 -bor (($Minor * 10) -band 0x0000ffff))
    }
    else {
        $RegistryEncodedVersion = $RegistryEncodedVersion -bor (($Major -band 0xff) -shl 24)
    }
}
else {
    $Minor = $VersionItems[1]
    if ($Minor -gt 255) {
        $RegistryEncodedVersion = $RegistryEncodedVersion -bor ((($Major -band 0xff) -shl 24) -bor 0x00ff0000 -bor ((($Minor * 10) + $VersionItems[2]) -band 0x0000ffff))
    }
    else {
        $RegistryEncodedVersion = $RegistryEncodedVersion -bor ((($Major -band 0xff) -shl 24) -bor (($Minor -band 0xff) -shl 16) -bor ($VersionItems[2] -band 0x0000ffff))
    }
}

$ProductName = "Jenkins $JenkinsVersion"

# Find the registry key for Jenkins in the Installer\Products area and CurrentVersion\Uninstall
$JenkinsProductsRegistryKey = Get-ChildItem -Path HKLM:\SOFTWARE\Classes\Installer\Products  | Where-Object { $_.GetValue("ProductName", "").StartsWith("Jenkins") }

$JenkinsUninstallRegistryKey = Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall  | Where-Object { $_.GetValue("DisplayName", "").StartsWith("Jenkins") }

if (($Null -eq $JenkinsProductsRegistryKey) -or ($Null -eq $JenkinsUninstallRegistryKey)) {
    Exit-Script -Message "Could not find the product information for Jenkins" -Fatal $True
}

# Update the Installer\Products area
$RegistryPath = $JenkinsProductsRegistryKey.Name.Substring($JenkinsProductsRegistryKey.Name.IndexOf("\"))

$OldProductName = $JenkinsProductsRegistryKey.GetValue("ProductName", "")
if ($OldProductName -ne $ProductName) {
    Set-ItemProperty -Path HKLM:$RegistryPath -Name "ProductName" -Type String -Value $ProductName 
}

$OldVersion = $JenkinsProductsRegistryKey.GetValue("Version", 0)
if ($OldVersion -ne $RegistryEncodedVersion) {
    Set-ItemProperty -Path HKLM:$RegistryPath -Name "Version" -Type DWord -Value $RegistryEncodedVersion
}

# Update the Uninstall area
$RegistryPath = $JenkinsUninstallRegistryKey.Name.Substring($JenkinsUninstallRegistryKey.Name.IndexOf("\"))
$OldDisplayName = $JenkinsUninstallRegistryKey.GetValue("DisplayName", "")
if ($OldDisplayName -ne $ProductName) {
    Set-ItemProperty -Path HKLM:$RegistryPath -Name "DisplayName" -Type String -Value $ProductName
}

$OldDisplayVersion = $JenkinsUninstallRegistryKey.GetValue("DisplayVersion", "")
$DisplayVersion = "{0}.{1}.{2}" -f ($RegistryEncodedVersion -shr 24), (($RegistryEncodedVersion -shr 16) -band 0xff), ($RegistryEncodedVersion -band 0xffff)
if ($OldDisplayVersion -ne $DisplayVersion) {
    Set-ItemProperty -Path HKLM:$RegistryPath -Name "DisplayVersion" -Type String -Value $DisplayVersion
}

$OldVersion = $JenkinsUninstallRegistryKey.GetValue("Version", 0)
if ($OldVersion -ne $RegistryEncodedVersion) {
    Set-ItemProperty -Path HKLM:$RegistryPath -Name "Version" -Type DWord -Value $RegistryEncodedVersion
}

$OldVersionMajor = $JenkinsUninstallRegistryKey.GetValue("VersionMajor", 0)
$VersionMajor = $RegistryEncodedVersion -shr 24
if ($OldVersionMajor -ne $VersionMajor) {

    Set-ItemProperty -Path HKLM:$RegistryPath -Name "VersionMajor" -Type DWord -Value $VersionMajor
}

$OldVersionMinor = $JenkinsUninstallRegistryKey.GetValue("VersionMinor", 0)
$VersionMinor = ($RegistryEncodedVersion -shr 16) -band 0xff
if ($OldVersionMinor -ne $VersionMinor) {
    Set-ItemProperty -Path HKLM:$RegistryPath -Name "VersionMinor" -Type DWord -Value $VersionMinor
}

Read-Host "Press ENTER to continue"
