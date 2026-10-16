# critique.md — bend-feasibility reciprocal critique (critique round)

Lineage: independent round complete — report `report:1db006672cb3467c582934e5385fe3fb`
with admitted completion request `message:bend-feasibility:92b02f50a5c93ec2e042518a643c32a8`
(retained as lineage; not superseded by this critique). Opposing report:
`deliverables/baton-contracts/report.md` + `evidence.md`, read in full.
Deliberation state: `deliverables/runtime-lead/amendments-r1.md`, `amendments-r2.md`.
Root candidates reviewed: `review-ready/design-sketch.final-review.md` (earlier round,
corrections in `../review-corrections.md`) and
`review-ready/design-sketch.reconciled.2e65ccfae24e.md`, SHA256
`2e65ccfae24efe0cb2112572f3e3d9a7c6a281142d444608efa864b16cf3132b` (hash verified this
round; read in full, 561 lines). All source claims below rechecked first-hand at
canonical `b1f006a6308bbb00e29a24322e4f7d5164774470` against the recorded compiler fork
(upstream v2.0.25 checker/Base/CLI byte-identical; comp.ts baton741→baton776 fork,
qualification false). Site inventory: `evidence-sites.md` (same directory).

## 1. Accepted claims (verified, no correction)

- **F1 core, F6, F7, and the §1 primitive table**: confirmed. The closed harness list,
  the route gate (`commands.bend:442-445` `message_route`, refusal
  `message-route-denied` with exact condition text), the absence of any
  repl/cell/cite/grant verb in `Domain.known` (agent-domain.bend:43), the SQLite-only
  knowledge store with destination-owner promotion (knowledge.bend:300-312,
  `promotion_admitted`), and the workspace+inputs branch record without any log-prefix
  or version vector (branching-model.bend:13-17) all check at the pin.
- **F5's source reading**: `agent-command.bend:85-117` says exactly what the report
  says — recipient-owned turn-scoped scope, the `handling-context` refusal string at
  :88 verbatim, first-receipt-wins via `coalesce(handled, receipt)`
  (`handling_sql`, :79-83), explicit selection generating `handled:<id>` receipts.
  `message-status.bend:7-8` keys receipts per (attempt, identity, message), so the
  deref-receipt conclusion (own rows) is right.
- **The contract tests' general executability**: all ten are CLI verbs over a scratch
  DB; none requires new host effects. My twelve probes establish the underlying effect
  surface works on this toolchain (DB-through-C-effects is the coordinator's own
  `sqlite.c` path; my P03/P05 prove the same effect contract end-to-end).
- **Reconciled candidate's incorporations** (checked against my round): §2's P03
  demonstration with the exit-2 explanation and the U32/EOVERFLOW segment-rotation
  consequence; §5's corrected interpreter-checks-before-running sentence, P10 JS-loader
  with process-boundary caveat, P11 + coordinator-build cost anchors; §6's constructor-
  namespace and `io_cstr` NUL-contract additions with multi-string packing tests; §5's
  same-UID ambient-authority statement with direct-write and SDK-impersonation tests.
  These now match my captured evidence; no residual disagreement on them.

## 2. Corrections (claim → evidence → correction → smallest discriminating test)

### C1. F1's gate-site count is understated: five sites → 8 SQL sites + 4 law sites + 2 Bend predicates + the launch dispatcher
Evidence: `evidence-sites.md` §A-C. Beyond the agreed five (control.bend:125,198,281;
delivery.bend:20; plus control.bend:177 which runtime-lead's R2-2 counted), the closed
list also gates `blocked_cause_sql` (commands.bend:196), `configure_admitted`
(commands.bend:301), `supported_sql` (instance.bend:58), `dirty_session_sql`
(stop.bend:58); three laws pin the generated SQL as exact strings
(control-laws.bend receiver/start/turn laws, :36-48, :104-115, :106) and one pins the
refusal string byte-exactly (:415); `supported_harness` gates the direct-turn path
(turn.bend:1519); and `launch` (turn.bend:1001-1008) dispatches via nested `Bool.pick`
with **claude as the fall-through default**.
Correction: the fifth-harness change set is ~15 edit sites plus the player module and
receiver path, and it MUST include control-laws.bend in lockstep.
Discriminating tests: (T11) a `turn` against a session whose harness is any
unsupported string must refuse with the :286 string, never fall through to a Claude
launch — pins the dispatcher's default arm; (T12) a partial gate edit (one IN-list
changed) must fail `check-native.sh` at the pinned laws — pins the lockstep property,
which is a feature: the law suite mechanically catches incomplete fifth-harness edits.

