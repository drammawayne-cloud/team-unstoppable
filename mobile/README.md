# TEAM UNSTOPPABLE — native iPhone and iPad app

Version 0.1.0. SwiftUI + AVPlayer; iOS 17 or later. No third-party runtime packages and no WebView wrapper. Native files are isolated under `mobile/`; existing website files are not replaced.

## Open and run

From the repository root run `python3 mobile/ios/generate_project.py`, then open `mobile/ios/TeamUnstoppable.xcodeproj`. The generator uses only Python's standard library and creates the native project and provisional assets. Alternatively open `mobile/ios/Open-in-Xcode.command` on your Mac. The downloadable handoff ZIP includes the generated project.

Select the TeamUnstoppable scheme and an iPhone simulator, then Run. For a physical iPhone, select the owner's Apple account/team in Signing & Capabilities. Default bundle ID: `com.oneteamunstoppable.app`; availability is not registered or verified. No credentials or signing certificates are included.

## Included

Five native tabs: Home, Radio, The Team, Events and More. Cream, dark and system appearances. Persistent native radio/mix player, background audio capability, lock-screen commands, AirPlay, interruption and headphone-disconnection handling, bounded reconnection, sleep timer and seeking for on-demand mixes.

Search and save profiles; browse and save events/mixes; request one-hour local event reminders; open tickets/videos; prepare a local booking draft and explicitly share it through iOS. Booking requests are not automatically submitted or confirmed.

## Radio and content

The real radio configuration is read from `https://raw.githubusercontent.com/drammawayne-cloud/highlife-radio/main/station.json`. Its existing AzuraCast stream and metadata addresses are bundled as fallback, not invented replacement streams. During authoring the configured sslip.io host could not be resolved from the authoring environment. Successful live audio therefore remains unverified. Playback state is distinct from server metadata status.

Edit `mobile/content.json` on main to publish public read-only app content. The app validates HTTPS links, IDs, schema and dates, then caches the last valid feed. Keep the bundled `ios/TeamUnstoppable/Resources/content.json` in sync for future releases. Data types are defined in `Core/AppModels.swift`.

Initial roster: Dramma Wayne and Short Temper, based on the owner's supplied context. Portraits use initials, not invented photos. Events, mixes and videos are deliberately empty until actual approved material is published. Do not use a YouTube page URL as a direct native audio URL. The TU icon is a provisional original development monogram, not the approved official team logo.

Publishing and administrator authorization should use the shared backend. No fake client-side admin login has been introduced. Accounts, new CMS, push-notification backend, live chat, merchandise checkout and in-app purchases are not implemented.

## Verification

`swift test --package-path mobile/ios` runs 20 model/validation tests. The Team Unstoppable iOS workflow builds on macOS and attempts a simulator launch and five real screenshots. Simulator launch captures are not comprehensive UI-interaction tests. Build success does not establish radio uptime or audio audibility.

A simulator `.app` is not installable on a physical iPhone. This is an iOS/iPadOS implementation; no Android binary is included.

## Before TestFlight / App Store

Authorize the owner's Apple Developer signing team; register the bundle ID and App Store Connect record. Approve/replace the development icon and profile copy. Verify radio DNS, TLS, audio and media rights. Publish approved support and privacy URLs, add actual catalog/event content, test on physical devices (locked screen, Wi-Fi/cellular transitions, phone interruption, AirPlay, headphones, VoiceOver and large text). Archive with a currently accepted Apple SDK and submit to TestFlight/App Review.

No signed IPA or App Store submission is included. GitHub CI builds unsigned simulator binaries only.

## Privacy

No tracking, analytics, advertising SDK or login. Saved items, preferences and booking drafts are local. Ordinary network requests go to GitHub and configured radio providers. Event notifications require user permission. PrivacyInfo.xcprivacy declares app-owned UserDefaults access (CA92.1) and no app-collected data. Review the final declarations against the shipped app and the owner's actual server practices before submission.
