# 🎨 BILEE - User Experience & Design Setup

## Complete Design System Implementation

This document outlines all the design system components, theme configurations, and constants implemented for the BILEE app.

---

## 📦 **Dependencies Added**

```yaml
dependencies:
  google_fonts: ^6.2.1      # Poppins & Inter typography
  provider: ^6.1.2          # State management for theme
  shared_preferences: ^2.3.4 # Theme persistence
```

---

## 🎨 **Color System**

### File: `lib/core/constants/app_colors.dart`

#### **Primary Colors**
- **Primary Blue**: `#1976D2` - Main brand color
- **Primary Blue Light**: `#42A5F5` - Gradient end color
- **Primary Gradient**: Linear gradient from `#1976D2` to `#42A5F5`

#### **Light Theme Colors**
- **Background**: `#F8F9FA` - Clean, light gray
- **Surface**: `#FFFFFF` - Pure white for cards
- **Text Primary**: `#212529` - High contrast black
- **Text Secondary**: `#6C757D` - Medium gray
- **Text Tertiary**: `#ADB5BD` - Light gray
- **Border**: `#DEE2E6` - Subtle borders
- **Divider**: `#E9ECEF` - Soft dividers

#### **Dark Theme Colors**
- **Background**: `#0D1117` - Deep dark
- **Surface**: `#161B22` - Elevated dark
- **Card Background**: `#21262D` - Darker cards
- **Text Primary**: `#F0F6FC` - Bright white
- **Text Secondary**: `#8B949E` - Medium gray
- **Text Tertiary**: `#6E7681` - Muted gray
- **Border**: `#30363D` - Dark borders
- **Divider**: `#21262D` - Subtle dividers

#### **Semantic Colors**
- **Success**: `#28A745` (Light) / `#34D058` (Dark) - Green
- **Error**: `#DC3545` (Light) / `#F85149` (Dark) - Red
- **Warning**: `#FFC107` (Light) / `#FFD33D` (Dark) - Orange
- **Info**: `#17A2B8` (Light) / `#58A6FF` (Dark) - Blue

#### **Special Colors**
- **Teal Accent**: `#00D4AA` - From app icon
- **Merchant Color**: `#1976D2` - Blue
- **Customer Color**: `#42A5F5` - Light blue

#### **Additional Colors**
- Overlay colors (10%, 30%, 50% black)
- Shadow colors (light, medium, dark)
- QR code colors (black/white)
- Receipt colors (paper, text, border)

---

## 📝 **Typography System**

### File: `lib/core/constants/app_typography.dart`

#### **Font Families**
- **Titles/Headlines**: `Poppins` (Bold, modern, attention-grabbing)
- **Body Text**: `Inter` (Clean, readable, professional)

#### **Font Weights**
- Light: 300
- Regular: 400
- Medium: 500
- Semi Bold: 600
- Bold: 700
- Extra Bold: 800

#### **Font Sizes**
- **3XL**: 32px - H1 headings
- **2XL**: 28px - H2 headings
- **XL**: 24px - H3 headings
- **LG**: 20px - H4 headings
- **MD**: 18px - H5 headings
- **Base**: 16px - Body large
- **SM**: 14px - Body regular
- **XS**: 12px - Body small
- **2XS**: 10px - Captions

#### **Line Heights**
- Tight: 1.2
- Normal: 1.5
- Relaxed: 1.75
- Loose: 2.0

#### **Letter Spacing**
- Tight: -0.5
- Normal: 0.0
- Wide: 0.5
- Wider: 1.0

---

## 📏 **Dimensions & Spacing**

### File: `lib/core/constants/app_dimensions.dart`

#### **Spacing System** (Base unit: 4px)
- 2XS: 4px
- XS: 8px
- SM: 12px
- MD: 16px
- LG: 20px
- XL: 24px
- 2XL: 32px
- 3XL: 40px
- 4XL: 48px
- 5XL: 64px

#### **Border Radius**
- XS: 4px
- SM: 8px
- MD: 12px (Buttons, Inputs)
- LG: 16px (Cards)
- XL: 20px (Chips)
- 2XL: 24px (Modals)
- Full: 9999px (Pills)

#### **Icon Sizes**
- XS: 16px
- SM: 20px
- MD: 24px
- LG: 32px
- XL: 40px
- 2XL: 48px
- 3XL: 64px

