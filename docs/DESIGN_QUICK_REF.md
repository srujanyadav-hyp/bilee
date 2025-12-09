# 🎨 BILEE Design System - Quick Reference

## Color Palette

### Primary Colors
```
Primary Blue:       #1976D2 ████████
Primary Blue Light: #42A5F5 ████████
Teal Accent:        #00D4AA ████████
```

### Light Theme
```
Background:    #F8F9FA ████████
Surface:       #FFFFFF ████████
Text Primary:  #212529 ████████
Text Secondary:#6C757D ████████
Border:        #DEE2E6 ████████
```

### Dark Theme
```
Background:    #0D1117 ████████
Surface:       #161B22 ████████
Text Primary:  #F0F6FC ████████
Text Secondary:#8B949E ████████
Border:        #30363D ████████
```

### Semantic Colors
```
Success: #28A745 ████████  Error:   #DC3545 ████████
Warning: #FFC107 ████████  Info:    #17A2B8 ████████
```

---

## Typography

### Font Families
- **Titles**: Poppins (Bold, modern)
- **Body**: Inter (Clean, readable)

### Text Styles
```
Display Large:  32px, Poppins Bold
Display Medium: 28px, Poppins Bold
Display Small:  24px, Poppins SemiBold

Headline Large: 24px, Poppins SemiBold
Headline Medium:20px, Poppins SemiBold
Headline Small: 18px, Poppins SemiBold

Title Large:    20px, Poppins SemiBold
Title Medium:   16px, Poppins SemiBold
Title Small:    14px, Poppins SemiBold

Body Large:     16px, Inter Regular
Body Medium:    14px, Inter Regular
Body Small:     12px, Inter Regular

Label Large:    16px, Inter SemiBold
Label Medium:   14px, Inter SemiBold
Label Small:    12px, Inter SemiBold
```

---

## Spacing Scale (4px base)

```
2XS:  4px  ▌
XS:   8px  ▌▌
SM:  12px  ▌▌▌
MD:  16px  ▌▌▌▌
LG:  20px  ▌▌▌▌▌
XL:  24px  ▌▌▌▌▌▌
2XL: 32px  ▌▌▌▌▌▌▌▌
3XL: 40px  ▌▌▌▌▌▌▌▌▌▌
4XL: 48px  ▌▌▌▌▌▌▌▌▌▌▌▌
5XL: 64px  ▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌▌
```

---

## Border Radius

```
XS:    4px  ▢  Small elements
SM:    8px  ▢  Compact items
MD:   12px  ▢  Buttons, Inputs
LG:   16px  ▢  Cards
XL:   20px  ▢  Chips
2XL:  24px  ▢  Modals
Full: 9999  ●  Pills (fully rounded)
```

---

## Component Sizes

### Buttons
```
Small:  36px height
Medium: 44px height (default)
Large:  52px height
XL:     60px height
```

### Icons
```
XS:  16px  ○
SM:  20px  ○
MD:  24px  ○  (default)
LG:  32px  ○
XL:  40px  ○
2XL: 48px  ○
3XL: 64px  ○
```

### Avatars
```
SM:  32px  ●
MD:  40px  ●
LG:  56px  ●
XL:  80px  ●
2XL: 120px ●
```

---

## Elevation (Shadow)

```
None: 0   No shadow
XS:   2   Subtle lift
SM:   4   Cards
MD:   8   Navigation
LG:   12  Modals
XL:   16  Dialogs
```

---

## Animation Durations

```
Fast:      200ms  Quick transitions
Normal:    300ms  Default animations
Slow:      500ms  Emphasis
Very Slow: 800ms  Splash, onboarding
```

---

## Usage Examples

### Using Colors
```dart
import 'package:bilee/core/constants/app_colors.dart';

Container(
  color: AppColors.primaryBlue,
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

### Using Typography
```dart
Text(
  'Welcome to BILEE',
  style: Theme.of(context).textTheme.displayLarge,
)
```

### Using Spacing
```dart
import 'package:bilee/core/constants/app_dimensions.dart';

Padding(
  padding: EdgeInsets.all(AppDimensions.paddingMD),
)
```

### Toggle Theme
```dart
Provider.of<ThemeProvider>(context).toggleTheme();
```

---

## File Structure

```
lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart       # Color palette
│   │   ├── app_typography.dart   # Font system
│   │   ├── app_dimensions.dart   # Spacing & sizes
│   │   └── app_strings.dart      # Text constants
│   └── theme/
│       ├── app_theme.dart        # Theme config
│       └── theme_provider.dart   # State management
└── main.dart                     # App entry with theme
```

---

## Design Principles

✅ **Premium** - Blue gradient, smooth shadows
✅ **Clean** - Light backgrounds, minimal clutter
✅ **Readable** - High contrast typography
✅ **Consistent** - 4px spacing system
✅ **Modern** - Outlined icons, soft corners
✅ **Accessible** - WCAG contrast ratios

---

## Theme Features

- ✅ Light mode
- ✅ Dark mode
- ✅ System mode (auto)
- ✅ Persistent theme (saved)
- ✅ Smooth switching
- ✅ All components themed

---

**Ready to build beautiful, consistent UI! 🚀**
