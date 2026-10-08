# Zforge — Using MCP and native shortcuts

## Local agent setup

1. Open Zforge Settings and scroll to **Automation**.
2. Folder authorization is requested contextually when an action first needs it. You may also preauthorize scopes with **Allow Folder…** in Settings. There are no default automation grants, and ordinary browser grants do not enable automation.
3. Choose **Copy MCP Configuration** and paste the JSON into a local client that supports MCP stdio. The command points to this installation's executable; copy it again if the app is moved.
4. Connect, call `get_capabilities`, and use its `authorized_folders`, limits and instructions to select valid targets.

Example for an installation in Applications:

```json
{
  "mcpServers": {
    "zforge": {
      "command": "/Applications/Zforge.app/Contents/MacOS/Zforge",
      "args": ["--mcp"]
    }
  }
}
```

The bundled executable runs its MCP mode without opening browser windows. No Node, Python, separate daemon, network port or engine download is needed by the client. Each client launches its own process under the local user's identity. Client-supplied names and MCP roots are not permissions; all clients under that user share the folders explicitly allowed for automation. This release does not implement per-client ACLs or remote access.

## Tool contracts

| Tool | Required inputs | Result |
| --- | --- | --- |
| `get_capabilities` | None | Authorized folders, formats, limits and connection instructions. |
| `list_directory` | `path` | Sorted direct children; optional `show_hidden`, `offset`, `limit`. |
| `list_archive` | `path` | Sorted direct archive children; optional relative `internal_path`, `password`, `offset`, `limit`. |
| `compress` | `sources`, `destination`, `format` (`zip` or `7z`) | Starts a job into a new archive. |
| `extract` | `archive`, `destination` | Starts a job into a new folder; optional `password`. |
| `test_archive` | `archive` | Starts an integrity job; optional `password`. |
| `operation_status` | `operation_id` | State, available progress, output path and failure code. |
| `cancel_operation` | `operation_id` | Requests cancellation; poll for the terminal state. |

All filesystem paths are absolute and must remain inside an explicitly allowed folder after physical symlink resolution, including an output that does not yet exist. Missing grants open a native picker for the requested folder. The caller waits for human consent; confirmation persists the read/write scope for future local agents and shortcuts, then resumes the same invocation. All input/output scopes must be authorized before archive work starts. Cancelling returns `cancelled` without starting a job or creating output; any earlier separately confirmed folder grants remain. Selecting a different or broader folder is rejected. Requests for one scope coalesce within each process; separate MCP processes do not share a dialog queue. A missing top-level path never requests a whole-disk grant. Already-authorized calls do not prompt. Required inputs, types, optional inputs and unknown fields are validated. Tool results include serialized JSON text and MCP structured content. Stable error codes include `authorizationRequired`, `invalidArguments`, `destinationExists`, `busy`, `notFound`, `passwordRequired`, `invalidPassword`, `unsafePath`, `archiveFailed`, `operationFailed`, and `cancelled`.

Compression accepts 1–256 sources and uses the native engine's standard compression options. Automated archive creation is currently unencrypted ZIP/7z; archive reading/testing/extraction accepts an optional password. Existing output files, folders and dangling symlinks are refused. Extraction claims a new folder exclusively; it never merges into an existing destination. Archive editing, removal, overwrite and general filesystem mutation are not exposed.

Each connection permits one active job and one active listing; the last 64 job records are retained until disconnect. Jobs have `running`, `cancelling`, `succeeded`, `failed` or `cancelled` states. Query the returned `operation_id` before deciding whether to repeat a request. Operation IDs do not survive reconnect. Disconnect cancels that connection's job and waits for cleanup. Failed/cancelled extraction can leave an empty or partially populated output folder, identified by `output_path`; inspect it before rerunning with a new destination. Passwords are held only in operation memory and never emitted in status or transport diagnostics.

Pages contain at most 200 items (default 100); listings over 10,000 direct children are refused. Pagination is a live offset over paths, not an immutable snapshot. If the directory/archive changes between pages, restart at offset zero. The engine's existing full archive parsing is not a total memory cap. Removing a grant requires renewed human consent for subsequent requests, including after reconnect; it does not forcibly stop already authorized work. Cancel that work through its connection before removing access if immediate interruption is needed.

## Siri, Shortcuts and Spotlight

The app publishes four App Intents actions in the Mac Shortcuts editor:

- **Compress Files**: input files, destination folder, archive name and ZIP/7z format; returns the created archive file.
- **Extract Archive**: archive, destination folder, new folder name and optional password; returns the extracted folder.
- **Test Archive Integrity**: archive and optional password; finishes successfully only after integrity testing succeeds.
- **Open Archive in Zforge**: an authorized archive; opens it using the existing app/Finder URL flow.