#### **Button Heights**
- SM: 36px
- MD: 44px
- LG: 52px
- XL: 60px

#### **Input Heights**
- Regular: 48px
- Large: 56px

#### **Avatar Sizes**
- SM: 32px
- MD: 40px
- LG: 56px
- XL: 80px
- 2XL: 120px

#### **QR Code Sizes**
- SM: 150px
- MD: 200px
- LG: 250px
- XL: 300px

#### **Elevation (Shadow)**
- None: 0
- XS: 2
- SM: 4
- MD: 8
- LG: 12
- XL: 16

#### **Animation Durations** (milliseconds)
- Fast: 200ms
- Normal: 300ms
- Slow: 500ms
- Very Slow: 800ms

---

## 🎭 **Theme Configuration**

### File: `lib/core/theme/app_theme.dart`

#### **Light Theme Features**
- Material Design 3 (Material You)
- Primary blue gradient colors
- Clean white surfaces
- High contrast text
- Subtle shadows
- Outlined icons
- Soft corner radius

#### **Dark Theme Features**
- Material Design 3
- Deep dark backgrounds
- Elevated surfaces
- Bright text on dark
- Reduced shadows
- Blue-tinted accents
- Same corner radius

#### **Themed Components**
All components are fully themed with both light and dark variants:

1. **App Bar**
   - Elevation: 0 (flat)
   - Poppins font for titles
   - Icon size: 24px

2. **Cards**
   - Elevation: 4
   - Border radius: 16px
   - Margin: 16px

3. **Buttons**
   - Elevated: Primary blue background
   - Outlined: Primary blue border
   - Text: Primary blue text
   - Height: 44px
   - Border radius: 12px
   - Inter font

4. **Input Fields**
   - Height: 48px
   - Border radius: 12px
   - Filled background
   - Focused border: 2px
   - Error states included

5. **Bottom Navigation**
   - Fixed type
   - Selected: Primary blue
   - Unselected: Tertiary text
   - Inter font

6. **Dialogs**
   - Border radius: 24px
   - Poppins for titles
   - Inter for content

7. **Chips**
   - Border radius: 20px (pill)
   - Selected: Primary blue

---

## 🔄 **Theme Provider**

### File: `lib/core/theme/theme_provider.dart`

#### **Features**
- ✅ Light mode support
- ✅ Dark mode support
- ✅ System mode (follows device settings)
- ✅ Persistent theme selection (SharedPreferences)
- ✅ Easy theme switching

#### **Methods**
- `toggleTheme()` - Switch between light/dark
- `setLightTheme()` - Explicitly set light
- `setDarkTheme()` - Explicitly set dark
- `setSystemTheme()` - Follow system
- `getThemeBrightness(context)` - Get current brightness

#### **Usage**
```dart
// Get theme provider
final themeProvider = Provider.of<ThemeProvider>(context);

// Toggle theme
themeProvider.toggleTheme();

// Check current theme
if (themeProvider.isDarkMode) {
  // Dark mode active
}
```

---

## 📱 **Main App Integration**

### File: `lib/main.dart`

#### **Implementation**
- ✅ Provider setup for theme management
- ✅ Theme switching button in app bar
- ✅ Demonstration of:
  - Display text styles (Poppins)
  - Body text styles (Inter)
  - Primary gradient colors
  - Button styling
  - Icons
  - Light/Dark switching

---

## 📝 **String Constants**

### File: `lib/core/constants/app_strings.dart`

Centralized string constants for:
- App information
- Onboarding text
- Authentication labels
- Role descriptions
- Common UI text
- Error messages

**Benefits**:
- Easy localization support in future
- Consistent text across app
- Single source of truth
- Easy to update

---

## 🎯 **Design Principles Applied**

