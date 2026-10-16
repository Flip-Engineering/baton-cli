# design-lead independent review and synthesis (round 1)

Session design-lead (Associate Conductor), Ensemble design-evaluation, under proposal-root
dispatch:6f27d5cf4f0490e581f3139ab608ee5f. Workers: proposal-strongman, failure-evaluation.

## 0. Revision base and method

- Review corpus: `/run/baton2-native-homelab/retained/baton-cli-orchestra-20261016/baton-cli` at
  `5941316491eb01d8794abddc5dcf1798801c4aaf` (CLI:).
- Canonical source re-checked: `/run/baton2-native-homelab/retained/baton2-compiler-741-20261015/postrelease-751-761-20261015-9/source`
  at `b1f006a6308bbb00e29a24322e4f7d5164774470` (SRC:), Bend2 toolchain `toolchain-home/bin/bend`
  2.0.25.
- Method: I re-read the sketch and all seven prior reviews, then re-derived the source-relative
  claims first-hand against SRC, and ran the smallest experiments on the pinned toolchain.
  Independent scouts re-derived the seat protocol, the knowledge layer and the REPL/citation
  question; their results are marked [SCOUT] where I have not personally reproduced the grep.
  Probes: `deliverables/design-lead/probes/`. My findings are recorded in Baton knowledge
  (`knowledge-record:5a4d1e06…`, `986567b0…`, `6fa6f377…`, `92ac4193…`).

## 1. Corrections to the prior audit (P1: the citation base is mixed across revisions)

Revised after proposal-strongman's round-2 critique (accepted: my first wording overstated). The
prior audit's citations do **not** all fail to resolve:

- `integration-baton.md` cites baton2 `10c2ae6d` and baton `1e050e420`; `integration-knowledge.md`
  cites `72fc39b45`; `feasibility-bend2.md` uses author-local paths `/Users/wahargis/Development/…`
  and `/tmp/bend-upstream`.
- In SRC, `1e050e420a99d775d3d2f943453c23535a701fd9` and `72fc39b45` **are** commits and both are
  ancestors of HEAD. At `1e050e42` the tree contains `impl/` (`impl/src/coordination-admission.mjs`
  7,257 lines; `coordination-ledger.mjs` 7,683; `mcp-northbound.mjs` 3,288;
  `swarm-native-bridge.mjs` 952), so the audit's JavaScript-line citations are reproducible **at
  their cited revision**. Only `10c2ae6d` is not an object in this repository.
- The JavaScript line was deliberately retired from this repository by commit `2b8449af`
  (2026-10-02, "Use the native coordinator source and contributor entry points"), which deleted
  `impl/`; HEAD `b1f006a6` (2026-10-16) has no `impl/` tree.

Consequence, stated exactly: the audit compares two lines that both existed, but only the Bend2 line
exists at the pinned production revision, and one of its two baton2 citations is unverifiable. Every
verdict must say which revision it is about. This also settles amendment 1 by history rather than by
argument: the repository itself chose the Bend2 line. Re-derived at b1f006a6:

- **C1 — Knowledge layer (integration-knowledge.md): verdict does not transfer.** At b1f006a6 SRC
  contains **no `impl/` tree at all**; the Cairn graph is spec + docs only
  (`spec/phase11/coordination-knowledge.md:164-166` lists 17 kinds, not the audit's 19;
  `docs/34-knowledge-horizons.md:13` claims 19, citing code absent here). The audit's "seat read
  path built and called by nothing" is **refuted here**: the names `recallPreview`,
  `serveKnowledge`, `knowledgeBriefingProvider`, `brief.knowledge` occur nowhere in SRC code, and
  the Bend2 seat knowledge store that does exist is live and consumed (CLI `main.bend:182-195`,
  `bend2/ui/orchestra/server.mjs:862`, `bend2/scripts/mcp-conductor.mjs:1165-1168`) [SCOUT].
- **C2 — "Neither exposes a task queue a harness client polls" (integration-baton.md §2.1): too
  strong.** `baton inbox` reads `messages` with `receipt IS NULL`, and the Codex path has a
  first-class queue (`codex_inbox_wakes`, `delivery.bend` queue SQL, `codex-inbox-store.bend:106-110`).
  Tasking is *push-delivered and* pollable [SCOUT].
