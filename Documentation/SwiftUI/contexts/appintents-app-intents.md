---
title: "App intents"
source_url: "https://developer.apple.com/documentation/appintents/app-intents"
source_identifier: "doc://com.apple.AppIntents/documentation/AppIntents/app-intents"
captured_at: "2026-10-07T14:23:22.620934+00:00"
source_sha256: "ee7a0538f2bf77d1275b9dc0195cdecfa722085d1b65ddfc8de2f1016cc06ebe"
source_etag: null
source_last_modified: "Fri, 11 Sep 2026 20:50:22 GMT"
source_format: "application/json"
depth: 1
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# App intents

## Quick reference

- Role: framework topic collection.
- Module: AppIntents.
- Relevance: native macOS app action discovery.
- Availability: collection does not specify one deployment floor; verify individual symbols. Zforge uses the macOS 27 SDK to compile for macOS 26.0.

## Summary

Model app actions as AppIntent types with parameters and observable results; the system discovers these actions across supported experiences.

## Practical implications

Share operation services with MCP and the UI. Localize user-facing action metadata and phrases. Compilation and extracted metadata establish registration inputs, not successful Siri execution. Test actual supported system surfaces separately.

## Content map

- App intent definition
- Add-on behaviors
- Parameters
- Disambiguation
- Results
- Dependency management
- Shortcuts support
- Intent-related data
- Type conversions
- Intent queries

## Second-level links

