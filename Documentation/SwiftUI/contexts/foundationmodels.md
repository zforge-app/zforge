---
title: "Foundation Models"
source_url: "https://developer.apple.com/documentation/foundationmodels"
source_identifier: "doc://com.apple.foundationmodels/documentation/FoundationModels"
captured_at: "2026-10-07T13:57:38.717629+00:00"
source_sha256: "0e9cc2d95d14c0ec179ddfcf34c4499397118db04c87960c80554f57518521b4"
source_etag: null
source_last_modified: "Mon, 14 Sep 2026 22:33:35 GMT"
source_format: "application/json"
depth: 0
categories: ["On-demand expansion"]
language: "en"
authority: "Apple Developer"
confidence: "primary-source"
---

# Foundation Models

## Quick reference

- Role: framework overview.
- Module: foundationmodels.
- Relevance to Zforge: native macOS automation and optional intelligence integration.
- Framework availability: iOS 26.0, iPadOS 26.0, Mac Catalyst 26.0, macOS 26.0, visionOS 26.0, watchOS 27.0. Individual symbols may require newer versions.

## Summary

Use language models for language understanding, structured generation, and tool calling.

## Practical implications

Consider an optional in-app natural-language experience using the system on-device model. Preserve ordinary operations when the selected model is unavailable. Framework introduction is macOS 26.0; newer symbols and model providers need separate availability checks.

This overview is conceptual evidence; no Zforge integration or target-SDK compilation was performed in this capture.

## Content map

- Essentials
- Sessions and prompts
- Session transcripts
- Prompt attachments
- Dynamic profiles
- Structured output
- Tools
- System language model
- Private Cloud Compute
- Custom language model provider
- Custom session properties
- Safety
- Performance and evaluation
- Protocols

## Second-level links