- **C3 — "No HTTP/JSON protocol exists on that line": partially refuted.** No HTTP, but a
  newline-delimited JSON-RPC surface exists over stdio and a local socket
  (`bend2/scripts/mcp-conductor.mjs:9-13`), plus WebSocket framing on the Codex path
  (`bend2/src/host/codex-proxy.bend`) [SCOUT].
- **C4 — Harness adapter file-name drift.** The audit's `feasibility-bend2.md` cites
  `harness/{omp,codex,claude,muse}-worker.bend`; the files at b1f006a6 are
  `{omp,codex,claude,muse}-player.bend` (`terminology.md` rename). Cosmetic, but it is the
  fingerprint of the revision mismatch [SCOUT].
- **C5 — Platform constants are not portable.** The feasibility report's program-lane figures
  (60-110 ms, 95 ms with SDK import) are darwin arm64. On this linux x64 host with the same pin:
  check-only 0.36 s, run 0.39 s, emit C 0.33 s for a trivial program (`probes/lawgate.txt`). Any
  program-lane cost argument must be re-measured on the deployment platform.

## 2. New first-order constraint the sketch and both workers miss (P1)

**Baton's native harness set is closed, and a Bend2 seat cannot be driven today.**

- `bend2/src/coordinator/delivery.bend:20` — `native_receiver_sql`:
  `CASE WHEN json_valid(s.endpoint) THEN s.harness IN ('codex','omp','muse','claude-code') AND …`.
- `bend2/src/coordinator/control.bend:125` (`receiver_admitted`), `:198` (`start_admission`),
  `:281` (`turn_admission_sql`) each repeat `harness IN ('codex','omp','muse','claude-code')`;
  the refusal text at `control.bend` names "a registered Codex, OMP, Muse or Claude Code session".
- `bend2/src/coordinator/recruit.bend:47-86`: `harness` is a free-text parameter stored verbatim
  into `sessions` — registration does not refuse a novel harness, so failure is **late**, at
  receiver/turn admission, not at recruit.

Independently corroborated by runtime-lead's worker baton-contracts
(`knowledge-record:98e39a22…`) and by my own source read.

Consequence for the design: `baton-cli` — a new native Bend2 harness — is a **fifth harness**, and
the coordinator has no registration path for it. The design must state, as a milestone-1 decision,
which of two changes it makes:

- **(a) Speak one of the four adapter protocols.** Match `harness/omp-player.bend` RPC,
  `codex-player.bend` `exec --json`, `claude-player.bend` `--print --input-format stream-json`, or
  `muse-player.bend` `exec --json --prompt-file`; then Baton drives it unchanged. Cost: the seat
  inherits a foreign wire shape rather than the "concise action-verb" CLI it wants, and it still
  cannot be *named* a new harness.
- **(b) Extend Baton.** Add `harness/bend2-player.bend`, extend the three closed sets and
  `Delivery.native_receiver_sql`, and extend settlement (`message-status.bend`). Cost: a coordinator
  change with a named change set and an owner; this is real coordinator surface, not seat work.

The sketch's §1 says only that the seat "speaks the orchestrator's existing CLI protocol (baton2)".
That sentence is necessary but not sufficient; without (a) or (b) the seat never receives a turn.

## 3. Category error: there is no "baton2 protocol" (P1)

The sketch's §1 and §2 premise — "takes tasking, messages, receipts, and wakes over the baton2
protocol" — describes a wire protocol that does not exist on the Bend2 line. The seat surface is a
**CLI**: `baton2 DATABASE COMMAND ARGS` (`docs/bend2/architecture.md:25`,
`bend2/src/coordinator/main.bend:44`), and the seat is the native harness process that Baton
launches via a stored endpoint argv ending `receive SESSION HARNESS MODEL EFFORT CWD LOG MSGID`
(`delivery.bend`, `receive.bend:run`) [SCOUT]. Rewrite §1/§2 accordingly; the audit states this and
the sketch does not.

## 4. Operator-requirement conformance