### **1. Premium Feel**
- Blue gradient (#1976D2 → #42A5F5)
- Smooth shadows and elevations
- Generous spacing
- Soft corner radius

### **2. Clean & Minimalistic**
- Light backgrounds (#F8F9FA)
- White cards with subtle shadows
- Ample whitespace
- Clear visual hierarchy

### **3. High Contrast Typography**
- Dark text on light backgrounds
- Light text on dark backgrounds
- Proper font weights
- Readable line heights

### **4. Consistent Spacing**
- 4px base unit system
- Predictable spacing scale
- Harmonious padding
- Balanced margins

### **5. Outlined Icon Style**
- Material Icons Outlined
- 24px default size
- Consistent stroke width
- Scalable sizes (16-64px)

### **6. Soft Corner Radius**
- Buttons: 12px
- Cards: 16px
- Inputs: 12px
- Modals: 24px
- Chips: 20px (pill)

---

## 🚀 **How to Use**

### **1. Colors**
```dart
import 'package:bilee/core/constants/app_colors.dart';

Container(
  color: AppColors.primaryBlue,
  decoration: BoxDecoration(
    gradient: AppColors.primaryGradient,
  ),
)
```

### **2. Typography**
```dart
import 'package:bilee/core/constants/app_typography.dart';

Text(
  'Title',
  style: Theme.of(context).textTheme.displayLarge,
)
```

### **3. Spacing**
```dart
import 'package:bilee/core/constants/app_dimensions.dart';

Padding(
  padding: EdgeInsets.all(AppDimensions.paddingMD),
  child: ...
)
```

### **4. Theme Switching**
```dart
import 'package:provider/provider.dart';

IconButton(
  icon: Icon(Icons.dark_mode),
  onPressed: () {
    context.read<ThemeProvider>().toggleTheme();
  },
)
```

---

## ✅ **What's Included**

### **Files Created**
1. ✅ `lib/core/constants/app_colors.dart` - Complete color system
2. ✅ `lib/core/constants/app_typography.dart` - Typography constants
3. ✅ `lib/core/constants/app_dimensions.dart` - Spacing & sizing
4. ✅ `lib/core/constants/app_strings.dart` - String constants
5. ✅ `lib/core/theme/app_theme.dart` - Full theme configuration
6. ✅ `lib/core/theme/theme_provider.dart` - Theme state management
7. ✅ `lib/main.dart` - Updated with theme integration

### **Features Implemented**
- ✅ Complete color palette (light + dark)
- ✅ Typography system (Poppins + Inter)
- ✅ Spacing & sizing system
- ✅ Border radius system
- ✅ Icon sizes
- ✅ Button styles
- ✅ Input field styles
- ✅ Card styles
- ✅ Full light theme
- ✅ Full dark theme
- ✅ Theme switching
- ✅ Theme persistence
- ✅ System theme support
- ✅ All Material components themed

### **Dependencies Added**
- ✅ google_fonts (Poppins & Inter)
- ✅ provider (State management)
- ✅ shared_preferences (Theme persistence)

---

## 🎨 **Design System Summary**

| Category | Implementation | Status |
|----------|---------------|--------|
| **Colors** | Light + Dark palettes | ✅ Complete |
| **Typography** | Poppins + Inter fonts | ✅ Complete |
| **Spacing** | 4px base system | ✅ Complete |
| **Components** | All Material widgets | ✅ Complete |
| **Theme** | Light + Dark themes | ✅ Complete |
| **State** | Provider integration | ✅ Complete |
| **Persistence** | SharedPreferences | ✅ Complete |

---

## 🎯 **Next Steps**

The design system is now **100% ready** for:
1. ✅ Building splash screen with animations
2. ✅ Creating onboarding screens
3. ✅ Implementing authentication UI
4. ✅ Designing merchant & customer features
5. ✅ Building all app screens with consistent design

---

## 📸 **Theme Showcase**

The main app now demonstrates:
- **Light/Dark theme toggle** (top-right icon)
- **Primary gradient** (logo container)
- **Display text** (app name in Poppins)
- **Title text** (tagline in Poppins)
- **Body text** (description in Inter)
- **Primary button** (Get Started button)
- **Icons** (theme toggle & QR icon)

**Test it**: Run the app and click the theme toggle icon to see smooth light/dark switching!

---

## 💡 **Key Highlights**

1. **Professional Grade**: Enterprise-level design system
2. **Fully Typed**: All constants properly typed in Dart
3. **Scalable**: Easy to extend and modify
4. **Consistent**: Single source of truth for design
5. **Modern**: Material Design 3 with custom theming
6. **Accessible**: High contrast, readable fonts
7. **Maintainable**: Well-organized, documented code
8. **Performance**: Optimized theme switching with Provider

---

**🎉 BILEE Design System is Production-Ready!**

All UI components can now use these constants and themes for a consistent, premium user experience across the entire app.