- [Accelerating app interactions with App Intents](appintents-system-registration.md) — expand on demand
- [Adding parameters to an app intent](https://developer.apple.com/documentation/appintents/adding-parameters-to-an-app-intent) — expand on demand
- [App Intents](https://developer.apple.com/documentation/appintents) — expand on demand
- [App entities](https://developer.apple.com/documentation/appintents/app-entities) — expand on demand
- [App enums](https://developer.apple.com/documentation/appintents/app-enums) — expand on demand
- [App extension](https://developer.apple.com/documentation/appintents/app-extension) — expand on demand
- [App intent types](https://developer.apple.com/documentation/appintents/app-intent-types) — expand on demand
- [App schema domains](appintents-schema-domains.md) — expand on demand
- [AppDependency](https://developer.apple.com/documentation/appintents/appdependency) — expand on demand
- [AppDependencyManager](https://developer.apple.com/documentation/appintents/appdependencymanager) — expand on demand
- [AppIntent](https://developer.apple.com/documentation/appintents/appintent) — expand on demand
- [CancellableIntent](https://developer.apple.com/documentation/appintents/cancellableintent) — expand on demand
- [Common data types](https://developer.apple.com/documentation/appintents/common-data-types) — expand on demand
- [Configuring the runtime behavior of your app intents](appintents-runtime-behavior.md) — expand on demand
- [ConfirmationConditions](https://developer.apple.com/documentation/appintents/confirmationconditions) — expand on demand
- [Creating your first app intent](https://developer.apple.com/documentation/appintents/creating-your-first-app-intent) — expand on demand
- [DynamicOptionsProvider](https://developer.apple.com/documentation/appintents/dynamicoptionsprovider) — expand on demand
- [InputConnectionBehavior](https://developer.apple.com/documentation/appintents/inputconnectionbehavior) — expand on demand
- [IntentChoiceOption](https://developer.apple.com/documentation/appintents/intentchoiceoption) — expand on demand
- [IntentDeprecation](https://developer.apple.com/documentation/appintents/intentdeprecation) — expand on demand
- [IntentDescription](https://developer.apple.com/documentation/appintents/intentdescription) — expand on demand
- [IntentDialog](https://developer.apple.com/documentation/appintents/intentdialog) — expand on demand
- [IntentModes](https://developer.apple.com/documentation/appintents/intentmodes) — expand on demand
- [IntentParameter](https://developer.apple.com/documentation/appintents/intentparameter) — expand on demand
- [IntentParameterContext](https://developer.apple.com/documentation/appintents/intentparametercontext) — expand on demand
- [IntentParameterDependency](https://developer.apple.com/documentation/appintents/intentparameterdependency) — expand on demand
- [IntentParameterSummary](https://developer.apple.com/documentation/appintents/intentparametersummary) — expand on demand
- [IntentPrediction](https://developer.apple.com/documentation/appintents/intentprediction) — expand on demand
- [IntentProjection](https://developer.apple.com/documentation/appintents/intentprojection) — expand on demand
- [IntentResult](https://developer.apple.com/documentation/appintents/intentresult) — expand on demand
- [IntentResultContainer](https://developer.apple.com/documentation/appintents/intentresultcontainer) — expand on demand
- [IntentSystemContext](https://developer.apple.com/documentation/appintents/intentsystemcontext) — expand on demand
- [IntentValueContainer](https://developer.apple.com/documentation/appintents/intentvaluecontainer) — expand on demand
- [IntentValueConvertible](https://developer.apple.com/documentation/appintents/intentvalueconvertible) — expand on demand
- [IntentValueConvertibleWrapper](https://developer.apple.com/documentation/appintents/intentvalueconvertiblewrapper) — expand on demand
- [IntentValueExpressing](https://developer.apple.com/documentation/appintents/intentvalueexpressing) — expand on demand
- [IntentValueExpression](https://developer.apple.com/documentation/appintents/intentvalueexpression) — expand on demand
- [IntentValueQuery](https://developer.apple.com/documentation/appintents/intentvaluequery) — expand on demand
- [LongRunningIntent](https://developer.apple.com/documentation/appintents/longrunningintent) — expand on demand
- [OpenIntent](https://developer.apple.com/documentation/appintents/openintent) — expand on demand
- [OpensIntent](https://developer.apple.com/documentation/appintents/opensintent) — expand on demand
- [ParameterSummary](https://developer.apple.com/documentation/appintents/parametersummary) — expand on demand
- [ParameterSummaryCaseCondition](https://developer.apple.com/documentation/appintents/parametersummarycasecondition) — expand on demand
- [ParameterSummaryDefaultCaseCondition](https://developer.apple.com/documentation/appintents/parametersummarydefaultcasecondition) — expand on demand
- [ParameterSummaryString](https://developer.apple.com/documentation/appintents/parametersummarystring) — expand on demand
- [ParameterSummarySwitchCondition](https://developer.apple.com/documentation/appintents/parametersummaryswitchcondition) — expand on demand
- [ParameterSummaryWhenCondition](https://developer.apple.com/documentation/appintents/parametersummarywhencondition) — expand on demand
- [PredictableIntent](https://developer.apple.com/documentation/appintents/predictableintent) — expand on demand
- [ProvidesDialog](https://developer.apple.com/documentation/appintents/providesdialog) — expand on demand
- [Resolvers](https://developer.apple.com/documentation/appintents/resolvers) — expand on demand
- [ResultsCollection](https://developer.apple.com/documentation/appintents/resultscollection) — expand on demand
- [ReturnsValue](https://developer.apple.com/documentation/appintents/returnsvalue) — expand on demand
- [ShowsSnippetView](https://developer.apple.com/documentation/appintents/showssnippetview) — expand on demand
- [Soup Chef with App Intents: Migrating custom intents](https://developer.apple.com/documentation/sirikit/soup-chef-with-app-intents-migrating-custom-intents) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand
- [UndoableIntent](https://developer.apple.com/documentation/appintents/undoableintent) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/appintents/app-intents).
- Captured: `2026-10-07T14:23:22.620934+00:00`.
- Payload SHA-256: `ee7a0538f2bf77d1275b9dc0195cdecfa722085d1b65ddfc8de2f1016cc06ebe`.
- Scope: one DocC JSON page; secondary links remain unvisited.
