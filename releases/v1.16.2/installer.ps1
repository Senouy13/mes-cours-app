$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$version = "1.16.2"
$base = "https://raw.githubusercontent.com/Senouy13/mes-cours-app/main/releases/v$version"
$parts = @("part_aa","part_ab","part_ac","part_ad","part_ae","part_af","part_ag")
$expectedSha256 = "D211BFBBEF201794055D3F454998101D4B049955FC78BFFBFBE69F6865592451"

# ---------- 1. Sauvegarde des cours avant toute chose ----------
$docs = [Environment]::GetFolderPath('MyDocuments')
$dataDir = Join-Path $docs "Mes cours"
$userData = Join-Path $env:APPDATA "Mes cours"
$reglages = Join-Path $userData "reglages.json"
if (Test-Path $reglages) {
    try { $r = Get-Content $reglages -Raw -Encoding UTF8 | ConvertFrom-Json; if ($r.dataDir -and (Test-Path $r.dataDir)) { $dataDir = $r.dataDir } } catch { }
}
$stamp = Get-Date -Format "yyyy-MM-dd_HH-mm"
$safe = Join-Path $docs ("Mes cours - copie avant mise a jour $version ($stamp)")
Write-Host "Sauvegarde de vos cours dans :" -ForegroundColor Cyan
Write-Host "  $safe"
New-Item -ItemType Directory -Path $safe -Force | Out-Null
if (Test-Path $dataDir) { Copy-Item -Path $dataDir -Destination (Join-Path $safe "Mes cours") -Recurse -Force }
if (Test-Path $userData) {
    $ud = Join-Path $safe "reglages-application"
    New-Item -ItemType Directory -Path $ud -Force | Out-Null
    foreach ($n in @("reglages.json","Local Storage","IndexedDB")) { $src = Join-Path $userData $n; if (Test-Path $src) { Copy-Item -Path $src -Destination $ud -Recurse -Force -ErrorAction SilentlyContinue } }
}
$nb = 0; $cdir = Join-Path $safe "Mes cours\cours"; if (Test-Path $cdir) { $nb = (Get-ChildItem $cdir -File).Count }
Write-Host "  -> $nb fichier(s) de cours sauvegarde(s)." -ForegroundColor Green

# ---------- 2. Fermeture propre de l'application si elle est ouverte ----------
$running = Get-Process -Name "Mes cours" -ErrorAction SilentlyContinue
if ($running) {
    Write-Host "Fermeture de Mes cours (vos cours sont enregistres automatiquement)..."
    foreach ($p in $running) { [void]$p.CloseMainWindow() }
    for ($i = 0; $i -lt 20 -and (Get-Process -Name "Mes cours" -ErrorAction SilentlyContinue); $i++) { Start-Sleep -Milliseconds 500 }
    if (Get-Process -Name "Mes cours" -ErrorAction SilentlyContinue) {
        Write-Host "Mes cours est toujours ouvert : fermez-le (Alt+F4), puis appuyez sur Entree." -ForegroundColor Yellow
        Read-Host | Out-Null
    }
}

# ---------- 3. Telechargement et installation ----------
$tmpDir = Join-Path $env:TEMP ("mes-cours-maj-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmpDir | Out-Null
$outExe = Join-Path $tmpDir "Mes cours Setup $version.exe"

Write-Host "Telechargement de la mise a jour (Mes cours $version)..."
$partFiles = @()
foreach ($p in $parts) {
    $dest = Join-Path $tmpDir $p
    Write-Host "  - $p"
    Invoke-WebRequest -Uri "$base/$p" -OutFile $dest -UseBasicParsing
    $partFiles += $dest
}

Write-Host "Assemblage du fichier..."
$outStream = [System.IO.File]::Create($outExe)
try {
    foreach ($pf in $partFiles) {
        $inStream = [System.IO.File]::OpenRead($pf)
        try { $inStream.CopyTo($outStream) } finally { $inStream.Close() }
    }
} finally { $outStream.Close() }
foreach ($pf in $partFiles) { Remove-Item -Path $pf -Force -ErrorAction SilentlyContinue }

Write-Host "Verification de l'integrite du fichier..."
$actualSha256 = (Get-FileHash -Path $outExe -Algorithm SHA256).Hash
if ($actualSha256 -ne $expectedSha256) {
    Write-Host "ERREUR : le fichier telecharge est corrompu (empreinte incorrecte)." -ForegroundColor Red
    Write-Host "Attendu : $expectedSha256"
    Write-Host "Obtenu  : $actualSha256"
    Read-Host "Appuyez sur Entree pour fermer"
    exit 1
}

Write-Host "OK. Lancement de l'installateur..."
Start-Process -FilePath $outExe -Wait
Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Mise a jour terminee. Sauvegarde conservee dans : $safe" -ForegroundColor Green
