$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$base = "https://raw.githubusercontent.com/Senouy13/mes-cours-app/main/releases/v1.15.0"
$parts = @("part_aa","part_ab","part_ac","part_ad","part_ae","part_af","part_ag")
$expectedSha256 = "768A84BA91DE6E5F0F7B3F26E786CAB1C0221C7AE44BA843EA8FA6AC1A2E0FD5"

$tmpDir = Join-Path $env:TEMP ("mes-cours-maj-" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmpDir | Out-Null
$outExe = Join-Path $tmpDir "Mes cours Setup 1.15.0.exe"

Write-Host "Telechargement de la mise a jour (Mes cours 1.15.0)..."
$partFiles = @()
foreach ($p in $parts) {
    $url = "$base/$p"
    $dest = Join-Path $tmpDir $p
    Write-Host "  - $p"
    Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    $partFiles += $dest
}

Write-Host "Assemblage du fichier..."
$outStream = [System.IO.File]::Create($outExe)
try {
    foreach ($pf in $partFiles) {
        $inStream = [System.IO.File]::OpenRead($pf)
        try { $inStream.CopyTo($outStream) } finally { $inStream.Close() }
    }
} finally {
    $outStream.Close()
}
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
