---
title: "Destination Video"
source_url: "https://developer.apple.com/documentation/visionOS/destination-video"
source_identifier: "doc://com.apple.visionOS/documentation/visionOS/destination-video"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "707bf10777cd03e7ef41ee56628940a75e68ca8e713f559eb1f5045f5cf2ad43"
source_etag: "W/\"756dca572d40dff52af92cdd2c40bf01\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Featured samples"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Destination Video

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: Sample Code
- Module: Not specified
- Relevance to Zforge: Contextual. Preserve the cross-platform concept, but prefer the native macOS/AppKit behavior for Zforge.
- Availability: iOS 18.0+, iPadOS 18.0+, Mac Catalyst 18.0+, macOS 15.0+, tvOS 18.0+, visionOS 2.0+, Xcode 16.0+

## Summary

**Official summary:** Leverage SwiftUI to build an immersive media experience in a multiplatform app.

Destination Video is a multiplatform video-playback SwiftUI app for iOS, iPadOS, macOS, tvOS, and visionOS. People get a familiar media-browsing experience navigating the libraryʼs content and playing videos they find interesting. The sample uses the TabView structure in SwiftUI to create an immersive, full-screen browsing experience with rich navigation hierarchy. While the app shares many of its views across platforms, it leverages platform-specific features to create a playback experience native to each platform. For example, it uses the SwiftUI window and scene customization APIs to create a more engaging and natural experience in macOS. This sample also demonstrates how to use SwiftData to persist app data in a SwiftUI app. In visionOS, the sample demonstrates how to play video within an immersive environment configured with Reality Composer Pro. It also uses the Group Activities framework to enable shared viewing experiences. Destination Video uses tab navigation with the sidebarAdaptable style, which…

## Content map

- Overview
- Implement tab navigation
- Customize windows in macOS
- Display horizontally scrollable cards in tvOS
- Present an immersive space
- Play video in a full-window player
- Configure the Spatial Audio experience
- Customize an environment using RealityKit and Reality Composer Pro
- Provide a shared viewing experience
- See Also
- Related samples
- Related articles
- Related videos

## Second-level links

### Overview and featured references

