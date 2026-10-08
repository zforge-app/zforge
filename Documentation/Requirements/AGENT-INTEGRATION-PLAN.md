# Zforge — Agent and Apple Intelligence integration

## Status and requested outcome

Requested on 2026-10-07: add an MCP server so agents can easily use Zforge, and integrate with Apple Intelligence. The initial integration is implemented: the bundled executable provides an MCP stdio mode, explicit automation folder grants, and four App Intents actions. A native picker grant and independent MCP ZIP/7z round-trip have passed; all four actions are visible in the Mac Shortcuts editor. Actual Siri invocation remains a separate acceptance check. Foundation Models is not included. The user selected Siri, Shortcuts, and Spotlight executing Zforge actions. Native system actions are required; an in-app intelligence experience is outside this request.

## Required behavior

- Expose documented, discoverable, typed Zforge operations through an MCP **server**, with explicit input schemas, structured results, actionable errors, and bounded/paginated listings.
- Make initial setup reproducible for compatible agent clients, with a documented connection configuration, version/capability discovery, and a connection troubleshooting procedure. Do not require developer runtimes or manual source builds for the intended distributed experience.
- Reuse the application's operation services, authorization, archive engine isolation, and cancellation semantics. UI state and selection must not be silently substituted for explicitly supplied operation targets.
- Preserve sandbox access and user grants. An agent-supplied path or client-declared root is not a file-access grant. Define grant acquisition, revocation, client identity, and restart behavior before exposing filesystem tools.
- Preserve existing confirmation requirements for destructive archive changes. A tool annotation or a caller-provided confirmation flag does not establish trusted user approval. Define how automation obtains approval and handles a headless caller before delivering those operations.
- Keep long operations asynchronous and observable, with stable operation identifiers, status/progress, cancellation, and explicit partial outcomes. Avoid duplicated work when requests are repeated; determine retry/idempotency semantics per operation.
- Keep metadata/content disclosure scoped to requested, authorized items, and omit passwords and sensitive contents from operational logs.
- Add native Apple system integration independently from MCP where requested; do not advertise MCP as an automatic Siri integration.

## Proposed architecture

The existing FileSystemServing / ArchiveServing domain services remain shared by the browser and the new AutomationOperations adapter. MCP and App Intents consume this adapter with explicit targets and a bounded job registry. The browser retains its established window state, handlers and selection. Foundation Models is outside the selected scope.

### MCP adapter

