# Security APP - Flutter UI Module

This is the Flutter module for Security APP. It provides the entire user interface (Welcome Screen, Setup, Dashboard, Log, Settings) and communicates with the native Android core via MethodChannels and EventChannels.

## Requirements

- Flutter 3.35.7 or higher
- Dart 3.9.2 or higher

## Build

To build the AAR (Android Archive) that is integrated into the main Android app:

    flutter build aar --no-debug --no-profile

The AAR will be generated in build/host/outputs/repo/.

## Integration

The main Android app (/app) depends on the AAR via releaseImplementation("com.aitechdb.security_ui:flutter_release:1.0"). After rebuilding the AAR, you must rebuild the Android app.