- [SwiftUI](swiftui.md) — Declare the user interface and behavior for your app on every platform. _(local context)_
- [TabView](https://developer.apple.com/documentation/SwiftUI/TabView) — A view that switches between multiple child views using interactive user interface elements. _(Apple Developer; expand on demand)_
- [SwiftData](https://developer.apple.com/documentation/SwiftData) — Write your model code declaratively to add managed persistence and efficient model fetching. _(Apple Developer; expand on demand)_
- [Reality Composer Pro](https://developer.apple.com/documentation/visionos#realitykit-and-reality-composer-pro) — _Apple Developer; expand on demand_
- [Group Activities](https://developer.apple.com/documentation/GroupActivities) — Create app-specific activities your users can share and experience together. _(Apple Developer; expand on demand)_
- [sidebarAdaptable](https://developer.apple.com/documentation/SwiftUI/TabViewStyle/sidebarAdaptable) — A tab bar style that adapts to each platform. _(Apple Developer; expand on demand)_
- [init(selection:content:)](https://developer.apple.com/documentation/SwiftUI/TabView/init(selection:content:)) — Creates a tab view that uses a builder to create and specify selection values for its tabs. _(Apple Developer; expand on demand)_
- [Tab](https://developer.apple.com/documentation/SwiftUI/Tab) — The content for a tab and the tab’s associated tab item in a tab view. _(Apple Developer; expand on demand)_
- [init(_:systemImage:value:content:)](https://developer.apple.com/documentation/SwiftUI/Tab/init(_:systemImage:value:content:)) — Creates a tab that the tab view presents when the tab view’s selection matches the tab’s value using a system image for the tab’s… _(Apple Developer; expand on demand)_
- [TabSection](https://developer.apple.com/documentation/SwiftUI/TabSection) — A container that you can use to add hierarchy within a tab view. _(Apple Developer; expand on demand)_
- [tabViewCustomization(_:)](https://developer.apple.com/documentation/SwiftUI/View/tabViewCustomization(_:)) — Specifies the customizations to apply to the sidebar representation of the tab view. _(Apple Developer; expand on demand)_
- [customizationID(_:)](https://developer.apple.com/documentation/SwiftUI/TabContent/customizationID(_:)) — Sets the identifier for a tab to persist its state. _(Apple Developer; expand on demand)_
- [Enhancing your app’s content with tab navigation](https://developer.apple.com/documentation/SwiftUI/Enhancing-your-app-content-with-tab-navigation) — Keep your app content front and center while providing quick access to navigation using the tab bar. _(Apple Developer; expand on demand)_
- [toolbar(removing:)](https://developer.apple.com/documentation/SwiftUI/View/toolbar(removing:)) — Remove a toolbar item present by default _(Apple Developer; expand on demand)_
- [toolbarBackgroundVisibility(_:for:)](https://developer.apple.com/documentation/SwiftUI/View/toolbarBackgroundVisibility(_:for:)) — Specifies the preferred visibility of backgrounds on a bar managed by SwiftUI. _(Apple Developer; expand on demand)_
- [Customizing window styles and state-restoration behavior in macOS](https://developer.apple.com/documentation/SwiftUI/Customizing-window-styles-and-state-restoration-behavior-in-macOS) — Configure how your app’s windows look and function in macOS to provide an engaging and more coherent experience. _(Apple Developer; expand on demand)_
- [card](https://developer.apple.com/documentation/SwiftUI/PrimitiveButtonStyle/card) — A button style that doesn’t pad the content, and applies a Liquid Glass effect when the button has focus. _(Apple Developer; expand on demand)_
- [scrollClipDisabled(_:)](https://developer.apple.com/documentation/SwiftUI/View/scrollClipDisabled(_:)) — Sets whether a scroll view clips its content to its bounds. _(Apple Developer; expand on demand)_
- [Section](https://developer.apple.com/documentation/SwiftUI/Section) — A container view that you can use to add hierarchy within certain views. _(Apple Developer; expand on demand)_
- [init(content:header:)](https://developer.apple.com/documentation/SwiftUI/Section/init(content:header:)) — Creates a section with a header and the provided section content. _(Apple Developer; expand on demand)_
- [Creating a tvOS media catalog app in SwiftUI](https://developer.apple.com/documentation/SwiftUI/Creating-a-tvOS-media-catalog-app-in-SwiftUI) — Build standard content lockups and rows of content shelves for your tvOS app. _(Apple Developer; expand on demand)_
- [ImmersiveSpace](https://developer.apple.com/documentation/SwiftUI/ImmersiveSpace) — A scene that presents its content in an unbounded space. _(Apple Developer; expand on demand)_
- [AVPlayerViewController](https://developer.apple.com/documentation/AVKit/AVPlayerViewController) — A view controller that displays content from a player and presents a native user interface to control playback. _(Apple Developer; expand on demand)_
- [fullScreenCover(isPresented:onDismiss:content:)](https://developer.apple.com/documentation/SwiftUI/View/fullScreenCover(isPresented:onDismiss:content:)) — Presents a modal view that covers as much of the screen as possible when binding to a Boolean value you provide is true. _(Apple Developer; expand on demand)_
- [AVPlayerViewControllerDelegate](https://developer.apple.com/documentation/AVKit/AVPlayerViewControllerDelegate) — A protocol that defines the methods to implement to respond to player view controller events. _(Apple Developer; expand on demand)_
- [Configuring your app for media playback](https://developer.apple.com/documentation/AVFoundation/configuring-your-app-for-media-playback) — Configure apps to enable standard media playback behavior. _(Apple Developer; expand on demand)_
- [AVAudioSession](https://developer.apple.com/documentation/AVFAudio/AVAudioSession) — An object that communicates to the system how you intend to use audio in your app. _(Apple Developer; expand on demand)_
- [DockingRegionComponent](https://developer.apple.com/documentation/RealityKit/DockingRegionComponent) — A component that docks a scene within a region of an immersive space. _(Apple Developer; expand on demand)_
- [VirtualEnvironmentProbeComponent](https://developer.apple.com/documentation/RealityKit/VirtualEnvironmentProbeComponent) — A component that provides environment lighting for entities you place within the same virtual world. _(Apple Developer; expand on demand)_
- [ReverbComponent](https://developer.apple.com/documentation/RealityKit/ReverbComponent) — A component that defines the reverberation of spatial audio sources. _(Apple Developer; expand on demand)_
- [immersiveEnvironmentPicker(content:)](https://developer.apple.com/documentation/SwiftUI/View/immersiveEnvironmentPicker(content:)) — Add menu items to open immersive spaces from a media player’s environment picker. _(Apple Developer; expand on demand)_
- [Building an immersive media viewing experience](https://developer.apple.com/documentation/visionos/building-an-immersive-media-viewing-experience) — Add a deeper level of immersion to media playback in your app with RealityKit and Reality Composer Pro. _(Apple Developer; expand on demand)_
- [Enabling video reflections in an immersive environment](https://developer.apple.com/documentation/visionos/enabling-video-reflections-in-an-immersive-environment) — Create a more immersive experience by adding video reflections in a custom environment. _(Apple Developer; expand on demand)_
- [AVFoundation](https://developer.apple.com/documentation/AVFoundation) — Work with audiovisual assets, control device cameras, process audio, and configure system audio interactions. _(Apple Developer; expand on demand)_
- [SharePlay](https://developer.apple.com/shareplay/) — _Apple Developer; expand on demand_
- [GroupActivity](https://developer.apple.com/documentation/GroupActivities/GroupActivity) — A type that can advertise your app’s activities to other participants. _(Apple Developer; expand on demand)_
- [GroupSession](https://developer.apple.com/documentation/GroupActivities/GroupSession) — A session for an in-progress activity that synchronizes content among participant devices. _(Apple Developer; expand on demand)_
- [AVPlaybackCoordinator](https://developer.apple.com/documentation/AVFoundation/AVPlaybackCoordinator) — An object that coordinates the playback of players in a connected group. _(Apple Developer; expand on demand)_
- [BOT-anist](https://developer.apple.com/documentation/visionos/bot-anist) — Build a multiplatform app that uses windows, volumes, and animations to create a robot botanist’s greenhouse. _(Apple Developer; expand on demand)_
- [Hello World](https://developer.apple.com/documentation/visionos/world) — Use windows, volumes, and immersive spaces to teach people about the Earth. _(Apple Developer; expand on demand)_
- [Happy Beam](https://developer.apple.com/documentation/visionos/happybeam) — Leverage a Full Space to create a fun game using ARKit. _(Apple Developer; expand on demand)_
- [Diorama](https://developer.apple.com/documentation/visionos/diorama) — Design scenes for your visionOS app using Reality Composer Pro. _(Apple Developer; expand on demand)_
- [Adopting the system player interface in visionOS](https://developer.apple.com/documentation/AVKit/adopting-the-system-player-interface-in-visionos) — Provide an optimized viewing experience for watching 3D video content. _(Apple Developer; expand on demand)_
- [Controlling the transport behavior of a player](https://developer.apple.com/documentation/AVFoundation/controlling-the-transport-behavior-of-a-player) — Play, pause, and seek through a media presentation. _(Apple Developer; expand on demand)_
- [Monitoring playback progress in your app](https://developer.apple.com/documentation/AVFoundation/monitoring-playback-progress-in-your-app) — Observe the playback of a media asset to update your app’s user-interface state. _(Apple Developer; expand on demand)_
- [Trimming and exporting media in visionOS](https://developer.apple.com/documentation/AVKit/trimming-and-exporting-media-in-visionos) — Display standard controls in your app to edit the timeline of the currently playing media. _(Apple Developer; expand on demand)_
- [Elevate your tab and sidebar experience in iPadOS](https://developer.apple.com/videos/play/wwdc2024/10147) — iPadOS 18 introduces a new navigation system that gives people the flexibility to choose between using a tab bar or sidebar. The newly redesigned… _(Apple Developer; expand on demand)_
- [Tailor macOS windows with SwiftUI](https://developer.apple.com/videos/play/wwdc2024/10148) — Make your windows feel tailor-made for macOS. Fine-tune your app’s windows for focused purposes, ease of use, and to express functionality. Use SwiftUI to… _(Apple Developer; expand on demand)_
- [Enhance the immersion of media viewing in custom environments](https://developer.apple.com/videos/play/wwdc2024/10115) — Extend your media viewing experience using Reality Composer Pro components like Docking Region, Reverb, and Virtual Environment Probe. Find out how to further enhance… _(Apple Developer; expand on demand)_
- [Create custom hover effects in visionOS](https://developer.apple.com/videos/play/wwdc2024/10152) — Learn how to develop custom hover effects that update views when people look at them. Find out how to build an expanding button effect… _(Apple Developer; expand on demand)_
- [Create a great spatial playback experience](https://developer.apple.com/videos/play/wwdc2023/10070) — Get ready to support video in your visionOS app! Take a tour of the frameworks and APIs that power video playback and learn how… _(Apple Developer; expand on demand)_
- [Deliver video content for spatial experiences](https://developer.apple.com/videos/play/wwdc2023/10071) — Learn how to prepare and deliver video content for visionOS using HTTP Live Streaming (HLS). Discover the current HLS delivery process for media and… _(Apple Developer; expand on demand)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/visionOS/destination-video)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `707bf10777cd03e7ef41ee56628940a75e68ca8e713f559eb1f5045f5cf2ad43`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
