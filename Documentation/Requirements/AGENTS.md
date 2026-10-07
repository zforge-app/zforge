# Zforge — requirements index and maintenance

This directory holds the project's requirements. Start with this index and open the documents related to the feature in question. [`../../AGENTS.md`](../../AGENTS.md) contains the general agent instructions; [`../AGENTS.md`](../AGENTS.md) indexes all documentation.

## Requirements documents

| Document | Authority and content |
| --- | --- |
| [`CURRENT-STATE.md`](CURRENT-STATE.md) | Source of truth for implemented observable contracts, their evidence, and code locations. Consult before changing any feature. |
| [`UI-UX-GUIDE.md`](UI-UX-GUIDE.md) | Requirements for presentation, native interaction, keyboard support, responsiveness, and accessibility. Prototype notes identified in `DIVERGENCES.md` do not replace the current contract. |
| [`PRODUCT-REQUIREMENTS.md`](PRODUCT-REQUIREMENTS.md) | Vision, platform, security, 7-Zip integration, licenses, distribution, and functional direction. Identifies the initial read-only milestone as historical and future stages as planned. |
| [`OPEN-REQUIREMENTS.md`](OPEN-REQUIREMENTS.md) | Pending requirements and decisions, linked to tasks and divergences. Does not redefine completed features. |
| [`DOCUMENTATION-REQUIREMENTS.md`](DOCUMENTATION-REQUIREMENTS.md) | Requirements for coverage, indexing, provenance, and updates to the local SwiftUI/macOS corpus. |
| [`FINDER-TAG-RESEARCH.md`](FINDER-TAG-RESEARCH.md) | External Apple-source evidence on hidden files and Finder tag-search scope; distinguishes documentation from user observations without changing the production contract. |
| [`TAG-CATALOG-OPTIMIZATION-ISSUE.md`](TAG-CATALOG-OPTIMIZATION-ISSUE.md) | Open ZF-42 issue: below-2-second cached readiness at 10,000 tagged records, below-1.5-MiB total storage, candidate designs and acceptance boundaries. |
| [`SEVENZIP-STATIC-INTEGRATION-PLAN.md`](SEVENZIP-STATIC-INTEGRATION-PLAN.md) | ZF-21 plan: static 7-Zip build, native adapter, migration, validation, and distribution. Backend implemented; evidence and remaining checks are recorded in the plan and regression matrix. |
| [`ARCHIVE-DRAG-DROP-PLAN.md`](ARCHIVE-DRAG-DROP-PLAN.md) | Current ZF-30 plan: visual parity with local items, keyboard confirmation, export, and reorganization within the same archive. Implementation and regression tests recorded; validation limits listed separately. |

## Precedence and updates

1. The user's direct instruction takes precedence. All application rules must be documented and kept up to date in this directory. Whenever a request changes a requirement, adds a new one, or fixes incorrect behavior, update the corresponding document in the same interaction, without waiting for a separate documentation request. Record unimplemented work as pending; when implementing it, synchronize the contract with delivered behavior and available evidence.
2. For existing behavior, `CURRENT-STATE.md` takes precedence over future intentions or prototype notes. `UI-UX-GUIDE.md` guides visual and interaction changes where there is no conflict with the current contract.
3. Planned direction remains in `PRODUCT-REQUIREMENTS.md`; open decisions and fixes belong in `OPEN-REQUIREMENTS.md`. Execution status belongs in [`../../TASKS.md`](../../TASKS.md). Conflicts and regressions belong in [`../../DIVERGENCES.md`](../../DIVERGENCES.md), separate from the source of truth.
4. In **every interaction with the project**, review the relevant contracts and keep them up to date. Record requirements, decisions, fixes, and new evidence in the same change. Update [`../../REGRESSION-COVERAGE.md`](../../REGRESSION-COVERAGE.md) when changing or characterizing a contract. Do not make edits without an actual change or turn a proposal into a delivered feature.
5. Keep relative links valid when moving documents. Reference code from this directory using `../../Zforge/`, `../../ZforgeTests/`, or `../../ZforgeUITests/`.
