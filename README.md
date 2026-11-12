# Swaap

A personal, native photo-transfer app for an iPhone and a Mac.

Choose a photo in the iPhone app, drag it toward either edge, and send it directly to the Mac companion. The Mac receives the file and saves it in `Downloads/Swaap`.

## Apps

- **Swaap-iOS** — SwiftUI photo picker, draggable photo card, and nearby sender.
- **Swaap-Mac** — SwiftUI receiver that advertises itself to the iPhone and saves incoming photos.
- **Shared/TransferService.swift** — encrypted Multipeer Connectivity session shared by both apps.

## How transfer works

Swaap uses Apple's Multipeer Connectivity framework. It discovers the companion nearby and transfers files over the available peer-to-peer transport (Bluetooth and/or local Wi-Fi). No cloud relay, external server, account, or subscription is involved.

## Requirements

- Xcode 16 or newer recommended
- iOS 17 or newer
- macOS 14 or newer
- Both devices with Wi-Fi and Bluetooth enabled; keep them reasonably close and on the same local network for the most reliable discovery

## Generate the Xcode project

This repository uses XcodeGen to keep the project definition readable.

```bash
brew install xcodegen
git clone https://github.com/ayaneklectik/swaap.git
cd swaap
git checkout feature/swaap-mvp
xcodegen generate
open Swaap.xcodeproj
```

Select the **Swaap-Mac** scheme and run it on your Mac first. Then select **Swaap-iOS**, choose your iPhone as the run destination, set your Apple Development signing team in Xcode, and run it on the phone. Approve the local-network permission prompts on both devices.

## First-run flow

1. Open Swaap on the Mac and leave it running.
2. Open Swaap on the iPhone. It searches for the Mac automatically.
3. Choose a photo from the Photos picker.
4. Drag the photo card decisively to the left or right edge.
5. The Mac receives it and saves it under `Downloads/Swaap`.

## Current MVP scope

- Native iOS and macOS app targets
- Photos picker on iPhone
- Edge-drag send interaction with a fling animation
- Nearby discovery and encrypted peer session
- Direct file transfer and automatic save on Mac
- No cloud storage or public backend

## Known platform limitation

iOS does not let third-party apps intercept gestures inside Apple's Photos app or imitate the private system-level NameDrop interaction. The custom gesture therefore happens inside Swaap, after choosing a photo with Apple's system Photos picker.

## Development branch

All implementation work is on `feature/swaap-mvp`. The `main` branch is kept as the bootstrap branch.