| Req | Shipped reality at b1f006a6 | Sketch/worker position | Verdict |
|---|---|---|---|
| 1 actual Bend2 | Bend2 coordinator + C host bindings ship (43,412 lines of `.bend`); the JS line's implementation is absent from SRC | sketch is Bend2-first | conforms |
| 2 concise action-verb commands | seat verbs `inbox/read/report/ask/send/guide/finish/confirm/acknowledge`; installed CLI is action-verb | unchanged | conforms; add a rule forbidding invented non-verb subcommands |
| 3 Baton owns control identity | message/turn/stop/wake ids generated (`agent-command.bend:70-73`, `agent-native.bend:186-192`); receipts derived from owned complete reads and auto-created on successful settlement (`message-status.bend`) | strongman/audit keep it | conforms; **caveat**: auto-settlement only for the four harnesses — a novel seat must ack by hand until (b) lands |
| 4 randomized seed | `native-initial-input.bend`: `lower(hex(randomblob(64)))` (128 hex chars) per attempt, reused across retries, instruction + guidance prepended | unchanged | conforms; seat must not reseed |
| 5 no ambient quotas | corpus position: no ambient caps; task-scoped recorded parameters | **contested**: redteam P2 + audit item 19 want a "task budget envelope" | req 5 wins: keep task-scoped recorded parameters + per-call tool timeouts; reject ambient caps |
| 6 authority/lineage/alternatives/evidence | knowledge store records claim/evidence/limits/relations; promotions notice the parent | unchanged | conforms |
| 7 land through root | Baton `land`/`push`/`remote-tip` exist | root owns integration | conforms |
| 8 runtime limits proven vs source+smallest experiment | — | — | conforms; C5 is the discipline applied to the darwin constants |

## 5. Where I strengthen, reject and correct

- **Strengthen** the audit's mechanical core: Bend2 has no in-process evaluator or runtime module
  loader. Personally reproduced: `bend --help` lists no `repl/eval/test/debug/fmt`; `bend base exec`,
  `bend base File.sync`, `bend base Json` are refused (rc=1); `bend base File` lists only
  open/read/read_bytes/read_at/write/close. So the program lane must be out of process and
  self-extension must be declarative-data or repository-act.
- **Strengthen** the amendment "law-gated admission": personally reproduced that importing a module
  with one open law fails `bend hostprog.bend --check-only` ("Error: 1 TODO found.", rc=1), and
  `--checkup` names the offending import. The out-of-process admission gate is real.
