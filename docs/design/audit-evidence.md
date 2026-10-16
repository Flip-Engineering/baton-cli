# Evidence audit: design-sketch.md against the research corpus

**Verdict:** the sketch's mechanical core — session-log invariants, the async operation layer, the
program lane, and the safety vocabulary — is grounded in code-verified harness studies and its
citations there check out. Its load-bearing quantitative justifications are vendor- or
paper-reported and in one case truncated to the flattering rows (NOOA's comparison), its
self-extension and promotion machinery extrapolates beyond its cited sources, and three of its
statements — "compaction is expected never to fire," the catalog "written once and masked at
decode," and "no quotas, counters, or step caps" — contradict either the corpus or the sketch
itself. The amendment list below names the edits; the first three are structural.

Grading key: **(a)** code-verified in a harness (the eight clone studies); **(b)** vendor-reported
or blog-only (survey harnesses, benchmark figures, paper-reported numbers); **(c)** extrapolated by
the proposal from a source that supports a different object or domain; **(d)** unsupported.
Citation convention: `nooa.md §3.5` means `docs/research/nooa.md` §3.5; verification notes cite the
source line the report itself records.

## Claim-by-claim grading

| # | Sketch claim (§) | Cited as | Verified | Grade |
|---|---|---|---|---|
| 1 | Log item vocabulary, contiguous seq validated on append/load, temp-file+fsync+dirsync commit (§2) | unreal-agent.md §6 | Matches `codec.go`, `store.go:433-468` as reported | a |
| 2 | Tool-call status persisted atomically with awaited operations (§2) | unreal-agent.md §6 | `itemRecord.Operations` single record | a |
| 3 | Every turn closes with a reason on every exit path; aborted stream settles as interrupted (§2) | deepseek-harness.md §1.1 | `agent.ts:298-391`; `interrupted: true` | a |
| 4 | A tool result never separates from its call (§2) | pi.md §4; arcee-nac.md §4 | pi: invariant lives in §7 (`compaction.ts:351`) and §9 (`orderToolResults`), §4 is the loop section; arcee §4 verified (`weighted_safe_boundary`) | a, pi cite imprecise |
| 5 | Truncated output fails every pending call with a re-issue instruction (§2) | pi.md §12 | Recorded in §12 item 8; primary statement is §4 | a |
| 6 | Effectful calls journal an intent before running (§2) | fx.md §4 | `tool_intent` with barrier | a |
| 7 | Writer latches failure when the log no longer ends where it committed (§2) | fx.md §10 | `SessionWriterChanged` | a |
| 8 | Inputs idempotent by caller-supplied id, persisted before processing (§2) | unreal-agent.md §3 | `inbox.go`, `loop.go:440` | a |
| 9 | Crash repair and fork are one operation at different causes (§2) | deepseek-harness.md §5; prime-agent.md §7 | dsh verified (§5.1, §10.2); prime §7 records fork-as-continuation, not the shared-operation claim | a (dsh); prime cite weak |
| 10 | Fork must not inherit in-flight calls; Unreal ships it as a live FIXME (§2) | unreal-agent.md §12 | `loop.go:593-596` | a |
| 11 | Compaction = appended turn, provenance digest, retained tail, carry-forward of pending calls with latest stub (§2) | arcee-nac.md §4; unreal-agent.md §7 | unreal §7 verified (`carryForwardContext`); arcee §4 verifies digests and cut-point refusal, not stub carry-forward | a, arcee half-imprecise |
| 12 | "It is expected never to fire" (§2) | none | Corpus position is dormant-with-threshold: nooa.md §3.6 (75% trigger, reactive archive, summarizer installed by default in the benchmark agent), arcee-nac.md §4/§10 (70% fallback), unreal-agent.md §7 (per-model thresholds) | d as stated |
| 13 | Renderings sized by format properties; every rendering has a handle to the whole value (§3) | nooa.md §3.2 | `TruncationConfig` table; "the variable itself is not truncated" | a |
| 14 | Overflow spills to a content-addressed file under the session directory; model gets preview plus path (§3) | fx.md §3; unreal-agent.md §4; arcee-nac.md §4 | fx: content-addressed handles, 16 KiB threshold, 4 KiB preview — verified. unreal: per-call capture files, not content-addressed. arcee: SQLite `output_id` paging, not files | a (fx); c (generalized to the other two) |
| 15 | Serialization at exactly one boundary; live objects refused (§3) | nooa.md §3.4 | `PersistentVars` refuses live objects | a |
| 16 | Truncation typed and never silent (§3) | context-networking.md §3.2 | Verified for baton's view plane (`MAX_REPL_BINDING_ITEMS = 512`, shed markers); as a harness rule it is borrowed from the orchestrator substrate | a (baton); c (as seat rule) |
| 17 | Three prompt regions: byte-stable prefix, append-only tagged events, dynamic tail (§3) | nooa.md §3.1 | Verified | a |
| 18 | Tool catalog written once and masked at decode rather than mutated (§3) | no-compaction-approaches.md §1; deepseek-harness.md §10 | Manus §1: masking-at-decode, vendor blog, no ablations, requires provider prefill support. dsh §10 records the opposite mechanism: catalog identical across modes, `ToolHistoryProjection` refuses a changed definition, changes surface as `developer/message` deltas | b (Manus); misattributed to dsh |
| 19 | Provider-resident parts re-attached only when provider and model match (§3) | fx.md §9 | `ProviderReplay.matches` | a |
| 20 | NOOA 82.2% at ~28 calls and 1.1M tokens vs "comparison harnesses' 66 calls and 2.2M" (§3) | nooa.md §3.5 | Paper-reported. The source also records OpenCode at 78.6% with a similar call count and ~1.3M tokens; the sketch omits that row | b; comparison truncated |
| 21 | Twelve-hour runs: context-managing methods keep improving; append-only baseline stalls inside two hours (§3) | context-language-models.md §5 | Paper-reported (§8: all API-model numbers paper-only). The improving methods are CLM (writable context), CLM+subagents, and summarization — a compaction method | b; posture mismatch |
| 22 | Pending calls are durable versioned operation records, at-most-once (§4) | unreal-agent.md §4 | Verified | a |
| 23 | Stub replaced in the staging window, else a second item for the same call id; "replacement is the primary path because the two-item form is provider-dependent" (§4) | unreal-agent.md §5 | Replacement rule verified. "Primary path" is an open question in §13 (no telemetry). Provider dependence of the two-item form is blog-reported (§11) | a (rule); b (provider); c ("primary") |
| 24 | Batched drain under an idle cap with a grace window (§4) | unreal-agent.md §3 | Idle cap verified in §3 (`slurpMaxItems = 100`, 1 ms); grace windows are §5 | a, cite imprecise |
| 25 | Model-ordered commits through a head-of-line cursor (§4) | deepseek-harness.md §1.1 | Verified | a |
| 26 | Join primitive is a handle; read the tail or full output (§4) | prime-agent.md §3 | `BashHandle` with `.tail()`/`.output()` verified; "end the turn and the seat sleeps until something lands" is unreal-agent.md §5, not prime | a (handle); c (blend) |
| 27 | Steering never queues behind a tool call (§4) | unreal-agent.md §3; arcee-nac.md §2 | unreal §3 verified. arcee §2 is the counterexample: steering queues in a table claimed at the next model-call boundary, and §10 records that a long thread delays steering for the whole batch | mis-cited counterexample |
| 28 | Writer fences: reads overlap, first writer runs alone (§4) | fx.md §4 | Verified | a |
| 29 | Program lane contract: one reserved entry point, byte-stable sorted SDK, nested guarded pipeline with call-id correlation, bounded overlap pool, typed failures, no replay (§5) | deepseek-harness.md §4 | All verified (`run_code`, sorted `.d.ts` SDK, `<parent>:ptc:<n>`, `maxParallelSubCalls = 10`, failure taxonomy) | a |
| 30 | Generated programs execute natively in the language the harness is written in (§5) | none | Corpus precedents are Node (dsh) and Python (prime); dsh §8 lists in-process native evaluation as an option whose confinement must be re-derived | d (design position) |
| 31 | Tool contract as data: concurrency class, idempotency/writes, permission target, result representation, timeouts (§5) | fx.md §3 | `ToolSpec` fields verified | a |
| 32 | Edit tool: unique match or refuse, diff before apply, preimage captured, undo restores exact bytes (§5) | fx.md §5 | Verified | a |
| 33 | Anthropic interface discipline: absolute paths, familiar formats, no line-count arithmetic (§5) | minimal-harness-survey.md Anthropic section | Engineering-blog guidance | b |
| 34 | The edit tool is the one addition the ablations price, at +7.7 points (§5) | benchmarks.md SWE-bench section | SWE-agent NeurIPS 2024 ablation, GPT-4 Turbo on SWE-bench Lite. benchmarks.md itself records the same-model edit-tool gap shrinking across generations (7.5 → 4.8 points) | b; 2024-dated |
| 35 | Self-extension: tool = Bend2 module, model-written, model-callable admission, same loader/confinement/logging (§6) | none | Closest precedent is dsh's `plugin_manager` installing npm bundles under danger-full-access or per-call approval (deepseek-harness.md §2) | c/d |
| 36 | Contract validated at admission; description generated from the data the executor enforces (§6) | deepseek-harness.md §4 | dsh's verified fact is the shared prompt/enforcement predicate (§4.1); admission-time validation of model-authored modules is not in dsh. nooa.md §1 (annotations are both prompt surface and runtime contract) is the closer source | c |
| 37 | Admission logged with module digest, admitting principal, authorizing approval (§6) | deepseek-harness.md §2 | dsh §2 verifies install-requires-approval; digest and principal logging are not recorded there | c/d |
| 38 | Extensions inherit authority and cannot widen it; escalation refused rather than clamped (§6) | fx.md §8 | `admitChildPermission` verified — for subagent children, not modules | a (mechanism); c (scope) |
| 39 | Prime stores an orchestration graph as a versioned, refinable artifact (§6) | prime-agent.md §4 | The fact is §9 (factory harness kind, `harness.py:34-39`), not §4 | a, mis-cited |
| 40 | CLM skill evolution: held-out task 38.3 → 74.2 behind a Pareto gate (§6) | context-language-models.md §5 | Number is paper-only (§8: all API-model numbers paper-only); the gate itself is code-verified (§4) | b (result); a (gate) |
| 41 | Promotion gate: mean-reward delta beats paired SE, ties by cost, held-out touched once after freeze (§6) | context-language-models.md §4 | `evolve.py` gate verified | a |
| 42 | Review gate where no task suite exists (§6) | prime-agent.md §6 | Review-gated auto-refine verified | a |
| 43 | Registration at a turn boundary, emits `harness.change`, change reason in request header (§6) | deepseek-harness.md §10 | Change-reason request headers and `developer/message` tool deltas verified; the event name `harness.change` appears in no corpus report | a (mechanism); invented name |
| 44 | Fork record triple with basis digest; workspace checkpoint in the style of Gemini CLI shadow-git (§7) | minimal-harness-survey.md Gemini CLI section | Vendor documentation | b |
| 45 | NAC provenance digests as the digest model; fx typed-mismatch checkpoint as the check (§7) | arcee-nac.md §4; fx.md §12 | Both verified (`provenance.rs`; `Meta {tool_schema_hash, model}` → `checkpoint.mismatch`) | a |
| 46 | Trajectories carry their capability set, in the spirit of CLM's harness fingerprint (§7) | context-language-models.md §3 | `code_fingerprint` hash verified; capability-set extension is the sketch's own | a (fingerprint); c (extension) |
| 47 | Hand-off cells into `worker:<seat>` at turn boundaries; version-pinned read served from last committed version (§8) | context-networking.md §2; deref-and-consistency.md §2 | Cells, citations, CAS bindings are landed baton code; the seat-side commit path is a named missing primitive (§2.3 item 1) and the mid-turn rule is deref §2.5 option 1, a recommendation | a (substrate); c (seat path, mid-turn rule) |
| 48 | Grants: attenuation-only derivation, recorded lineage, subtree revocation, macaroon caveats at deref, per-grant persistability (§8) | addressing-and-authority.md §1 | Prior-art mapping (seL4, macaroons, Cap'n Proto Level 2); no implementation exists; §6 questions open | c |
| 49 | Revocation cuts future dereferences, never retro-invalidates resolved citations (§8) | uncited (addressing-and-authority.md §6 item 3) | Prior-art-derived design rule | c |
| 50 | Shared state is an append-only ledger; live shared context closed; a fence bump per commit reproduces false sharing in the reader's cache (§8) | deref-and-consistency.md §3 | DSM literature plus the corpus's recorded refusals | a (record); c (choice) |
| 51 | Commits are deliberate acts rather than a per-turn rhythm (§8) | context-networking.md §6 | Fence mechanics verified in baton code; cadence is an unmeasured open question there, and sketch §16 lists it as open | mixed; see C6 |
| 52 | Peer content untrusted with ledger provenance, sanitized, no self-cited authority (§8) | context-networking.md §4.2 | Verified baton posture | a (baton) |
| 53 | Compaction summaries as a place injections have survived (§8) | context-language-models.md §7 | Paper §6 citing an OpenAI report | b |
| 54 | Workset shape: goal, ordered items with scope/acceptance/dependencies, status, verification recipe (§9) | arcee-nac.md §5 | Verified | a |
| 55 | Markdown notes prohibited; Anthropic's initializer chose JSON (§9) | no-compaction-approaches.md §2 | Vendor blog | b |
| 56 | Two safety layers: OS-enforced sandbox mode (network off, repo metadata read-only) plus approval policy (§10) | minimal-harness-survey.md Codex CLI section | Vendor documentation | b |
| 57 | Closed outcome union; full/partial enforcement with named denial reasons; `unavailable` for a throwing answerer (§10) | deepseek-harness.md §6 | Verified | a |
| 58 | Approvals invocation-only, never reusable grants (§10) | arcee-nac.md §7 | Verified | a |
| 59 | Undo content-backed; `unavailable` rather than a guess when the preimage is missing (§10) | fx.md §5 | Verified | a |
| 60 | No plugin registry or distribution channel (§11) | deepseek-harness.md §8 | Recorded anti-pattern | a |
| 61 | No full-screen interface; the event log is the interface (§11) | fx.md §7, §15 | §15 states the recommendation; §7 documents the scrollback TUI being set aside | a, cite imprecise |
| 62 | No harness-local memory service; standing store is the orchestrator's knowledge layer (§11) | minimal-harness-survey.md gptme section; no-compaction-approaches.md §7 | gptme verified; §7 records a contested debate (LangChain/Letta hold memory belongs in the harness; Cloudflare holds a managed service), with no verdict | b; contest unacknowledged |
| 63 | No subagent spawning; a seat that needs help asks its conductor (§11) | prime-agent.md §11.2 | Recorded design judgment | a (as judgment) |
| 64 | No quotas, counters, or step caps; benchmark instruments cap steps because they are instruments (§11) | benchmarks.md concept 5 | Concept 5 and the synthesis say the opposite for baton-cli: the tasking protocol should carry explicit step/token/time budgets per task, record them, and enforce them uniformly | contradiction; see C5 |
| 65 | No stateless per-action execution; live streaming shell required by the async contract (§11) | minimal-harness-survey.md "What does not transfer" | Recorded judgment | a (as judgment) |
| 66 | Async vs blocking unmeasured; program lane and citation hand-off unmeasured (§12) | benchmarks.md unknowns | Verified | a |
| 67 | Context postures as emulation switches (§12) | minimal-harness-survey.md Open Interpreter section | Vendor-reported feature | b |
| 68 | Per-deref receipts with cited version, cell id, digest match, bytes, shed markers, latency (§12) | deref-and-consistency.md §4.4 | Measurement design, not built | c (design spec) |
| 69 | Parse-failure events recorded by default (§12) | benchmarks.md Aider section | Verified recommendation | a |
| 70 | Binary size and startup latency gated in CI (§13) | fx.md §1 | Verified (52,429-byte delta; 2 ms budgets) | a |
| 71 | Protocol state machine, model-checked with violating witness configs, replayed against the runtime (§13) | fx.md §11 | Verified | a |
| 72 | Codec fixtures and fuzz as the engineering weight (§13) | unreal-agent.md §6 | Verified (7 fuzz files, golden fixtures) | a |
| 73 | Tests outnumbering source is expected (§13) | unreal-agent.md §2 | ~2:1 measured | a |

## Vendor numbers the sketch treats as settled

**NOOA's SWE-bench economics (row 20).** nooa.md §3.5 reports the comparison the sketch cites, but
the sketch quotes only the PI row (66 calls, 2.2M tokens) and drops the OpenCode row (78.6% at a
similar call count and ~1.3M tokens). As cited, the passage implies the alternative posture costs
double the calls and tokens; the source's own table shows one comparison harness matching NOOA's
call count at 78.6%. All three rows are paper-reported (NVIDIA's arXiv:2607.20709), not
reproduced; nooa.md §7 further records that the blog's "22–72k median prompt tokens" figure
appears nowhere in the paper, that call counts differ between blog and paper (29 vs ~28), and
that whether the benchmark runs had the summarizer installed is not stated. The sketch should cite
the full three-row comparison, label every number paper-reported, and keep the architectural
claim (bounded previews, values in-process) separate from the economics.

**CLM's long-horizon evidence (row 21).** The 12-hour EdgeBench numbers are paper-only:
context-language-models.md §8 lists all API-model results under "paper-only," and the
12-hour runs used Qwen3.6-27B and Claude 4.6 Sonnet. The methods that "keep improving across the
full window" are CLM (writable context), CLM+subagents, and summarization; at the 128K budget
summarization outscores CLM (47.8 vs 47.3). The sketch's posture — projection-bounded
append-only — is neither of those; the citation supports "some context management beats none at
twelve hours," a weaker and different claim.

**CLM's FLOPs shares.** The sketch cites none of them — no occurrence of prefix-reuse FLOPs,
SCR, or the 7.7x head-edit multiple anywhere in design-sketch.md — so there is nothing to
regrade. For the record: the corpus grades the SCR implementation code-verified with shipped
tests (context-language-models.md §8), records the FLOPs-share drift between paper and repo
(65.0% vs 65.5%, §9), and notes the FLOPs metric is a model of serving rather than wall-clock
(§7). If the measurement campaign adopts a cache-accounting metric, deref-and-consistency.md
§4.2 already selects CLM's prefix-reuse FLOPs; the sketch should say so when it writes the
campaign up rather than treating the metric as given.

**The +7.7 edit-tool ablation (row 34).** The number is the SWE-agent NeurIPS 2024 ablation on
GPT-4 Turbo over SWE-bench Lite. benchmarks.md's own unknowns section records that same-model
harness spreads shrink across model generations (the Anthropic-scaffold-minus-mini gap went 7.5 →
4.8 points between Sonnet 4 and Opus 4.5). The sketch states the 2024 figure as current pricing.

**CLM's skill-evolution result (row 40).** 38.3 → 74.2 is paper-only (ContextBench, GPT-5.4 with
a Claude Fable 5.1 proposer). The gate mechanism is code-verified; the outcome number is not.
The sketch leans on the outcome.

**Unreal's cost claims.** The sketch avoids them, and that is correct: unreal-agent.md §10 marks
the 40%-savings and per-benchmark numbers vendor-reported with no independent replication, and
§11 lists them blog-only. The async mechanics the sketch adopts from §3–§5 are code-verified;
the benefit is properly confined to bet 1.

**Manus's token ratios.** no-compaction-approaches.md §9 records the 100:1 ratio and the 50-call
average as blog-reported with no published ablations. The sketch does not cite these numbers; it
does cite Manus's masking rule (row 18), which carries the same evidentiary weight and an
additional portability caveat — masking requires provider prefill support (no-compaction-approaches.md §1, Tradeoffs).

## Extrapolations across domains

**Benchmarks to orchestrator seat.** Rows 20, 21, and 34 all rest on SWE-bench-class or
single-repository optimization tasks measured over minutes to twelve hours. The seat the sketch
targets is a long-horizon orchestrator seat woken by tasking over days. The corpus contains no
controlled measurement of any context posture at that horizon: deref-and-consistency.md §4.1 and
context-networking.md §5.2 define the measurement that would settle it, and the sketch's own
milestone 4 schedules it. Rows 20–21 and 34 should carry that scope note rather than reading as
settled support.

**fx's child authority to module admission (row 38).** fx.md §8 verifies
`admitChildPermission` for subagent children: ranked permission modes, refusal on escalation. The
sketch transfers the mechanism to admitted tool modules. The mechanism exists; its application to
modules is the sketch's design and should be marked as such.

**The handle-join blend (row 26).** prime-agent.md §3 supplies the handle primitive
(`BashHandle.tail()`/`.output()`); the sleep-until-something-lands semantics come from
unreal-agent.md §5's preamble contract. Citing prime alone blends two systems.

**CLM's fingerprint to capability sets (row 46).** The verified fact is a `code_fingerprint`
hash of harness source in usage records (context-language-models.md §3). Capability-set
trajectories are the sketch's addition, acknowledged by "in the spirit of" — acceptable, kept
here for completeness.

## Unsupported or mis-cited specifics

- **Row 12** ("expected never to fire"): no citation, and the corpus holds the opposite nuance.
  See C1.
- **Row 18**: the masking half is Manus's vendor claim; dsh's §10 records a different mechanism.
  See C2.
- **Row 23**: "replacement is the primary path" — unreal-agent.md §13 lists whether replacement
  dominates as an open question with no in-repo telemetry; the provider-dependence of the
  two-item form is vendor-reported (§11).
- **Row 30**: no corpus system runs generated programs in the harness's own language; dsh §8
  explicitly lists re-deriving confinement as the open cost of in-process evaluation.
- **Row 37**: module digest and admitting principal in the admission event are the sketch's
  design; dsh §2 verifies only that installation requires authorization.
- **Row 43**: `harness.change` is an invented event name; dsh's vocabulary is `request/header`
  change reasons plus `developer/message` tool deltas (deepseek-harness.md §1.1, §10).
- **Row 14**: "content-addressed file under the session directory" describes fx only; unreal
  writes per-call capture files and arcee pages a stored stream by `output_id`.
- **Row 4**: the pi citation for the cut-point invariant should be §7 (and §9/§11), where
  `isCutPointMessage` and `orderToolResults` live; §4 is the loop section.
- **Row 39**: the prime citation for the versioned orchestration graph should be §9.

## Internal consistency

**C1 — "Compaction … It is expected never to fire" (§2).** The corpus position is dormancy with
a defined trigger, not absence of firing. NOOA ships three compaction paths; the shipped
benchmark agent installs the summarizer by default at a 75%-of-window trigger, and a reactive
archive fires when a provider rejects a request (nooa.md §3.6). NAC keeps threshold compaction at
70% for its orchestrator as a fallback (arcee-nac.md §4, §10). Unreal fires compaction at
per-model thresholds near 200k tokens (unreal-agent.md §7). no-compaction-harnesses.md §9
summarizes the field: summarization is "retired to the role … an unused safety mechanism, invoked
only when the displacement store was not written to in time." The sketch's own §3 cites CLM §5
showing a plain append-only baseline stalling inside two hours; the sketch's displacement stores
(spill files, standing state, dynamic tail) bound the projections but the event region still
accumulates turn records, and nooa.md §3.6 records that NOOA's own events grow linearly with the
only releases being its three compaction paths. **What the sketch should say:** compaction is a
defined safety stage with a concrete trigger — name one, for example NOOA's 75%-of-window
proactive threshold plus a provider-rejection archive — and state which of the three regions is
expected to stay bounded by construction and which is not.

**C2 — Catalog masking vs self-extension (§3 vs §6).** §3 states the tool catalog is "written
once and masked at decode rather than mutated." §6 makes admission a model-callable registration
step that adds a tool to the seat's catalog at a turn boundary, and §6's final paragraph
acknowledges that a catalog change invalidates the cached prefix. These cannot both hold as
stated: an admitted extension either mutates the catalog (the thing §3 forbids) or is masked at
decode (in which case the model cannot call it until it is unmasked, which is a mutation of
availability). Manus's masking solves authorization with definitions fixed; dsh solves it by
keeping definitions identical across modes and refusing changed definitions
(`ToolHistoryProjection`, deepseek-harness.md §5.1). The sketch's §16 lists the boundary-timing
question as open but §3 states the rule unconditionally. **What the sketch should say:** pick one
mechanism and scope the other: definitions fixed at seat start with decode-time masking for
availability (Manus, vendor-reported, provider-dependent), or turn-boundary definition changes
surfaced as dsh-style deltas with the prefix invalidation priced. Self-extension then uses the
chosen mechanism and the sketch says so.

**C3 — "Minimal" vs a growing admitted set (§1, §3, §6).** §1 promises a small tool set; §6
says self-extension "adds capability to a seat and does not alter what 'minimal' means." For the
model, the effective catalog grows with every admission: the generated description enters the
prompt, and each admission invalidates the cached prefix from the changed block onward — the
economics §3 itself invokes. The sketch places no budget on extension descriptions. fx.md §14
gives the corpus precedent for budgeting a growing catalog: skill descriptions capped at 1,024
bytes with the catalog prompt budgeted at 2% of the window and over-budget entries dropped with a
notice. **What the sketch should say:** "minimal" names the shipped set; admitted extensions pay
an explicit prompt budget and a prefix-invalidation cost, both recorded, with the fx §14 numbers
as the starting defaults.

**C4 — Two planes vs OS-enforced sandboxing (§3 vs §10).** §3 adopts NOOA's two planes: whole
values live in the process, the transcript carries renderings. nooa.md §3.6 records the
limitation the sketch must confront: in-process execution is what preserves pass by reference,
and the sandbox backend "trades reference semantics away at the boundary." §10 adopts Codex
CLI-style OS enforcement with network off by default for everything the seat can technically do.
In a single Bend2 binary, confining tool execution to the OS means confining the process that
also holds the whole values, or moving tools out of process. The sketch never states which
components run confined and which stay in-process. **What the sketch should say:** name the
boundary — for example, bash and the program lane run in confined child processes, while the
seat's typed standing state stays in-process and the second plane covers seat state only — and
mark the resulting limitation of the value plane against nooa.md §3.6.

**C5 — "No quotas, counters, or step caps" vs the corpus's budget guidance (§11, row 64).**
benchmarks.md concept 5 and its synthesis point 3 draw the opposite conclusion for baton-cli:
scores move with step budgets (tau-bench 30 → 100), so the tasking protocol should carry explicit
step/token/time budgets per task, record them in the session, and enforce them uniformly. The
sketch cites concept 5 to justify omitting budgets and keeps only per-tool timeouts. The
defensible position is the corpus's: no ambient harness caps, but task-scoped budgets arrive with
the tasking, are recorded, and are enforced. **What the sketch should say** exactly that.

**C6 — Steering citation and commit cadence (§4, §8).** §4 cites arcee-nac.md §2 for "a steering
message never queues behind a tool call." arcee §2 records the opposite behavior — steering
queues in a table claimed at the next model-call boundary, and §10 records that a long thread
delays steering for the whole batch. The never-queueing property belongs to unreal-agent.md §3
(and dsh's next-step inbox, deepseek-harness.md §1.1). Separately, §8 states "Commits are
deliberate acts rather than a per-turn rhythm" while §16 lists commit cadence as open and
context-networking.md §6 records the cadence/cache interaction as unmeasured. **What the sketch
should say:** cite unreal §3 for the steering property, cite arcee as the recorded
counterexample; either mark the commit-cadence policy as a bet with a falsification condition or
restate §8 to defer to §16.

**C7 — Smaller citation repairs.** Row 4 (pi §7 not §4), row 24 (grace windows are unreal §5),
row 26 (prime §3 for the handle, unreal §5 for the sleep semantics), row 39 (prime §9 not §4),
row 61 (fx §15 is the supporting record; §7 is the TUI being set aside). Each is a one-line
citation fix; the underlying claims are verified.

Where the sketch is right and needs no change: rows 1–3, 5–11, 13, 15, 17, 19, 22, 25, 28–29,
31–32, 41–45, 47 (substrate half), 50, 52, 54, 57–60, 63, 65–66, 68–73. The mechanical core of
the proposal is the best-supported part of the document.

## Proposed amendments

1. **Rewrite the §3 "reason this shape matters" paragraph (sketch lines 76–81).** Quote the full
   NOOA comparison — NOOA 82.2% at ~28 calls/1.1M, OpenCode 78.6% at a similar call count/~1.3M,
   PI 78.2% at 66 calls/2.2M — label all figures paper-reported (nooa.md §3.5, arXiv:2607.20709),
   and delete the inference that the alternative posture costs 66 calls/2.2M. State what the
   evidence supports: bounded projections with in-process values kept one harness's transcript
   small on SWE-bench Verified; long-horizon improvement evidence exists only for writable-context
   and summarization postures on 12-hour single-repository runs (context-language-models.md §5,
   paper-only). Add a sentence scoping all of it: no corpus measurement covers a long-horizon
   orchestrator seat; milestone 4's campaign is the instrument.
2. **Replace "It is expected never to fire" (§2, sketch line 52) with a trigger and a boundary
   statement.** Text along the lines of: "Compaction is a safety stage with a defined trigger —
   proactive at 75% of the window on the NOOA pattern, plus a reactive archive when the provider
   rejects a request (nooa.md §3.6). The event region is expected to stay small because tool
   bodies spill and standing state lives in the dynamic tail; it is not bounded by construction,
   and the trigger exists for when it grows anyway." This reconciles §2 with §3's own CLM
   citation and with no-compaction-harnesses.md §9.
3. **Resolve the catalog contradiction between §3 and §6.** In §3, replace "The tool catalog is
   written once and masked at decode rather than mutated" with the chosen mechanism, stated with
   its evidence class: either (i) definitions fixed at seat start, availability gated by
   decode-time masking, marked vendor-reported and provider-dependent
   (no-compaction-approaches.md §1), or (ii) definitions change only at turn boundaries, surfaced
   as request-header change reasons plus `developer/message` tool deltas, with the prefix
   invalidation priced (deepseek-harness.md §10). In §6, point the registration step at the same
   mechanism, and replace the invented `harness.change` event name with the chosen vocabulary.
4. **Budget admitted extensions (§6).** Add: admitted extension descriptions pay an explicit
   prompt budget with over-budget entries refused at admission, using fx's skill-catalog numbers
   as defaults (catalog budget 2% of the window, per-description cap 1,024 bytes, dropped entries
   noticed — fx.md §14); "minimal" names the shipped set, and the model-visible catalog plus its
   invalidation costs are recorded per admission.
5. **Fix §11's step-cap bullet (sketch lines 266–268).** Replace "No quotas, counters, or step
   caps in a working seat. Benchmark instruments cap steps because they are instruments" with the
   corpus position: no ambient harness caps; task-scoped step/token/time budgets arrive with the
   tasking, are recorded in the session, and are enforced uniformly (benchmarks.md synthesis 3,
   concept 5). Keep per-call timeouts as tool properties.
6. **Fix the steering citations (§4, sketch lines 101–104).** Cite unreal-agent.md §3 (and
   deepseek-harness.md §1.1) for "a steering message never queues behind a tool call"; cite
   arcee-nac.md §2 and §10 as the recorded counterexample that marks the property's boundary
   (batch-granularity steering delay), or drop the arcee citation.
7. **State the sandbox/value-plane boundary (§10, with a cross-reference from §3).** Add one
   paragraph: which components run in OS-confined child processes (bash, the program lane) and
   which stay in-process (the seat's typed standing state); note that NOOA's evidence ties the
   value plane to in-process execution and that confinement trades reference semantics at the
   boundary (nooa.md §3.6); declare the second plane as covering seat state, not tool bodies.
8. **Regrade the self-extension evidence (§6, rows 35–37, 43).** Reword the admission bullets to
   name what is verified (dsh's install-requires-authorization, §2; the shared
   prompt/enforcement predicate, §4.1) and what is the sketch's design (module digest and
   admitting principal in the admission event; admission-time contract validation for
   model-authored modules). This keeps the design and stops borrowing dsh's citation for it.
9. **Correct the miscitations (rows 4, 14, 23, 26, 39, 61).** pi §7 for the cut-point invariant;
   attribute the spill mechanism to fx and describe unreal's capture files and arcee's
   `output_id` paging as the two recorded variants; drop "replacement is the primary path" or
   mark it unmeasured (unreal-agent.md §13); cite prime-agent.md §9 for the orchestration graph;
   cite fx §15 for the event-log-as-interface recommendation.
10. **Mark the commit cadence as a bet (§8, §14).** Either add a fourth bet — "deliberate commits
    beat per-turn commits on receiver cache stability" with the falsification condition already
    written in context-networking.md §5.1 — or soften §8's sentence to reference §16's open
    question and context-networking.md §6.
