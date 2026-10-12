# Zforge — Agent integration evidence

The initial records below are historical. Current mainline delivery is MCP-only; native Apple development remains on `codex/apple-intelligence`.

Measured on 2026-10-07 using Xcode 27/macOS 27 SDK on macOS 27.0.1, Apple Silicon. Sources are the uncommitted ZF-43 implementation; Release is locally Apple Development signed and passes strict codesign verification. This is a characterization baseline, not a claim of performance improvement.

## Workload and results

`BuildSupport/Automation/mcp-smoke.py` launches a fresh signed process in `--mcp` mode, initializes an actual MCP stdio connection, discovers eight tools, reads capabilities, verifies denial of an unapproved folder and typed-argument rejection, closes stdin and asserts a clean exit without stderr. Three sequential Release invocations all pass. Median initialization: **0.017008 s**; maximum child peak RSS: **23.156 MiB**. CPU user/system time and every numeric sample are preserved in [raw results](agent-integration-results.json). Child RSS from `getrusage` is distinct from total-system physical footprint.

Earlier Debug protocol discovery passed with 0.104779 s initialization and 0.186452 s total elapsed. That first characterization precedes the final capabilities/alias/shutdown refinements and is not an exact-final baseline comparison.

## Boundaries and next acceptance workload

These samples cover connection/discovery and denied-access requests only. They do not measure large directories, archive staging/compression, cancellation latency, UI frame rate or native system-action latency. Before optimizing the initial feature, record a 1,000-item directory listing baseline using FileSystemService directly and through the adapter, an archive workload with a representative large/solid input, and matched CPU/memory/response measurements. Define thresholds before those changes; preserve sorted/live-pagination semantics, authorizations, output refusal and cancellation.

After explicit user approval, the native picker-to-persisted-grant-to-independent-Release-process test passed ZIP/7z compression, inspection, integrity, extraction and output refusal. That small fixture run completed in 0.384813 s, including 0.119293 s initialization; child peak RSS was 32,522,240 bytes. Its numeric sample is preserved separately from the three denied-access baseline samples. The grant was removed through Settings afterward. This is functional small-fixture evidence, not large-workload performance acceptance. No original user files or contents are included in these artifacts.

Final installed build 2 after native grant removal: `--revoked-root /tmp/ZforgeAutomationSmoke-20261007` verifies denial of that same folder, protocol discovery, capabilities, other denied access and typed errors, with clean exit. Initialization is 0.034982 s; total elapsed 0.113487 s; child peak RSS 24,215,552 bytes. This single final-source cleanup sample is stored separately and is not a matched performance comparison with the earlier baseline.


## Contextual folder consent characterization — 2026-10-07

The final Release build 5 compiles successfully, contains four native action definitions, passes strict deep signature verification using the system trust store, and replaces the existing installed application after confirmed exit. Previous signed build 4 is preserved in a temporary rollback bundle. The standard DerivedData Debug build 5 is the final tested source; its catalog is subsequently reformatted without any JSON content changes.

Three matched fresh-process probes of installed Release builds 2 and 5 characterize initialize/discovery, capabilities, missing top-level access refusal and typed arguments. Median initialization increases from 15.584 ms to 79.661 ms; maximum child RSS increases from 24.109 MiB to 41.594 MiB. The first final sample is 575.139 ms; all samples remain in the raw artifact. Median child CPU rises from 17.243 ms to 38.442 ms. The minimal AppKit event loop supports native permission UI at a measured startup/memory cost. This is characterization of a small workload, not a predeclared performance acceptance or an improvement claim. Large operations, cold filesystem caches, long sessions and full browser frame pacing remain unmeasured.

All three final installed probes exit 0 with clean stderr and pure JSON-RPC stdout. An intermediate direct launch from the temporary build location emits a system sandbox-extension stderr diagnostic; the installed location passes without filtering or weakening the smoke assertion. Sandboxed signature verification initially cannot use the trust store; the same strict check succeeds outside that restriction. The initial sandboxed fresh DerivedData build cannot resolve package hosts; authorized Xcode build succeeds with pinned dependencies.

The real final installed stdio process requests the revoked synthetic folder. Its native picker is observed with the physical folder explanation and exact-folder CTA. Closing client stdin while that panel is open dismisses it, returns no late response, writes no stderr and exits 0 in 38.942 ms. The application inventory confirms it is no longer running. A diagnostic script syntax error is corrected before this executed probe; no failed process behavior is reclassified as passing. No consent is granted by the disconnect probe. Documents, Downloads and Music remain the only user-created automation grants; the synthetic test scope was removed through Settings before the probe.

[All before/after samples, final source fingerprints and disconnect record](contextual-permission-results.json). [Final 286-case / 378-execution regression summary](contextual-permission-test-results.json). Installed native Shortcuts cancellation and same-invocation integrity completion were checked on signed Release build 4; build 5 changes display-path presentation and is independently covered by final unit/UI, signed installation and actual stdio disconnection. Siri and Spotlight routing remain separate unresolved system checks.


## MCP-only delivery split — 2026-10-12

Signed Release build 24 delivers the existing MCP core without native action/entity metadata or Shortcuts setup controls. Four MCP core files are byte-for-byte unchanged from original main. Installed actual stdio discovery of eight tools, capabilities, denied access and typed errors passes with clean stderr/exit. A single fresh-process sample initializes in 0.587806 s, uses 0.038047 s user / 0.017935 s system CPU, peaks at 44,122,112 bytes child RSS and completes in 0.649633459 s. These figures are characterization, not a matched before/after comparison or performance improvement. Strict temporary-location attempts retain their sandbox stderr failures; no assertion is weakened.

Affected automation suites pass 33 distinct cases / 34 executions, including real ZIP/7z round trips and consolidation/consent contracts. Both serial UI cases pass English/Brazilian Portuguese Settings/configuration cancellation and contextual cancellation/disconnect. The complete delivery run has one tag-menu failure in 301 cases / 469 executions; unchanged original main reproduces the identical failure in 318 cases / 492 executions. Full regression remains failed. Release/signature, executed tests, screenshot review and installed small stdio workload are distinct evidence; broader picker layout, language/accessibility/volume and large-resource acceptance remains open. [Structured current results and source fingerprints](mcp-only-delivery-results.json).
