---
title: "Technology-specific views"
source_url: "https://developer.apple.com/documentation/swiftui/technology-specific-views"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Technology-specific-views"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "8b0f4aedad33e508dd9605297302cf1de76ee7253ca0d81e8c5e088007a49ee8"
source_etag: "W/\"ca44b939da239f04aef4d2780165acc8\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Framework integration"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Technology-specific views

Context normalized for quick retrieval. The official URL and hash allow changes to be verified; this file does not replace the source.

## Quick reference

- Role: API Collection
- Module: SwiftUI
- Relevance to Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Summary

**Official summary:** Use SwiftUI views that other Apple frameworks provide.

To access SwiftUI views that another framework defines, import both SwiftUI and the other framework into the file where you use the view. You can find the framework to import by looking at the availability information on the view’s documentation page. For example, to use the Map view in your app, import both SwiftUI and MapKit. For design guidance, see Technologies in the Human Interface Guidelines.

## Content map

- Overview

## Second-level links

### Overview and featured references

- [Map](https://developer.apple.com/documentation/MapKit/Map) — A view that displays an embedded map interface. _(Apple Developer; expand on demand)_
- [Technologies](https://developer.apple.com/design/Human-Interface-Guidelines/technologies) — Discover the Apple technologies, features, and services you can integrate into your app or game. _(Apple Developer; expand on demand)_

### Displaying web content

- [WebView](https://developer.apple.com/documentation/WebKit/WebView-swift.struct) — A view that displays some web content. _(Apple Developer; expand on demand)_
- [WebPage](https://developer.apple.com/documentation/WebKit/WebPage) — An object that controls and manages the behavior of interactive web content. _(Apple Developer; expand on demand)_
- [onWebViewImmersiveEnvironmentRequest(shouldAllow:present:dismiss:)](https://developer.apple.com/documentation/swiftui/view/onwebviewimmersiveenvironmentrequest(shouldallow:present:dismiss:)) — Manages the lifecycle of immersive environments requested by websites. _(Apple Developer; expand on demand)_
- [webViewBackForwardNavigationGestures(_:)](https://developer.apple.com/documentation/swiftui/view/webviewbackforwardnavigationgestures(_:)) — Determines whether horizontal swipe gestures trigger backward and forward page navigation. _(Apple Developer; expand on demand)_
- [webViewContentBackground(_:)](https://developer.apple.com/documentation/swiftui/view/webviewcontentbackground(_:)) — Specifies the visibility of the webpage’s natural background color within this view. _(Apple Developer; expand on demand)_
- [webViewContextMenu(menu:)](https://developer.apple.com/documentation/swiftui/view/webviewcontextmenu(menu:)) — Adds an item-based context menu to a WebView, replacing the default set of context menu items. _(Apple Developer; expand on demand)_
- [webViewElementFullscreenBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/webviewelementfullscreenbehavior(_:)) — Determines whether a web view can display content full screen. _(Apple Developer; expand on demand)_
- [webViewLinkPreviews(_:)](https://developer.apple.com/documentation/swiftui/view/webviewlinkpreviews(_:)) — Determines whether pressing a link displays a preview of the destination for the link. _(Apple Developer; expand on demand)_
- [webViewMagnificationGestures(_:)](https://developer.apple.com/documentation/swiftui/view/webviewmagnificationgestures(_:)) — Determines whether magnify gestures change the view’s magnification. _(Apple Developer; expand on demand)_
- [webViewOnScrollGeometryChange(for:of:action:)](https://developer.apple.com/documentation/swiftui/view/webviewonscrollgeometrychange(for:of:action:)) — Adds an action to be performed when a value, created from a scroll geometry, changes. _(Apple Developer; expand on demand)_
- [webViewScrollInputBehavior(_:for:)](https://developer.apple.com/documentation/swiftui/view/webviewscrollinputbehavior(_:for:)) — Enables or disables scrolling in web views when using particular inputs. _(Apple Developer; expand on demand)_
- [webViewScrollPosition(_:)](https://developer.apple.com/documentation/swiftui/view/webviewscrollposition(_:)) — Associates a binding to a scroll position with the web view. _(Apple Developer; expand on demand)_
- [webViewTextSelection(_:)](https://developer.apple.com/documentation/swiftui/view/webviewtextselection(_:)) — Determines whether to allow people to select or otherwise interact with text. _(Apple Developer; expand on demand)_

### Accessing Apple Pay and Wallet

- [PayWithApplePayButton](https://developer.apple.com/documentation/PassKit/PayWithApplePayButton) — A type that provides a button to pay with Apple pay. _(Apple Developer; expand on demand)_
- [AddPassToWalletButton](https://developer.apple.com/documentation/PassKit/AddPassToWalletButton) — A type that provides a button that enables people to add a new or existing pass to Apple Wallet. _(Apple Developer; expand on demand)_
- [VerifyIdentityWithWalletButton](https://developer.apple.com/documentation/PassKit/VerifyIdentityWithWalletButton) — A type that displays a button to present the identity verification flow. _(Apple Developer; expand on demand)_
- [addOrderToWalletButtonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/addordertowalletbuttonstyle(_:)) — Sets the button’s style. _(Apple Developer; expand on demand)_
- [addPassToWalletButtonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/addpasstowalletbuttonstyle(_:)) — Sets the style to be used by the button. (see ). _(Apple Developer; expand on demand)_
- [onApplePayCouponCodeChange(perform:)](https://developer.apple.com/documentation/swiftui/view/onapplepaycouponcodechange(perform:)) — Called when a user has entered or updated a coupon code. This is required if the user is being asked to provide a coupon… _(Apple Developer; expand on demand)_
- [onApplePayPaymentMethodChange(perform:)](https://developer.apple.com/documentation/swiftui/view/onapplepaypaymentmethodchange(perform:)) — Called when a payment method has changed and asks for an update payment request. If this modifier isn’t provided Wallet will assume the payment… _(Apple Developer; expand on demand)_
- [onApplePayShippingContactChange(perform:)](https://developer.apple.com/documentation/swiftui/view/onapplepayshippingcontactchange(perform:)) — Called when a user selected a shipping address. This is required if the user is being asked to provide a shipping contact. _(Apple Developer; expand on demand)_
- [onApplePayShippingMethodChange(perform:)](https://developer.apple.com/documentation/swiftui/view/onapplepayshippingmethodchange(perform:)) — Called when a user selected a shipping method. This is required if the user is being asked to provide a shipping method. _(Apple Developer; expand on demand)_
- [payLaterViewAction(_:)](https://developer.apple.com/documentation/swiftui/view/paylaterviewaction(_:)) — Sets the action on the PayLaterView. See . _(Apple Developer; expand on demand)_
- [payLaterViewDisplayStyle(_:)](https://developer.apple.com/documentation/swiftui/view/paylaterviewdisplaystyle(_:)) — Sets the display style on the PayLaterView. See . _(Apple Developer; expand on demand)_
- [payWithApplePayButtonDisableCardArt()](https://developer.apple.com/documentation/swiftui/view/paywithapplepaybuttondisablecardart()) — Sets the features that should be allowed to show on the payment buttons. _(Apple Developer; expand on demand)_
- [payWithApplePayButtonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/paywithapplepaybuttonstyle(_:)) — Sets the style to be used by the button. (see ). _(Apple Developer; expand on demand)_
- [verifyIdentityWithWalletButtonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/verifyidentitywithwalletbuttonstyle(_:)) — Sets the style to be used by the button. (see ). _(Apple Developer; expand on demand)_
- [AsyncShareablePassConfiguration](https://developer.apple.com/documentation/PassKit/AsyncShareablePassConfiguration) — _Apple Developer; expand on demand_
- [transactionTask(_:action:)](https://developer.apple.com/documentation/swiftui/view/transactiontask(_:action:)) — Provides a task to perform before this view appears _(Apple Developer; expand on demand)_

### Authorizing and authenticating

- [LocalAuthenticationView](https://developer.apple.com/documentation/LocalAuthentication/LocalAuthenticationView) — A SwiftUI view that displays an authentication interface. _(Apple Developer; expand on demand)_
- [SignInWithAppleButton](https://developer.apple.com/documentation/AuthenticationServices/SignInWithAppleButton) — A SwiftUI view that creates the Sign in with Apple button for display. _(Apple Developer; expand on demand)_
- [signInWithAppleButtonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/signinwithapplebuttonstyle(_:)) — Sets the style used for displaying the control (see ). _(Apple Developer; expand on demand)_
- [authorizationController](https://developer.apple.com/documentation/swiftui/environmentvalues/authorizationcontroller) — A value provided in the SwiftUI environment that views can use to perform authorization requests. _(Apple Developer; expand on demand)_
- [webAuthenticationSession](https://developer.apple.com/documentation/swiftui/environmentvalues/webauthenticationsession) — A value provided in the SwiftUI environment that views can use to authenticate a user through a web service. _(Apple Developer; expand on demand)_

### Configuring Family Sharing

- [FamilyActivityPicker](https://developer.apple.com/documentation/FamilyControls/FamilyActivityPicker) — A view in which users specify applications, web domains, and categories without revealing their choices to the app. _(Apple Developer; expand on demand)_
- [familyActivityPicker(isPresented:selection:)](https://developer.apple.com/documentation/swiftui/view/familyactivitypicker(ispresented:selection:)) — Presents an activity picker view as a sheet. _(Apple Developer; expand on demand)_
- [familyActivityPicker(headerText:footerText:isPresented:selection:)](https://developer.apple.com/documentation/swiftui/view/familyactivitypicker(headertext:footertext:ispresented:selection:)) — Presents an activity picker view as a sheet. _(Apple Developer; expand on demand)_
- [familyActivityPicker(title:headerText:footerText:isPresented:selection:)](https://developer.apple.com/documentation/swiftui/view/familyactivitypicker(title:headertext:footertext:ispresented:selection:)) — Present an activity picker sheet for selecting apps and websites to manage. _(Apple Developer; expand on demand)_

### Reporting on device activity

- [DeviceActivityReport](https://developer.apple.com/documentation/DeviceActivity/DeviceActivityReport) — A view that reports the user’s application, category, and web domain activity in a privacy-preserving way. _(Apple Developer; expand on demand)_

### Working with managed devices

- [managedContentStyle(_:)](https://developer.apple.com/documentation/swiftui/view/managedcontentstyle(_:)) — Applies a managed content style to the view. _(Apple Developer; expand on demand)_
- [automatedDeviceEnrollmentAddition(isPresented:)](https://developer.apple.com/documentation/swiftui/view/automateddeviceenrollmentaddition(ispresented:)) — Presents a modal view that enables users to add devices to their organization. _(Apple Developer; expand on demand)_

### Creating graphics

- [Chart](https://developer.apple.com/documentation/Charts/Chart) — A SwiftUI view that displays a chart. _(Apple Developer; expand on demand)_
- [SceneView](https://developer.apple.com/documentation/SceneKit/SceneView) — A SwiftUI view for displaying 3D SceneKit content. _(Apple Developer; expand on demand)_
- [SpriteView](https://developer.apple.com/documentation/SpriteKit/SpriteView) — A SwiftUI view that renders a SpriteKit scene. _(Apple Developer; expand on demand)_

### Getting location information

- [LocationButton](https://developer.apple.com/documentation/CoreLocationUI/LocationButton) — A SwiftUI button that grants one-time location authorization. _(Apple Developer; expand on demand)_
- [mapStyle(_:)](https://developer.apple.com/documentation/swiftui/view/mapstyle(_:)) — Specifies the map style to be used. _(Apple Developer; expand on demand)_
- [mapScope(_:)](https://developer.apple.com/documentation/swiftui/view/mapscope(_:)) — Creates a mapScope that SwiftUI uses to connect map controls to an associated map. _(Apple Developer; expand on demand)_
- [mapFeatureSelectionDisabled(_:)](https://developer.apple.com/documentation/swiftui/view/mapfeatureselectiondisabled(_:)) — Specifies which map features should have selection disabled. _(Apple Developer; expand on demand)_
- [mapFeatureSelectionAccessory(_:)](https://developer.apple.com/documentation/swiftui/view/mapfeatureselectionaccessory(_:)) — Specifies the selection accessory to display for a _(Apple Developer; expand on demand)_
- [mapFeatureSelectionContent(content:)](https://developer.apple.com/documentation/swiftui/view/mapfeatureselectioncontent(content:)) — Specifies a custom presentation for the currently selected feature. _(Apple Developer; expand on demand)_
- [mapControls(_:)](https://developer.apple.com/documentation/swiftui/view/mapcontrols(_:)) — Configures all views in the associated environment to have standard size and position controls _(Apple Developer; expand on demand)_
- [mapControlVisibility(_:)](https://developer.apple.com/documentation/swiftui/view/mapcontrolvisibility(_:)) — Configures all Map controls in the environment to have the specified visibility _(Apple Developer; expand on demand)_
- [mapCameraKeyframeAnimator(trigger:keyframes:)](https://developer.apple.com/documentation/swiftui/view/mapcamerakeyframeanimator(trigger:keyframes:)) — Uses the given keyframes to animate the camera of a when the given trigger value changes. _(Apple Developer; expand on demand)_
- [lookAroundViewer(isPresented:scene:allowsNavigation:showsRoadLabels:pointsOfInterest:onDismiss:)](https://developer.apple.com/documentation/swiftui/view/lookaroundviewer(ispresented:scene:allowsnavigation:showsroadlabels:pointsofinterest:ondismiss:)) — _Apple Developer; expand on demand_
- [lookAroundViewer(isPresented:initialScene:allowsNavigation:showsRoadLabels:pointsOfInterest:onDismiss:)](https://developer.apple.com/documentation/swiftui/view/lookaroundviewer(ispresented:initialscene:allowsnavigation:showsroadlabels:pointsofinterest:ondismiss:)) — _Apple Developer; expand on demand_
- [onMapCameraChange(frequency:_:)](https://developer.apple.com/documentation/swiftui/view/onmapcamerachange(frequency:_:)) — Performs an action when Map camera framing changes _(Apple Developer; expand on demand)_
- [mapItemDetailPopover(isPresented:item:displaysMap:attachmentAnchor:)](https://developer.apple.com/documentation/swiftui/view/mapitemdetailpopover(ispresented:item:displaysmap:attachmentanchor:)) — Presents a map item detail popover. _(Apple Developer; expand on demand)_
- [mapItemDetailPopover(isPresented:item:displaysMap:attachmentAnchor:arrowEdge:)](https://developer.apple.com/documentation/swiftui/view/mapitemdetailpopover(ispresented:item:displaysmap:attachmentanchor:arrowedge:)) — Presents a map item detail popover. _(Apple Developer; expand on demand)_
- [mapItemDetailPopover(item:displaysMap:attachmentAnchor:)](https://developer.apple.com/documentation/swiftui/view/mapitemdetailpopover(item:displaysmap:attachmentanchor:)) — Presents a map item detail popover. _(Apple Developer; expand on demand)_
- [mapItemDetailPopover(item:displaysMap:attachmentAnchor:arrowEdge:)](https://developer.apple.com/documentation/swiftui/view/mapitemdetailpopover(item:displaysmap:attachmentanchor:arrowedge:)) — Presents a map item detail popover. _(Apple Developer; expand on demand)_
- [mapItemDetailSheet(isPresented:item:displaysMap:)](https://developer.apple.com/documentation/swiftui/view/mapitemdetailsheet(ispresented:item:displaysmap:)) — Presents a map item detail sheet. _(Apple Developer; expand on demand)_
- [mapItemDetailSheet(item:displaysMap:)](https://developer.apple.com/documentation/swiftui/view/mapitemdetailsheet(item:displaysmap:)) — Presents a map item detail sheet. _(Apple Developer; expand on demand)_

### Displaying media

- [CameraView](https://developer.apple.com/documentation/HomeKit/CameraView) — A SwiftUI view into which a video stream or an image snapshot is rendered. _(Apple Developer; expand on demand)_
- [NowPlayingView](https://developer.apple.com/documentation/WatchKit/NowPlayingView) — A view that displays the system’s Now Playing interface so that the user can control audio. _(Apple Developer; expand on demand)_
- [VideoPlayer](https://developer.apple.com/documentation/AVKit/VideoPlayer) — A view that displays content from a player and a native user interface to control playback. _(Apple Developer; expand on demand)_
- [continuityDevicePicker(isPresented:onDidConnect:)](https://developer.apple.com/documentation/swiftui/view/continuitydevicepicker(ispresented:ondidconnect:)) — A should be used to discover and connect nearby continuity device through a button interface or other form of activation. On tvOS, this presents… _(Apple Developer; expand on demand)_
- [cameraAnchor(isActive:)](https://developer.apple.com/documentation/swiftui/view/cameraanchor(isactive:)) — Specifies the view that should act as the virtual camera for Apple Vision Pro 2D Persona stream. _(Apple Developer; expand on demand)_
- [foveatedStreamingPauseSheet(session:)](https://developer.apple.com/documentation/swiftui/view/foveatedstreamingpausesheet(session:)) — Tells the system to present a sheet with controls for resuming or ending the foveated streaming session when it pauses. _(Apple Developer; expand on demand)_

### Supporting Group Activities

- [groupActivityAssociation(_:)](https://developer.apple.com/documentation/swiftui/view/groupactivityassociation(_:)) — Specifies how a view should be associated with the current SharePlay group activity. _(Apple Developer; expand on demand)_

### Selecting photos

- [PhotosPicker](https://developer.apple.com/documentation/PhotosUI/PhotosPicker) — A view that displays a Photos picker for choosing assets from the photo library. _(Apple Developer; expand on demand)_
- [photosPicker(isPresented:selection:matching:preferredItemEncoding:)](https://developer.apple.com/documentation/swiftui/view/photospicker(ispresented:selection:matching:preferreditemencoding:)) — Presents a Photos picker that selects a . _(Apple Developer; expand on demand)_
- [photosPicker(isPresented:selection:matching:preferredItemEncoding:photoLibrary:)](https://developer.apple.com/documentation/swiftui/view/photospicker(ispresented:selection:matching:preferreditemencoding:photolibrary:)) — Presents a Photos picker that selects a from a given photo library. _(Apple Developer; expand on demand)_
- [photosPicker(isPresented:selection:maxSelectionCount:selectionBehavior:matching:preferredItemEncoding:)](https://developer.apple.com/documentation/swiftui/view/photospicker(ispresented:selection:maxselectioncount:selectionbehavior:matching:preferreditemencoding:)) — Presents a Photos picker that selects a collection of . _(Apple Developer; expand on demand)_
- [photosPicker(isPresented:selection:maxSelectionCount:selectionBehavior:matching:preferredItemEncoding:photoLibrary:)](https://developer.apple.com/documentation/swiftui/view/photospicker(ispresented:selection:maxselectioncount:selectionbehavior:matching:preferreditemencoding:photolibrary:)) — Presents a Photos picker that selects a collection of from a given photo library. _(Apple Developer; expand on demand)_
- [photosPickerAccessoryVisibility(_:edges:)](https://developer.apple.com/documentation/swiftui/view/photospickeraccessoryvisibility(_:edges:)) — Sets the accessory visibility of the Photos picker. Accessories include anything between the content and the edge, like the navigation bar or the sidebar. _(Apple Developer; expand on demand)_
- [photosPickerDisabledCapabilities(_:)](https://developer.apple.com/documentation/swiftui/view/photospickerdisabledcapabilities(_:)) — Disables capabilities of the Photos picker. _(Apple Developer; expand on demand)_
- [photosPickerSearchText(_:)](https://developer.apple.com/documentation/swiftui/view/photospickersearchtext(_:)) — Sets search text of the Photos picker. _(Apple Developer; expand on demand)_
- [photosPickerStyle(_:)](https://developer.apple.com/documentation/swiftui/view/photospickerstyle(_:)) — Sets the mode of the Photos picker. _(Apple Developer; expand on demand)_
- [photosPickerMetadataOptions(_:)](https://developer.apple.com/documentation/swiftui/view/photospickermetadataoptions(_:)) — Sets metadata options for the Photos picker. _(Apple Developer; expand on demand)_
- [photosSharedAlbumCreationSheet(isPresented:defaultTitle:defaultSharingPolicy:photoLibrary:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/photossharedalbumcreationsheet(ispresented:defaulttitle:defaultsharingpolicy:photolibrary:oncompletion:)) — Presents a view for allowing the user to create a new shared album. _(Apple Developer; expand on demand)_
- [photosSharedAlbumCustomizationSheet(isPresented:albumIdentifier:photoLibrary:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/photossharedalbumcustomizationsheet(ispresented:albumidentifier:photolibrary:oncompletion:)) — Presents a view for allowing the user to customize a specified shared album. _(Apple Developer; expand on demand)_
- [photosSharedAlbumPostingSheet(isPresented:items:defaultAlbumIdentifier:photoLibrary:completion:)](https://developer.apple.com/documentation/swiftui/view/photossharedalbumpostingsheet(ispresented:items:defaultalbumidentifier:photolibrary:completion:)) — Presents an “Add to Shared Album” sheet that allows the user to post the given items to a shared album. _(Apple Developer; expand on demand)_

### Generating images

- [imagePlaygroundGenerationStyle(_:in:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundgenerationstyle(_:in:)) — Sets the selected and allowed styles to use when displaying the image generation sheet. _(Apple Developer; expand on demand)_
- [imagePlaygroundOptions(_:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundoptions(_:)) — Sets the options to use when generating an image. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concept:sourceImage:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concept:sourceimage:oncompletion:oncancellation:)) — Presents the system sheet to create an image using the specified string and optional starting image. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concept:sourceImage:onCompletion:onAdaptiveImageGlyphCreation:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concept:sourceimage:oncompletion:onadaptiveimageglyphcreation:oncancellation:)) — Presents the system sheet to create images from the specified input. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concept:sourceImageURL:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concept:sourceimageurl:oncompletion:oncancellation:)) — Presents the system sheet to create an image using the specified string and image URL. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concept:sourceImageURL:onCompletion:onAdaptiveImageGlyphCreation:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concept:sourceimageurl:oncompletion:onadaptiveimageglyphcreation:oncancellation:)) — Presents the system sheet to create an image or Genmoji using the specified string and image URL. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concepts:sourceImage:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concepts:sourceimage:oncompletion:oncancellation:)) — Presents the system sheet to create an image using one or more concepts and an optional starting image. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concepts:sourceImage:onCompletion:onAdaptiveImageGlyphCreation:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concepts:sourceimage:oncompletion:onadaptiveimageglyphcreation:oncancellation:)) — Presents the system sheet to create an image or Genmoji using one or more concepts and an optional starting image. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concepts:sourceImageURL:onCompletion:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concepts:sourceimageurl:oncompletion:oncancellation:)) — Presents the system sheet to create an image using one or more concepts and an image URL. _(Apple Developer; expand on demand)_
- [imagePlaygroundSheet(isPresented:concepts:sourceImageURL:onCompletion:onAdaptiveImageGlyphCreation:onCancellation:)](https://developer.apple.com/documentation/swiftui/view/imageplaygroundsheet(ispresented:concepts:sourceimageurl:oncompletion:onadaptiveimageglyphcreation:oncancellation:)) — Presents the system sheet to create an image or Genmoji using one or more concepts and an image URL. _(Apple Developer; expand on demand)_

### Previewing content

- [quickLookPreview(_:)](https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:)) — Presents a Quick Look preview of the contents of a single URL. _(Apple Developer; expand on demand)_
- [quickLookPreview(_:in:)](https://developer.apple.com/documentation/swiftui/view/quicklookpreview(_:in:)) — Presents a Quick Look preview of the URLs you provide. _(Apple Developer; expand on demand)_

### Interacting with networked devices

- [DevicePicker](https://developer.apple.com/documentation/DeviceDiscoveryUI/DevicePicker) — A SwiftUI view that displays other devices on the network, and creates an encrypted connection to a copy of your app running on that… _(Apple Developer; expand on demand)_
- [devicePickerSupports](https://developer.apple.com/documentation/swiftui/environmentvalues/devicepickersupports) — Checks for support to present a DevicePicker. _(Apple Developer; expand on demand)_

### Configuring a Live Activity

- [activitySystemActionForegroundColor(_:)](https://developer.apple.com/documentation/swiftui/view/activitysystemactionforegroundcolor(_:)) — The text color for the auxiliary action button that the system shows next to a Live Activity on the Lock Screen. _(Apple Developer; expand on demand)_
- [activityBackgroundTint(_:)](https://developer.apple.com/documentation/swiftui/view/activitybackgroundtint(_:)) — Sets the tint color for the background of a Live Activity that appears on the Lock Screen. _(Apple Developer; expand on demand)_
- [isActivityFullscreen](https://developer.apple.com/documentation/swiftui/environmentvalues/isactivityfullscreen) — A Boolean value that indicates whether the Live Activity appears in a full-screen presentation. _(Apple Developer; expand on demand)_
- [activityFamily](https://developer.apple.com/documentation/swiftui/environmentvalues/activityfamily) — The size family of the current Live Activity. _(Apple Developer; expand on demand)_

### Interacting with the App Store and Apple Music

- [appStoreOverlay(isPresented:configuration:)](https://developer.apple.com/documentation/swiftui/view/appstoreoverlay(ispresented:configuration:)) — Presents a StoreKit overlay when a given condition is true. _(Apple Developer; expand on demand)_
- [manageSubscriptionsSheet(isPresented:)](https://developer.apple.com/documentation/swiftui/view/managesubscriptionssheet(ispresented:)) — _Apple Developer; expand on demand_
- [refundRequestSheet(for:isPresented:onDismiss:)](https://developer.apple.com/documentation/swiftui/view/refundrequestsheet(for:ispresented:ondismiss:)) — Display the refund request sheet for the given transaction. _(Apple Developer; expand on demand)_
- [offerCodeRedemption(options:isPresented:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/offercoderedemption(options:ispresented:oncompletion:)) — Presents a sheet that enables customers to redeem offer codes that you configure in App Store Connect. _(Apple Developer; expand on demand)_
- [musicPicker(isPresented:title:selection:)](https://developer.apple.com/documentation/swiftui/view/musicpicker(ispresented:title:selection:)) — Presents a music picker to select items from the Apple Music catalog and the user’s music library. _(Apple Developer; expand on demand)_
- [musicSubscriptionOffer(isPresented:options:onLoadCompletion:)](https://developer.apple.com/documentation/swiftui/view/musicsubscriptionoffer(ispresented:options:onloadcompletion:)) — Initiates the process of presenting a sheet with subscription offers for Apple Music when the binding is . _(Apple Developer; expand on demand)_
- [currentEntitlementTask(for:priority:action:)](https://developer.apple.com/documentation/swiftui/view/currententitlementtask(for:priority:action:)) — Declares the view as dependent on the entitlement of an In-App Purchase product, and returns a modified view. _(Apple Developer; expand on demand)_
- [inAppPurchaseOptions(_:)](https://developer.apple.com/documentation/swiftui/view/inapppurchaseoptions(_:)) — Add a function to call before initiating a purchase from StoreKit view within this view, providing a set of options for the purchase. _(Apple Developer; expand on demand)_
- [manageSubscriptionsSheet(isPresented:subscriptionGroupID:)](https://developer.apple.com/documentation/swiftui/view/managesubscriptionssheet(ispresented:subscriptiongroupid:)) — _Apple Developer; expand on demand_
- [onInAppPurchaseCompletion(perform:)](https://developer.apple.com/documentation/swiftui/view/oninapppurchasecompletion(perform:)) — Add an action to perform when a purchase initiated from a StoreKit view within this view completes. _(Apple Developer; expand on demand)_
- [onInAppPurchaseStart(perform:)](https://developer.apple.com/documentation/swiftui/view/oninapppurchasestart(perform:)) — Add an action to perform when a user triggers the purchase button on a StoreKit view within this view. _(Apple Developer; expand on demand)_
- [productIconBorder()](https://developer.apple.com/documentation/swiftui/view/producticonborder()) — Adds a standard border to an in-app purchase product’s icon . _(Apple Developer; expand on demand)_
- [productViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/productviewstyle(_:)) — Sets the style for In-App Purchase product views within a view. _(Apple Developer; expand on demand)_
- [productDescription(_:)](https://developer.apple.com/documentation/swiftui/view/productdescription(_:)) — Configure the visibility of labels displaying an in-app purchase product description within the view. _(Apple Developer; expand on demand)_
- [storeButton(_:for:)](https://developer.apple.com/documentation/swiftui/view/storebutton(_:for:)) — Specifies the visibility of auxiliary buttons that store view and subscription store view instances may use. _(Apple Developer; expand on demand)_
- [storeProductTask(for:priority:action:)](https://developer.apple.com/documentation/swiftui/view/storeproducttask(for:priority:action:)) — Declares the view as dependent on an In-App Purchase product and returns a modified view. _(Apple Developer; expand on demand)_
- [storeProductsTask(for:priority:action:)](https://developer.apple.com/documentation/swiftui/view/storeproductstask(for:priority:action:)) — Declares the view as dependent on a collection of In-App Purchase products and returns a modified view. _(Apple Developer; expand on demand)_
- [subscriptionStatusTask(for:priority:action:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstatustask(for:priority:action:)) — Declares the view as dependent on the status of an auto-renewable subscription group, and returns a modified view. _(Apple Developer; expand on demand)_
- [subscriptionStoreButtonLabel(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorebuttonlabel(_:)) — Configures subscription store view instances within a view to use the provided button label. _(Apple Developer; expand on demand)_
- [subscriptionStoreControlIcon(icon:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorecontrolicon(icon:)) — Sets a view to use to decorate individual subscription options within a subscription store view. _(Apple Developer; expand on demand)_
- [subscriptionStoreControlStyle(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorecontrolstyle(_:)) — Sets the control style for subscription store views within a view. _(Apple Developer; expand on demand)_
- [subscriptionStoreControlStyle(_:placement:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorecontrolstyle(_:placement:)) — Sets the control style and control placement for subscription store views within a view. _(Apple Developer; expand on demand)_
- [subscriptionStoreOptionGroupStyle(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstoreoptiongroupstyle(_:)) — Sets the style subscription store views within this view use to display groups of subscription options. _(Apple Developer; expand on demand)_
- [subscriptionStorePickerItemBackground(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorepickeritembackground(_:)) — Sets the background style for picker items of the subscription store view instances within a view. _(Apple Developer; expand on demand)_
- [subscriptionStorePickerItemBackground(_:in:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorepickeritembackground(_:in:)) — Sets the background shape and style for subscription store view picker items within a view. _(Apple Developer; expand on demand)_
- [subscriptionStorePolicyDestination(for:destination:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorepolicydestination(for:destination:)) — Configures a view as the destination for a policy button action in subscription store views. _(Apple Developer; expand on demand)_
- [subscriptionStorePolicyDestination(url:for:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorepolicydestination(url:for:)) — Configures a URL as the destination for a policy button action in subscription store views. _(Apple Developer; expand on demand)_
- [subscriptionStorePolicyForegroundStyle(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorepolicyforegroundstyle(_:)) — Sets the style for the terms of service and privacy policy buttons within a subscription store view. _(Apple Developer; expand on demand)_
- [subscriptionStorePolicyForegroundStyle(_:_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorepolicyforegroundstyle(_:_:)) — Sets the primary and secondary style for the terms of service and privacy policy buttons within a subscription store view. _(Apple Developer; expand on demand)_
- [subscriptionStoreSignInAction(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstoresigninaction(_:)) — Adds an action to perform when a person uses the sign-in button on a subscription store view within a view. _(Apple Developer; expand on demand)_
- [subscriptionStoreControlBackground(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionstorecontrolbackground(_:)) — Set a standard effect to use for the background of subscription store view controls within the view. _(Apple Developer; expand on demand)_
- [subscriptionPromotionalOffer(offer:compactJWS:)](https://developer.apple.com/documentation/swiftui/view/subscriptionpromotionaloffer(offer:compactjws:)) — Selects a promotional offer to apply to a purchase a customer makes from a subscription store view. _(Apple Developer; expand on demand)_
- [subscriptionIntroductoryOffer(applyOffer:compactJWS:)](https://developer.apple.com/documentation/swiftui/view/subscriptionintroductoryoffer(applyoffer:compactjws:)) — Selects the introductory offer eligibility preference to apply to a purchase a customer makes from a subscription store view. _(Apple Developer; expand on demand)_
- [subscriptionOfferViewButtonVisibility(_:for:)](https://developer.apple.com/documentation/swiftui/view/subscriptionofferviewbuttonvisibility(_:for:)) — _Apple Developer; expand on demand_
- [subscriptionOfferViewDetailAction(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionofferviewdetailaction(_:)) — _Apple Developer; expand on demand_
- [subscriptionOfferViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/subscriptionofferviewstyle(_:)) — _Apple Developer; expand on demand_
- [preferredSubscriptionOffer(_:)](https://developer.apple.com/documentation/swiftui/view/preferredsubscriptionoffer(_:)) — Selects a subscription offer to apply to a purchase that a customer makes from a subscription store view, a store view, or a product… _(Apple Developer; expand on demand)_
- [preferredSubscriptionPricingTerms(_:)](https://developer.apple.com/documentation/swiftui/view/preferredsubscriptionpricingterms(_:)) — _Apple Developer; expand on demand_

### Accessing health data

- [healthDataAccessRequest(store:objectType:predicate:trigger:completion:)](https://developer.apple.com/documentation/swiftui/view/healthdataaccessrequest(store:objecttype:predicate:trigger:completion:)) — Asynchronously requests permission to read a data type that requires per-object authorization (such as vision prescriptions). _(Apple Developer; expand on demand)_
- [healthDataAccessRequest(store:readTypes:trigger:completion:)](https://developer.apple.com/documentation/swiftui/view/healthdataaccessrequest(store:readtypes:trigger:completion:)) — Requests permission to read the specified HealthKit data types. _(Apple Developer; expand on demand)_
- [healthDataAccessRequest(store:shareTypes:readTypes:trigger:completion:)](https://developer.apple.com/documentation/swiftui/view/healthdataaccessrequest(store:sharetypes:readtypes:trigger:completion:)) — Requests permission to save and read the specified HealthKit data types. _(Apple Developer; expand on demand)_
- [workoutPreview(_:isPresented:)](https://developer.apple.com/documentation/swiftui/view/workoutpreview(_:ispresented:)) — Presents a preview of the workout contents as a modal sheet _(Apple Developer; expand on demand)_

### Providing tips

- [popoverTip(_:arrowEdge:action:)](https://developer.apple.com/documentation/swiftui/view/popovertip(_:arrowedge:action:)) — Presents a popover tip on the modified view. _(Apple Developer; expand on demand)_
- [popoverTip(_:isPresented:attachmentAnchor:arrowEdge:action:)](https://developer.apple.com/documentation/swiftui/view/popovertip(_:ispresented:attachmentanchor:arrowedge:action:)) — Presents a popover tip on the modified view. _(Apple Developer; expand on demand)_
- [popoverTip(_:isPresented:attachmentAnchor:arrowEdges:action:)](https://developer.apple.com/documentation/swiftui/view/popovertip(_:ispresented:attachmentanchor:arrowedges:action:)) — Presents a popover tip on the modified view. _(Apple Developer; expand on demand)_
- [tipAnchor(_:)](https://developer.apple.com/documentation/swiftui/view/tipanchor(_:)) — Sets a value for the specified tip anchor to be used to anchor a tip view to the of the view. _(Apple Developer; expand on demand)_
- [tipBackground(_:)](https://developer.apple.com/documentation/swiftui/view/tipbackground(_:)) — Sets the tip’s view background to a style. _(Apple Developer; expand on demand)_
- [tipBackgroundInteraction(_:)](https://developer.apple.com/documentation/swiftui/view/tipbackgroundinteraction(_:)) — Controls whether people can interact with the view behind a presented tip. _(Apple Developer; expand on demand)_
- [tipCornerRadius(_:antialiased:)](https://developer.apple.com/documentation/swiftui/view/tipcornerradius(_:antialiased:)) — Sets the corner radius for an inline tip view. _(Apple Developer; expand on demand)_
- [tipImageSize(_:)](https://developer.apple.com/documentation/swiftui/view/tipimagesize(_:)) — Sets the size for a tip’s image. _(Apple Developer; expand on demand)_
- [tipViewStyle(_:)](https://developer.apple.com/documentation/swiftui/view/tipviewstyle(_:)) — Sets the given style for TipView within the view hierarchy. _(Apple Developer; expand on demand)_
- [tipImageStyle(_:)](https://developer.apple.com/documentation/swiftui/view/tipimagestyle(_:)) — Sets the style for a tip’s image. _(Apple Developer; expand on demand)_
- [tipImageStyle(_:_:)](https://developer.apple.com/documentation/swiftui/view/tipimagestyle(_:_:)) — Sets the style for a tip’s image. _(Apple Developer; expand on demand)_
- [tipImageStyle(_:_:_:)](https://developer.apple.com/documentation/swiftui/view/tipimagestyle(_:_:_:)) — Sets the style for a tip’s image. _(Apple Developer; expand on demand)_

### Showing a translation

- [translationPresentation(isPresented:text:attachmentAnchor:arrowEdge:replacementAction:)](https://developer.apple.com/documentation/swiftui/view/translationpresentation(ispresented:text:attachmentanchor:arrowedge:replacementaction:)) — Presents a translation popover when a given condition is true. _(Apple Developer; expand on demand)_
- [translationTask(_:action:)](https://developer.apple.com/documentation/swiftui/view/translationtask(_:action:)) — Adds a task to perform before this view appears or when the translation configuration changes. _(Apple Developer; expand on demand)_
- [translationTask(source:target:action:)](https://developer.apple.com/documentation/swiftui/view/translationtask(source:target:action:)) — Adds a task to perform before this view appears or when the specified source or target languages change. _(Apple Developer; expand on demand)_
- [translationTask(source:target:preferredStrategy:action:)](https://developer.apple.com/documentation/swiftui/view/translationtask(source:target:preferredstrategy:action:)) — Adds a task to perform before this view appears or when the specified source or target languages change. _(Apple Developer; expand on demand)_

### Presenting journaling suggestions

- [journalingSuggestionsPicker(isPresented:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/journalingsuggestionspicker(ispresented:oncompletion:)) — Presents a visual picker interface that contains events and images that a person can select to retrieve more information. _(Apple Developer; expand on demand)_
- [journalingSuggestionsPicker(isPresented:journalingSuggestionToken:onCompletion:)](https://developer.apple.com/documentation/swiftui/view/journalingsuggestionspicker(ispresented:journalingsuggestiontoken:oncompletion:)) — Presents a visual picker interface that contains events and images that a person can select to retrieve more information. _(Apple Developer; expand on demand)_

### Managing contact access

- [contactAccessButtonCaption(_:)](https://developer.apple.com/documentation/swiftui/view/contactaccessbuttoncaption(_:)) — _Apple Developer; expand on demand_
- [contactAccessButtonStyle(_:)](https://developer.apple.com/documentation/swiftui/view/contactaccessbuttonstyle(_:)) — _Apple Developer; expand on demand_
- [contactAccessPicker(isPresented:completionHandler:)](https://developer.apple.com/documentation/swiftui/view/contactaccesspicker(ispresented:completionhandler:)) — Modally present UI which allows the user to select which contacts your app has access to. _(Apple Developer; expand on demand)_

### Syncing game saves

- [gameSaveSyncingAlert(directory:finishedLoading:)](https://developer.apple.com/documentation/swiftui/view/gamesavesyncingalert(directory:finishedloading:)) — Presents a modal view while the game synced directory loads. _(Apple Developer; expand on demand)_

### Handling game controller events

- [handlesGameControllerEvents(matching:)](https://developer.apple.com/documentation/swiftui/view/handlesgamecontrollerevents(matching:)) — Specifies the game controllers events which should be delivered through the GameController framework when the view, or one of its descendants has focus. _(Apple Developer; expand on demand)_

### Creating a tabletop game

- [tabletopGame(_:parent:automaticUpdate:)](https://developer.apple.com/documentation/swiftui/view/tabletopgame(_:parent:automaticupdate:)) — Adds a tabletop game to a view. _(Apple Developer; expand on demand)_
- [tabletopGame(_:parent:automaticUpdate:interaction:)](https://developer.apple.com/documentation/swiftui/view/tabletopgame(_:parent:automaticupdate:interaction:)) — Supplies a closure which returns a new interaction whenever needed. _(Apple Developer; expand on demand)_

### Configuring camera controls

- [realityViewCameraControls](https://developer.apple.com/documentation/swiftui/environmentvalues/realityviewcameracontrols) — The camera controls for the reality view. _(Apple Developer; expand on demand)_
- [realityViewCameraControls(_:)](https://developer.apple.com/documentation/swiftui/view/realityviewcameracontrols(_:)) — Adds gestures that control the position and direction of a virtual camera. _(Apple Developer; expand on demand)_
- [realityViewLayoutBehavior(_:)](https://developer.apple.com/documentation/swiftui/view/realityviewlayoutbehavior(_:)) — A view modifier that controls the frame sizing and content alignment behavior for _(Apple Developer; expand on demand)_

### Interacting with transactions

- [transactionPicker(isPresented:selection:)](https://developer.apple.com/documentation/swiftui/view/transactionpicker(ispresented:selection:)) — Presents a picker that selects a collection of transactions. _(Apple Developer; expand on demand)_

### Framework integration

- [AppKit integration](swiftui-appkit-integration.md) — Add AppKit views to your SwiftUI app, or use SwiftUI views in your AppKit app. _(local context)_
- [UIKit integration](swiftui-uikit-integration.md) — Add UIKit views to your SwiftUI app, or use SwiftUI views in your UIKit app. _(local context)_
- [WatchKit integration](swiftui-watchkit-integration.md) — Add WatchKit views to your SwiftUI app, or use SwiftUI views in your WatchKit app. _(local context)_

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/swiftui/technology-specific-views)
- Captured: `2026-07-16T23:52:09+00:00`
- Payload SHA-256: `8b0f4aedad33e508dd9605297302cf1de76ee7253ca0d81e8c5e088007a49ee8`
- Scope: first level from home SwiftUI; absolute links above have not yet been covered.