The official [Swift MCP SDK](https://github.com/modelcontextprotocol/swift-sdk) is pinned to 0.12.0. Its 0.11.0 NetworkTransport source fails Xcode 27 concurrency checking; the later official release includes the fix without weakening checks or patching dependency sources.

The selected transport is the application's own executable with `--mcp`, launched by a local stdio client. The launcher bypasses SwiftUI application startup in this mode. A separate helper, IPC, network listener and new entitlements are unnecessary: this process uses the application's existing sandbox identity and separately stored automation bookmarks. Client names and roots are not authentication; the local user controls which clients launch this executable, and all such clients share the explicit automation grants. There are no default automation grants and ordinary browser grants do not authorize agent requests.

Eight tools provide capabilities/authorized-root discovery, bounded folder/archive pages, ZIP/7z creation, extraction to a new folder, integrity testing, operation status and cancellation. One job and one listing can run per connection; 64 terminal job records are retained. New requests cannot start after shutdown, including authorization that was in flight. Cancellation uses the task's native operation handle rather than globally cancelling a later job. Existing/dangling-symlink destinations are refused; extraction claims its new folder exclusively. Destructive editing is not exposed. [Complete tool/setup contract](AGENT-USAGE.md).

### Native system actions

[App Intents](../SwiftUI/contexts/appintents.md) exposes application actions and entities to Siri, Shortcuts, Spotlight, and Apple Intelligence. Define typed compression/extraction/archive-opening intents and suitable entities/shortcuts over shared services. Use system schemas only where their meaning and target-OS availability match the action. Framework availability alone does not guarantee Siri AI behavior on every supported system; validate each supported surface on an actual OS.

The user's screenshot reports that Siri cannot control Zforge despite reading its visible documentation. The requested conversational command refers to the first two files in an onscreen list. The initial four generic actions use saved custom shortcuts by name. The macOS 27 system-open follow-up below adds schema-based opening; actual Siri execution remains unverified. Onscreen file entities/context, ambiguity handling and language-model routing are pending; generic App Intents metadata and MCP do not deliver that contract. [Native macOS guidance](../SwiftUI/contexts/hig-app-shortcuts.md); [Siri entity/context requirements](../SwiftUI/contexts/appintents-siri-ai.md).

### Foundation Models — outside the selected scope

[Foundation Models](../SwiftUI/contexts/foundationmodels.md) is the candidate for an in-app natural-language experience using Apple's system on-device model. This is distinct from exposing actions to Siri and is not required for the selected scope. The framework is introduced on macOS 26.0, matching Zforge's deployment floor, but individual APIs may require newer systems. Check model availability at runtime, preserve ordinary manual/MCP operations when unavailable, and map generated requests to typed validated operations with the same authorization and confirmations. Exact UI, supported commands, model configuration and evaluation workloads remain pending.

## Acceptance and unresolved decisions

### Contextual folder authorization — implemented and verified 2026-10-07; broader conditions pending

The user personally validates the compression shortcut but rejects mandatory advance folder setup. Both Shortcuts actions and MCP requests that encounter a missing automation grant must request that specific folder through a contextual native picker, explaining the operation's read/write access. Preserve explicit user consent, existing grants, protected paths and physical boundaries. Authorize all required scopes before beginning archive work, then continue the same invocation without requiring a manual retry. Cancelled, mismatched or unavailable authorization must not begin the operation. Already-authorized calls remain in the background without a prompt. Coalesce concurrent requests within each process and prevent duplicate/unbounded dialogs; independent MCP processes do not share a dialog queue. A client-supplied path never creates a grant by itself.

1. Select first supported agent clients and validate actual discovery and tool calls with them, including launch/reconnect and missing grants.
2. Prototype signed packaging/transport and sandbox access; explicitly test app closed, multiple clients/windows, grant revocation, unavailable volumes and malformed/traversal paths.
3. Establish relevant baseline tests before service extraction. Add protocol, real-file/archive integration, cancellation/error/concurrency and user-approval tests without reducing existing UI guarantees.
4. Define a representative latency/CPU/memory baseline and acceptance thresholds before implementing performance-affecting changes; test bounded listings and repeated/large operations.
5. Validate App Intents in the requested system surfaces and languages; an intent that compiles is not evidence that Siri executes it correctly.
6. Foundation Models and an in-app natural-language interface are not part of this task; a later request must establish their requirements and evaluations.

## Implementation and verification — 2026-10-07

Implementation lives in `Zforge/Automation`, with the native settings section in the existing Settings form and English/Brazilian Portuguese strings in the String Catalog. Existing entitlements remain sufficient; no network server is added. Unit/protocol/real ZIP and 7z tests, native intent execution, and serial Settings UI checks have executed. Detailed counts, first-round failures, diagnostic output and remaining verification are in REGRESSION-COVERAGE. Debug and Release signed builds pass. This initial implementation phase precedes the subsequent commit preparation.

Primary Apple framework/action/shortcut pages were incorporated into the local corpus. The runtime is macOS 27.0.1, built with Xcode 27/macOS 27 SDK for macOS 26.0; macOS 26 runtime compatibility is not yet exercised.

The user explicitly authorized `/tmp/ZforgeAutomationSmoke-20261007`; native picker -> persisted bookmark -> independent signed Release MCP process passed ZIP/7z compression, listing, testing, extraction and existing-output refusal. A saved Shortcuts integrity action also completed after repairing authorization comparison for the native `/.nofollow/` namespace, while preserving operational paths and bookmark leases. The grant was removed through Settings afterward; the installed process passes protocol checks and denies access. No original files were used.

Native Mac App Shortcuts phrases are unsupported according to platform-specific HIG; the unsupported provider was removed. Four App Intents actions are visible after installing signed build 2 in Applications. The new custom shortcut **Compactar com Zforge** is saved with the Compress Files action, 7z and Ask Each Time inputs. The user later confirmed personal validation of this shortcut after authorizing an omitted folder. The reported authorization warning was explained by missing scope, not a requirement to enable MCP. Independently, the standard Xcode Debug bundle was still build 1 without the automation actions; rebuilding it produces signed build 2, four native actions and eight MCP tools, reading the existing user grants. No user-created grant was removed. Retrying Siri through its actual `com.apple.campo` identity submits three queries, including the exact name after saving/closing the editor; each fails to find the shortcut. The earlier name-based computer-use binding timeout was infrastructure evidence only; these later replies establish an actual discovery failure. Spotlight invocation, broader visual/accessibility conditions, external-volume/revocation behavior and large-workload resource measurements remain open. OR-20 / ZF-43 must retain these evidence boundaries.

## Siri schema follow-up — 2026-10-08

The next supported slice is content opening, not an unrelated schema assigned to compression. Release build 12 publishes `OpenZforgeContentIntent` using `system.open` on macOS 27, with an archive AppEntity and bounded on-demand authorized discovery; the original four file actions remain available on macOS 26. Files-domain schemas explicitly do not make actions discoverable to Siri/Apple Intelligence. No matching public compression/extraction schema exists in the checked SDK. See CURRENT-STATE for discovery/security limits.

A saved control shortcut, **Zforge Siri Control**, contains only Apple's Current Date action. Manual execution succeeds; a fresh conversational Siri request refuses to run it. This demonstrates a saved-shortcut routing failure independent of Zforge within this surface. A preceding request for Zforge Contextual Permission Test is not a verified saved-name probe: that name was absent from the current library. Native system-open discovery, consent/cancellation and repeated opening pass in installed build 10. Fresh Siri saved-name and direct-action/path requests are refused before invoking the archive action; voice invocation and Spotlight require separate evidence. Build 11 corrects the Settings guidance without changing accepted opening behavior. Do not change privacy settings, remove historical app copies or reset global caches to conceal this boundary.
