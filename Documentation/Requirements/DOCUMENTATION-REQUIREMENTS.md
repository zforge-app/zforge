# Zforge — requirements for the local technical documentation reference

This document preserves the project's requirements for a local, versioned, searchable reference for SwiftUI and macOS APIs. The detailed operating procedure is in [`../SwiftUI/AGENTS.md`](../SwiftUI/AGENTS.md), and the corpus index is in [`../SwiftUI/INDEX.md`](../SwiftUI/INDEX.md). The paths below are relative to the repository root.

## Local SwiftUI documentation reference

- Development must have a local, versioned, searchable reference for official documentation, guides, examples, recommended practices, and relevant visual materials for SwiftUI and the macOS APIs used by Zforge.
- The operational reference resides in `Documentation/SwiftUI`. Before using it, read `Documentation/SwiftUI/AGENTS.md`; start with `Documentation/SwiftUI/INDEX.md`, use `Documentation/SwiftUI/GUIDANCE.md` as a synthesis for broad decisions, and open only the primary contexts supporting the conclusion in `Documentation/SwiftUI/contexts`. Search the corpus with `rg` before using the web.
- `Documentation/SwiftUI/metadata/captures.json` is the inventory of coverage, origin, depth, date, and capture hashes. Relative links in contexts point to pages already incorporated; absolute links represent boundaries not yet ingested. The reproducible initial crawler is in `Documentation/SwiftUI/tools/bootstrap.py` and must be used only for complete, audited updates, because it regenerates the initial scope.
- The documentation home page serves as a seed, not as a sufficient corpus. Ingestion must use an incremental crawler with an allowlist of official domains and areas, preserving the canonical URL, version or date, platform, availability, hash, capture date, and relationships between pages.
- Store raw material, metadata, normalized text, code blocks, links to sample projects, and visual references separately. Images must retain the original file and metadata, with OCR or an indexable description when this adds value; do not assume that an entire image can safely be reduced to text.
- Prioritize the supplied official documentation and local SDK/Xcode when validating API availability and signatures. The local corpus is the only planned retrieval source for project-specific decisions; do not use Context7 or another external service as a substitute for this corpus.
- Queries must return excerpts with origin, version, platform, and confidence level, and updates must be incremental, with change detection and the ability to pin an SDK version. The copy must remain for local use during the initial phase, with a review of Apple's terms before any redistribution.
- Whenever an external link in a local context must be accessed, create a new context file from the consulted page, update metadata and the index, and replace the external link in the source document with a relative reference to the new file. Links found on that new page remain external until needed; do not expand recursively without demand.
- If the required information is absent from the local reference, search the official Apple Developer site first and incorporate the page actually used into the corpus through the same incremental flow before completing the task.

## Documentation language

- All project documents, logs, and strings in tests must be written in English, regardless of the conversation language. This includes generated documentation, log messages, test descriptions, assertion messages, and test fixture strings.
- Other languages are permitted only for text localization, including tests that verify localized text, or when explicitly specified. A conversation in another language does not establish an exception. This policy is also recorded in the root `AGENTS.md`.
- The user requested English translations of the 138 documents inventoried on 2026-10-05. Maintain project documentation, normalized corpus annotations, and the context template in English.
- Preserve technical identifiers, actual file paths, commands, hashes, dates, measurements, and validation status. Translate section titles and update links to the corresponding anchors together. Preserve primary-source provenance and metadata; translating a local synthesis does not constitute a new source capture.
- `Documentation/SwiftUI/tools/bootstrap.py` must generate its headings and annotations in English so a later audited refresh does not reintroduce Portuguese prose.
- This documentation change does not change the application's supported interface languages, the String Catalog translations, or localized test fixtures.
