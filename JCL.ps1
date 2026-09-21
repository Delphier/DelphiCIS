param([switch]$uninstall)

$sourceDir = Join-Path $PWD "source"
$JclBase = Join-Path $sourceDir "common\JclBase.pas"

if (!(Test-Path $JclBase)) {
    Write-Host "Invalid JCL directory: $PWD"
    exit 1
}

$prompt = $uninstall ? "Uninstall JCL from" : "Install JCL to"
$json = radstudio select "${prompt}:" --json | ConvertFrom-Json

if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

if ($json.Count -eq 0) {
    exit
}

$ide = $json[0]
$name = $ide.name
$paths = "common", "include", "windows"

foreach ($path in $paths) {
    $libDir = Join-Path $sourceDir $path
    if ($uninstall) {
        radstudio $name library-path remove $libDir
    } else {
        radstudio $name library-path add $libDir
    }
}

Write-Host "Done!"
