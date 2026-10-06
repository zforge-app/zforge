# Zforge — Documentation Index

This directory combines the versioned requirements of Zforge and the local technical documentation used to implement them. General instructions for the agent are [`../AGENTS.md`](../AGENTS.md).

## Project requirements

1. [`Requirements/AGENTS.md`](Requirements/AGENTS.md) — index of required documents, precedence and maintenance routine. Read first when working on requirements or functionality.
2. [`Requirements/CURRENT-STATE.md`](Requirements/CURRENT-STATE.md) — observable contracts already implemented, code points and limits of evidence; source of truth of current behavior.
3. [`Requirements/UI-UX-GUIDE.md`](Requirements/UI-UX-GUIDE.md) — specification of interface, interaction, responsiveness and accessibility; prototype notes are subordinated to the current state.
4. [`Requirements/PRODUCT-REQUIREMENTS.md`](Requirements/PRODUCT-REQUIREMENTS.md) — product vision, platform, 7-Zip, security, licensing, distribution and requirements of the initial milestone, with explicit status in the document itself.
5. [`Requirements/OPEN-REQUIREMENTS.md`](Requirements/OPEN-REQUIREMENTS.md) — requirements and decisions still open, separate from the implemented behavior.
6. [`Requirements/DOCUMENTATION-REQUIREMENTS.md`](Requirements/DOCUMENTATION-REQUIREMENTS.md) — local documentation source requirements SwiftUI and macOS.
7. [`Requirements/SEVENZIP-STATIC-INTEGRATION-PLAN.md`](Requirements/SEVENZIP-STATIC-INTEGRATION-PLAN.md) — plan of ZF-21 for native static integration of 7-Zip, with registered implementation, pending phases and verifications.

8. [`Requirements/ARCHIVE-DRAG-DROP-PLAN.md`](Requirements/ARCHIVE-DRAG-DROP-PLAN.md) — plan in force from ZF-30 for exit and reorganization of internal items, with confirmation and visual parity.

## Technical documentation SwiftUI

- [`SwiftUI/AGENTS.md`](SwiftUI/AGENTS.md) — own rules of query, incremental update and provenance of the Apple corpus.
- [`SwiftUI/INDEX.md`](SwiftUI/INDEX.md) — map of local contexts; [`SwiftUI/GUIDANCE.md`](SwiftUI/GUIDANCE.md) synthesizes broad decisions.
- [`SwiftUI/README.md`](SwiftUI/README.md) — corpus structure; `SwiftUI/contexts/` contains primary contexts, `SwiftUI/metadata/` records captures, asset and code blocks, and `SwiftUI/tools/` stores maintenance tools.

## Related tracking outside Documentation

- [`../TASKS.md`](../TASKS.md) — pending activities and decisions.
- [`../DIVERGENCES.md`](../DIVERGENCES.md) — differences between requests, documents and observed behaviour.
- [`../REGRESSION-COVERAGE.md`](../REGRESSION-COVERAGE.md) — matrix of contracts, tests and manual checks.

In each interaction, consult the affected requirements and update your contracts when there is new information. Changes in activity status and divergences must be reflected in the corresponding tracking documents in the same interaction.

## Implementation Comparisons

- [Benchmarks/7zip-linking.md](Benchmarks/7zip-linking.md) — comparison performed of official CLI, static and dynamic integration, with reproducible scripts and individual measurements.

- [Benchmarks/7zip-ram.md](Benchmarks/7zip-ram.md) — RAM total Zforge and engines, real test with time series, baseline and post-cleaning.

- [Benchmarks/icon-previews.md](Benchmarks/icon-previews.md) — bounded content-preview workload, disabled baseline, cold/warm latency, CPU, memory and main-actor response.

- [Benchmarks/startup-tag-scan.md](Benchmarks/startup-tag-scan.md) — startup CPU/heap diagnosis, delivered bounded tag discovery, reproducible comparisons and remaining verification.

- [Benchmarks/tag-discovery-ab.md](Benchmarks/tag-discovery-ab.md) — real-app enabled/disabled global tag discovery comparison, balanced startup windows and all numeric samples.

- [Benchmarks/visible-tag-discovery.md](Benchmarks/visible-tag-discovery.md) — visible Home/Shared completion and post-completion resource measurements, with the failed initial latency target.
