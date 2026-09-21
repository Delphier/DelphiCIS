param([switch]$uninstall)

$componentName = "TSMBIOS"
$sourceDir = Join-Path $PWD "source"
$sourceMain = Join-Path $sourceDir "uSMBIOS.pas"

if (!(Test-Path $sourceMain)) {
    Write-Host "Invalid $componentName directory: $PWD"
    exit 1
}

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

if ($uninstall) {
    radstudio $name library-path remove $sourceDir
} else {
    radstudio $name library-path add $sourceDir
}

Write-Host "Done!"
