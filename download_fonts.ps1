# Automated Font Downloader for Indian Languages
# Downloads Noto Sans fonts from GitHub

$ErrorActionPreference = "Stop"

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Downloading Indian Language Fonts for PDF" -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

# Base URL for Noto fonts on GitHub
$baseUrl = "https://github.com/google/fonts/raw/main/ofl"

# Font mappings: folder name -> (github path, Regular filename, Bold filename)
$fonts = @{
    "NotoSansDevanagari" = @("notosansdevanagari", "NotoSansDevanagari-Regular.ttf", "NotoSansDevanagari-Bold.ttf")
    "NotoSansTelugu" = @("notosanstelugu", "NotoSansTelugu-Regular.ttf", "NotoSansTelugu-Bold.ttf")
    "NotoSansTamil" = @("notosanstamil", "NotoSansTamil-Regular.ttf", "NotoSansTamil-Bold.ttf")
    "NotoSansKannada" = @("notosanskannada", "NotoSansKannada-Regular.ttf", "NotoSansKannada-Bold.ttf")
    "NotoSansMalayalam" = @("notosansmalayalam", "NotoSansMalayalam-Regular.ttf", "NotoSansMalayalam-Bold.ttf")
    "NotoSansGujarati" = @("notosansgujarati", "NotoSansGujarati-Regular.ttf", "NotoSansGujarati-Bold.ttf")
    "NotoSansGurmukhi" = @("notosansgurmukhi", "NotoSansGurmukhi-Regular.ttf", "NotoSansGurmukhi-Bold.ttf")
    "NotoSansBengali" = @("notosansbengali", "NotoSansBengali-Regular.ttf", "NotoSansBengali-Bold.ttf")
    "NotoSansOriya" = @("notosansoriya", "NotoSansOriya-Regular.ttf", "NotoSansOriya-Bold.ttf")
}

$totalFonts = $fonts.Count * 2  # Regular + Bold for each
$downloaded = 0

foreach ($folderName in $fonts.Keys) {
    $githubPath, $regularName, $boldName = $fonts[$folderName]
    
    # Create directory
    $targetDir = "assets\fonts\$folderName"
    if (!(Test-Path $targetDir)) {
        New-Item -ItemType Directory -Force -Path $targetDir | Out-Null
    }
    
    Write-Host "Downloading $folderName..." -ForegroundColor Yellow
    
    # Download Regular weight
    $regularUrl = "$baseUrl/$githubPath/$regularName"
    $regularTarget = "$targetDir\$regularName"
    
    try {
        Write-Host "  → $regularName" -ForegroundColor White -NoNewline
        Invoke-WebRequest -Uri $regularUrl -OutFile $regularTarget -UseBasicParsing
        $downloaded++
        Write-Host " ✓" -ForegroundColor Green
    } catch {
        Write-Host " ✗ (Failed)" -ForegroundColor Red
        Write-Host "    URL: $regularUrl" -ForegroundColor Gray
    }
    
    # Download Bold weight
    $boldUrl = "$baseUrl/$githubPath/$boldName"
    $boldTarget = "$targetDir\$boldName"
    
    try {
        Write-Host "  → $boldName" -ForegroundColor White -NoNewline
        Invoke-WebRequest -Uri $boldUrl -OutFile $boldTarget -UseBasicParsing
        $downloaded++
        Write-Host " ✓" -ForegroundColor Green
    } catch {
        Write-Host " ✗ (Failed)" -ForegroundColor Red
        Write-Host "    URL: $boldUrl" -ForegroundColor Gray
    }
    
    Write-Host ""
}

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "  Downloaded $downloaded / $totalFonts fonts" -ForegroundColor Green
Write-Host "===================================================" -ForegroundColor Cyan

if ($downloaded -eq $totalFonts) {
    Write-Host "`n✓ All fonts downloaded successfully!" -ForegroundColor Green
} else {
    Write-Host "`n⚠ Some fonts failed to download." -ForegroundColor Yellow
    Write-Host "You may need to download them manually from:" -ForegroundColor Yellow
    Write-Host "https://fonts.google.com/noto" -ForegroundColor Cyan
}
