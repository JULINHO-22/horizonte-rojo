param([Parameter(Mandatory = $true)][string]$Godot)

$motor = (Resolve-Path -LiteralPath $Godot).Path
$proyecto = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $proyecto
try {
    New-Item -ItemType Directory -Force 'build/web' | Out-Null
    & $motor --headless --export-release Web build/web/index.html
    if ($LASTEXITCODE -ne 0) { throw "Godot no pudo exportar Red Horizon." }
    Copy-Item -LiteralPath 'assets/refugio_horizonte.png' -Destination 'build/web/portada.png'
    Compress-Archive -Path 'build/web/*' -DestinationPath 'build/Red-Horizon-Web.zip' -Force
} finally {
    Pop-Location
}