- [Adding intelligent app features with generative models](https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models) — expand on demand
- [Adding server-side intelligence with Private Cloud Compute](https://developer.apple.com/documentation/foundationmodels/adding-server-side-intelligence-with-private-cloud-compute) — expand on demand
- [Analyzing images with multimodal prompting](https://developer.apple.com/documentation/foundationmodels/analyzing-images-with-multimodal-prompting) — expand on demand
- [Analyzing the runtime performance of your Foundation Models app](https://developer.apple.com/documentation/foundationmodels/analyzing-the-runtime-performance-of-your-foundation-models-app) — expand on demand
- [Attachment](https://developer.apple.com/documentation/foundationmodels/attachment) — expand on demand
- [Bring an LLM provider to the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/339) — expand on demand
- [Build agentic app experiences with the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2026/242) — expand on demand
- [Categorizing and organizing data with content tags](https://developer.apple.com/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags) — expand on demand
- [Composing dynamic sessions with instructions and profiles](https://developer.apple.com/documentation/foundationmodels/composing-dynamic-sessions-with-instructions-and-profiles) — expand on demand
- [ContextOptions](https://developer.apple.com/documentation/foundationmodels/contextoptions) — expand on demand
- [ConvertibleFromGeneratedContent](https://developer.apple.com/documentation/foundationmodels/convertiblefromgeneratedcontent) — expand on demand
- [ConvertibleToGeneratedContent](https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent) — expand on demand
- [DataAttachmentRepresentable](https://developer.apple.com/documentation/foundationmodels/dataattachmentrepresentable) — expand on demand
- [DataEntryRepresentable](https://developer.apple.com/documentation/foundationmodels/dataentryrepresentable) — expand on demand
- [Debug and profile agentic app experiences with Instruments](https://developer.apple.com/videos/play/wwdc2026/243) — expand on demand
- [DynamicGenerationSchema](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema) — expand on demand
- [DynamicInstructions](https://developer.apple.com/documentation/foundationmodels/dynamicinstructions) — expand on demand
- [DynamicInstructionsForEach](https://developer.apple.com/documentation/foundationmodels/dynamicinstructionsforeach) — expand on demand
- [Evaluating language model responses](https://developer.apple.com/documentation/evaluations/evaluating-language-model-responses) — expand on demand
- [Evaluating prompts to measure performance and improve model responses](https://developer.apple.com/documentation/foundationmodels/evaluating-prompts-to-measure-performance-and-improve-model-responses) — expand on demand
- [Expanding generation with tool calling](https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling) — expand on demand
- [Foundation Models updates](https://developer.apple.com/documentation/updates/foundationmodels) — expand on demand
- [Generable](https://developer.apple.com/documentation/foundationmodels/generable) — expand on demand
- [Generable(description:)](https://developer.apple.com/documentation/foundationmodels/generable(description:)) — expand on demand
- [Generate dynamic game content with guided generation and tools](https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools) — expand on demand
- [GeneratedContent](https://developer.apple.com/documentation/foundationmodels/generatedcontent) — expand on demand
- [Generating Swift data structures with guided generation](https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation) — expand on demand
- [Generating content and performing tasks with Foundation Models](https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models) — expand on demand
- [GenerationOptions](https://developer.apple.com/documentation/foundationmodels/generationoptions) — expand on demand
- [GenerationSchema](https://developer.apple.com/documentation/foundationmodels/generationschema) — expand on demand
- [Guide(description:)](https://developer.apple.com/documentation/foundationmodels/guide(description:)) — expand on demand
- [ImageAttachmentContent](https://developer.apple.com/documentation/foundationmodels/imageattachmentcontent) — expand on demand
- [ImageReference](https://developer.apple.com/documentation/foundationmodels/imagereference) — expand on demand
- [Improving the safety of generative model output](https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output) — expand on demand
- [Instructions](https://developer.apple.com/documentation/foundationmodels/instructions) — expand on demand
- [LanguageModel](https://developer.apple.com/documentation/foundationmodels/languagemodel) — expand on demand
- [LanguageModelCapabilities](https://developer.apple.com/documentation/foundationmodels/languagemodelcapabilities) — expand on demand
- [LanguageModelError](https://developer.apple.com/documentation/foundationmodels/languagemodelerror) — expand on demand
- [LanguageModelExecutor](https://developer.apple.com/documentation/foundationmodels/languagemodelexecutor) — expand on demand
- [LanguageModelExecutorGenerationChannel](https://developer.apple.com/documentation/foundationmodels/languagemodelexecutorgenerationchannel) — expand on demand
- [LanguageModelExecutorGenerationRequest](https://developer.apple.com/documentation/foundationmodels/languagemodelexecutorgenerationrequest) — expand on demand
- [LanguageModelSession](https://developer.apple.com/documentation/foundationmodels/languagemodelsession) — expand on demand
- [LanguageModelSession.DynamicProfile](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/dynamicprofile) — expand on demand
- [LanguageModelSession.DynamicProfileModifier](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/dynamicprofilemodifier) — expand on demand
- [LanguageModelSession.Profile](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/profile) — expand on demand
- [LanguageModelSession.SessionProperty](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/sessionproperty) — expand on demand
- [Managing the context window](https://developer.apple.com/documentation/foundationmodels/managing-the-context-window) — expand on demand
- [Optimizing key-value caching in language model sessions](https://developer.apple.com/documentation/foundationmodels/optimizing-key-value-caching-in-language-model-sessions) — expand on demand
- [Origami: Crafting a dynamic tutorial for Apple Intelligence](https://developer.apple.com/documentation/foundationmodels/origami-crafting-a-dynamic-tutorial-for-apple-intelligence) — expand on demand
- [PrivateCloudComputeLanguageModel](https://developer.apple.com/documentation/foundationmodels/privatecloudcomputelanguagemodel) — expand on demand
- [Prompt](https://developer.apple.com/documentation/foundationmodels/prompt) — expand on demand
- [Prompting an on-device foundation model](https://developer.apple.com/documentation/foundationmodels/prompting-an-on-device-foundation-model) — expand on demand
- [Running a Core AI model in a Foundation Models session](https://developer.apple.com/documentation/foundationmodels/running-a-core-ai-model-in-a-foundation-models-session) — expand on demand
- [SessionPropertyEntry()](https://developer.apple.com/documentation/foundationmodels/sessionpropertyentry()) — expand on demand
- [SessionPropertyKey](https://developer.apple.com/documentation/foundationmodels/sessionpropertykey) — expand on demand
- [SessionPropertyValues](https://developer.apple.com/documentation/foundationmodels/sessionpropertyvalues) — expand on demand
- [Supporting languages and locales with Foundation Models](https://developer.apple.com/documentation/foundationmodels/supporting-languages-and-locales-with-foundation-models) — expand on demand
- [SystemLanguageModel](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel) — expand on demand
- [Technologies](https://developer.apple.com/documentation/technologies) — expand on demand
- [Tool](https://developer.apple.com/documentation/foundationmodels/tool) — expand on demand
- [Transcripts](https://developer.apple.com/documentation/foundationmodels/transcripts) — expand on demand
- [Updating prompts for new model versions](https://developer.apple.com/documentation/foundationmodels/updating-prompts-for-new-model-versions) — expand on demand
- [com.apple.developer.private-cloud-compute](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.developer.private-cloud-compute) — expand on demand

## Provenance

- Source: [Apple Developer](https://developer.apple.com/documentation/foundationmodels).
- Captured: `2026-10-07T13:57:38.717629+00:00`.
- Payload SHA-256: `0e9cc2d95d14c0ec179ddfcf34c4499397118db04c87960c80554f57518521b4`.
- Scope: one official DocC JSON page; secondary pages were not traversed.
