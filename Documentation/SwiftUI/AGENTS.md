# Operating the local SwiftUI reference

These instructions apply to all content in `Documentation/SwiftUI`.

## Required consultation order

1. Start with `INDEX.md` to locate the appropriate conceptual family. For broad decisions, use `GUIDANCE.md` as a synthesis and open the primary contexts supporting the conclusion.
2. Search the corpus before opening the web, preferably with `rg -n -i '<concept|symbol|API>' Documentation/SwiftUI/contexts`.
3. Read only the contexts that answer the question and check the URL, capture date, platforms, availability, and confidence level in the front matter.
4. For Zforge decisions, prioritize information applicable to macOS. Treat UIKit, WatchKit, and visionOS as context and preserve native adaptation through SwiftUI/AppKit.
5. When signatures, availability, or compilation behavior need to be exact, also validate against the local SDK and Xcode. Record which SDK supports the conclusion.

The local corpus is the first retrieval source. Do not use Context7 or another external aggregator to replace this source.

## Required incremental expansion

Every absolute link in a context represents a boundary that has not yet been ingested. Whenever one of these links must be accessed to obtain information:

1. Consult the corresponding official page without automatically following the links found on it. Each expansion remains limited to one page.
2. Before completing the task, create a new file in `contexts/` using `CONTEXT-TEMPLATE.md`. Its name must be stable, descriptive, in kebab-case, and must not collide with another context.
3. Record the canonical URL, DocC identifier when available, capture timestamp, payload SHA-256 hash, available ETag or Last-Modified, format, platform, availability, origin, and confidence.
4. Consolidate the page for retrieval: a short summary, signature when applicable, section map, practical implications, and all secondary links found. Secondary links remain absolute and are not visited in the same expansion.
5. Update `metadata/captures.json` and, when applicable, the asset and code-block indexes. Add the context to `INDEX.md` in an appropriate on-demand expansion section.
6. Only after creating and verifying the new file, replace the consulted external link in the source document with a relative Markdown reference to the new context. Also replace semantically identical occurrences in the corpus when they point to the same canonical URL. Preserve the official URL in the new file's front matter and Provenance section.
7. Do not replace the link with a stub or mark a page as local when capture fails. In that case, keep the external link and record the blocker in the ongoing work.

This sequence is mandatory: accessing a corpus link requires materializing its local context and replacing the external reference with the local reference.

## Missing local information

If the required information is absent from the corpus:

1. Search the official [Apple Developer](https://developer.apple.com/) site first, restricting the search to official Apple sources.
2. When the answer uses a page found in the search, incorporate it into the corpus through the same incremental expansion protocol before completing the task.
3. If web documentation and the local SDK disagree, treat the Zforge target SDK version as compilation evidence and the official page as conceptual guidance; explicitly record the divergence.

## Maintenance and quality

- `contexts/` contains the normalized, searchable layer; do not copy entire pages. Preserve compact summaries and link indexes.
- `metadata/captures.json` is the authoritative inventory for coverage, hashes, and failures. `metadata/assets.json` and `metadata/code-blocks.json` maintain separate indexes for visual and code materials.
- `tools/bootstrap.py` reconstructs the initial scope and overwrites generated contexts. Use it only for a complete, audited update; preserve subsequent expansions and annotations.
- A hash change does not prove a semantic change. Compare the context with the source before changing recommendations.
- Do not redistribute the corpus or Apple payloads without reviewing the applicable terms.
