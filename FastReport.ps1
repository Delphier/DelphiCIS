param([switch]$uninstall)

$componentName = "FastReport VCL"
$prompt = $uninstall ? "Uninstall $componentName from:" : "Install $componentName to:"
$json = radstudio select $prompt --json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($json.Count -eq 0) {
    exit
}

$ide = $json[0]
$name = $ide.name
$packageVersion = $ide.package_version

$dpkDir = "LibRS$packageVersion\VCL"
if (!(Test-Path $dpkDir)) {
    Write-Host "Invalid $componentName directory: $PWD, or"
    Write-Host "this version of $componentName does not support $name"
    exit 1
}

$dpks = @("frCoreLibrary", "frGraphicsLibrary", "frLocalizationLibrary", "frControlsLibrary", "frDataLibrary", "frBarcodeLibrary", "frEditorsLibrary",
    "frADODataLibrary", "frFDDataLibrary", 
    "fs", "fsDB", "fsADO", "fsFD",
    "fqb", "fqbADO", "fqbFD", "fqbDBX",
    "frx", "frxe", "frxHTML", "frxPDF", "frxcs", "frxIntIOBase", "frxIntIO", "frxIntIOIndy",
    "frxDB", "frxQueryBuilder", "frxADO", "frxADOQueryBuilder", "frxFD", "frxFDQueryBuilder", "frxDBX", "frxDBXQueryBuilder",
    "frFastGrid", "frFastGridExportLibrary",
    "frSmartMemo", "fqbSM", "frxSM",
    "fcx", "fcxe", "fcxfs", "fcxp")
$languages = (Get-ChildItem -Path $dpkDir "frLanguage*.dpk").BaseName | % { $_.Substring(0, $_.Length - $packageVersion.Length) }
$dpks += $languages

$SourcesDir = "Sources"
$sourceDirs = (Get-ChildItem -Path $SourcesDir -Directory).FullName
$sourceDirs = $sourceDirs | % { Join-Path $_ "VCL\Sources" }
$sourceDirs = $sourceDirs -join ";"

$LibDir = Join-Path $PWD "Lib"
$RSDir = Join-Path $LibDir "RS$packageVersion"

function compilePackage($dpk, $isDesigntime, $platform, $outputDir) {
    $dpk = "$dpk$packageVersion.dpk"
    if ($isDesigntime) { $dpk = "dcl" + $dpk }
    $dpk = Join-Path $dpkDir $dpk
    if (!(Test-Path $dpk)) { return }

    Write-Host "===============================================" -ForegroundColor Green
    Write-Host "${platform}: $dpk" -ForegroundColor Blue
    Write-Host "===============================================" -ForegroundColor Green

    $cmd = $isDesigntime ? @("package", "compile", "--install") : @("dcc")
    radstudio $name @cmd $dpk -b -q `
        --platform=$platform `
        --unit-search-dirs=$sourceDirs `
        --unit-output-dir=$outputDir `
        --package-bpl-output-dir=$outputDir `
        --package-dcp-output-dir=$outputDir `
        -- -W-
}

if ($uninstall) {
    foreach ($platform in $ide.ide_platforms) {
        $bplDir = Join-Path $RSDir $platform
        foreach ($dpk in $dpks) {
            radstudio $name --platform=$platform package unregister (Join-Path $bplDir "dcl$dpk$packageVersion.bpl")
        }
        radstudio $name --platform=$platform env-path remove $bplDir
    }

    foreach ($platform in $ide.platforms) {
        radstudio $name --platform=$platform library-path remove (Join-Path $RSDir $platform)
        radstudio $name --platform=$platform browsing-path remove $sourceDirs
    }

    if (Test-Path $RSDir) {Remove-Item $RSDir -Recurse}
    Remove-Item $LibDir -ErrorAction Ignore
} else {
    $platforms = "Win32", "Win64"
    foreach ($platform in $platforms) {
        if ($platform -notin $ide.platforms) { continue }
        $outputDir = Join-Path $RSDir $platform
        foreach ($dpk in $dpks) {
            compilePackage $dpk $false $platform $outputDir
        }
        radstudio $name --platform=$platform library-path add $outputDir
        radstudio $name --platform=$platform browsing-path add $sourceDirs
        Get-ChildItem -Path "$SourcesDir\*" -Recurse -File -Include "*.dfm", "*.res" | Copy-Item -Destination $outputDir -Force
    }

    foreach ($platform in $ide.ide_platforms) {
        $outputDir = Join-Path $RSDir $platform
        foreach ($dpk in $dpks) {
            compilePackage $dpk $true $platform $outputDir
        }
        radstudio $name --platform=$platform env-path add $outputDir
    }
}

Write-Host "Done!" -ForegroundColor Green
