# Zoron Video Exporter

An iOS SwiftUI app that re-encodes a video at a user-selected H.264 bitrate (5–100 Mbps). It is intended for video **after** it has been exported from Alight Motion. It does not modify Alight Motion or bypass any of that app's export restrictions; increasing the bitrate cannot restore quality already removed by a prior export.

## Build locally

Requirements: macOS, Xcode 15+ and [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). From this folder run:

```sh
xcodegen generate
open ZoronVideoExporter.xcodeproj
```

Choose an Apple Development team in Signing & Capabilities, connect an iPhone, then select **Product > Run**.

## Build with GitHub Actions

1. Create a GitHub repository and upload the contents of this folder.
2. Open **Actions**, select **Build iOS app**, then choose **Run workflow** (or push to `main`).
3. When the run is green, download `ZoronVideoExporter-unsigned-ipa` from its Artifacts section. It is intentionally unsigned, which is the correct input for Sideloadly.

## Install with Sideloadly

1. On Windows, install the current Sideloadly release from [sideloadly.io](https://sideloadly.io/) and install Apple's iTunes and iCloud **directly from Apple**, not the Microsoft Store versions.
2. Connect the iPhone/iPad by USB, unlock it, and tap **Trust** if prompted. Make sure it appears in Sideloadly's device menu.
3. Drag `ZoronVideoExporter-unsigned.ipa` into Sideloadly, select your device, and enter the Apple ID you use on that device. A free Apple ID is sufficient for personal sideloading.
4. Click **Start** and complete the Apple ID verification prompts. Sideloadly signs the IPA locally and installs it.
5. On the device, open **Settings > General > VPN & Device Management**, select the developer profile, and tap **Trust**. Then open Zoron Exporter.

Free Apple IDs usually require refreshing the app's signing roughly every seven days and have Apple-imposed app/device limits. Do not share an IPA signed with your personal Apple ID.
