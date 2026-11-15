param([Parameter(Mandatory = $true)][string]$Godot)

$motor = (Resolve-Path -LiteralPath $Godot).Path
$proyecto = Split-Path -Parent $PSScriptRoot
Push-Location -LiteralPath $proyecto
try {
    New-Item -ItemType Directory -Force 'build/web' | Out-Null
    New-Item -ItemType File -Force 'build/.gdignore' | Out-Null
    & $motor --headless --export-release Web build/web/index.html
    if ($LASTEXITCODE -ne 0) { throw "Godot no pudo exportar Red Horizon." }
    & $motor --headless --script res://web/preparar_portada.gd
    if ($LASTEXITCODE -ne 0) { throw "Godot no pudo generar la portada Web." }
    $archivos = @('index.html', 'index.js', 'index.wasm', 'index.pck', 'index.png',
        'index.audio.worklet.js', 'index.audio.position.worklet.js', 'portada.jpg')
    $rutas = $archivos | ForEach-Object { Join-Path 'build/web' $_ }
    Compress-Archive -LiteralPath $rutas -DestinationPath 'build/Red-Horizon-Web.zip' -Force
} finally {
    Pop-Location
}
