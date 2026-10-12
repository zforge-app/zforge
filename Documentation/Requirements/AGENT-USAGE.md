# Zforge — Using MCP

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

All filesystem paths are absolute and must remain inside an explicitly allowed folder after physical symlink resolution, including an output that does not yet exist. Missing grants open a native picker for the requested folder. The caller waits for human consent; confirmation persists the read/write scope for future local agents, then resumes the same invocation. All input/output scopes must be authorized before archive work starts. Cancelling returns `cancelled` without starting a job or creating output; any earlier separately confirmed folder grants remain. Selecting a different or broader folder is rejected. Requests for one scope coalesce within each process; separate MCP processes do not share a dialog queue. A missing top-level path never requests a whole-disk grant. Already-authorized calls do not prompt. Required inputs, types, optional inputs and unknown fields are validated. Tool results include serialized JSON text and MCP structured content. Stable error codes include `authorizationRequired`, `invalidArguments`, `destinationExists`, `busy`, `notFound`, `passwordRequired`, `invalidPassword`, `unsafePath`, `archiveFailed`, `operationFailed`, and `cancelled`.

Compression accepts 1–256 sources and uses the native engine's standard compression options. Automated archive creation is currently unencrypted ZIP/7z; archive reading/testing/extraction accepts an optional password. Existing output files, folders and dangling symlinks are refused. Extraction claims a new folder exclusively; it never merges into an existing destination. Archive editing, removal, overwrite and general filesystem mutation are not exposed.

Each connection permits one active job and one active listing; the last 64 job records are retained until disconnect. Jobs have `running`, `cancelling`, `succeeded`, `failed` or `cancelled` states. Query the returned `operation_id` before deciding whether to repeat a request. Operation IDs do not survive reconnect. Disconnect cancels that connection's job and waits for cleanup. Failed/cancelled extraction can leave an empty or partially populated output folder, identified by `output_path`; inspect it before rerunning with a new destination. Passwords are held only in operation memory and never emitted in status or transport diagnostics.

Pages contain at most 200 items (default 100); listings over 10,000 direct children are refused. Pagination is a live offset over paths, not an immutable snapshot. If the directory/archive changes between pages, restart at offset zero. The engine's existing full archive parsing is not a total memory cap. Removing a grant requires renewed human consent for subsequent requests, including after reconnect; it does not forcibly stop already authorized work. Cancel that work through its connection before removing access if immediate interruption is needed.

## Deferred Apple integration

This mainline delivery exposes MCP only. Native Shortcuts/App Intents, Siri actions, archive Spotlight donation and onscreen context are preserved on `codex/apple-intelligence` for future continuation. [Open issue and branch reference](SIRI-DISCOVERY-ISSUE.md). These features are not advertised by the current Settings flow.

## Troubleshooting and developer reproduction

- `authorizationRequired`: the folder is unavailable or this invocation cannot present authorization. Run interactively, or preauthorize the target folder in Settings. Ordinary browser access and a path supplied by the caller do not suffice.
- `destinationExists`: use a new archive/folder name; automatic replacement is deliberately unavailable.
- `busy`: finish or cancel the current job, or wait for the current listing to finish.
- An invalid or unavailable archive: inspect `error_code`, confirm the path, and supply the correct password when needed. Native diagnostic text and passwords are not returned to agents.

The application depends on official Swift MCP SDK 0.12.0, pinned in Xcode with resolved transitive revisions. SDK 0.11.0 fails Xcode 27 concurrency checking in its NetworkTransport implementation; no SDK sources or compiler checks were weakened.

For developers, `BuildSupport/Automation/mcp-smoke.py --executable <bundle executable>` validates initialization, discovery, typed errors and denied access over actual stdio. Add `--root <synthetic allowed folder>` after choosing that folder through Settings to validate real ZIP/7z compression, inspection, testing, extraction and refusal to replace outputs. After removing the synthetic grant, --revoked-root opens contextual authorization; cancel it to verify that no listing runs. This interactive case is distinct from the script's noninteractive denied-path check. This developer script requires Python; the distributed server does not.


### Redundant folder grants

The automation list keeps usable covering parents instead of redundant descendants. Authorizing Downloads after a subfolder replaces the subfolder entry; authorizing a child of an already allowed parent adds nothing. Re-adding a parent cleans usable redundant entries from earlier versions. Physical boundaries govern coverage: a symlink leading outside the parent keeps its independent permission. Unknown/unavailable bookmarks are retained conservatively. Failed authorization preserves the previous list, and active operations keep their existing leases. Removing the consolidated parent blocks future access to its covered descendants; old child grants are not restored automatically. This shared policy applies to Settings and MCP.
