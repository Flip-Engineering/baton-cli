# fx (Vercel Labs): architecture of a single-binary, streaming-first coding agent

fx is a minimal coding agent CLI from Vercel Labs, written in Zig and shipped as one native binary with no runtime to install. This report analyzes the implementation directly: the source at commit `6afa7c33dac528c223053adeecac046a0e18bff2` (2026-10-14, "Merge pull request #1299 from vercel-labs/prepare-v0.0.14", `pub const version = "0.0.14"` in `src/main.zig`), shallow-cloned to verify claims against real control flow and data structures. Documentation claims remain cited, but code evidence outranks them; one docs/code discrepancy in compaction numbers is recorded. The report names the architectural pattern each subsystem exemplifies and closes with the concepts that make the design coherent.

## 1. Binary, build, and startup

- Measured (this report): release v0.0.13, `fx-macos-aarch64` tarball downloaded 2026-10-14; the unpacked executable is a Mach-O arm64 binary of 7,068,832 bytes (6.74 MiB). The launch announcement claimed 6.39 MiB ([HN](https://news.ycombinator.com/item?id=49353339)); the current build is slightly larger. The README says stable Apple silicon releases must fit a fixed size limit; no absolute size constant appears in any workflow or script at HEAD (searched `binary-size.yml`, `bench.yml`, `release.yml`, `pgso-macos-arm64.yml`, `scripts/`), so the limit's value remains an open question.
- Size gate: `.github/workflows/binary-size.yml` builds every pull request and its base commit in ReleaseSafe for linux-x86_64, linux-aarch64, macos-x86_64, and macos-aarch64, compares section sizes, and annotates growth over a 52,429-byte delta. The two arm64 binaries are smoke-tested because they run nowhere else on a pull request.
- Latency gate: `benchmarks/check_budgets.py` budgets six commands — `fx` startup, `fx help`, `fx status --json`, `fx background --json`, `fx doctor --json`, `fx sessions --json` — at 2 ms mean wall clock on Linux, measured with hyperfine.
- Startup discipline in `src/main.zig`: top-level help renders through a `FixedBufferAllocator` with `exitFast`, no I/O beyond the write; threaded I/O initializes only for paths that need it (`needsEarlyThreadedIo` covers foreground sessions, `ask`, `acp`). The 10 microsecond cold-start claim ([HN](https://news.ycombinator.com/item?id=49353339)) stays vendor-reported, but the code structure (fast paths that skip thread and I/O setup) corroborates the approach.
- Scale: `src/` holds 687 Zig files, 95,762 lines (measured). The HN estimate of ~600k lines including everything overstates the source roughly 6x.
- Size gate: `.github/workflows/binary-size.yml` builds every pull request and its base commit in ReleaseSafe for linux-x86_64, linux-aarch64, macos-x86_64, and macos-aarch64, compares section sizes, and annotates growth over a 52,429-byte delta. A smoke-test step runs each release-style build; its comment notes the Linux arm64 and macOS binaries run nowhere else on a pull request.
- Pattern: budgeted binaries. "Small and fast" is enforced as CI contracts — byte deltas and wall-clock budgets — and every pull request pays for its own growth.

## 2. One agent core, many hosts

The central structural decision: the agent loop references no host. `src/core/agent/runtime/deps.zig` defines `AgentRuntimeDeps` as a struct of function pointers — `push_text` (a `TextEmission` union: `assistant_started`, `assistant_source`, `assistant_rendered`, `assistant_restarted`, `operational`), `push_event`, `push_diff_block`, `take_steering_boundary`, `wait_for_subagent`, `validate_tool_call`, `recovery_checkpoint`, `append_turn_piece`, and so on. `src/core/agent/runtime/orchestrator.zig` (12,655 lines), the turn engine, calls only these indirections.

Four hosts mount the same core:

- The native CLI (`src/main.zig`, `src/ui/`, `src/core/app/`).
- The Agent Client Protocol server (`src/acp/server.zig`, 4,702 lines), shared verbatim by all embedding hosts.
- libfx, the JavaScript SDK (`sdk/`): the native Node addon is "a native byte transport around the existing ACP server, not an independently maintained agent implementation" (`sdk/NAPI.md`), and the WebAssembly build reuses the same ACP translation.
- The session manager as an isolated module (`src/core/session_manager/`) with its own build options.

Host services are typed capabilities, not environment checks: `src/core/hosts/host.zig` declares `Capabilities { process_control, url_open, native_url_open, terminal }`, a `UrlOpener`, a `Clipboard` (native: `pbcopy`/`xclip`/`osascript`, `src/core/hosts/native.zig`), and a secret store (macOS Keychain or a profile file, `src/core/hosts/native_secret_store.zig`). `src/core/hosts/target.zig` reduces platform detection to one flag (`is_wasm`).

The embed posture is default-deny: the native addon ships with native tools off, ACP-provided MCP off, the secret store off, and read/output limits at zero (`sdk/NAPI.md`), under the rule "Every new capability needs a typed boundary, permission analysis, explicit configuration, and native security coverage." Gateway URL validation is duplicated in JavaScript and Zig as deliberate defense in depth.

Pattern: microkernel plugin seam. The core is a turn engine over injected effects; hosts differ only in which capabilities they inject, which is what makes CLI, editor, browser, and Node embeddings the same agent.

## 3. Tool registry and dispatch

Seventeen built-in tools are registered in `src/builtins/tools.zig` (`pub const all`, line 843); fifteen are advertised to the model in a fixed `advertisement_order`. Three are `.internal = true` (`capability_search`, `mcp_select_tool`, `read_tool_result`) — "fx's own discovery or bookkeeping step rather than work the user asked for. Hosts may hide these calls." The advertised catalog: `read_file`, `glob_files`, `grep_files`, `edit_file`, `write_file`, `shell`, `subagent`, `capability_search`, `skill`, `install_skill`, `mcp_select_tool`, `mcp_features`, `ask_user_question`, `web_fetch`, `web_search` (`vision` and `read_tool_result` join conditionally). The read-only set is exactly `read_file`, `glob_files`, `grep_files`.

Each tool is a `ToolSpec` (`src/core/tooling/tool_dispatch.zig`, line 455) carrying the contract the runtime needs:

- `executor_kind` and `activity_kind` — dispatch and presentation classification.
- `requires_approval` — true for `write_file`, `edit_file`, `shell`; false for reads.
- `permission_target_kind` — how the action names a target (path, parent, create-parent, none) for rule matching.
- `provider_executed` — the provider runs the tool. Only `web_search` sets it: "Such a tool never reaches a call-time permission check, so advertisement is its only enforcement point and requires an already-settled allow." The spec carries `write_provider_advertisement_fn`, which injects the gateway's provider-specific search tool schemas into the model's tool list.
- `host_concurrent` / `host_idempotent` — declared only by host-supplied tools (section 4).
- `reads_only_fn` / `irreversible_fn` — per-call predicates, not static flags.
- `decode` / `validate` / `call` — parse, pre-check, execute.

Tool results are budgeted at 64 KiB for the model (`default_max_tool_result_bytes`, `src/core/tooling/tool_result_limits.zig`). Oversized outputs spill to a per-session store (`src/core/session/result_store.zig`): threshold 16 KiB, preview 4 KiB, the body stored in the session's `tool-results/` folder. Handles are content-addressed — `result-{tool}-{call_sha256[:8]}-{content_sha256[:8]}.txt` for v1 sessions, full-sha256 blob names for v2 (`src/core/session/artifact_digest.zig`; blobs are mode 0400, immutable). `read_tool_result` pages a stored output (8 KiB default, 64 KiB max) or searches it; stored text caps at 8 MiB. Model-visible bytes and captured bytes are therefore decoupled by construction.

Pattern: contracts-as-data. Every axis the runtime enforces (concurrency, permission targets, idempotency, presentation) is a field on the tool spec, declared once and read by the call path.

## 4. Tool concurrency and effect journaling, as implemented

This resolves the open question about in-turn scheduling. `src/core/agent/runtime/parallel_execution.zig` schedules a leading prefix of each model tool-call batch: `leadingParallelGroup` classifies the run of calls from the start as one of three kinds — `read_only` (the read-only tools, excluding provider-executed results), `subagent`, or `host` (host tools declaring `host_concurrent`, capped at 16, `max_parallel_host_calls`). The first writer ends the group and runs alone; a test states it directly: "host calls run together until a writer, which runs alone" (line 671). Builds without threads run everything sequentially.

Execution (`runParallelCalls`, line 200) spawns one `std.Thread` per call with a per-slot arena allocator on the C allocator, joins by completion order under a mutex/condition, and checks the cancel flag at each worker's start. The orchestrator gates the parallel path: read-only groups run concurrently only in `auto` or `yolo` permission modes; subagent and host groups require each call reviewed before the group starts; the path is skipped entirely when vision is required, a context delta is in flight, or live tool authority is present (`src/core/agent/runtime/orchestrator.zig`, line 9980).

Effect safety is journal-first. Before any call in a batch runs, the journaled path writes a `tool_intent` event naming the calls about to run, and — unless every call is provider-executed or idempotent-non-writing — waits until the host has stored the intent (`src/acp/prompt.zig`, line 2765: `waits` computation and `flushJournal`). The comment states the invariant: "only a stored intent reruns a call under the same id." Calls that run ahead of their intent are those whose re-execution is harmless by declaration; a crash before the intent lands makes the model ask again. Repeated identical failures inside a turn escalate: `IdenticalFailureEscalationState` hashes tool plus arguments and counts exact repeats, feeding guidance to the model (`src/core/agent/runtime/tool_admission.zig`, line 291).

Pattern: intent-before-effect journaling with a safety-class schedule. Concurrency is derived from declared tool safety, permission review is unchanged per call, and the durable record of "about to run" precedes every effect that needs one.

## 5. The file mutation pipeline

Writes and edits are prepared, authorized, and applied in three phases (`src/core/tooling/file_mutation.zig`, `file_mutation_contract.zig`, `file_mutation_execution.zig`):

- Prepare: resolve the target through inode-verified traversal anchors (`FileIdentity` = device, inode, kind; symlink and hard-link escapes rejected as `SessionPathUnsafe`), capture the preimage (`absent` or `present` with content and content hash, capped at 4 MiB), and build the diff preview. This happens before any approval.
- Authorize: permission rules evaluate against the prepared targets. A no-op edit — the file already contains the requested content — short-circuits to success with "No changes to {path}; it already contains the requested content" and skips approval (`preparedMutationIsNoop`, `file_mutation_contract.zig` line 594; applied at `file_mutation_execution.zig` line 84). Edit semantics enforce uniqueness: `old_string == new_string` fails; zero occurrences fails with "Re-read the file... if the change is already applied, do not retry"; multiple occurrences fail with a count.
- Apply: execution holds a two-phase `commit_token` (`src/core/tooling/result_commit.zig`: commit or cancel against an identity); a prepared mutation that lost its authorization window fails with "approved filesystem identity changed" and is discarded.

Undo is content-backed: `src/core/workspace/change_tracker.zig` records `{kind: write|edit, path, previous_content}` per operation; `undoLast` restores or deletes, and reports `unavailable` — never a guess — when the preimage is missing or the restore fails.

Pattern: prepare-authorize-apply with captured preimages. Approval sees a concrete diff against a verified preimage; undo restores content from the captured preimage.

## 6. Shell and web

The `shell` tool (`src/tools/shell/shell.zig`) exposes three actions with closed field contracts (tested at line 1843): `run {action, command, cwd, profile, shell, tty, yield_time_ms, timeout_ms, reload}`, `interact {action, session_id, chars, yield_time_ms}`, `stop {action, session_id}`. `yield_time_ms` defaults to 30,000 ms (`src/core/execution/managed_execution_contract.zig`): a command that finishes inside the yield returns one result; a longer one returns an owned `session_id` that stays live across prompts, and `interact` observes output (read-only) or sends input. `profile` selects `user` or `clean` (skip startup files). Shell sessions die with fx and are not recovered on resume.

Startup cost is amortized by `src/core/terminal/shell_snapshot.zig`: the first `user`-profile command runs the login shell once (10 s capture timeout, 8 MiB max capture) and records its exported environment plus replayed aliases, functions, and options in process memory; later commands start a clean shell restored from that snapshot. A changed startup file or `/shell reload` marks the snapshot dirty and advances the approval epoch so remembered approvals stop matching. Contents are never logged. Commands receive `AI_AGENT=fx`.

Web access: `web_fetch` applies a URL policy (`src/tools/web/url_policy.zig`), converts HTML to Markdown (`html_to_markdown.zig`), masks credential-like query values in display (`redactUrlForDisplay`, `src/core/shared/text_utils.zig`), and stores downloads as session artifacts. `web_search` is provider-executed through the gateway advertisement (section 3); provider search aliases (`exa_search`, `perplexity_search`, `parallel_search`) project to the `web_search` name in ACP (`src/core/tooling/tool_presentation.zig`, line 250).

## 7. The terminal interface, as implemented

The conversation renders into scrollback; the alternate screen is owned only by three named modal surfaces. `src/ui/shell_runtime.zig` defines `AlternateScreenOwner = { none, file_approval, full_transcript, catalog_menu }`, and `src/core/app/app_lifecycle.zig` enters (`\x1b[?1049h`) and leaves it around exactly those surfaces — the approval screen and the ctrl+o full transcript can hand ownership between each other. The launch claim "makes sparing use of complex TUI or paints" ([HN](https://news.ycombinator.com/item?id=49353339)) is therefore accurate with a qualification: three modal islands exist, and the main surface is the scrollback.

State is broadcast on a side channel: `src/ui/terminal/program_status.zig` implements OSC 7501 — `\x1b]7501;state=...:app=fx\x1b\\` with states `idle`, `working`, `done`, `error`, and `blocked:kind=permission|question` plus a 256-byte base64 message — written unconditionally, since terminals without the protocol ignore it.

The headless path (`fx ask`, `src/core/cli/cli_ask.zig`) selects output by surface: `selectOutputMode` (line 1342) returns `json` with `--json`, `quiet` with `--quiet`, `raw` when stdout is not a TTY (assistant Markdown straight to stdout), else terminal styling. Progress and diagnostics go to stderr (tested: "fx ask JSON recovery keeps stdout structured and reports progress on stderr", line 9497). The JSON result (`PromptRunResult`, line 303) carries `exit_code`, `assistant_output`, `final_output`, `final_source` (raw final response as saved to history), `interrupted`, `model`, `session_id`, `tool_calls`, `step_count`, `resolved_provider`, `usage`. An interrupted headless run exits 130; termination by SIGTERM exits 143.

Steering is queue admission, not stream injection. `src/core/agent/worker_runtime.zig` (line 1063, `admitPrompt`) keeps one admission-ordered queue; a steer joins the active turn when eligible and interrupts the model stream only when no steering wait boundary is active — a running tool or an in-flight compaction defers delivery to the next boundary of kind `model`, `cancelled`, or `finalizing` (`SteeringBoundaryKind`). The orchestrator drains deferred guidance into the turn's message suffix at those boundaries (`orchestrator.zig`, line 162). Over ACP, steering caps at 64 KiB per message and 1 MiB queued (`src/acp/libfx_steering.zig`), and a steer sets the turn's cancel flag at a model-streaming boundary while a user cancel wins.

Pattern: scrollback as the primary surface with owned modal islands. The interface budget is spent on one live line, occasional full-screen views, and a status side channel — and the same events feed every other host.

## 8. Subagent delegation, as implemented

The model-facing surface is deliberately small. `src/tools/agent/subagent.zig` accepts exactly two actions — `run {task, model?, effort?}` and `message {agent, instructions?, message, model?, effort?}` — with strict unknown-field rejection; `wait`, `stop`, `cancel`, and `inspect` decode as `invalid_enum`. Lifecycle is not the model's to control; the tool description states the division: "fx owns timing, worker identities, cancellation, permissions, persistence, and cleanup" (`src/builtins/tools.zig`, line 187). A message to a working child queues feedback for its next safe boundary; a delivery receipt is explicitly not the final result.

Enforcement of one-level delegation is structural, in three places:

- The tool host checks the caller: `executeManaged` (`src/core/subagent/tool_host.zig`, line 281) fails with `caller_unavailable` when `caller_id` differs from `root_id` — only the root session's turn may delegate.
- Children lose the tool entirely: `withoutSubagentNames`/`withoutSubagentFunctions` strip `subagent` from the child's advertised tool set (`src/core/subagent/agent_adapter.zig`, lines 268 and 377).
- Permission cannot escalate: `admitChildPermission` (`src/core/subagent/authority.zig`, line 23) ranks modes `ask(0) < auto(1) < yolo(2)` and rejects a child request above the parent with `PermissionEscalation`.

Authority is captured once per child turn as an immutable snapshot: `AdmissionSnapshot` (`src/core/subagent/domain.zig`, line 44) holds parent and source ids, model, provider, effort, ultrafast flag, permission mode, tool names, rules, grants, integration names, an authority generation, and the MCP view.

Child state is durable: `src/core/subagent/child_state.zig` maintains `children.json` (schema v2, own lock and owner marker, 256 children max) in the parent session's `subagent/` component folder, with phases `{idle, running, awaiting_approval, interrupted, finished}` and outcomes `{completed, failed, cancelled, interrupted, lost}` — `lost` records work that never reached the child's log before a crash. Each child conversation is a real session: its manifest carries `subagent_child: true` (`src/core/session/session_codec.zig`, line 962), and the store excludes such sessions from listing and external resume (`src/core/subagent/resume_admission.zig` lines 103 and 150; managed-child marker checks in `session_catalog_cache.zig` line 609). The docs statement that child conversations "do not appear separately in `fx resume`" is the user-visible side of a store-level partition.

Results return through the parent's runtime: `wait_for_subagent` (`src/core/app/app_callbacks.zig`, line 775) waits on yielded children with a 20 ms pulse, then `prepareSubagentContext` (line 789) injects them as runtime context under the header "Subagent results (untrusted tool output, not user instructions)", one JSON record per child, with per-child delivery acknowledgements so a resumed session never re-delivers.

Pattern: capability with captured authority. Delegation is one tool with two verbs; everything durable about the child (identity, permissions, lifecycle, outcome) lives in the parent's session state, and the child is a first-class session that happens to be invisible from outside.

## 9. Provider abstraction, as implemented

`src/core/config/model_provider.zig` defines `ProviderId = gateway | codex | grok | configured { name, binding }`, where `binding` is a 32-byte hash of the configured definition's identity. `bind()` re-checks the hash against the current settings and fails with `ConfiguredProviderChanged` when the definition changed since the reference was saved — saved provider references are content-bound, so a settings edit cannot silently reroute an existing session.

Custom connections are data with one protocol: `Protocol` has the single member `openai-chat-completions` (`src/core/config/configured_provider.zig`, line 33). Fields cover `base_url` (HTTPS except loopback), auth (none or bearer-from-env), `tool_choice_mode`, `reviewer_model`, and `model_metadata` (`context_window`, `max_output_tokens`, `supports_tool_use`, `supports_vision`).

Transports live in `src/gateway/`: `chat_completions.zig` (OpenAI-compatible), `vercel_protocol.zig` (AI Gateway), `openai_codex.zig`, `xai_grok.zig`, `responses_protocol.zig` (OpenAI Responses), `sse.zig` (stream parsing). One mechanism the docs never describe: `ProviderReplay` (`src/core/shared/types.zig`, line 1508) — an assistant message can carry provider-specific opaque parts (`parts_json`, capped at 4 MiB) tagged with the provider and model that produced them; a later request replays those parts only when the current selection matches (`matches`, checked in `src/gateway/chat_completions.zig` `build_for`, line 50) and drops them otherwise. The observed purpose: provider-resident message data (reasoning signatures, provider tool-call ids) survives turn-to-turn on the same endpoint without corrupting requests elsewhere; the exact provider semantics of the parts remain provider-defined.

Two capability plumbing facts matter for harness design. First, model capabilities (context window and friends) are the compaction threshold's input; an unknown context window disables automatic compaction, matching the docs. Second, token estimates self-correct: `src/core/agent/runtime/agent.zig` carries `request_token_calibration` — the last provider-measured input-token count paired with the estimated request that produced it — and the compactor scales its budgets by that ratio (`Correction` in `src/core/compactor/window.zig`).

Pattern: providers as bound data. Transport, credential, and per-model capability metadata are separate, content-verified configuration; the runtime reads capabilities as first-class inputs.

## 10. Sessions v1: the on-disk event log

This resolves the open question about the CLI session format. Each conversation is a directory: `~/.fx/sessions/<id>/`, where the id is 12-character url-safe base64 of 9 random bytes (`src/core/session/session_layout.zig`, line 29). The directory contents (`src/core/session/session_log.zig`, lines 32–49):

| File | Role |
| --- | --- |
| `events.jsonl` | The conversation log — the authority |
| `session.json` | Manifest (projection summary, below) |
| `permissions.json` | Permission rules and grants |
| `recovery.json` | Recovery checkpoint bound to a conversation seq |
| `recovery.asked` | Sticky suppression of auto-continue after an unclean exit |
| `owner.live` | `{pid, opened_at_ms}` marker of the live writer |
| `authority.json`, `authority.pending.json` | Schema authority and its migration fence |
| `commit.pending.json`, `session.lock`, `commit.lock` | Publication and locking protocol |
| `history-cache.bin` | Binary replay cache (disposable) |
| `tool-results/`, `logs/commands/`, `artifacts/`, `subagent/` | Spilled bodies, artifacts, child state |

The log format: one JSON line per event, `ConversationEnvelope { schema_version: 3, seq, timestamp_ms, event }` (`src/core/session/session_event.zig`, line 186), where `event` is a `ConversationEvent` union: `user`, `assistant` (optionally with `provider_replay`), `tool_call` (id, name, arguments_json, argument integrity, provenance `fx_local|provider_executed`), `tool_result` (status, artifact reference, preview, completeness, file presentations), `steering`, `turn_completed`, `interrupted`, `context_checkpoint`. A state-machine validator (`validateConversationTransition`, line 218) rejects out-of-order seqs, duplicate tool-call ids, tool results that answer nothing, name mismatches, and checkpoint-coverage violations.

The writer (`ConversationWriter`, `session_log.zig` line 255) appends positionally at its committed byte offset after `confirmUnchanged` — the file must still end where this writer last committed, else the writer latches `SessionWriterChanged` and stays failed. Each append fsyncs; a failed append truncates back to the committed offset and latches `SessionPersistenceUncertain` (lines 538–578). A torn tail on open truncates to the last complete frame. Single-writer control is a `session.lock` advisory flock with a 2 s deadline plus the `owner.live` liveness marker, written on every writable open and removed on clean close; a leftover marker sets `previous_owner_died` on the next open (line 3146, tested at 4791).

The manifest (`src/core/session/session_projection.zig`) summarizes the log: `schema_version: 3`, `storage_format: event_log_v1`, id, `authority_id`, `log_generation`, workspace roots, `history_len`, token totals, `last_event_seq`, `event_log_bytes` plus a stat fingerprint, `generation_base_seq/bytes`, `checkpoint_seq` and `checkpoint_sha256`, preferences. Staleness is byte-exact: the log size differing from the manifest makes the projection stale (line 230). The `authority.pending.json` fence makes readers refuse a session mid-migration (`SessionAuthorityBoundaryUnavailable`, `session_authority.zig` line 170).

Crash recovery is two-layered. In-turn: `recovery.json` binds `{conversation_seq, checkpoint}` where the checkpoint (`RecoveryCheckpoint`, `src/core/session/session_codec.zig` line 136) records the turn id, user turn, partial assistant source, execution memory, recovery cause and action, tool state, authority (provider/model/credential identity), fast/ultrafast state, and the provider attempt budget (`max_provider_attempts`, `consumed`, `outstanding_reservation`). Across sessions: `fx session recover` copies to the last good boundary (`recoverSessionCopy`, `session_store.zig` line 2808), refusing subagent children.

Two performance mechanisms sit beside the log. `history-cache.bin` (`src/core/session/history_snapshot.zig`) mirrors the log one-to-one in a compact binary form — length-prefixed, CRC32-checked frames, bound to the log by a watermark recording the covered byte range and tail CRC — so resume validates and replays at memcpy speed; it is disposable, and the log is always the authority. Lazy log compaction (`src/core/session/session_compaction.zig`) rewrites, on writable resume, frames whose inline file-snapshot payloads dominate log bytes into content-addressed result-store artifacts, replacing the log by atomic rename after a full re-validation; a freshness marker skips unchanged logs.

Pattern: append-only log with fence-confirmed appends. The log is the truth; the manifest, cache, and projection are re-derivable; every concurrency question (two writers, torn tail, mid-migration) resolves through a file-level protocol with explicit error states.

## 11. Sessions v2: the session manager and fork

Behind `--sessions-v2` / `FX_SESSIONS_V2=1` (`src/core/session/session_adapter.zig`, lines 3 and 66 — the only fx file importing it), sessions run on a dedicated module, `src/core/session_manager/` (~11.2k lines), layered explicitly in its doc comments:

- L0, `storage.zig`: the only file-system-touching code. Dirs 0700, files 0600, blobs 0400 (immutable); no path reachable through a symlink; exclusive creates; a fault injector behind `-Dhooks=true` models process and machine crashes for tests.
- L2, `fold.zig`: pure core — lines in, state out. "Resuming from the newest snapshot must equal a full fold" is a stated property (checked in `tla/ResumeSnapshot.tla`, referenced but not present in this clone).
- L3, `catalog.zig`: `index.jsonl`, derived and rebuildable — one checksummed line per change (`put`, `opened`, `del` tombstones), appended under `index.lock`, never fsynced; a deleted id never resurrects; `list` reads only the index and self-heals missing folders; `rebuild` re-derives it.
- L4, `api.zig`: thirteen operations (`openNew`, `openResume`, `openFork`, `openImport`, `Session.append`, `Session.putBlob`, `Session.state`, `Session.read`, `Session.close`, `read`, `getBlob`, `list`, `delete`) plus `verify`/`rebuild` for doctor. Every input is checked here; lower levels trust it; a `Session` is safe from any thread; index failures never fail a session change.

Schema (`schema.zig`, line 17): events `session_created`, `turn_started`, `item`, `compacted`, `turn_committed`, `turn_interrupted`, `set`, `child_spawned`, `child_finished`, `snapshot`, `closed`; `Host = app | ask | acp | sdk | child`; `Role = root | child`. Storage is one `log.jsonl` per session plus content-hashed blobs, with a snapshot every 64 KiB (`default_snapshot_every_bytes`, `session.zig` line 31).

Fork is a first-class operation. `openFork` (`api.zig` line 328; `session.zig` line 1593) creates a new root session whose log lines 2..S are the source's, unchanged, with S ending a turn; `ForkPoint` is a turn boundary or `last_good` (a damaged source forks to its last good turn — the recovery path reuses it). Every source blob is hard-linked so the fork stays whole if the source is deleted, and the manifest records `forked_from {id, seq}`. Children are named at spawn (`child_spawned` events); a taken child id fails the first turn's append and leaves the existing session untouched.

The durability design is formally verified. `sdk/tests/model/` holds TLA+ modules (`DurableSession.tla`, `DurableSteer.tla`, `AgentRouting.tla`) model-checked with TLC by `check.sh`; each `Witness-*.cfg` must violate the invariant named after it, so the spec's mutations are confirmed detectable. The specs model exactly the hard parts: claim fencing ("a write counts only when its writer still heads the chain"), lease takeover by a replacement worker, cutoff continuation within 30 s of a deadline, and named-agent routing (a session belongs to the agent its first stored input names; a prompt sent to another agent's session is forwarded). Then `drive.mjs`, `drive-agents.mjs`, and `drive-steer.mjs` walk the TLC-generated state graphs against the real runtime in WebAssembly, converting model-checked designs into executed test paths. The session manager's own comments reference a `docs/session-manager/system-design.md` and `tla/*.tla` files that are absent from this clone — internal references, marked as unverifiable here.

Pattern: event-sourced storage with fork-by-prefix. Append-only logs plus pure folds make fork a line-copy operation, snapshots a cache with an equivalence property, and the catalog a derived index — with the concurrency design model-checked and then replayed against the shipped code.

## 12. The libfx journal and durable hosts

The SDK-level session format (`src/core/agent/runtime/journal.zig`) is the journal the docs describe, now with its full event set: `turn_committed`, `turn_progress` (delta-compressed against a base seq after the turn's first), `tool_intent`, `turn_progress_cleared`, `history_replaced`, `input_accepted`, `input_withdrawn`, `turn_yielded`, and `tool_result` — the last one per finished call with what the model sees, "so a crash before the next progress leaves it answered." Version discipline is explicit: delta and `tool_result` events are version 2; everything else stays version 1 so an older reader still loads a newer journal. `foldFrom` (line 500) rebuilds the session from events, enforcing contiguous seqs, a 4 MiB load bound, and a 1024-turn cap.

Delivery is push-with-barriers: `src/acp/libfx_journal.zig` sends `libfx/journal_append` notifications in seq order, with `barrier: true` where fx waits for the host to store the event before continuing (`appendMarked`, line 304; `flushJournal` at `src/acp/prompt.zig` line 2790). The host batches and flushes asynchronously otherwise (`sdk/fx-sdk.js` `queueJournalEvents`, line 2380).

Fencing is the host's contract: `persistence.append({ expected, idempotencyKey, data })` rejects with `FxFencedError` when `expected` is not the head and returns the stored cursor for a repeated idempotencyKey (reference implementation, `sdk/fx-sdk.js` line 288). On a fence error the agent "stops the turn and its effects now" (line 2426).

Checkpoints and snapshots are binary, opaque to hosts. `FXCP` (`src/core/agent/runtime/checkpoint.zig`, line 9): magic, version, sha256 header, then `u32 json_len | json | u32 blob_count | (u32 blob_len | blob)*` — version 2 stores inline image bytes raw in a trailing blob section; 4 MiB cap, 1024-turn cap, and a `Meta {libfx_version, tool_schema_hash, model}` record so a resume under a different core, tool set, or model loads with a `checkpoint.mismatch` event naming what changed. `FXSN` (`journal.zig` line 231): a quiet-prefix snapshot — covered seq and turn, last turn id, and optionally the yielded open turn as JSON — that hosts store as opaque bytes. Restore requires a fresh agent (`restoreCheckpoint` rejects a used one).

Ambiguous tool calls get an explicit protocol: on resume, calls with no stored result are collected (`unfinishedCalls`, `src/acp/libfx_journal.zig` line 532); the host's `onAmbiguous` callback decides rerun per call, and the identifier for downstream idempotency keys is the model's tool call id, "stable across restores of a persisted session" (`sdk/fx-sdk.js` line 2583). Calls not rerun are answered to the model as possibly-run. Durable hosts (`sdk/durable/local.mjs`, `vercel.mjs`, `world.mjs`) add lease renewal, a `holderInfo`/`alive()` pid probe for instant crash detection, queue-redelivery, a `wakeHandler` HTTP route, and named-agent routing per the `AgentRouting.tla` design.

Pattern: journal-plus-snapshot with host-owned storage. The core owns event semantics and folding; the host owns durability primitives (append with expected cursor, checkpoint bytes); the barrier flag lets fx choose where waiting for durability is load-bearing.

## 13. Context compaction, as implemented

Compaction has one entry point: `src/core/compactor/compactor.zig` `compact()` — manual `/compact`, the automatic threshold, and provider-overflow recovery all call it. The module doc lists its parts: `window.zig` chooses what to compact; `summarize.zig` builds the compacted conversation; `ledger.zig` asks the model for notes; `lint.zig` checks the notes; `model.zig` issues the requests (lowest reasoning effort, with a fallback model); `records.zig` saves and searches records; `checkpoint.zig` is the saved format.

Window selection (`window.zig`, lines 23–27): right after compaction the whole request aims for at most 20% of the usable input (`after_percent = 20`), the newest turns kept unchanged may use up to 40% of that room (`kept_percent = 40`), and at most 4 turns are kept (`max_kept_turns = 4`). Estimates are scaled by the measured correction ratio (provider-counted versus estimated tokens from a recent request), and a provider overflow bounds the room by the rejected request's size. Discrepancy recorded: the docs page (context-compaction) states a 5% retained-history target and a 10% handoff cap; neither number appears in `window.zig` at HEAD, where the constants are 20%/40%/4-turns. The docs' `auto_compact_percent` default of 80 with a 10–80 range is confirmed (`settings.zig`).

What compaction keeps (`summarize.zig`): every user message and every final reply, word for word, clipped only when the compacted text would not fit (each clip names the saved turn that keeps it whole); the conversation's own model writes notes only for the new turns — what the assistant did between user messages, why each tool call was made and what it showed; from the second compaction on, the previous checkpoint is saved whole as the next ledger (L1, L2, ...) and replaced in-context by one standing summary. Every turn is saved word for word as M1, M2, ... and every tool call with its result as T1, T2, .... The records are plain files in the session's tool-results store (`compacted-M12.txt`, `compacted-T12.txt`, `compacted-L1.txt`), searchable by BM25-style scoring (rare words weigh more; in-order phrase co-occurrence weighs more; at most 3 phrases, 5 results) exposed to the agent through `compactor.search` (`records.zig`). `lint.zig` validates each model-written note against the saved turns and marks what it cannot confirm.

The saved format (`checkpoint.zig`): the string `"fx-compactor-v1\n"` followed by a JSON payload — the turns since the last fold, add-only entries for rules, facts, decisions and status, the skills and MCP tools used, ledger pointers, and the M/T counts. Legacy `"fx-compaction-state-v1"` checkpoints keep working. In the session, compaction lands as a `context_checkpoint` event carrying `covers_through_seq`, committed as a `compacted_summary` history turn with `removed_turn_count` and `compaction_count` (`session_log.zig` line 2226).

Pattern: lossy-verbatim reclamation. The conversation is a budgeted variable: user intent and final answers survive exactly; everything else is displaced into content-addressed, searchable records; model-written glue is linted against saved evidence.

## 14. Context economy elsewhere

The same budget discipline appears in two more places. Skills: the model sees names and descriptions only; the catalog prompt is budgeted — 2% of the model's context window in bytes when a window is known, otherwise 8,000 characters (`SkillPromptBudget.resolve`, `src/core/skills/skill_runtime.zig` line 3066) — individual descriptions cap at 1,024 bytes, and over-budget entries are dropped with a `[context]` notice (line 3296). Bodies load on demand through the `skill` tool. MCP: schemas load within their budget; `capability_search` and `mcp_select_tool` gate what the model sees; a second MCP engine exists behind `FX_MCP_ENGINE=v2` (`src/core/mcp_host/host.zig` line 2).

## 15. What baton-cli should copy, and what fits poorly

Copy (each grounded in the sections above):

1. Budgeted binaries: CI-enforced byte-size deltas and wall-clock budgets on trivial commands (section 1). Straightforward to replicate in Bend2 regardless of toolchain.
2. One core, many hosts through a dependency-injection seam (section 2): baton-cli's seat should be the same agent whether the orchestrator, a human terminal, or a test drives it, with every host effect an injected function pointer.
3. The journal/checkpoint session model (sections 10–12): append per step, delta-compress progress, store per-call tool results so a crash mid-batch leaves answered calls answered, fence writers with an expected-cursor append, and keep opaque checkpoints as the fork primitive with a recorded meta for mismatch detection.
4. Intent-before-effect journaling with per-tool idempotency declarations (section 4): a tool with effects is recorded before it runs; safe-to-rerun tools run ahead; `executionId` is the stable key for downstream idempotency.
5. Leading-prefix concurrency with writer fences (section 4): conservative, declared-safety-driven parallelism where permission review is unchanged per call.
6. Prepare-authorize-apply file mutation with captured preimages and content-backed undo (section 5).
7. Large tool results spilled to content-addressed handles with previews, searchable after resume (section 3).
8. The one-level subagent model with captured, non-escalating authority (section 8) — the right ceiling for a seat; fan-out belongs to the orchestrator.
9. Compaction as lossy-verbatim reclamation with searchable displacement records and linted summaries (section 13).
10. Content-bound provider references and capability metadata as first-class config (section 9).

Fits poorly for an orchestrator-driven headless seat:

- The scrollback terminal and its three modal islands are human-interface investment (section 7); a headless seat needs the event stream as the interface, which libfx's journal already provides and the CLI should be derived from.
- `ask_user_question` and approval prompts assume a human; seat permissions must resolve through pre-granted rules or orchestrator policy.
- Child subagent conversations are partitioned away from listing and external resume (section 8) — the opposite of what an orchestrator needs, which is child seats as addressable, wakeable first-class sessions.
- The LLM permission reviewer in `auto` mode adds a model call and nondeterminism at seat action time; deterministic rules plus explicit grants are the predictable choice for seats.
- fx has no cross-process wake model for the CLI itself: a seat cannot be paused, messaged, and resumed by an external coordinator between turns. The libfx durable layer (section 12) is the substrate for it — prompts queue behind running turns, sessions survive process replacement, and named agents route by ownership — but it stops at the SDK boundary. That gap is the one baton-cli exists to fill.

Remaining open questions:

- The Apple silicon absolute size limit is enforced somewhere outside the repo's workflows and scripts (searched; not found at HEAD).
- The 10 microsecond cold start remains vendor-reported; the code's fast paths corroborate the approach.
- The session manager's `docs/session-manager/system-design.md` and `tla/*.tla` references point at files absent from the public clone.
- The exact provider semantics inside `ProviderReplay.parts_json` are provider-defined and not documented.

## Core architectural concepts

1. **The session is a fenced, append-only event log; everything else is a projection.** `events.jsonl` with a state-machine validator and offset-confirmed, fsynced appends (`session_log.zig`); the manifest, `history-cache.bin`, `index.jsonl`, and UI state are all re-derivable, and staleness is byte-exact. Fork-by-prefix and recovery follow from the log shape directly (`openFork`, `recoverSessionCopy`).
2. **One agent core, many hosts through a dependency-injection seam.** The turn engine calls only `AgentRuntimeDeps` function pointers; the ACP server is shared verbatim by CLI, Node addon, and WebAssembly; host capabilities are typed and default-deny in embedded contexts.
3. **Effects are journaled before they run, and classified for recovery.** `tool_intent` with a barrier before effect-bearing batches; idempotent-non-writing tools run ahead; on resume, ambiguous calls are rerun under a stable execution id or answered as possibly-run; fenced writers stop making effects.
4. **Concurrency is scheduled by declared safety class, with writer fences.** Leading prefix groups (read-only / subagent / host-concurrent, capped at 16), one thread per call, the first writer runs alone, and permission review is identical per call whether concurrent or alone.
5. **Authority is captured once and cannot escalate.** Immutable admission snapshots per child turn, ranked permission modes with an explicit escalation error, content-bound provider references, and file-level locks plus liveness markers for writer authority.
6. **Context is a budgeted variable.** Tool results, skill catalogs, and MCP schemas all spend against declared budgets with notices when trimmed; token estimates self-calibrate from provider counts; compaction reclaims overflow while keeping user intent and final answers verbatim, displacing the rest into searchable content-addressed records.

## Sources

Code (commit `6afa7c33dac528c223053adeecac046a0e18bff2`, cloned from https://github.com/vercel-labs/fx; repo-relative paths cited inline):

- `src/main.zig`, `build.zig`, `benchmarks/check_budgets.py`, `.github/workflows/binary-size.yml`, `docs/long-turn-memory.md`
- `src/core/agent/runtime/deps.zig`, `orchestrator.zig`, `parallel_execution.zig`, `tool_batch.zig`, `tool_admission.zig`, `agent.zig`, `model_response_recovery.zig`, `journal.zig`, `checkpoint.zig`
- `src/core/tooling/tool_dispatch.zig`, `tool_result_limits.zig`, `file_mutation.zig`, `file_mutation_contract.zig`, `file_mutation_execution.zig`, `result_commit.zig`
- `src/builtins/tools.zig`; `src/tools/agent/subagent.zig`, `vision.zig`; `src/tools/shell/shell.zig`; `src/tools/web/`
- `src/core/session/session_log.zig`, `session_event.zig`, `session_codec.zig`, `session_projection.zig`, `session_authority.zig`, `session_layout.zig`, `history_snapshot.zig`, `session_compaction.zig`, `result_store.zig`, `artifact_digest.zig`, `session_store.zig`, `session_adapter.zig`
- `src/core/session_manager/api.zig`, `storage.zig`, `fold.zig`, `catalog.zig`, `session.zig`, `schema.zig`
- `src/core/subagent/tool_host.zig`, `agent_adapter.zig`, `authority.zig`, `domain.zig`, `child_state.zig`, `resume_admission.zig`, `execution.zig`, `managed_owner.zig`
- `src/core/config/model_provider.zig`, `configured_provider.zig`, `context_limits.zig`, `agent_steps.zig`; `src/core/compactor/compactor.zig`, `window.zig`, `summarize.zig`, `records.zig`, `checkpoint.zig`, `settings.zig`
- `src/core/skills/skill_runtime.zig`; `src/core/terminal/shell_snapshot.zig`; `src/core/hosts/native.zig`, `native_secret_store.zig`, `host.zig`; `src/core/app/app_lifecycle.zig`, `app_callbacks.zig`; `src/ui/shell_runtime.zig`, `src/ui/terminal/program_status.zig`
- `src/gateway/chat_completions.zig`, `vercel_protocol.zig`, `openai_codex.zig`, `xai_grok.zig`, `responses_protocol.zig`, `sse.zig`; `src/acp/server.zig`, `jsonrpc.zig`, `libfx_journal.zig`, `libfx_steering.zig`, `prompt.zig`, `sessions.zig`, `tool_call_presentation.zig`
- `sdk/fx-sdk.js`, `sdk/NAPI.md`, `sdk/durable/local.mjs`, `sdk/durable/world.mjs`, `sdk/tests/model/DurableSession.tla`, `AgentRouting.tla`, `DurableSteer.tla`, `check.sh`

Documentation:

- Repository and README: https://github.com/vercel-labs/fx
- Binary size CI workflow: https://github.com/vercel-labs/fx/blob/main/.github/workflows/binary-size.yml
- Release v0.0.13 (measured binary): https://github.com/vercel-labs/fx/releases/latest
- Tools: https://fx.sh/docs/capabilities/tools
- Subagents: https://fx.sh/docs/capabilities/subagents
- Sessions: https://fx.sh/docs/using-fx/sessions
- Context compaction: https://fx.sh/docs/using-fx/context-compaction
- Working with fx: https://fx.sh/docs/using-fx/working-with-fx
- fx ask: https://fx.sh/docs/using-fx/fx-ask
- ACP server: https://fx.sh/docs/using-fx/acp
- Permissions: https://fx.sh/docs/configure-fx/permissions
- Models: https://fx.sh/docs/configure-fx/models
- Custom model connections: https://fx.sh/docs/configure-fx/custom-model-connections
- Context limits: https://fx.sh/docs/configure-fx/context-limits
- libfx Durability: https://fx.sh/docs/lib/durability
- libfx Save and restore: https://fx.sh/docs/lib/checkpoints
- Vercel docs, fx with AI Gateway: https://vercel.com/docs/ai-gateway/coding-agents/fx
- Hacker News launch discussion (2026-08-18): https://news.ycombinator.com/item?id=49353339