### C2. F1's quoted refusal string is truncated
Evidence: control.bend:286-287 and its byte-exact law control-laws.bend:415: the full
string ends "…recorded workspace**; inspect its session and retained work.**"
Correction: test 1's expected string must be the full text; note the gate also requires
`parent IS NOT NULL AND workspace<>''`, so the test recipe must recruit with a parent
and workspace or a different refusal fires first (their fail-late note partially covers
ordering).

### C3. F4 is understated: knowledge search/traverse/citation are wired to a foreign schema and are latent failures on this line
Evidence: knowledge.bend:186 (citation synthesis), :205, :209 (traverse/search) read
`FROM nodes`/`edges`; no bend2 code creates those tables (only retained-tree hit: a
digested foreign Rust migration under docs/reference/evidence); the live DB copy
(baton-contracts' own orchestra-copy-20261016.db, queried read-only this round) has 24
tables and `SELECT count(*) FROM nodes` errors "no such table: nodes"; the write path
creates only the three knowledge* tables (knowledge.bend:16-19).
Correction: F4's "KG search/traversal … SHIPPED form, WRONG store" and its LiveOK
(help-text) marking should read: record/read/promote are shipped and store-backed;
**search, traverse, and the citation-synthesis arm reference a schema this line never
materializes** — on any store this line creates, they fail with an SQLite no-such-table
error. The reconciled candidate's §8 ("destination-owner promotion have source
consumers") is accurate for record/promote/read but does not yet carry this.
Severity: I would raise the store item inside F4 from Medium framing ("wrong store")
to a concrete broken-read finding; the pollution/retention discussion is moot until
the read path has a store on this line.
Smallest discriminating test (T9b): a *registered* session runs
`knowledge search --query x` against the scratch DB — predicted: SQLite no-such-table
error naming `nodes` (or `edges`). This also sharpens their test 9, which only
exercises the unregistered-reader refusal.

### C4. F2's "nothing to commit through" overstates absence: a content-identity and admission substrate exists in-tree
Evidence: `Domain.known` carries `context` (agent-domain.bend:43; verb surface
`context engines|install|query|result` at :198/:314); context/store.bend:89-110
(`managed_artifact_schema` — "binds the verified invocation bytes to the exact
immutable artifact", sha256 identity, association rows); context/bound-admission.bend,
identity.bend, native-managed-query.bend (Bootstrap with
artifact_sha256/invocation_sha256/owner_witness), service.bend
(SubmissionManaged/SubmissionManagedUncertain).
Correction: F2's High rating **stands** (no cell/manifest/binding/versioned-read
surface, confirmed by grep and DB copy), but the correction text should say the
missing pieces are the named-artifact cell model, version semantics, cross-seat deref
receipts, and lease/fence rules — while content-addressed admission with ownership and
uncertain-outcome handling already has an in-tree implementation (the managed-query
machinery) that the commit lane should extend rather than re-invent. Language side
confirms the hard half: no evaluator/loader at the pin (my independent round), so no
seat-side Bend2-code substrate exists without coordinator changes — via the SQLite
knowledge store a seat could write rows only through coordinator verbs (route/authority
gated), and direct DB writes would bypass every admission contract; the context/
engine is coordinator-side, seat-reachable only through its verbs.

### C5. F5's framing slip (conclusion unaffected)
The report asks whether "the receipt model is enforceable under the language's affine
constraints in the way it assumes." Enforceability does not live in the type system:
`handling_sql` is a BEGIN IMMEDIATE transaction with a SQL condition keyed on
(attempt, native, identity) and `coalesce` first-write-wins (agent-command.bend:79-83).
Bend's affine rules shape how the SQL string is *built* (pure defs, `+` binders), not
whether receipts are enforceable. F5's conclusion — turn-scoped, recipient-owned, own
rows for deref receipts — is confirmed as stated above.

### C6. Reconciled candidate residual additions (§1, §4, §13)
(a) §1's change-site list (control.bend, delivery.bend, message-status.bend,
harness/*-player.bend) should add **turn.bend** (launch dispatcher with the claude
fall-through, `supported_harness` at :1519, the 20 OMP feature flags) and
**control-laws.bend** (three SQL-pinning laws + :415 string law) — the laws are also
the reviewer's guarantee that partial edits fail the build. (b) §4's "a concrete event
effect or observation-polling composition must be specified and tested" should cite the
demonstrated Base TCP EOF semantics (peer close arrives as the empty string;
`None{}` is timeout-only — P06): any wake/read effect must define close detection, and
the naive poll loop iterates forever on EOF (P06's first run is the retained counter-
example, truncated with provenance). (c) §13 "builds record the exact compiler" should
name that the recorded fork (baton741→baton776 lineage) is not a release artifact
(qualification false, fork-manifest.json) — release qualification is #772's lane.

## 3. Contract tests 1-10: executability and amendments

Executable against a scratch DB with the installed release binary, no new effects:
1, 2, 4, 5, 6, 7, 8, 9, 10. Amendments:
- Test 1: use the full refusal string (C2); recruit with parent+workspace.
- Test 3: needs a live receiver endpoint; `receiver --command EXECUTABLE` accepts any
  executable, so a stub script makes the wake hermetic. As written ("wakes the child's
  endpoint") it presumes a registered real endpoint.
- Test 9: keep, and add T9b (C3).
- Add T11/T12 (C1).
- Version-skew caveat for all ten: the tests execute the *installed* 2.0.0 release
  (e6a56295) while the evidence cites b1f006a6 source; the law-pinned strings (C1)
  make drift unlikely for the gated behaviors but not impossible elsewhere. Exact-
  source execution of the suite belongs to the release/build lane; this lane is barred
  from coordinator builds.

## 4. Demonstrated primitives vs seat contract (from my twelve probes)

Demonstrated at the pin (Linux, both lanes where stated): durability family
(write/fsync/fsync-dir/rename/unlink/stat-size/mkdir, P03); child supervision with
streamed stdout + captured stderr + wait (P05, audit-era C from bdc234c3); AF_UNIX
request/response (P04); HTTP/1.1 incremental reads over Base TCP + EOF-as-empty-read
(P06); completion-order join (P07); dlopen extension (P08); law-gated admission with
TODO refusal, --checkup markers, no-ring-axiom reflexivity failure, record forgeability
(P09); JS-host in-process evaluation (P10); costs (P11); checker shape rules verbatim
(P02); Base surface inventory/refusals (P01); template-guard delta behavior (P12).
NOT yet seat contracts (agreed with both reports): crash-window replay, restart
custody, confinement (confined-child probe unexecuted anywhere), effect cancellation,
native-module load/reload custody, log rotation under the 4 GiB Base bound, torn-frame
repair. The reconciled text draws this line correctly in §2/§5/§6/§13; my critique
adds only C6's three residuals.

## 5. Severity ranking and D1-D4 dispositions

- F1 High — agree, strengthened (C1/C2).
- F2 High — agree on absence; correction text refined (C4).
- F3 High — agree (no grant machinery; my P09 forgeability and the candidate's own
  admission requirement align).
- F4 — **disagree with the framing as stated**; upgrade to the concrete broken-read
  finding (C3). This is my main severity disagreement.
- F5 Medium — agree, framing corrected (C5).
- F6 Medium — agree (`message_sql` verified verbatim).
- F7 Low — agree; no counterparty evidence checked from my side.
- D1 (unbounded knowledge growth): retain; my module reading supports it — no
  DELETE/retention statements in knowledge.bend — still not a growth proof.
- D2 (mechanism over discipline for seat writes): agree, strengthened — the write path
  has no seat-role gate in what I read (author is an unchecked string; tables auto-
  install), so discipline is currently the *only* gate; mechanism requires new code.
- D3 (never ride omp identity): agree, with mechanism — riding omp activates the ~20
  `String.eq(harness,"omp\n")` feature sites (steer/awake, `omp_frame_kind` event
  classification, filter handshake, resume-file lookup) against a foreign event
  stream; free-text recruit plus fail-late turn admission makes the mistake cheap to
  commit and expensive to diagnose.
- D4: no position (JS-line evidence is outside my specialty).

## 6. Preserved dissent

Confined-child sequencing dissent stands unchanged: no lane has executed a confined
Bend2-child probe; same-UID ambient authority is the default threat model for
everything the seat spawns (the reconciled §5 now states this honestly and adds the
right tests — direct log write by the child, SDK-request impersonation by an unrelated
same-UID process — but they remain unexecuted). I keep the ranking: that probe precedes
the §12 measurement campaign. No invented agreement: every accepted claim above was
rechecked against source this round; C1-C6 are open corrections, not endorsements.

## 7. Costs and limits (observed, carried from the independent round)

P11: check 353 ms / emit C 420 ms / link 855 ms / native run 32 ms / interpreted
409 ms (trivial program; ~300 ms of the interpreted figure is bun+checker startup, so
per-call streaming economics favor compile-once natives — 32 ms). Coordinator scale:
emit 2101.119 s, max RSS 142,651,376 KiB (recorded build, diagnostics on). Open limits:
template-depth-guard trigger shape (P12 open); confined-child authority; native-module
load/reload; crash-window replay; 4 GiB Base bound rotation.
