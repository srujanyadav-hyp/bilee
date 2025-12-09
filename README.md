# 🧾 BILEE - Paperless Billing System

**Digital receipts made simple, safe, and instant.**

BILEE is a modern, paperless billing system that completely eliminates physical printed receipts. Instead of thermal paper receipts containing harmful chemicals like BPA and BPS, merchants using BILEE generate instant digital receipts that transfer directly phone-to-phone through a secure QR-based system.

---

## 🎯 **Purpose**

- Replace paper receipts with digital receipts
- Reduce costs for merchants (no printers, paper, or ink)
- Protect customers from BPA/BPS chemical exposure
- Offer a smarter, cleaner, faster way to handle bills
- Keep receipt history organized forever

---

## ✨ **Features**

### For Merchants 🏪
- Create digital bills with ease
- Generate QR codes for customers to scan
- View daily summary (total revenue, customers served)
- Export daily summaries (PDF/Excel)
- No individual bill storage (privacy-focused)
- Automatic daily reset

### For Customers 👤
- Scan QR codes to receive receipts instantly
- View live bills as merchants create them
- Store all receipts permanently
- Search and organize receipt history
- Access receipts anytime for returns/warranty
- Track expenses effortlessly

---

## 🎨 **Design System**

BILEE uses a premium, minimalistic design with:

- **Colors**: Blue gradient (#1976D2 → #42A5F5)
- **Typography**: Poppins (titles) + Inter (body)
- **Themes**: Full light & dark mode support
- **Icons**: Outlined style with smooth strokes
- **Animations**: Signature splash with logo animation

📚 **See full documentation**: 
- [Complete Design System Guide](DESIGN_SYSTEM.md)
- [Quick Reference](DESIGN_QUICK_REF.md)
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md)

---

## 🏗️ **Architecture**

Clean Architecture with feature-based modules:

```
lib/
├── core/                    # Shared utilities
│   ├── constants/          # Colors, typography, dimensions
│   └── theme/              # Light & dark themes
├── features/
│   ├── authentication/     # Login, signup, OTP
│   ├── splash/            # Splash screen
│   ├── onboarding/        # App introduction
│   ├── merchant_billing/  # Create bills, QR codes
│   ├── merchant_dashboard/# Merchant home
│   ├── merchant_summary/  # Daily summary, export
│   ├── customer_scanner/  # QR code scanner
│   ├── customer_receipts/ # Receipt history
│   ├── customer_dashboard/# Customer home
│   └── profile/           # User profile
└── main.dart              # App entry
```

Each feature follows: **Data → Domain → Presentation** layers

---

## 🚀 **Getting Started**

### Prerequisites
- Flutter SDK 3.10.1 or higher
- Dart 3.10.1 or higher

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/srujanyadav-hyp/bilee.git
   cd bilee
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Run on specific platform
```bash
flutter run -d chrome        # Web
flutter run -d windows       # Windows
flutter run -d android       # Android
flutter run -d ios           # iOS
```

---

## 📱 **Current Status**

✅ **Phase 1: Design System** - Complete
- Color system (light + dark)
- Typography system (Poppins + Inter)
- Spacing & dimensions
- Complete theming
- Theme switching & persistence

🚧 **Phase 2: Core Features** - In Progress
- Splash screen with animations
- Onboarding screens
- Authentication (Email, Phone, Google)
- Merchant & Customer flows

---

## 🛠️ **Tech Stack**

- **Framework**: Flutter 3.10.1
- **Language**: Dart 3.10.1
- **State Management**: Provider
- **Fonts**: Google Fonts (Poppins, Inter)
- **Storage**: SharedPreferences
- **Backend**: Firebase (planned)

---

## 🎨 **Design Highlights**

- **Material Design 3** - Modern, adaptive components
- **Dual Themes** - Beautiful light & dark modes
- **Premium UI** - Blue gradient, soft shadows
- **Typography** - Professional Poppins + Inter combo
- **Consistency** - 4px base spacing system
- **Accessibility** - High contrast, readable fonts

---

## 📖 **Documentation**

- [Design System Guide](DESIGN_SYSTEM.md) - Complete design documentation
- [Quick Reference](DESIGN_QUICK_REF.md) - At-a-glance design specs
- [Implementation Summary](IMPLEMENTATION_SUMMARY.md) - What's been built

---

## 🤝 **Contributing**

This is a production project. Please follow the established:
- Clean architecture patterns
- Design system guidelines
- Code style and conventions

---

## 📄 **License**

Private - Not for public distribution

---

## 👥 **Author**

**Srujan Yadav**
- GitHub: [@srujanyadav-hyp](https://github.com/srujanyadav-hyp)

---

## 🙏 **Acknowledgments**

- Flutter team for the amazing framework
- Google Fonts for beautiful typography
- Material Design for component guidelines

---

**🎉 BILEE - Making the world paperless, one receipt at a time!**
