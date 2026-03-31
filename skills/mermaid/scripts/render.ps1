# Mermaid diagram renderer — Windows PowerShell
# Usage: render.ps1 <input.mmd> <output.png> [theme] [width]

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$Input,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Output,

    [Parameter(Position = 2)]
    [string]$Theme = "dark",

    [Parameter(Position = 3)]
    [string]$Width
)

$ErrorActionPreference = "Stop"

$Args = @("-i", $Input, "-o", $Output, "-t", $Theme)

if ($Width) {
    $Args += @("-w", $Width)
}

& mmdc @Args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
