# Download Variable Fonts (Better - single file with all weights)
$fonts = @{
    "NotoSansDevanagari" = "notosansdevanagari/NotoSansDevanagari[wdth,wght].ttf"
    "NotoSansTelugu" = "notosanstelugu/NotoSansTelugu[wdth,wght].ttf"
    "NotoSansTamil" = "notosanstamil/NotoSansTamil[wdth,wght].ttf"
    "NotoSansKannada" = "notosanskannada/NotoSansKannada[wdth,wght].ttf"
    "NotoSansMalayalam" = "notosansmalayalam/NotoSansMalayalam[wdth,wght].ttf"
    "NotoSansGujarati" = "notosansgujarati/NotoSansGujarati[wdth,wght].ttf"
    "NotoSansGurmukhi" = "notosansgurmukhi/NotoSansGurmukhi[wdth,wght].ttf"
    "NotoSansBengali" = "notosansbengali/NotoSansBengali[wdth,wght].ttf"
    "NotoSansOriya" = "notosansoriya/NotoSansOriya[wght].ttf"
}

Write-Host "Downloading Variable Fonts..." -ForegroundColor Cyan

foreach ($dir in $fonts.Keys) {
    $url = "https://github.com/google/fonts/raw/main/ofl/$($fonts[$dir])"
    $output = "assets\fonts\$dir\$dir-Variable.ttf"
    
    Write-Host "Downloading $dir..." -ForegroundColor Yellow -NoNewline
    
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
        Write-Host " ✓" -ForegroundColor Green
    } catch {
        Write-Host " ✗" -ForegroundColor Red
    }
}

Write-Host "`nDone!" -ForegroundColor Green
