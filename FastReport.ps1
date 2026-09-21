param([switch]$uninstall)

$PackagesVCL = Join-Path $PWD "PackagesVCL"
$frReportFilesDproj = Join-Path $PackagesVCL "frReportFiles.dproj"

if (!(Test-Path $frReportFilesDproj)) {
    Write-Host "Invalid FastReport directory: $PWD"
    exit 1
}

$prompt = $uninstall ? "Uninstall FastReport from" : "Install FastReport to"
$json = radstudio select "${prompt}:" --json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($json.Count -eq 0) {
    exit
}

$ide = $json[0]
$name = $ide.name
$libDir = Join-Path $PWD "Lib$($ide.version)"
$vclDir = Join-Path $libDir "VCL"
$dclfrReportFilesBpl = "dclfrReportFiles$($ide.package_version_number).bpl"
$env:ProductVersion = $ide.version

if ($uninstall) {
    foreach ($platform in $ide.ide_platforms) {
        $bplDir = Join-Path $vclDir $platform
        radstudio $name --platform=$platform package unregister (Join-Path $bplDir $dclfrReportFilesBpl)
        radstudio $name --platform=$platform env-path remove $bplDir
    }

    foreach ($platform in $ide.platforms) {
        radstudio $name --platform=$platform library-path remove (Join-Path $vclDir $platform)
    }

    if (Test-Path $libDir) {Remove-Item $libDir -Recurse}
} else {
    $platforms = "Win32", "Win64"
    foreach ($platform in $platforms) {
        if ($platform -notin $ide.platforms) { continue }
        $outputDir = Join-Path $vclDir $platform
        radstudio $name --platform=$platform build $frReportFilesDproj
        radstudio $name --platform=$platform library-path add $outputDir
    }

    foreach ($platform in $ide.ide_platforms) {
        $outputDir = Join-Path $vclDir $platform
        radstudio $name --platform=$platform build (Join-Path $PackagesVCL "dclfrReportFiles.dproj")
        radstudio $name --platform=$platform package register (Join-Path $outputDir $dclfrReportFilesBpl)
        radstudio $name --platform=$platform env-path add $outputDir
    }
}

Write-Host "Done!"