# Swaap

A private, personal photo-transfer experience between an iPhone and a Mac.

Swaap aims to make sending a photo feel physical: choose a photo, drag or fling it toward the edge of the iPhone screen, and watch it arrive on the paired Mac with a matching transition.

## Product direction

- Native SwiftUI iOS app for photo selection and the send gesture.
- Native SwiftUI macOS companion for receiving files.
- Nearby-device discovery over Bluetooth Low Energy.
- Direct photo transfer over the local network; no cloud relay, account system, VPS, or public upload service.
- Coordinated send/receive animations designed specifically for Swaap.

## Platform constraints

Swaap cannot take over gestures inside Apple's Photos app or reproduce Apple's private system-level NameDrop behavior. Photo selection will use Apple's Photos picker inside Swaap, and the custom drag-to-send interaction will happen in the Swaap app.

## Development

The initial implementation will target the user's iPhone and Mac. The iOS and macOS apps will be developed as native Swift projects.

## Status

Repository initialized. MVP implementation is in progress on the `feature/swaap-mvp` branch.
