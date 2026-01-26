# Indian Language Font Support for PDF

## Required Fonts for All Supported Languages

Based on your app's language support, you need fonts for these scripts:

### Script → Font Mapping

| Language | Script | Font Required |
|----------|--------|---------------|
| Telugu (తెలుగు) | Telugu | Noto Sans Telugu |
| Hindi (हिन्दी) | Devanagari | Noto Sans Devanagari |
| English | Latin | Noto Sans (base) |
| Tamil (தமிழ்) | Tamil | Noto Sans Tamil |
| Kannada (ಕನ್ನಡ) | Kannada | Noto Sans Kannada |
| Malayalam (മലയാളം) | Malayalam | Noto Sans Malayalam |
| Marathi (मराठी) | Devanagari | Noto Sans Devanagari |
| Gujarati (ગુજરાતી) | Gujarati | Noto Sans Gujarati |
| Punjabi (ਪੰਜਾਬੀ) | Gurmukhi | Noto Sans Gurmukhi |
| Bengali (বাংলা) | Bengali | Noto Sans Bengali |
| Odia (ଓଡ଼ିଆ) | Odia | Noto Sans Oriya |

## Download Instructions

Download the following fonts from Google Fonts (https://fonts.google.com/noto):

1. **Noto Sans Devanagari** (Hindi, Marathi)
2. **Noto Sans Telugu**
3. **Noto Sans Tamil**  
4. **Noto Sans Kannada**
5. **Noto Sans Malayalam**
6. **Noto Sans Gujarati**
7. **Noto Sans Gurmukhi** (Punjabi)
8. **Noto Sans Bengali**
9. **Noto Sans Oriya** (Odia)

For each font, download both Regular and Bold weights.

## Directory Structure

```
assets/fonts/
├── NotoSansDevanagari/
│   ├── NotoSansDevanagari-Regular.ttf
│   └── NotoSansDevanagari-Bold.ttf
├── NotoSansTelugu/
│   ├── NotoSansTelugu-Regular.ttf
│   └── NotoSansTelugu-Bold.ttf
├── NotoSansTamil/
│   ├── NotoSansTamil-Regular.ttf
│   └── NotoSansTamil-Bold.ttf
├── NotoSansKannada/
│   ├── NotoSansKannada-Regular.ttf
│   └── NotoSansKannada-Bold.ttf
├── NotoSansMalayalam/
│   ├── NotoSansMalayalam-Regular.ttf
│   └── NotoSansMalayalam-Bold.ttf
├── NotoSansGujarati/
│   ├── NotoSansGujarati-Regular.ttf
│   └── NotoSansGujarati-Bold.ttf
├── NotoSansGurmukhi/
│   ├── NotoSansGurmukhi-Regular.ttf
│   └── NotoSansGurmukhi-Bold.ttf
├── NotoSansBengali/
│   ├── NotoSansBengali-Regular.ttf
│   └── NotoSansBengali-Bold.ttf
└── NotoSansOriya/
    ├── NotoSansOriya-Regular.ttf
    └── NotoSansOriya-Bold.ttf
```

## Implementation Strategy

I will create a PDF service that:
1. Loads all required fonts
2. Uses font fallback mechanism to automatically select the correct font based on the script
3. Ensures seamless rendering of mixed-language content (e.g., "Chicken 65" in Telugu + English numbers)

## Package Size Consideration

All fonts combined will be approximately **10-15 MB**. If this is too large, we can:
- Use variable fonts (single file with multiple weights)
- Only include Regular weight (skip Bold)
- Lazy-load fonts based on merchant's primary language preference
