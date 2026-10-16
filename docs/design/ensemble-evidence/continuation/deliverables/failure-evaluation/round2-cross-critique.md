# Round 2: cross-critique of proposal-strongman, and review of the root-prepared candidate

Session: failure-evaluation (ensemble design-evaluation). Continuation after operator reboot; same
session and native lineage; the interrupted attempt's result is preserved as unknown by the
reconciliation observation and is not claimed here.

Pins unchanged: baton-cli corpus @ 5941316; canonical source @ b1f006a6; bend 2.0.25 linux-x64.
Prior round's probes (P1-P6) and report remain retained evidence. New source facts used here are
quoted with paths; no new runtime probes were executed this round — the two probes named in Attack 2
are specified with predicted outcomes and remain unexecuted (costs and status stated).

## 0. Strongest case for the strongman (before judging)

The strongman's round 2 is the most self-correcting document in the ensemble: it withdrew a
borrowed citation after `git cat-file` recheck and restated the section-8 finding on first-hand
evidence (no `impl/` tree at b1f006a6, zero `repl.` hits under `bend2/`); it confirmed the closed
harness set at four admission gates with line numbers and proposed the smallest named change with
its own falsifier (add `bend2-player`, extend the admission sets; shim-sh test as the falsifier);
it reduced §8 to dependency + interface + experiment instead of shipping fiction; and it attacked
the weakest tail of its own adopted position (D). Its correction to design-lead ("checkouts that do
not exist" overstates; the 1e050e420 object exists in SRC) is exact — I verified the same
distinction in my round 1 (S8) and it holds. Its linux timings probe (0.324/0.350 s) correctly
re-derived the darwin-bound 60-110 ms constants. "Burns silently should go" was correct and is
exactly what the Conductor's ruling implements. On the four points below the flaws are
specification and sequencing, not direction.

## 1. Attack: durable park-and-resume on a provider quota outcome

**Position: the refinement dies under the ruling, and it was already the wrong mechanism on this
architecture; three halves survive.**

Merits, independent of the ruling:
- Parking is not expressible as a benign "behavior" in baton2's drive-and-settle model. A seat
  turn runs under an attempt with a physical session lock (`session-lock.bend`: try_acquire /
  wait_acquire; "A serve task waits for the current session owner to release its physical lock").
  Park-in-place means holding the lock while sleeping — precisely my S7 wedge, now by design, with
  no timer wake available at Base (P5: no deadline on `Chan.recv`, no select; only `IO.sleep`/`IO.now`).
  Park-and-return means ending the attempt so the coordinator can re-deliver later — which is
  retain-and-report with a new name and a lost wake contract. The shipped coordinator has no park
  concept (zero `park` hits under `bend2/src/coordinator/`).
- The strongman's cited precedent (prime-agent.md §9) parks inside a harness that owns its process,
  retry policy, and wake clock. Baton2 seats are driven; wake authority is the coordinator's
  delivery endpoint. Adopting Prime's behavior without Prime's process model imports the wedge.
- What the ruling formalizes already ships: provider quota/rate outcomes are detected and retained
  as observed diagnostics (`subscription-fallback.bend:255-263`: 429 `api_error_status`, "quota
  exceeded", "spend cap", "insufficient balance", "hit your … limit"), retained and reported to the
  Conductor at settlement.

Surviving halves: (1) **retain-and-report** — quota outcomes as retained ledger facts, reported;
shipped, and now the rule. (2) **"Burns silently should go"** — correct; the fix is reporting, not
parking. (3) **Measurement-arm budgets** — the tau-bench sensitivity point survives in the
instrument domain: measurement conditions may cap and must be recorded (candidate §12 already
states "Finite measurement conditions describe observed runs and create no runtime task budget").
Dead: policy-driven parking, and any wake/retry policy inside the seat. Candidate verdict: the
root-prepared candidate already encodes the ruling (§4 "Baton requires no duration, token, or step
estimate and enforces no such budget on admission, continuation, pause, truncation, stop, or
unfinished work"; review-notes "Apply the operator ruling to task-scoped and per-call limits as
well as ambient limits"). I accept that encoding and note it also rules out **my own round-1
coordinator half** (auto-mark-lost at a recorded deadline) — self-correction recorded in §6 below.

## 2. Attack: "the child holds no authority the seat did not grant"

**Position: false as an OS claim at the pin; the strongest contract actually claimable is
"no authority amplification + complete attribution"; mediation is advisory for hostile same-UID
code.**

Evidence at the pin:
- Same UID by construction: the proposed lane spawns `bend <program>` through the authored process
  family, which has no sandbox primitives — zero hits for seccomp/landlock/pledge/unveil/chroot/
  setuid/setgid in `bend2/src/host/process-spawn.c`. The child inherits the seat's ambient
  authority: session log, workspace, spill files, and anything the seat's UID can touch, including
  writing the file the re-entry mediation is supposed to guard. The root-prepared candidate §5 now
  states this ("A same-UID child inherits ambient filesystem, process, and network authority
  available to that user. Routing SDK calls through a socket mediates those calls.") — accept.
- No unforgeable value (my P2): no type-level authority to pass through a socket in the first
  place; whatever the child presents is data.
- The coordinator's own control plane uses peer-credential PID checks
  (`process-spawn.c:1203-1213` `br_observer_pid`: `SO_PEERCRED` on Linux, `LOCAL_PEERPID` on Apple)
  — a precedent available to the re-entry socket, but note it distinguishes *which* PID, not what
  privilege; same-UID passes any UID check, so the boundary would need exact recorded-child-PID
  pinning plus a one-time nonce.

Contract claimable at the pin, and only this:
1. **No authority amplification**: the child cannot do anything the seat process could not already
   do; the lane is not a privilege-escalation path.
2. **Complete attribution**: stdout, stderr, status, and every *sanctioned* nested call are logged.
3. **Mediated sanctioned calls**: the SDK socket routes nested effects through the guarded pipeline.

Unproven / unprovable without new mechanisms: that a hostile child uses the socket at all. The
guarded pipeline guards calls that ask to be guarded. Two discriminating probes (specified, not
executed; each is a small isolated program plus one extra process, minutes of work):
- **Bypass probe**: the spawned program writes a line into the session log (or opens the orchestra
  database) directly and exits. Predicted at the pin: succeeds. Negative witness for any claim that
  mediation confines. Preventing invariant: an OS executor policy (named prerequisite, absent).
- **Impersonation probe**: an unrelated same-UID process connects to the re-entry socket and issues
  a well-formed nested-call frame. Predicted at the pin unless PID-pinning is implemented:
  accepted. Countermeasure contract: SO_PEERCRED exact-PID match against the recorded child plus a
  one-time nonce delivered via argv; still not confinement (the child itself passes), only
  anti-impersonation.

The strongman's round-2 acceptance ("socket re-entry is routing rather than an authority boundary")
is correct and I concur; the candidate §5 wording should additionally name the two probes and the
amplification formulation. Exact delta D5 below.

## 3. Attack: alternatives A and B against P1 (law gate red at the pin) and P5 (no deadline wait)

**Position: A survives both probes structurally, with two named preconditions. B survives as a
mechanism, not with its stated safety claim; its falsifier must carry five preconditions.**

**Alternative A (crash-safe blocking seat).**
- P1 does not reach it: A admits nothing; no `--check-only` gate on its path.
- P5 does not reach its core: a blocking seat waits on children with the C family's blocking
  waitpid; no channel-select needed. Its per-call tool timeouts (tool properties) require a
  WNOHANG+sleep poll loop in the executor — expressible, small, and must be **named**, else a hung
  tool blocks the turn forever with no visibility. Precondition A1: name the per-call deadline
  mechanism (WNOHANG poll loop or poll-timeout effect).
- Its falsification condition ("if blocking matches async within noise, the async layer is not
  worth its complexity") has a structural precondition the strongman's list omits: **the comparator
  must exist**. A's falsifier is a gate on *adopting async later*, not on shipping A; the
  experiment budget for it belongs to the async milestone, and it must satisfy the Attack-4
  controls or its result is invalid.
- A's honest boundary ("long tools block the turn; steering waits") is correct and matches the
  shipped wake/steer model.

**Alternative B (orchestrator-admitted ephemeral programs, no durable self-extension).**
- P1 hits the *repository-act* path's laws, not the per-admission gate: the strongman's own probe
  proves a fresh open-law module is refused (`--check-only` rc=1), and my P1 proves the production
  tree's own laws file fails the same gate today. So per-admission checking of generated files
  works; the claim "Bend2 tools admitted through repository changes, with `bend --check-only` and
  the relevant contract laws checked under the pinned toolchain" (candidate §6.2) is **not
  currently true of this repository**. Precondition B1: repair `knowledge-laws.bend` (three drifts)
  and get the repo's laws green before the repository-act path ships. Candidate §13's wording
  ("a failing unrelated law is not an automatic prerequisite for every seat feature") is right in
  general and must be scoped: for the law-contract admission path specifically, laws-green is a
  direct entry condition.
- P5 does not block B's core (B builds on blocking A).
- B's round-1 safety sentence — "satisfies the four authorization properties via process separation
  + externalized signed admission evidence" — is **false at the pin twice over**: process
  separation does not exist (same-UID child, Attack 2), and nothing signs anything (admission
  evidence is unsigned rows). The candidate's §6 downgrade of the Unfireable Safety Kernel to
  "individually insufficient necessary properties … covers a particular pure decision function" is
  the correct treatment — accept, and apply the same downgrade to B's claim: B offers proven
  **fail-closed admission checking** and proven **no runtime loader**; process separation and
  signed externalized evidence are named prerequisites it does not supply.
- Remaining preconditions for B's falsifier ("ephemeral programs show no turn/token win … or review
  latency dominates"): B2 — the loopback re-entry protocol exists and has passed the Attack-2
  impersonation probe; B3 — executed-bytes = admitted-bytes binding demonstrated (candidate §6;
  see D2); B4 — proposal-refusal semantics under no-parking are specified (refused proposal →
  seat continues without the capability and reports; no queue that gates continuation), so "review
  latency dominates" is measurable rather than a wedge; B5 — the program-lane per-call costs
  measured on linux (strongman 0.324/0.350 s; runtime-lead 0.544/0.642 s cited by the candidate)
  enter the comparison as constants, not the darwin 60-110 ms.

## 4. Attack: is the async A/B well-posed before the wait mechanism and completion contract?

**Position: not well-posed as the strongman specified it; the root-prepared candidate's §4 fixes
the two structural blockers (S3, S7) and leaves five experimental controls unstated.**

Structural:
- S3 (head-of-line stall) is **dissolved by the candidate's design**: "Arriving results persist
  immediately under their operation identity … durable observations and result handles remain
  available while an earlier call is pending. The head-of-line cursor orders provider-visible
  items … The cursor has no elapsed-time closure rule." A completed result is no longer held
  hostage by an unfinished predecessor. Accept.
- S7 (never-settling operation) is **answered by visibility, not resolution** under the ruling: "A
  never-settled operation remains visible to its owner and Conductor until actual settlement or
  authorized cancellation resolves it." I accept this and record my self-correction (§6): my
  round-1 "coordinator auto-marks lost at a recorded deadline" is a ceiling gate on unfinished work
  and is out of bounds; explicit authorized cancellation is the only resolution path, and the wait
  mechanism must still be named and tested (P5).
- Therefore the A/B is well-posed **only after**: (1) the wake/wait mechanism is implemented with
  its observation semantics established (candidate §4 already requires naming and testing it);
  (2) the async arm's task-end boundary for *measurement* is pre-registered as a measurement
  condition — since no runtime gate exists, censoring is an instrument choice that must be stated
  and applied symmetrically to the blocking arm; (3) the controls below exist.

Controls the strongman's experiment list omits (exact deltas to candidate §12/§14 row 1):
- C1 **Batching confound**: idle-cap + grace-window batching changes model-visible result
  grouping; sweep the grace window {0, default, large} or add a one-result-per-turn replay arm, or
  token deltas measure batching, not asynchrony.
- C2 **Symmetric measurement patience**: pre-register the observation window and report
  right-censored (never-settled) runs as censored, in both arms; otherwise the async arm wins
  wall-clock by waiting invisibly.
- C3 **Commit scheduling**: log per-operation commit latency and reorder events; with results
  persisting immediately, provider-visible ordering is a separate axis that must not contaminate
  the latency measurement.
- C4 **Steering latency as a measured outcome**: candidate §4 says "Record the actual control
  latency for each adapter" — promote this from instrumentation to a reported comparison axis;
  steering-never-queues is a *reason* for async, so the A/B that omits it under-measures async's
  claimed benefit.
- C5 **Provider acceptance checks logged**: replacement vs second-item acceptance per provider is
  recorded as a blocking restriction where present (candidate §4 has the mechanism; the experiment
  must condition on it).

## 5. Review of the root-prepared candidate (design-sketch.final-review.md)

**Overall: grounded acceptance.** The candidate incorporates my round-1 evidence accurately and
without inflation: torn-tail repair as a typed event (§2 = my S1); recovery taxonomy with the
unknown-outcome state and the crash-window replay requirement (§2 = my S2); relation-upsert
lineage replacement described exactly as I reproduced it, with public coordinator reproduction and
a protected contract kept as separate work (§8, lines 350-354); executed-bytes-must-match-admitted-
bytes (§6 = my S4); wait mechanism named as unspecifiable at Base with the probe cited (§4 = my
P5); same-UID honesty and "no confined Bend2-child probe was executed" (§5); laws-file failure
reported with the correct scope note (§13 = my P1); linux probe constants replacing darwin ones
(§5). Paper lanes are kept separate throughout (NOOA/CLM/PASTE/TomasuLLM/ALITA-G labeled; version
links given). The seed paragraph (§1) matches shipped behavior I can corroborate first-hand
(`native-initial-input.bend`; my own initialization used the retained-seed retry path). The
review-notes corrections (PASTE v2/v3 both 43.5%; CLM baseline wording; TomasuLLM depth vs
configured maximum; ALITA-G validation-set specificity; monitor study prefix-at-tool-boundary
design) are consistent with my corpus spot-checks where they overlap; the version-specific numbers
I could not check independently (e.g., PASTE v1 48.5%) are labeled by their provenance and I raise
no dissent.

**Exact final delta (all small; none reopen scope):**

- **D1 (§6 path 2 / §13).** Scope the laws-green condition: the repository-act admission path may
  not ship while the repository's own law files fail `--check-only` at the pin (P1: three drifts in
  `knowledge-laws.bend`). Keep §13's general note that an unrelated failing law is not a
  prerequisite for unrelated seat features.
- **D2 (§6).** For executed=admitted binding, state the preferred mechanism: protected
  content-addressed storage; if boundary-verification is chosen instead, the "demonstrated
  race-free binding" should be named concretely (open-by-fd then exec on that fd, or digest+exec in
  one process step), because a path re-read after admission is exactly the TOCTOU the sentence
  forbids.
- **D3 (§5).** Add the confinement contract wording and probes: claim "no authority amplification +
  complete attribution; SDK mediation is advisory for hostile same-UID code until an OS executor
  policy exists"; append the bypass probe and the impersonation probe (with SO_PEERCRED
  exact-PID-pinning plus nonce as the candidate countermeasure, citing `process-spawn.c:1203-1213`
  as the in-tree precedent) to §5's proposed tests.
- **D4 (§12, §14 row 1).** Add controls C1-C5 to the async comparison: grace-window sweep or
  one-result-per-turn replay arm; symmetric pre-registered observation window with censored-run
  reporting; per-operation commit latency and reorder logging; steering/control latency as a
  reported comparison axis; provider acceptance form conditioned and logged.
- **D5 (§8, lines 350-354).** Name the candidate fixes for relation lineage so "protected relation
  contract" has a shape: immutable relation ids, or author-namespaced ids at ingest
  (`agent-native.bend:215` prefixing the caller id with the author), or findings-style
  content-guarded conflict with a notice. Any one suffices; the current upsert admits silent
  authorship transfer.
- **D6 (§4).** One sentence the candidate lacks: a completion request carries the pending-operation
  state explicitly (ids, ages, observed states) so the Conductor's confirmation decision is made on
  complete evidence — this replaces my superseded auto-mark-lost half and requires no gate.
- **D7 (§3).** The spill-read bound is still unnamed: "declared preview and complete paged reads"
  (§8) bounds cross-seat reads, but the seat's own `read` tool needs a named byte cap with receipt
  for spill handles (S5's bait channel). One sentence.
- **D8 (workset).** §9 has schema validation and provenance for workset updates — accept; add that
  provenance records the *source class* (peer message, tool output, model authorship) so injection
  canaries (S5) have a measurable signal.

No other corrections required; the candidate survives cross-examination on every point where my
evidence touches it.

## 6. Self-correction (recorded for lineage)

My round-1 principle "coordinator auto-marks lost at a recorded deadline and closes the attempt"
is **superseded by the operator ruling** as encoded in the candidate: no runtime quota, budget, or
ceiling gates admission, continuation, or unfinished work. The surviving quiescence contract is:
quiescence as *information* (pending set, ages, observed states), never a gate; wait mechanism
named and tested; never-settled operations visible until settlement or explicit authorized
cancellation; completion requests carry pending-state evidence (D6). The same ruling supersedes
my S7 "deadline auto-close" wording everywhere it appears in my round-1 deliverable.

## Evidence, costs, unmeasured

- New source facts this round (read-only, at b1f006a6): no sandbox primitives in
  `host/process-spawn.c` (zero hits, listed primitives); `br_observer_pid` SO_PEERCRED/
  LOCAL_PEERPID at :1203-1213; zero `park` hits under `bend2/src/coordinator/`;
  `subscription-fallback.bend:255-263` quota/rate outcome detection patterns.
- Unexecuted probes, with predicted outcomes and costs: bypass probe and impersonation probe
  (Attack 2) — each minutes of work, no provider calls; predicted failures are the negative
  witnesses that would justify the OS-executor-policy prerequisite. Not run: seat does not exist;
  running them against the coordinator's own control socket is outside this lane's ownership
  boundaries.
- Unmeasured: the async A/B (blocked on wait mechanism + controls), citation handoff (E1),
  program-lane economics on linux at realistic sizes, relation-hijack public coordinator
  reproduction (root lane), confined-child authority tests.
- Constraints honored: read-only source; no shared-checkout edits; no process signaling; no full
  coordinator compile; probes and scratch DBs under this lane's directory; no ambient caps; no
  manual acknowledgements.
