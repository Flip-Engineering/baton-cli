# Reciprocal critique: root candidate reconciled design (contracts specialty)

Target: `recovery-20261016T1802Z/review-ready/design-sketch.reconciled.2e65ccfae24e.md`
(SHA256 verified `2e65ccfa…cf3132b`, 561 lines). Opposing report
`report:1db006672cb3467c582934e5385fe3fb` read in full; `FINDINGS.md`,
`review-corrections.md`, `probes/README.md` re-read; p02/p03/p04/p10
sources+outputs inspected. Source pin `b1f006a6308bbb00e29a24322e4f7d5164774470`
(all citations re-verified first-hand; no verdict inherited).
Seed lens: opaque strings decode against outputs, never summaries.

Prior artifacts preserved untouched: `../report.md`, `../evidence.md`,
`../critique/critique.md`. This file is the separate reciprocal artifact.

## Standing

The candidate is a genuine improvement over the proposal: it names the
five-gate adapter integration (§1), route validation (`message_route`), the
unexecuted confinement probe (§5), REPL-as-dependency (§8), the SQLite store
(§8), the relation-lineage defect (§8, issue #785), and open decisions (§16).
Most of my F1–F7 already landed in its text. What follows is therefore
acceptances with line evidence, four corrections, and residual dissent —
not a rejection.

## Accepted claims (verified at pin)

- A1 — §1 adapter integration (control/delivery/message-status/harness).
  The five gates re-verified: `control.bend:132,177-183,203,287`,
  `delivery.bend:29`; plus per-harness turn branches
  (`turn.bend:244-261,556-704`) and codex settle SQL
  (`message-status.bend:62-85`). "Correctly identified adapter plus the
  corresponding admission, receiver, wake, and settlement changes" is accurate.
- A2 — §1 route sentence. `message_route` (`commands.bend:428-430`) gates all
  message admission incl. dispatch (`agent-native.bend:353` → message action;
  `commands.bend:442-445`). Denied routes store nothing, wake nobody.
- A3 — §2 durability honesty. p03 output confirms write→fsync→rename→
  dirfsync→stat both lanes, exit 2 as probe-constructed unlink artifact.
  "Leaves the seat's crash-window durability and recovery contract to be
  implemented" is the correct label. EOVERFLOW (`effs/file_size.c:6-13`),
  `io_cstr` NUL (`comp.ts:5670-5686`, `buf[n]=0; *len=n`), telemetry
  (`main.ts:129-140`, `BEND_NO_TELEMETRY=1` skips) all verified verbatim.
- A4 — §5 same-UID child + caller-identity/replay protocol requirement +
  "No confined Bend2-child probe was executed". Confirmed absent (probes/
  holds p01–p12, none confined). The two named tests (direct log write;
  unrelated-UID SDK request) are the right discriminating pair; add my T2
  (cross-child credential) as the third.
- A5 — §5 interpreter-checks + P10 bun host as separate process needing
  evaluation. p02/p03 outputs show checker Errors and reliance reports on
  interpreted runs; `host.mjs` loads via bun preload in-process *of the bun
  host*, out-of-process of any seat. F2 stands (no cells/citations/admission
  in p10's path — pure defs only, ad hoc `{"$":…}` encoding).
- A6 — §6 three paths, forgeability, executed-vs-admitted binding, NUL ABI.
  Consistent with p09 forge (`Mk{999}` runs) and law-gate captures.
- A7 — §7 branch record + proposed basis. `branching-model.bend:13-17` has
  workspace+inputs, no log prefix, no version vector; selection rules
  confirmed. The basis triple is correctly labeled proposal.
- A8 — §8 REPL-unimplemented + SQLite store + relation upsert defect.
  `knowledge.bend:288,296` (`ON CONFLICT(id) DO UPDATE SET author=…`) proves
  the lineage-replacement mechanism behind issue #785; law drift proved
  (`knowledge-laws.bend:19` schemaless-kind, `:101` 2-arg call vs 3-arg def,
  `:67` `evidence_ok` unmatched). Repair-as-target-work (§13) correctly
  sequenced after, not before, seat features.
- A9 — §§4/12 no-budget + informational heartbeat; §15 dependency table;
  §16 open decisions (adapter first — agrees with my sequencing dissent D-b,
  now converged).

## Corrections (contract misstatements remaining)

- R1 (Low-Med) — §4 "A completion request carries pending operation
  identities, observed states, ages, and retained result references."
  Source: the request carries the report body only
  (`agent-command.bend:203-215` → `send_item` kind `completion-request`);
  pending assessment is coordinator-computed counts
  (`commands.bend:381-390`: pendingCount + oldestPendingId). Per-operation
  identities/ages reach the Conductor only if authored into the body text.
  Fix: request carries body; reconciliation projection carries counts; a
  per-operation pending-state contract needs its own mechanism.
- R2 (Low) — §1 route enumeration ("recorded parent, Conductor, tight-peer,
  or operator route") narrows `message_route`: parent↔child either direction,
  conductor-descendant (any depth), tight peers (equal depth, non-ancestor),
  operator↔top-conductor. A reader building a parent-only gate would
  under-admit. Fix: enumerate exactly.
- R3 (Low, load-bearing direction) — §8 "scoped CLI, MCP, and browser readers
  … have source consumers" is true (command dispatch `control.bend:352-353`;
  `ui/orchestra/knowledge.js`; `baton2_action`) but every path is a
  seat/operator-initiated pull: the turn prompt carries only the instruction
  string (`turn.bend:181-187`), never a composed knowledge slice. No ambient
  delivery exists. Fix: state pull-only explicitly so §12's retrieval
  experiments don't assume briefing composition.
- R4 (Low) — §2 family lists the single-writer lock + writer-position refusal
  beside demonstrated items; flock is unproven (no probe, no seat-scope lock
  effect). Name it proposed/untested alongside the crash window (partially
  covered by the existing honesty sentence — extend that sentence to the lock).

No "all primitives ship" wording found in the candidate — §§8/11/15 keep
proposed planes separate throughout. That challenge is recorded as
satisfied, not outstanding.

## Unresolved disagreements → convergences

- D-b sequencing: converged (§16 bullet 1 is the adapter). Residual: keep the
  gate change ahead of the confinement probe in any schedule.
- D2 per-turn writes: converged — candidate §8 calls the seat-`Contradicts`
  restriction "an admission-policy choice requiring its own mechanism".
- D3 omp-identity bootstrap: converged — §1 requires "correctly identified
  adapter".
- D1 SQLite retention: still open, correctly listed (§16 knowledge bullet).

## Smallest discriminating tests (all scratch-scope, none run here)

- T1: append-mode + flock + kill-9 mid-commit + repair (closes C1).
- T2: cross-child socket credential presentation (closes C2).
- T3: complete-with-pending-ops then inspect Conductor-visible reconciliation
  (decides R1: counts vs identities).
- T4: relation-upsert authorship regression at pin (locks #785 behavior).
- T5: `bend --check-only` on repaired `knowledge-laws.bend` (unlocks §6 path 2).

## Residual dissent

- The §7 steelman-adjacent claim "all reachable with a few hundred lines of C
  effects" (opposing report) still omits the hot path, lock, crash behavior,
  framing/auth protocol, and fifth-harness coordinator change (five gates +
  adapter + turn/ settle branches). Demonstrated primitives / proposed
  contracts / observed costs / open limits must stay in separate columns;
  the candidate mostly does this — the opposing summary does not.
- Observed costs (p11 trivial; 2101 s coordinator emit) are single-run anchors,
  not budgets; seat-sized emit interpolation is still owed (candidate §5
  already says so — accepted).

## Limits of this critique

Bend2-line only. JS/Cairn history, benchmark figures, and paper citations
taken as preserved evidence, not re-verified. No live dispatch executed
(shared DB); no coordinator built; no processes signaled; no caps set.
