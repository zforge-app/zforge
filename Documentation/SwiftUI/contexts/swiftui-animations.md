---
title: "Animations"
source_url: "https://developer.apple.com/documentation/swiftui/animations"
source_identifier: "doc://com.apple.SwiftUI/documentation/SwiftUI/Animations"
captured_at: "2026-07-16T23:52:09+00:00"
source_sha256: "cba04ec15ab374eca313793347cb808c439f3c48f2107495ea58aed8ae44e11b"
source_etag: "W/\"85d543fbf7a41c47df6e5df6d2052990\""
source_last_modified: null
source_format: "application/json"
depth: 1
categories: ["Views"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Animations

Contexto normalizado para recuperação rápida. A URL oficial e o hash permitem verificar mudanças; este arquivo não substitui a fonte.

## Consulta rápida

- Papel: API Collection
- Módulo: SwiftUI
- Relevância para Zforge: Direct as SwiftUI guidance; confirm macOS availability before adopting an API in Zforge.

## Síntese

**Resumo oficial:** Create smooth visual updates in response to state changes.

You tell SwiftUI how to draw your app’s user interface for different states, and then rely on SwiftUI to make interface updates when the state changes. To avoid abrupt visual transitions when the state changes, add animation in one of the following ways: Animate all of the visual changes for a state change by changing the state inside a call to the withAnimation(_:_:) global function. Add animation to a particular view when a specific value changes by applying the animation(_:value:) view modifier to the view. Animate changes to a Binding by using the binding’s animation(_:) method. SwiftUI animates the effects that many built-in view modifiers produce, like those that set a scale or opacity value. You can animate other values by making your custom views conform to the Animatable protocol, and telling SwiftUI about the value you want to animate. When an animated state change results in adding or removing…

## Mapa do conteúdo

- Overview

## Links do segundo nível

### Overview and featured references

- [withAnimation(_:_:)](https://developer.apple.com/documentation/swiftui/withanimation(_:_:)) — Returns the result of recomputing the view’s body with the provided animation. _(Apple Developer; expandir sob demanda)_
- [animation(_:value:)](https://developer.apple.com/documentation/swiftui/view/animation(_:value:)) — Applies the given animation to this view when the specified value changes. _(Apple Developer; expandir sob demanda)_
- [Binding](https://developer.apple.com/documentation/swiftui/binding) — A property wrapper type that can read and write a value owned by a source of truth. _(Apple Developer; expandir sob demanda)_
- [animation(_:)](https://developer.apple.com/documentation/swiftui/binding/animation(_:)) — Specifies an animation to perform when the binding value changes. _(Apple Developer; expandir sob demanda)_
- [Animatable](https://developer.apple.com/documentation/swiftui/animatable) — A type that describes how to animate a property of a view. _(Apple Developer; expandir sob demanda)_
- [AnyTransition](https://developer.apple.com/documentation/swiftui/anytransition) — A type-erased transition. _(Apple Developer; expandir sob demanda)_
- [slide](https://developer.apple.com/documentation/swiftui/anytransition/slide) — A transition that inserts by moving in from the leading edge, and removes by moving out towards the trailing edge. _(Apple Developer; expandir sob demanda)_
- [scale](https://developer.apple.com/documentation/swiftui/anytransition/scale) — Returns a transition that scales the view. _(Apple Developer; expandir sob demanda)_
- [Motion](https://developer.apple.com/design/Human-Interface-Guidelines/motion) — Beautiful, fluid motions bring the interface to life, conveying status, providing feedback and instruction, and enriching the visual experience of your app or game. _(Apple Developer; expandir sob demanda)_

### Adding state-based animation to an action

- [withAnimation(_:completionCriteria:_:completion:)](https://developer.apple.com/documentation/swiftui/withanimation(_:completioncriteria:_:completion:)) — Returns the result of recomputing the view’s body with the provided animation, and runs the completion when all animations are complete. _(Apple Developer; expandir sob demanda)_
- [AnimationCompletionCriteria](https://developer.apple.com/documentation/swiftui/animationcompletioncriteria) — The criteria that determines when an animation is considered finished. _(Apple Developer; expandir sob demanda)_
- [Animation](https://developer.apple.com/documentation/swiftui/animation) — The way a view changes over time to create a smooth visual transition from one state to another. _(Apple Developer; expandir sob demanda)_

### Adding state-based animation to a view

- [animation(_:)](https://developer.apple.com/documentation/swiftui/view/animation(_:)) — Applies the given animation to this view when this view changes. _(Apple Developer; expandir sob demanda)_
- [animation(_:body:)](https://developer.apple.com/documentation/swiftui/view/animation(_:body:)) — Applies the given animation to all animatable values within the closure. _(Apple Developer; expandir sob demanda)_

### Creating phase-based animation

- [Controlling the timing and movements of your animations](https://developer.apple.com/documentation/swiftui/controlling-the-timing-and-movements-of-your-animations) — Build sophisticated animations that you control using phase and keyframe animators. _(Apple Developer; expandir sob demanda)_
- [phaseAnimator(_:content:animation:)](https://developer.apple.com/documentation/swiftui/view/phaseanimator(_:content:animation:)) — Animates effects that you apply to a view over a sequence of phases that change continuously. _(Apple Developer; expandir sob demanda)_
- [phaseAnimator(_:trigger:content:animation:)](https://developer.apple.com/documentation/swiftui/view/phaseanimator(_:trigger:content:animation:)) — Animates effects that you apply to a view over a sequence of phases that change based on a trigger. _(Apple Developer; expandir sob demanda)_
- [PhaseAnimator](https://developer.apple.com/documentation/swiftui/phaseanimator) — A container that animates its content by automatically cycling through a collection of phases that you provide, each defining a discrete step within an… _(Apple Developer; expandir sob demanda)_

### Creating keyframe-based animation

- [keyframeAnimator(initialValue:repeating:content:keyframes:)](https://developer.apple.com/documentation/swiftui/view/keyframeanimator(initialvalue:repeating:content:keyframes:)) — Loops the given keyframes continuously, updating the view using the modifiers you apply in . _(Apple Developer; expandir sob demanda)_
- [keyframeAnimator(initialValue:trigger:content:keyframes:)](https://developer.apple.com/documentation/swiftui/view/keyframeanimator(initialvalue:trigger:content:keyframes:)) — Plays the given keyframes when the given trigger value changes, updating the view using the modifiers you apply in . _(Apple Developer; expandir sob demanda)_
- [KeyframeAnimator](https://developer.apple.com/documentation/swiftui/keyframeanimator) — A container that animates its content with keyframes. _(Apple Developer; expandir sob demanda)_
- [Keyframes](https://developer.apple.com/documentation/swiftui/keyframes) — A type that defines changes to a value over time. _(Apple Developer; expandir sob demanda)_
- [KeyframeTimeline](https://developer.apple.com/documentation/swiftui/keyframetimeline) — A description of how a value changes over time, modeled using keyframes. _(Apple Developer; expandir sob demanda)_
- [KeyframeTrack](https://developer.apple.com/documentation/swiftui/keyframetrack) — A sequence of keyframes animating a single property of a root type. _(Apple Developer; expandir sob demanda)_
- [KeyframeTrackContentBuilder](https://developer.apple.com/documentation/swiftui/keyframetrackcontentbuilder) — The builder that creates keyframe track content from the keyframes that you define within a closure. _(Apple Developer; expandir sob demanda)_
- [KeyframesBuilder](https://developer.apple.com/documentation/swiftui/keyframesbuilder) — A builder that combines keyframe content values into a single value. _(Apple Developer; expandir sob demanda)_
- [KeyframeTrackContent](https://developer.apple.com/documentation/swiftui/keyframetrackcontent) — A group of keyframes that define an interpolation curve of an animatable value. _(Apple Developer; expandir sob demanda)_
- [CubicKeyframe](https://developer.apple.com/documentation/swiftui/cubickeyframe) — A keyframe that uses a cubic curve to smoothly interpolate between values. _(Apple Developer; expandir sob demanda)_
- [LinearKeyframe](https://developer.apple.com/documentation/swiftui/linearkeyframe) — A keyframe that uses simple linear interpolation. _(Apple Developer; expandir sob demanda)_
- [MoveKeyframe](https://developer.apple.com/documentation/swiftui/movekeyframe) — A keyframe that immediately moves to the given value without interpolating. _(Apple Developer; expandir sob demanda)_
- [SpringKeyframe](https://developer.apple.com/documentation/swiftui/springkeyframe) — A keyframe that uses a spring function to interpolate to the given value. _(Apple Developer; expandir sob demanda)_

### Creating custom animations

- [CustomAnimation](https://developer.apple.com/documentation/swiftui/customanimation) — A type that defines how an animatable value changes over time. _(Apple Developer; expandir sob demanda)_
- [AnimationContext](https://developer.apple.com/documentation/swiftui/animationcontext) — Contextual values that a custom animation can use to manage state and access a view’s environment. _(Apple Developer; expandir sob demanda)_
- [AnimationState](https://developer.apple.com/documentation/swiftui/animationstate) — A container that stores the state for a custom animation. _(Apple Developer; expandir sob demanda)_
- [AnimationStateKey](https://developer.apple.com/documentation/swiftui/animationstatekey) — A key for accessing animation state values. _(Apple Developer; expandir sob demanda)_
- [UnitCurve](https://developer.apple.com/documentation/swiftui/unitcurve) — A function defined by a two-dimensional curve that maps an input progress in the range [0,1] to an output progress that is also in… _(Apple Developer; expandir sob demanda)_
- [Spring](https://developer.apple.com/documentation/swiftui/spring) — A representation of a spring’s motion. _(Apple Developer; expandir sob demanda)_

### Making data animatable

- [AnimatableValues](https://developer.apple.com/documentation/swiftui/animatablevalues) — _Apple Developer; expandir sob demanda_
- [AnimatablePair](https://developer.apple.com/documentation/swiftui/animatablepair) — A pair of animatable values, which is itself animatable. _(Apple Developer; expandir sob demanda)_
- [VectorArithmetic](https://developer.apple.com/documentation/swiftui/vectorarithmetic) — A type that can serve as the animatable data of an animatable type. _(Apple Developer; expandir sob demanda)_
- [EmptyAnimatableData](https://developer.apple.com/documentation/swiftui/emptyanimatabledata) — An empty type for animatable data. _(Apple Developer; expandir sob demanda)_

### Updating a view on a schedule

- [Updating watchOS apps with timelines](https://developer.apple.com/documentation/watchOS-Apps/updating-watchos-apps-with-timelines) — Seamlessly schedule updates to your user interface, even while it’s inactive. _(Apple Developer; expandir sob demanda)_
- [TimelineView](https://developer.apple.com/documentation/swiftui/timelineview) — A view that updates according to a schedule that you provide. _(Apple Developer; expandir sob demanda)_
- [TimelineSchedule](https://developer.apple.com/documentation/swiftui/timelineschedule) — A type that provides a sequence of dates for use as a schedule. _(Apple Developer; expandir sob demanda)_
- [TimelineViewDefaultContext](https://developer.apple.com/documentation/swiftui/timelineviewdefaultcontext) — Information passed to a timeline view’s content callback. _(Apple Developer; expandir sob demanda)_

### Synchronizing geometries

- [matchedGeometryEffect(id:in:properties:anchor:isSource:)](https://developer.apple.com/documentation/swiftui/view/matchedgeometryeffect(id:in:properties:anchor:issource:)) — Defines a group of views with synchronized geometry using an identifier and namespace that you provide. _(Apple Developer; expandir sob demanda)_
- [MatchedGeometryProperties](https://developer.apple.com/documentation/swiftui/matchedgeometryproperties) — A set of view properties that may be synchronized between views using the function. _(Apple Developer; expandir sob demanda)_
- [GeometryEffect](https://developer.apple.com/documentation/swiftui/geometryeffect) — An effect that changes the visual appearance of a view, largely without changing its ancestors or descendants. _(Apple Developer; expandir sob demanda)_
- [Namespace](https://developer.apple.com/documentation/swiftui/namespace) — A dynamic property type that allows access to a namespace defined by the persistent identity of the object containing the property (e.g. a view). _(Apple Developer; expandir sob demanda)_
- [geometryGroup()](https://developer.apple.com/documentation/swiftui/view/geometrygroup()) — Isolates the geometry (e.g. position and size) of the view from its parent view. _(Apple Developer; expandir sob demanda)_

### Defining transitions

- [transition(_:)](https://developer.apple.com/documentation/swiftui/view/transition(_:)) — Associates a transition with the view. _(Apple Developer; expandir sob demanda)_
- [Transition](https://developer.apple.com/documentation/swiftui/transition) — A description of view changes to apply when a view is added to and removed from the view hierarchy. _(Apple Developer; expandir sob demanda)_
- [TransitionProperties](https://developer.apple.com/documentation/swiftui/transitionproperties) — The properties a can have. _(Apple Developer; expandir sob demanda)_
- [TransitionPhase](https://developer.apple.com/documentation/swiftui/transitionphase) — An indication of which the current stage of a transition. _(Apple Developer; expandir sob demanda)_
- [AsymmetricTransition](https://developer.apple.com/documentation/swiftui/asymmetrictransition) — A composite that uses a different transition for insertion versus removal. _(Apple Developer; expandir sob demanda)_
- [contentTransition(_:)](https://developer.apple.com/documentation/swiftui/view/contenttransition(_:)) — Modifies the view to use a given transition as its method of animating changes to the contents of its views. _(Apple Developer; expandir sob demanda)_
- [contentTransition](https://developer.apple.com/documentation/swiftui/environmentvalues/contenttransition) — The current method of animating the contents of views. _(Apple Developer; expandir sob demanda)_
- [contentTransitionAddsDrawingGroup](https://developer.apple.com/documentation/swiftui/environmentvalues/contenttransitionaddsdrawinggroup) — A Boolean value that controls whether views that render content transitions use GPU-accelerated rendering. _(Apple Developer; expandir sob demanda)_
- [ContentTransition](https://developer.apple.com/documentation/swiftui/contenttransition) — A kind of transition that applies to the content within a single view, rather than to the insertion or removal of a view. _(Apple Developer; expandir sob demanda)_
- [PlaceholderContentView](https://developer.apple.com/documentation/swiftui/placeholdercontentview) — A placeholder used to construct an inline modifier, transition, or other helper type. _(Apple Developer; expandir sob demanda)_

### Defining matched transitions

- [matchedTransitionSource(id:in:)](https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:)) — Identifies this view as the source of a navigation transition, such as a zoom transition. _(Apple Developer; expandir sob demanda)_
- [matchedTransitionSource(id:in:configuration:)](https://developer.apple.com/documentation/swiftui/view/matchedtransitionsource(id:in:configuration:)) — Identifies this view as the source of a navigation transition, such as a zoom transition. _(Apple Developer; expandir sob demanda)_
- [MatchedTransitionSourceConfiguration](https://developer.apple.com/documentation/swiftui/matchedtransitionsourceconfiguration) — A configuration that defines the appearance of a matched transition source. _(Apple Developer; expandir sob demanda)_
- [EmptyMatchedTransitionSourceConfiguration](https://developer.apple.com/documentation/swiftui/emptymatchedtransitionsourceconfiguration) — An unstyled matched transition source configuration. _(Apple Developer; expandir sob demanda)_

### Defining navigation transitions

- [navigationTransition(_:)](https://developer.apple.com/documentation/swiftui/view/navigationtransition(_:)) — Sets the navigation transition style for this view. _(Apple Developer; expandir sob demanda)_
- [NavigationTransition](https://developer.apple.com/documentation/swiftui/navigationtransition) — A type that defines the transition to use when navigating to a view. _(Apple Developer; expandir sob demanda)_
- [AnyNavigationTransition](https://developer.apple.com/documentation/swiftui/anynavigationtransition) — A type-erasing navigation transition that allows for providing any navigation transition value dynamically. _(Apple Developer; expandir sob demanda)_
- [CrossFadeNavigationTransition](https://developer.apple.com/documentation/swiftui/crossfadenavigationtransition) — A navigation transition that cross-fades between the appearing view and the disappearing view. _(Apple Developer; expandir sob demanda)_

### Moving an animation to another view

- [withTransaction(_:_:)](https://developer.apple.com/documentation/swiftui/withtransaction(_:_:)) — Executes a closure with the specified transaction and returns the result. _(Apple Developer; expandir sob demanda)_
- [withTransaction(_:_:_:)](https://developer.apple.com/documentation/swiftui/withtransaction(_:_:_:)) — Executes a closure with the specified transaction key path and value and returns the result. _(Apple Developer; expandir sob demanda)_
- [transaction(_:)](https://developer.apple.com/documentation/swiftui/view/transaction(_:)) — Applies the given transaction mutation function to all animations used within the view. _(Apple Developer; expandir sob demanda)_
- [transaction(value:_:)](https://developer.apple.com/documentation/swiftui/view/transaction(value:_:)) — Applies the given transaction mutation function to all animations used within the view. _(Apple Developer; expandir sob demanda)_
- [transaction(_:body:)](https://developer.apple.com/documentation/swiftui/view/transaction(_:body:)) — Applies the given transaction mutation function to all animations used within the closure. _(Apple Developer; expandir sob demanda)_
- [Transaction](https://developer.apple.com/documentation/swiftui/transaction) — The context of the current state-processing update. _(Apple Developer; expandir sob demanda)_
- [Entry()](https://developer.apple.com/documentation/swiftui/entry()) — Creates an environment values, transaction, container values, or focused values entry. _(Apple Developer; expandir sob demanda)_
- [TransactionKey](https://developer.apple.com/documentation/swiftui/transactionkey) — A key for accessing values in a transaction. _(Apple Developer; expandir sob demanda)_

### Deprecated types

- [AnimatableModifier](https://developer.apple.com/documentation/swiftui/animatablemodifier) — A modifier that can create another modifier with animation. _(Apple Developer; expandir sob demanda)_

### Views

- [View fundamentals](swiftui-view-fundamentals.md) — Define the visual elements of your app using a hierarchy of views. _(contexto local)_
- [View configuration](swiftui-view-configuration.md) — Adjust the characteristics of views in a hierarchy. _(contexto local)_
- [View styles](swiftui-view-styles.md) — Apply built-in and custom appearances and behaviors to different types of views. _(contexto local)_
- [Text input and output](swiftui-text-input-and-output.md) — Display formatted text and get text input from the user. _(contexto local)_
- [Images](swiftui-images.md) — Add images and symbols to your app’s user interface. _(contexto local)_
- [Controls and indicators](swiftui-controls-and-indicators.md) — Display values and get user selections. _(contexto local)_
- [Menus and commands](swiftui-menus-and-commands.md) — Provide space-efficient, context-dependent access to commands and controls. _(contexto local)_
- [Shapes](swiftui-shapes.md) — Trace and fill built-in and custom shapes with a color, gradient, or other pattern. _(contexto local)_
- [Drawing and graphics](swiftui-drawing-and-graphics.md) — Enhance your views with graphical effects and customized drawings. _(contexto local)_

## Proveniência

- Fonte: [Apple Developer](https://developer.apple.com/documentation/swiftui/animations)
- Captura: `2026-07-16T23:52:09+00:00`
- SHA-256 do payload: `cba04ec15ab374eca313793347cb808c439f3c48f2107495ea58aed8ae44e11b`
- Escopo: primeiro nível a partir da home SwiftUI; links absolutos acima ainda não foram percorridos.
