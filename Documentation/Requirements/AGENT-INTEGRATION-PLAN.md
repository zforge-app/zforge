# Zforge — MCP delivery and deferred Apple Intelligence integration

## Delivery decision — 2026-10-12

The user requests delivery of the validated MCP on `main` and preservation of all native Apple integration on `codex/apple-intelligence` for future continuation. The complete native implementation, diagnostic project, tests, primary-source captures and evidence are preserved at `ffee8fb`; [the open issue](SIRI-DISCOVERY-ISSUE.md) records the branch, unresolved Siri behavior and closure criteria. Existing native shortcut actions are included in the deferral. Deferral is not native runtime acceptance.

## Delivered architecture

The application's executable launches a local MCP stdio server through `--mcp`, bypassing SwiftUI scenes and ordinary browser startup. Official Swift MCP SDK 0.12.0 remains pinned. No separate daemon, IPC service, network listener, extra entitlement, developer runtime or engine download is required by the distributed client.

The transport adapter consumes AutomationOperations over existing FileSystemServing / ArchiveServing services. Each connection owns one bounded job registry, one active job/listing and 64 terminal records. Only the MCP transport writes stdout; transport failure diagnostics use stderr without arguments, paths, passwords or engine payloads.

Eight typed tools cover capabilities/authorized roots, paginated directory/archive listings, new ZIP/7z compression, extraction to a new folder, integrity, status and cancellation. Existing outputs and dangling-symlink destinations are refused. Long work has observable terminal outcomes, cancellation and explicit partial extraction output. Destructive archive editing is not exposed. [Complete contract](AGENT-USAGE.md).

Contextual exact-folder consent, separate persistent automation bookmarks, physical path checks and covering-parent consolidation remain shared infrastructure. No caller-supplied name/root/path creates a grant; ordinary browser access does not authorize agents. The Settings list permits explicit advance setup/revocation. All required scopes precede work; cancellation or mismatched consent prevents output. Local clients share the user's explicit grants without per-client ACLs.

## Deferred native scope

App Intents, the macOS 26 native route, modern files.file/system.open archive entities, Spotlight indexing/reindexing, onscreen associations, scoped window handoff and Siri/Shortcuts acceptance are branch-only development. The browser's ordinary URL opening and general password-cancellation guard remain on main. Foundation Models remains outside the selected scope.

The full historical native contract and acceptance matrices are preserved on the continuation branch. Native-only tests are moved with their implementation; MCP/shared tests retain their scenarios. The mainline Settings flow and distribution tests now assert the MCP-only contract. No history rewrite, user-grant removal or unrelated localization rollback is part of this split.

## Verification and remaining boundaries

The user confirms the MCP is already validated. Before separating source, the relevant original suites execute 34 distinct cases / 35 executions with zero failures/skips. That baseline includes two native-only scenarios, which remain on the Apple branch. Delivery build 24 passes all 33 affected cases / 34 executions, both serial localized UI cases, signed Release and installed actual stdio checks. The complete suite retains one tag-menu failure reproduced in unchanged original main; see REGRESSION-COVERAGE and [structured evidence](../Benchmarks/mcp-only-delivery-results.json). Build success or metadata absence alone is not MCP functional approval. Historical UI-infrastructure, large-workload and macOS 26 runtime limits remain separate from the scope decision.
