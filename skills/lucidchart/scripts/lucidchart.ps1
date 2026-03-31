# Lucidchart REST API helper
# Requires: LUCID_API_KEY env var

param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(Position = 1)]
    [string]$Arg1,

    [Parameter(Position = 2)]
    [string]$Arg2,

    [Parameter(Position = 3)]
    [string]$Arg3
)

$ErrorActionPreference = "Stop"

$BaseUrl = "https://api.lucid.co"

if (-not $env:LUCID_API_KEY) {
    Write-Error "LUCID_API_KEY environment variable is not set.`nCreate an API key at https://developer.lucid.co and set it."
    exit 1
}

function Invoke-LucidApi {
    param(
        [string]$Method,
        [string]$Path,
        [hashtable]$ExtraHeaders = @{},
        [object]$Body,
        [string]$OutFile
    )

    $headers = @{
        "Authorization"     = "Bearer $($env:LUCID_API_KEY)"
        "Lucid-Api-Version" = "1"
    }
    foreach ($k in $ExtraHeaders.Keys) {
        $headers[$k] = $ExtraHeaders[$k]
    }

    $params = @{
        Method  = $Method
        Uri     = "$BaseUrl$Path"
        Headers = $headers
    }

    if ($Body) {
        $params["Body"] = ($Body | ConvertTo-Json -Compress)
        $params["ContentType"] = "application/json"
    }

    if ($OutFile) {
        $params["OutFile"] = $OutFile
    }

    Invoke-RestMethod @params
}

function Invoke-Create {
    if (-not $Arg1) {
        Write-Error "Usage: lucidchart.ps1 create <title> [folder_id]"
        exit 1
    }
    $body = @{ title = $Arg1; product = "lucidchart" }
    if ($Arg2) {
        $body["parent"] = [int]$Arg2
    }
    $resp = Invoke-LucidApi -Method POST -Path "/documents" -Body $body
    Write-Output "Document ID: $($resp.documentId)"
    Write-Output "Edit URL:    $($resp.editUrl)"
    $resp | ConvertTo-Json -Depth 10
}

function Invoke-CreateFromTemplate {
    if (-not $Arg1 -or -not $Arg2) {
        Write-Error "Usage: lucidchart.ps1 create-from-template <title> <template_uuid> [folder_id]"
        exit 1
    }
    $body = @{ title = $Arg1; template = $Arg2 }
    if ($Arg3) {
        $body["parent"] = [int]$Arg3
    }
    $resp = Invoke-LucidApi -Method POST -Path "/documents" -Body $body
    Write-Output "Document ID: $($resp.documentId)"
    Write-Output "Edit URL:    $($resp.editUrl)"
    $resp | ConvertTo-Json -Depth 10
}

function Invoke-Export {
    if (-not $Arg1 -or -not $Arg2) {
        Write-Error "Usage: lucidchart.ps1 export <document_id> <output_file>"
        exit 1
    }
    Invoke-LucidApi -Method GET -Path "/documents/$Arg1" -ExtraHeaders @{ "Accept" = "image/png" } -OutFile $Arg2
    Write-Output "Exported to $Arg2"
}

function Invoke-Search {
    if (-not $Arg1) {
        Write-Error "Usage: lucidchart.ps1 search <keywords>"
        exit 1
    }
    $body = @{ keywords = $Arg1; product = @("lucidchart") }
    $resp = Invoke-LucidApi -Method POST -Path "/accounts/me/documents/search" -Body $body -ExtraHeaders @{ "Lucid-Request-As" = "admin" }
    $resp | ConvertTo-Json -Depth 10
}

function Invoke-Get {
    if (-not $Arg1) {
        Write-Error "Usage: lucidchart.ps1 get <document_id>"
        exit 1
    }
    $resp = Invoke-LucidApi -Method GET -Path "/documents/$Arg1" -ExtraHeaders @{ "Accept" = "application/json" }
    $resp | ConvertTo-Json -Depth 10
}

function Invoke-Folders {
    $resp = Invoke-LucidApi -Method GET -Path "/folders" -ExtraHeaders @{ "Accept" = "application/json" }
    $resp | ConvertTo-Json -Depth 10
}

function Show-Help {
    @"
Usage: lucidchart.ps1 <command> [args...]

Commands:
  create <title> [folder_id]                        Create a blank document
  create-from-template <title> <template> [folder]  Create from template
  export <document_id> <output.png>                  Export as PNG
  search <keywords>                                  Search documents
  get <document_id>                                  Get document info
  folders                                            List folders
  help                                               Show this help
"@
}

switch ($Command) {
    "create"                { Invoke-Create }
    "create-from-template"  { Invoke-CreateFromTemplate }
    "export"                { Invoke-Export }
    "search"                { Invoke-Search }
    "get"                   { Invoke-Get }
    "folders"               { Invoke-Folders }
    "help"                  { Show-Help }
    default                 { Show-Help }
}
