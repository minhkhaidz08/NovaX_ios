# NovaX — iOS

Port của app Android **NovaX** sang iOS bằng SwiftUI. Giữ **100% chức năng** so với bản Android: auth qua Plexus Auth API, 3 bậc key (Basic/Pro/Vip), dashboard launcher game, module list, system info, profile & settings.

## Features
- Authenticated login via **Plexus Auth API** (`/api/verify`)
- Auto-login (khôi phục session) + monitor re-verify mỗi 60s
- 4-tab dashboard: **Home / System Info / Profile / Settings**
- Launcher card Free Fire / FF MAX (detect + launch)
- Module list 3 bậc: **Aimlock** (Basic), **Aimbot Legit Safe** (Pro), **Aimbot Body** (Vip) — khóa theo đúng tier key
- System hardware information
- Keychain-secured credential + HWID
- Purple dark/light theme giống bản Android
- Anti-debug (`ptrace`) + certificate pinning + chuỗi nhạy cảm mã hóa XOR

## Cách tránh bị Arena Safe (Anti-Cheat Free Fire)
Giống hệt project `ultralock-ios`:
- Là **app thường** (regular app), **KHÔNG** dùng overlay, floating window, accessibility service hay touch injection lên màn hình game
- Giao diện nền tối, opaque, không có cửa sổ xuyên thấu lên game
- Không yêu cầu quyền bất thường nào ngoài INTERNET
- App chạy độc lập — mở trước khi vào game, không hiển thị lớp phủ lên Free Fire

## Requirements
- Xcode 16.0+
- iOS 16.0+
- Swift 5.9+

## Setup

### 1. Clone
```bash
git clone https://github.com/your-username/novax-ios.git
cd novax-ios
```

### 2. Generate Xcode project (XcodeGen)
```bash
brew install xcodegen
cd NovaX && xcodegen generate
open NovaX.xcodeproj
```

### 3. Build & Run
Chọn simulator iOS 16+ và chạy (⌘R). Để chạy trên máy thật cần ký code bằng Apple ID / sideload.

## Project Structure
```
NovaX/
├── project.yml              # XcodeGen config
└── Sources/NovaX/
    ├── NovaXApp.swift       # App entry (anti-debug)
    ├── ContentView.swift    # Root: splash / login / main
    ├── AppViewModel.swift   # Auth, monitor, features, settings, toast
    ├── Theme.swift          # NovaX purple palette (dark/light)
    ├── Components.swift     # Reusable UI components
    ├── SplashView.swift     # Splash + auto-login
    ├── LoginView.swift      # License key login
    ├── MainContainer.swift  # Top bar + 4 tabs + bottom bar
    ├── HomeView.swift       # Dashboard + launcher + modules
    ├── MemoryView.swift     # System info
    ├── ProfileView.swift    # Account / HWID / logout
    ├── SettingsView.swift   # Appearance / system / about / reset
    ├── DeviceUtils.swift    # HWID + hardware info
    ├── SecurityUtils.swift  # Keychain, HMAC, anti-debug, pinning
    ├── ObfuscatedString.swift
    ├── Haptics.swift
    ├── Info.plist
    ├── nova_logo.png
    └── nova_logo_1024.png   # App icon
```

## Build for CI
```bash
cd NovaX
xcodegen generate
xcodebuild build -project NovaX.xcodeproj -scheme NovaX -sdk iphonesimulator CODE_SIGNING_ALLOWED=NO
```

GitHub Actions (`.github/workflows/ios-build.yml`) tự build unsigned `.ipa` và upload artifact — ký code offline bằng bất kỳ công cụ sideload nào.

## License
Private — All rights reserved.
