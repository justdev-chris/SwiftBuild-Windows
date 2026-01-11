# 🚀 SwiftBuild for Windows - iOS Development Without a Mac

> **Compile SwiftUI apps on Windows using GitHub Actions. Get real .ipa files without Apple hardware.**

## ✨ Features
- **Zero Mac Required** - Build iOS apps from Windows/Linux
- **Completely Free** - Uses GitHub's macOS runners + free Apple ID
- **Real .ipa Output** - Ready for sideloading with AltStore
- **SwiftUI Support** - Full Swift 5.9 + iOS 15+ SDK
- **Customizable** - App name, bundle ID, icons, orientation

## 🚀 Quick Start
 1. Fork this repository
 2. Edit App/Sources/Main.swift (your SwiftUI code)
 3. Edit config.json (app settings)
 4. Push to GitHub
 5. Download .ipa from Actions tab
 6. Install with AltStore (free sideloading)

## 🎨 Custom App Icon (Optional)

### Option 1: Use Default Icon
The template includes a clean blue default icon. No action needed.

### Option 2: Use Custom Icon
1. Create a **1024x1024 PNG** icon
2. Place it at: `Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`
3. Push to GitHub

### Icon Requirements:
- **Size:** 1024x1024 pixels
- **Format:** PNG with transparency
- **Location:** `Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

The build system will automatically scale your icon to all required iOS sizes.

## 🛠 How It Works
1. **GitHub Actions** spins up a macOS runner
2. **Xcode** compiles your Swift code
3. **xcodebuild** packages it as unsigned .ipa
4. **Download** and sideload with AltStore

## 📁 Project Structure
```
├── config.json              # App configuration
├── App/Sources/Main.swift   # Your SwiftUI code
├── Resources/               # App icons (optional)
└── .github/workflows/      # Build pipeline
```

## 💡 Use Cases
- **Learning SwiftUI** without Mac investment
- **Prototyping iOS apps** from Windows
- **CI/CD for open-source iOS projects**
- **Cross-platform development workflows**

## 🤝 Contributing
Found a bug? Have a feature request? Open an issue or PR!

## 📄 License
MIT - Free to use, modify, and distribute.

## Why?
Because Apple not making a simple solution for users who wanna build iOS apps on Windows is just them being lazy.