Use file/folder parameters backed by local file URLs inside the automation grants. Data-only shortcut files are currently refused; save them to an allowed folder first. Compression, extraction and testing run in the background and use the same native engine/services as MCP. Shortcuts wait for completion and return failure instead of claiming success for a submitted job. Opening an archive brings Zforge forward; its browser retains its existing authorization/navigation rules.

On native macOS, automatic App Shortcuts phrases are [unsupported](../SwiftUI/contexts/hig-app-shortcuts.md). Save a custom shortcut containing a Zforge action, then invoke that shortcut by its name with Siri or Spotlight. Settings includes **Open Shortcuts** and this setup guidance. English and Brazilian Portuguese titles, descriptions, summaries and setup text are in the String Catalog.

The initial generic AppShortcutsProvider was removed after actual Mac discovery investigation. A registration update from the general Apple sample produced a native refresh error; it does not enable unsupported Mac App Shortcuts. Build 2 was installed at `/Applications/Zforge.app`; all four actions then appeared in the Mac editor, where the earlier build search returned no actions. This Mac has 104 historical registered copies; none were removed or globally reset.

Conversational references such as “the first two files from this list” remain a pending requirement, including ordering, window identity, explicit targets and confirmation. The app does not yet publish indexed file entities or onscreen entity associations. The Xcode 27 SDK's Files schema has no compression or extraction action; do not assign an unrelated schema to those intents. Reading a screen or documentation does not grant executable access to that content.

Availability also depends on OS, registration/indexing, language and Siri configuration. Extracted metadata, direct intent execution, editor discovery, saved-shortcut execution and actual Siri invocation are separate evidence; see REGRESSION-COVERAGE.

Current Mac verification: a saved Test Archive Integrity action completed against a synthetic authorized 7z archive. Native `/.nofollow/` URLs are accepted for authorization comparison while operations retain their protected paths. The test grant was revoked afterward. **Compactar com Zforge** is saved with Compress Files, 7z and Ask Each Time for files, name and destination; no test-folder paths remain in it. The user personally validated this shortcut after authorizing a previously omitted folder. Both source and destination require explicit automation grants; missing access now requests foreground continuation and a contextual folder picker. Selecting an input in Shortcuts does not silently create that grant. Three Siri queries failed to find the saved name, including after closing the editor; a fourth query in a new conversation after personal validation responded that Siri cannot run shortcuts directly. This installation therefore has confirmed editor discovery, integrity execution and user-reported personal compression validation, with Siri and Spotlight acceptance still pending.

## Troubleshooting and developer reproduction

- `authorizationRequired`: the folder is unavailable or this invocation cannot present authorization. Run interactively, or preauthorize the target folder in Settings. Ordinary browser access and a path supplied by the caller do not suffice.
- `destinationExists`: use a new archive/folder name; automatic replacement is deliberately unavailable.
- `busy`: finish or cancel the current job, or wait for the current listing to finish.
- An invalid or unavailable archive: inspect `error_code`, confirm the path, and supply the correct password when needed. Native diagnostic text and passwords are not returned to agents.
- Missing native actions: use the installed build 2 or later, reopen the Shortcuts editor and search for Zforge. Save a custom shortcut; automatic App Shortcuts phrases do not apply to native macOS. Keep distribution build numbers increasing so older development copies do not compete with the current release. Do not infer Siri readiness from compilation alone.

The application depends on official Swift MCP SDK 0.12.0, pinned in Xcode with resolved transitive revisions. SDK 0.11.0 fails Xcode 27 concurrency checking in its NetworkTransport implementation; no SDK sources or compiler checks were weakened.

For developers, `BuildSupport/Automation/mcp-smoke.py --executable <bundle executable>` validates initialization, discovery, typed errors and denied access over actual stdio. Add `--root <synthetic allowed folder>` after choosing that folder through Settings to validate real ZIP/7z compression, inspection, testing, extraction and refusal to replace outputs. After removing the synthetic grant, --revoked-root opens contextual authorization; cancel it to verify that no listing runs. This interactive case is distinct from the script's noninteractive denied-path check. This developer script requires Python; the distributed server does not.


### Redundant folder grants

The automation list keeps usable covering parents instead of redundant descendants. Authorizing Downloads after a subfolder replaces the subfolder entry; authorizing a child of an already allowed parent adds nothing. Re-adding a parent cleans usable redundant entries from earlier versions. Physical boundaries govern coverage: a symlink leading outside the parent keeps its independent permission. Unknown/unavailable bookmarks are retained conservatively. Failed authorization preserves the previous list, and active operations keep their existing leases. Removing the consolidated parent blocks future access to its covered descendants; old child grants are not restored automatically. This shared policy applies to Settings, MCP and Shortcuts.
