# 🛡️ Security APP by AI-Tech-DB

Security APP is a modern, privacy-focused local VPN firewall and security monitor for Android. 
Unlike commercial VPNs, it does not route your data to a remote server. It creates a local VPN tunnel directly on your device to intercept and filter traffic, ensuring maximum privacy.

Built with a powerful Kotlin core (VPN, DNS, Room) and a stunning Flutter UI, it protects your device against trackers, malicious domains, and suspicious apps.

## 🎬 Preview

https://github.com/user-attachments/assets/22d55705-7e8d-4a34-aeff-7ce5b1577b79

## ✨ Features

- Local VPN Firewall: Intercepts DNS queries and TLS SNI to block malicious, phishing, and tracking domains.
- Custom Blacklist: Manually block specific domains from the UI.
- Suspicious Apps Monitor: Scans installed apps and calculates a risk score based on dangerous permissions (Accessibility, Overlay, SMS).
- Recent Connections (Log): Real-time log of blocked/allowed connections with a configurable retention policy (OFF, 24h, 3 days).
- Battery Optimization Check: Guides the user to disable Android's aggressive battery saver, ensuring the VPN service stays alive.
- Modern UI: Dark, futuristic Flutter UI with custom animations (Welcome Screen, Setup).
- Lookalike Domain Shield: Detects domains that look like famous brands (e.g., g00gle.com).
- Exit & Stop: One-tap button to stop the VPN and completely close the app.

## 🛠️ Tech Stack

### Android (Kotlin)
- AGP 8.6.0 / Gradle 8.7
- Kotlin 2.1.10 / KSP 2.1.10-1.0.29
- Compose Compiler Plugin 2.1.10
- Room Database (Local storage for logs and rules)
- R8/ProGuard (Code shrinking)
- Local VPN Service (SentinelVpnService, DnsInterceptor, PacketEngine)

### Flutter (Dart)
- Flutter 3.35.7 / Dart 3.9.2
- Material 3 UI
- Battery Optimization Helper
- MethodChannel / EventChannel (Bridge between Flutter and Kotlin)

### Build Environment
- Docker (tacuns-dev container)
- Android SDK 36 / Min SDK 29

## 📂 Project Structure

```text
/
├── app/                    # Android native module (Kotlin)
├── security_ui/            # Flutter module (Dart)
├── gradle/                 # Gradle wrapper
├── build.gradle.kts
├── settings.gradle.kts
├── README.md
├── LICENSE
├── assets/                 # Demo video and media
└── .gitignore
```

## 🚀 Build & Run
Prerequisites
Docker installed on your host.

Android SDK in /opt/android-sdk.

Flutter SDK in /opt/flutter.

A connected Android device (via USB) or emulator.

### Build the Flutter AAR (if you modify Dart code)
```bash
docker exec -it -u root tacuns-dev bash -c '
cd /security_ui
flutter build aar --no-debug --no-profile
'
```

### Build the Android APK
```bash
docker exec -it -u root tacuns-dev bash -c '
cd /app
./gradlew :app:assembleRelease --no-daemon
'
```

The APK will be generated at: app/build/outputs/apk/release/app-release.apk

### Install on device
```bash
docker exec -it -u root tacuns-dev bash -c '
adb install -r /app/app/build/outputs/apk/release/app-release.apk
'
```

## 🔒 Security & Privacy
All filtering happens locally on your device. No data is sent to remote servers.

The VPN service uses a foreground notification to stay alive.

The app requests only the necessary permissions (BIND_VPN_SERVICE, FOREGROUND_SERVICE, etc.).

## 🧪 Testing & Verification
Check VPN service logs: adb logcat -s DnsInterceptor:D *:S

Verify VPN process: adb shell ps -A | grep tacu

Check VPN permission: adb shell dumpsys package com.tacu.nsfwzerotrust | grep BIND_VPN_SERVICE

## 📝 Notes
If you modify Dart code, you MUST regenerate the Flutter AAR and rebuild the Android app.

The Gradle cache is located at /root/.gradle inside the container. If the build behaves strangely, run ./gradlew --stop and delete .gradle in the project directory.

The build uses local.properties with sdk.dir=/opt/android-sdk and flutter.sdk=/opt/flutter.

## 📄 License & Attribution
This project is licensed under the GNU General Public License v3.0 (GPLv3). See the LICENSE file for details.

What we built (AI-Tech-DB)
The Flutter-based user interface (Welcome Screen, Setup, Dashboard, Log, Settings), the native Android bridge (MainActivity.kt, MethodChannels), and all the integration logic were designed and written from scratch by AI-Tech-DB.

What is derived (TacUNS)
The core firewall engine is based on the original TacUNS project, which was licensed under the Apache License 2.0. The original Apache 2.0 code has been modified and integrated into this GPLv3 project. See the NOTICE file for full attribution details.

Made with ❤️ by AI-Tech-DB
