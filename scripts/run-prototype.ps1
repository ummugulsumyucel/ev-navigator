# Prototip demo — API anahtarları android/local.properties içinden okunur.
$propsPath = Join-Path $PSScriptRoot "..\android\local.properties"
$key = ""
if (Test-Path $propsPath) {
    Get-Content $propsPath | ForEach-Object {
        if ($_ -match '^GOOGLE_MAPS_API_KEY=(.+)$') { $key = $matches[1].Trim() }
    }
}
if (-not $key) {
    Write-Error "android/local.properties içinde GOOGLE_MAPS_API_KEY tanımlı değil."
    exit 1
}
Set-Location (Join-Path $PSScriptRoot "..")
flutter run `
    --dart-define=GOOGLE_MAPS_API_KEY=$key `
    --dart-define=GOOGLE_DIRECTIONS_API_KEY=$key
