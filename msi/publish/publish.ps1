function Export-Variables($file) {
    Get-Content $file | Select-String -Pattern "^export"| ForEach-Object {
        $array= $_[0].ToString().split("=")
        $array[0] = $array[0].Replace("export","").Trim()
        if($array[1].Contains('${')) {
            $array[1] = $ExecutionContext.InvokeCommand.ExpandString($array[1].Replace('${', '${env:'))
        } elseif($array[1] -match '\$\(([^)]*)\)(.*)') {
            $command = $Matches[1].Trim()
            $rest = $Matches[2]
            if($command.StartsWith('realpath')) {
                $command = Invoke-Expression -Command $command.Replace('realpath', 'Resolve-Path')
            } else {
                Write-Error "Unknown command to convert: $command"
            }
            $array[1] = '{0}{1}' -f $command,$rest
            $array[1] = $ExecutionContext.InvokeCommand.ExpandString($array[1])
        }
        [System.Environment]::SetEnvironmentVariable($array[0], $array[1])
    }
}

if(($null -ne $env:BRAND) -and (Test-Path $env:BRAND)) {
    Export-Variables .\$env:BRAND
}

Export-Variables .\$env:BUILDENV

Write-Host "Copying binaries to ${env:MSIDIR}"

if(!(Test-Path $env:MSIDIR)) {
  New-Item -ItemType Directory -Path $env:MSIDIR
}

Get-ChildItem -Path '.\msi\build\bin\Release\en-US\*' -File -Include *.msi,*.msi.sha256 | Copy-Item -Destination $env:MSIDIR

Get-ChildItem -Path $env:MSIDIR