- **Correct** the "one orchestrator line" decision (audit amendment 1). It is not an open choice
  between two live lines: the installed coordinator **is** the Bend2 build, and SRC contains the
  Bend2 implementation with the JS line's code absent. Restate amendment 1 as: target the Bend2
  line; §8's commit-and-cite becomes a proposal **against the Bend2 line**, blocked on the separate
  REPL lane (#778), with the reachable half (version-pinned cite + bounded render + deref receipt)
  shipping only after that lane lands.
- **Correct** §7: no operation copies a log prefix. Branching starts a fresh native conversation per
  candidate over a workspace snapshot (`branching-model.bend:13`: `branch_rounds(…, workspace,
  branch_count, snapshot, task, inputs, knowledge, includes, evaluator, direction, harness, model,
  effort, command)`), reproduced first-hand. The fork triple is a proposed extension to that record.
- **Reject** "compaction is expected never to fire" (unanimous with strongman and evidence-lead):
  proactive at 75% of window, reactive on provider rejection, pending-call carry-forward;
  no-compaction becomes a measurement arm.
- **Reject** the audit/redteam budget envelope as written; see req 5.
- **Accept** the steelman's load-bearing attack (measured evidence ∩ novel mechanisms = ∅) and its
  remedy: move the provider-contract check and the projection-bounding A/B into milestones 1-2 exit
  criteria.

## 6. Disagreements preserved (not forced to consensus)

1. **Any budget, quota or timeout vs the operator ruling.** The prior audit (amendment 19) and
   redteam (P2) recommend a mandatory task budget envelope; the operator requires that no runtime
   step, token or time quota, and no arbitrary ceiling, controls admission, continuation or
   unfinished work — a task-scoped budget or timeout used that way is a conflict too, and calling a
   limit a tool property does not remove it. Position taken: no such mechanism. Preserved dissent:
   the redteam's burn-risk and failure-evaluation's S7 quiescence concern are real; they are
   answered by retention, reporting and Conductor decision, not by a seat-side deadline, and
   failure-evaluation's S7.2/S7.5 and correction 5 are contested rather than adopted.
2. **Sequence: crash-safe blocking seat first (Alternative A) vs async-first.** strongman keeps
   async at milestone 2 with an A/B gate; the redteam prefers blocking-first. Position: async-first
   is retained *behind* the measurement gate, not assumed; the dissent is recorded because the
   A/B's token half is unmeasured.
3. **Catalog-at-turn-boundary latency.** Conservative (mask-at-decode, catalog changes only at turn
   boundaries) vs the cost of waiting for a fresh capability. Unresolved.

## 7. Change map: current Baton/Bend2

| Sketch element | Bend2 reality at b1f006a6 | Change class |
|---|---|---|
| §1 "baton2 protocol" | CLI `baton2 DATABASE COMMAND ARGS` | text fix |
| §1 seat registration | closed set {codex,omp,muse,claude-code}; recruit fail-late | **new coordinator change (§2 above)** |
| §2 append durability | Base has no fsync/rename/stat; C effect needed; `File.open(...,"a")` = O_APPEND | design + host layer |
| §4 async op layer | no seat-side equivalent; process family exists (`host/process-spawn.c`) | seat work |
| §5 program lane | no in-process eval; `bend prog` child; law gate real | replace text |
| §6 self-extension | no runtime module loader; declarative data + repo act + dlopen | replace text |
| §7 fork triple | branch_rounds snapshot, fresh conversation, no log prefix | restate as proposal |
| §8 cells/citations/grants | **absent** on the Bend2 line; JS implementation not in SRC | proposal, blocked on #778 |
| §9 workset | no seat-side typed workset | seat work |
| §11 knowledge read | Bend2 seat knowledge store live; read via `baton knowledge` | converge on the Bend2 store |
| §11 quotas | no quota/ceiling/timeout may gate admission, continuation or unfinished work | operator ruling; observation only |

## 8. Claim register (round 1)

| # | Claim | Verdict | Evidence | Severity |
|---|---|---|---|---|
| 1 | Bend2 has no in-process evaluator / runtime module loader | holds | `bend --help`; probes; no repl token in `bend2/src` | blocks §5,§6 as written |
| 2 | Program lane must be out of process | holds | as #1 | design change |
| 3 | Law-gated admission via `--check-only` works | holds | `probes/lawgate.txt` | enables §6 replacement |
| 4 | Self-extension authority cannot come from Bend2 types | holds | forgeable records (feasibility probe 7) | safety |
| 5 | A new Bend2 harness cannot be driven today | holds | `control.bend:125,198,281`; `delivery.bend:20`; `recruit.bend` | **P1** |
| 6 | "baton2 protocol" exists | refuted | `docs/bend2/architecture.md:25`; `main.bend:44` | P1 text |
| 7 | REPL cells/citations/grants reachable by a seat | refuted at b1f006a6 | no `repl` token in `bend2/`; no `impl/` at HEAD (removed by 2b8449af) | P1 dependency |
| 8 | Fork copies a log prefix | refuted | `branching-model.bend:13` | P1 text |
| 9 | Tasking is push-only, no queue the seat polls | refuted | `inbox` + `codex_inbox_wakes` | P3 |
| 10 | Prior-audit knowledge verdicts transfer to the pinned revision | refuted at b1f006a6 (reproducible at 1e050e42) | no `impl/` at HEAD; Bend2 store live; in-tree Cairn spec says 17 kinds | P1 |
| 11 | Compaction never fires | rejected | CLM 12 h, Chroma rot, NOOA summarizer | P1 |
| 12 | Ambient budget envelope required | rejected | operator req 5 | dissent |
| 13 | Seed is per-attempt 128-hex, reused on retry | holds | `native-initial-input.bend` | conformance |
| 14 | Program-lane cost is 60-110 ms | platform-bound | `probes/lawgate.txt` (0.33-0.39 s here) | P2 |
| 15 | Steelman: evidence/mechanism non-overlap | holds | NOOA in-process vs OS confinement | sequencing |
| 16 | The pinned tree's law gate is green | **refuted** | `bend bend2/src/coordinator/knowledge-laws.bend --check-only` exits 1 (failure-evaluation P1; I re-ran it) | P1 prerequisite |
| 17 | Base can express a deadline-bounded wait | **refuted** | `Chan.recv` has no timeout, no select/race; only `IO.sleep`/`IO.now` (failure-evaluation P5) | P1 for §4 |
| 18 | A tool-declaration digest pins executed bytes | **refuted** | declaration admitted, bytes live in a seat-writable path (failure-evaluation S4) | P2 safety |
| 19 | The shipped seat knowledge store preserves lineage | **refuted** | `knowledge.bend:288` `ON CONFLICT(id) DO UPDATE SET author=excluded.author,…`; `agent-native.bend:215` keeps a caller id (S6; I verified both) | P1, violates req 6 |
| 20 | A timeout/budget may gate unfinished work | **rejected** | operator ruling | dissent recorded |

## 9. Experiments (cheapest first, zero model cost first)

1. **E-HARNESS (new, P1):** recruit a novel-harness session and attempt a dispatch at b1f006a6 on a
   throwaway DB copy; confirm the refusal and name the exact code change. Cost: minutes, no model.
2. **E-LOG:** durability fuzz + crash injection against O_APPEND+fsync append; assert call/result
   atomicity and reason-on-every-exit. No model.
3. **E-GATE:** admission gate end to end: open law → `--check-only` refusal → satisfied proof →
   admission. No model (partly done).
4. **E-PROVIDER:** replacement vs second-item tool-result acceptance on the target providers, plus
   prefix-cache hit rate across turns. Minutes of model time.
5. **E-BOUND:** projection bounding A/B, transcript bytes/tokens per task. One seat.
6. **E-ASYNC:** async vs blocking, tokens/turns/wall-clock. Needs the op layer.
7. **E-LANE:** program lane vs discrete calls; measured on the deployment platform (C5).
8. **E-CITE:** two-seat citation vs inline vs re-derivation, after #778.

## 10. Source-linked follow-ups

1. Coordinator issue: add a fifth harness (or explicitly refuse it) — `control.bend:125,198,281`,
   `delivery.bend:20`, `message-status.bend` settlement. (Owner: root lane.)
2. `knowledge-laws.bend` drift: schema law omits `kind`/`source_kind`; references undefined
   `evidence_ok`; calls `promotion_admitted/2` against the module's `/3`
   (`knowledge.bend:306`) [SCOUT]. File as a defect.
3. `main.bend` usage prints `baton DATABASE COMMAND ARGS` while `architecture.md:25` says `baton2`.
4. Rewrite the corpus citations to pin each claim to its own revision (the JS-line claims are
   reproducible at `1e050e42`; the baton2 claims at `10c2ae6d` are not reproducible in this repo),
   and remove author-local paths (`/Users/wahargis/…`) so the audit can be re-run.
5. `knowledge-laws.bend` fails its own gate, which is stronger than drift: the M1 schema law omits
   `kind`/`source_kind`/`destination_kind` that `knowledge.bend` ships, and line 67 references
   `K.evidence_ok`, which has no definition anywhere under `bend2/src/`. File as a defect and let
   the gate prove it. (Raised by proposal-strongman round 2; I verified the missing definition.)

## 11. Deliberation addendum (peer positions, and where I disagree)

Peer material read after recording my own findings: `deliverables/baton-contracts/report.md`
(runtime lane), `deliverables/evidence-lead/{claim-register-v0,experiments-v0,interim-note}.md`,
`deliverables/proposal-strongman/strongman-proposal.md`.

- **Agreement — F1 is real and independently corroborated.** baton-contracts reaches the same
  closed-harness-set result from the same three gates plus the live CLI, and also confirms
  `recruit` accepts a free-text harness so the refusal lands at turn time
  (`knowledge-record:98e39a22…`). Two independent derivations, same answer.
- **Disagreement — the knowledge verdict (O-KNOW-01).** evidence-lead's claim register keeps
  O-KNOW-01 (two stores; Cairn graph; "seat read path built, tested, called by nothing") as
  SUPPORTED, leaning on `integration-knowledge.md`. I reject that at b1f006a6: SRC contains no
  `impl/` tree, the audit's read-path names occur nowhere in SRC code, and the in-tree Cairn spec
  says 17 node kinds where the audit says 19. The correct grade is *unverifiable in this
  checkout*, with the JS-line evidence marked inherited — which is what baton-contracts D4 asks
  for before `audit-findings.md` amendments 1-2 are executed. Preserved as a live disagreement.
- **First-hand evidence for the live read path.** Working as design-lead I read the scoped knowledge
  store through the shipped CLI and observed 23 findings across the worker scope, including three
  authored by evidence-lead and two by baton-contracts. That is direct proof that the seat
  knowledge read path is live and scope-aware at b1f006a6, and it refutes "called by nothing" as
  applied to this revision.
- **New constraint from baton-contracts F6, adopted.** Dispatch is route-gated
  (`agent-native.bend:353`; `commands.bend:442-445`): a worker cannot dispatch or steer outside
  parent/conductor/tight-peer/operator routes, and a denied route stores nothing and wakes nobody.
  §4's "orchestrator inbox" tool and any seat-to-seat steering must therefore name the route they
  travel, and the fixture set must include `message-route-denied`.
- **New constraint from baton-contracts F5, adopted.** `acknowledge` is recipient-owned and
  turn-scoped with first-receipt-wins (`agent-command.bend:85-117`); a §8 deref receipt must mint
  its own rows rather than reuse message receipts.
- **Agreement — no identity riding.** baton-contracts D3 rejects bootstrapping a Bend2 seat under
  the `omp` harness identity; I concur: it falsifies route identity, observed fields and OMP-only
  `steer` semantics. A fifth harness must be explicit.
- **Agreement — mechanism over discipline.** baton-contracts D2 holds that per-turn seat knowledge
  writes should be forbidden by mechanism, not discipline; concur (settlement-time emission).
- **Accepted correction from proposal-strongman round 2.** My first wording — "cites checkouts that
  do not exist" — was overstated: `1e050e42` and `72fc39b45` are real commits and ancestors of HEAD,
  and `impl/` is present at `1e050e42`; only `10c2ae6d` is absent. Section 1 and the claim register
  are corrected above, and `knowledge-record:afb1881b…` supersedes `knowledge-record:5a4d1e06…`.
  The substantive consequence is unchanged and sharper: the audit compares revisions, and the
  repository retired the JS line at `2b8449af`.
- **Operator resolution of the quota/park language (this supersedes my earlier adoption of the
  strongman's refinement).** The Conductor has ruled: no runtime step, token or time quota, and no
  arbitrary ceiling, controls admission, continuation or unfinished work; a task-scoped budget or
  timeout used that way is still a conflict; provider quota failures are observed outcomes to
  retain and report; and policy-driven parking is not accepted. Resolved text: task-scoped
  parameters are recorded and reported only; per-call timeouts are operational tool properties
  whose outcome is an observation; a call that does not return, or a provider quota error, is
  reported to the Conductor, who decides; the seat never parks or caps itself. The strongman's
  "durable park and resume on provider quota" (round-2 critique, section D) is **rejected**, and so
  is any seat-side `timed_out` transition that ends work. Preserved dissent: the redteam's
  P2 burn-risk is real and is now handled by reporting rather than by a cap; if the Conductor wants
  a stronger guarantee it must come from the operator's tasking, not from the seat.
- **evidence-lead's claim register `I-QUOTA-02` is marked RESOLVED; that resolution does not
  hold.** The register preserved the corpus position (recorded parameters, enforced uniformly);
  under the Conductor's ruling, uniform *enforcement* is itself the conflict when it controls
  unfinished work. Original preserved; the correction is: parameters are recorded and reported,
  enforcement removed, parking removed. Recorded here and raised back to evidence-lead rather than
  edited into their file.
- **Correction accepted from runtime-lead on the lock citation.** `SRC:bend2/src/host/session-lock.c`
  does not exist; `session-lock.bend` declares the `SessionLock` effect and its C half is in
  `process-spawn.c` (`flock(LOCK_EX|LOCK_NB)` at `:2438`; the database lock is `sqlite.c:881`). My
  revised §2 and follow-up 1 are corrected accordingly.
- **Correction to the §5 authority claim (raised by the Conductor).** Socket re-entry is transport
  and routing, not confinement: it does not deny a same-UID child filesystem or process access.
  Revised §5 now names the real boundary (an OS sandbox profile, network off except loopback,
  explicit writable roots, repository metadata read-only) and marks it **untested**, with a probe
  that attempts a direct out-of-root write and a direct process spawn from inside the child. Until
  that probe runs, the design must not imply that protocol routing bounds all effects.
- **§8 form agreed with proposal-strongman:** keep the dependency statement, the reachable
  version-pinned read, and the E1 experiment; drop grants and fences to named proposals; and never
  cite the `context/` subsystem's JSON array cells as substrate.
