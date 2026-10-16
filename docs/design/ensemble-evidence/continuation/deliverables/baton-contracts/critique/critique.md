# baton-contracts critique of bend-feasibility (reciprocal round)

Seed lens (brief, as tasked): uniform opaque hex — no substring means anything
without a decoder, and the string authorizes nothing. I applied the same lens
to this lane's packet: every claim decoded against its own `output.txt`, not
its summary; and "demonstrated" wording checked for what authority it actually
carries. Where the packet meets that bar I confirm; where summary outruns
output I attack.

Inputs read: `FINDINGS.md` (220 lines), `review-corrections.md` (96),
`probes/README.md`, `p03_durability/{dur.bend,run.sh,output.txt,dur.c}`,
`p04_unix_socket/output.txt`, `p10_js_loader/output.txt`,
`runtime-lead/amendments-r1.md` + `amendments-r2.md`. All source citations
re-verified first-hand at `b1f006a6`.

## C1 (High): p03 demonstrates the publication path, not the durability hot path

CONFIRM the narrow claim, ATTACK the broad reading. `dur.bend:42-57`
executes exactly: `mkdir`, `File.open("store/log.tmp","w")` (truncate-create,
not append), `File.write`, `Host.sync`, `rename`, `Host.sync_dir`,
`Host.stat_size`, `unlink` (fails ENOENT by probe construction, exit 2).
Both lanes print `size 9` over `hello-log`. The six C-half ops are
demonstrated on Linux — the `review-corrections.md` B3 wording ("primitives
demonstrated … the seat's contract remains to be implemented") is careful and
I endorse it.

What the probe does NOT execute, and the proposal's contract requires
(`feasibility-bend2.md` Use 2; `audit-findings.md` amendment 5): the per-commit
hot path `File.open(path,"a")` (O_APPEND) + write + `fsync(file)` on the live
log. No `"a"`-mode open appears in `dur.bend`. Nor does any `flock`
single-writer lock, any rotation trigger, the U32 4 GiB bound as behavior, or
any crash-window exercise (kill between effect and commit, torn-frame repair,
writer-position latch — the task's three named residuals are all still open).

Consequence: FINDINGS §7's "Every hard primitive the design needs … has now
been demonstrated end-to-end" overclaims by omission. The demonstrated
sequence is whole-file publication (the rotation/compaction path); the
contract's hot path is append+fsync+flock (unexecuted). Seat work must still
prove the hot path, the lock, and one crash-recovery behavior before the
durability family can be cited as closed. Suggested fix: one sentence in §7
carrying the B3 caveat, plus a p03-followup probe (append-mode + flock +
kill-9 mid-commit with repair) sequenced before milestone-1 exit.

## C2 (High): socket re-entry is a convention with no authentication contract — confirmed, extended

I CONFIRM `amendments-r1.md` B (socket re-entry is routing, not an authority
boundary) from the contracts side, and add two findings from this round:

(a) No existing Baton mechanism can authenticate the re-entry. `message_route`
(`commands.bend:428-430`) governs session→session message admission; receipts
(`agent-command.bend:85-117`) bind recipient-owned message reads; native
requests bind attempts to harness-CLI invocations. None of them knows a file
descriptor: nothing binds a socket peer to a child/attempt identity today, and
the seat's child never appears in any Baton table. "Every SDK-expressed
effect passes the guarded pipeline" is therefore enforceable only as seat-side
code discipline plus OS confinement (untested) — not as a Baton contract.

(b) Even the convention lacks a protocol. `p04` output prints
`socket said PONG\0` — a trailing NUL crosses the demo framing, consistent
with the `io_cstr` NUL contract (FINDINGS §3.3) having no framing answer yet.
Before confinement is even the binding constraint, the loopback lane needs a
framing + per-child authentication protocol (length-prefix/NUL rule; per-child
secret bound to the attempt id, checked per re-entered call). Neither exists.

Contract test (scratch DB + seat harness): spawn two children, present child
A's credential on child B's socket, show the seat cannot distinguish them —
pins the gap; flips to pass when per-child attempt-bound credentials land.

## C3 (Medium): fifth-harness admission — R2-2 confirmed, two sites added

I re-verified all five gates first-hand at `b1f006a6` and R2-2 is exactly
right: `control.bend:132` (receiver admission), `:177-183` (endpoint
configuration), `:203` (session start), `:287` (turn admission),
`delivery.bend:29` (native-receiver eligibility: harness set AND endpoint
shape `receive … id`). Two additions from this round:

(a) `control.bend:203` gates session START, so a baton-cli Conductor session
itself needs the gate change — the lane is not only about Players.
(b) Past the gates, `turn.bend:244-261,556-704` branches prompt delivery and
frame classification per harness (omp/muse/codex + Claude import), and
`message-status.bend:62-85` carries codex-specific record/terminal/settle
SQL. A fifth harness needs a `harness/bend2-player.bend` adapter PLUS these
per-harness branches — the change is wider than five predicates.

On the task's question: NOTHING in the out-of-process lane design requires a
seat-side verb outside `Domain.known` (`agent-domain.bend:43`). Spawn, socket,
and `bend`-as-child are host effects; SDK re-entry hits the seat's own
internal tool pipeline, not Baton verbs; its Baton touchpoints
(inbox/report/finish/dispatch) all ship. The admission burden is 100%
coordinator-side. The lane is correctly sequenced as milestone work with a
coordinator-change precondition — which is also my sequencing dissent (below).

## C4 (Medium): p10 changes nothing about F2; "structured" overstates the posture

F2 (no seat-side commit lane; REPL cells/citations absent) STANDS. `p10`
output proves the compiler's JS-side evaluator (`main.ts` book_run path)
serves a module's non-IO defs to a JS host inside a bun child:
`double(21) = 42`, constructors as `{"$":"Some","value":7}`. That is a
bun-child evaluation primitive — out-of-process relative to the seat. It
creates no content-addressed store, no version pinning, no citation grammar,
no admission verb: the entire F2 absence (commit lane + REPL substrate #778)
is untouched.

Three qualifications the FINDINGS §4.3 posture claim should carry:
(i) only non-IO defs cross (`default` exports; effectful generated programs
still need the text/child path); (ii) the constructor encoding is an ad hoc JS
projection, not a typed result contract — a result-codec contract test is owed
before the lane can claim "structured (non-text) call results"; (iii) the bun
child preloads the full compiler (`main.ts`), widening the lane's TCB versus
a `bend`-as-child invocation. None of this diminishes p10 as a probe; it
bounds what the posture can be cited for.

## Agreements (preserved, no dissent)

- B3 wording, B1 checker-verdict correction, B2 cost anchors, §3 new
  constraints (4 GiB bound, constructor namespace, NUL contract, EOF-as-empty)
  — all consistent with this specialty's evidence; the NUL and EOF findings
  strengthen C2's framing-protocol point.
- The five-gate enumeration in R2-2 (my R2 interim mislabel corrected there is
  acknowledged; fresh verification above supersedes both).
- r1-B recast of child authority (confirmed in C2); r2-R2-1 timeout recast is
  outside this specialty but compatible — heartbeat-as-information needs no
  new Baton verb.

## Disagreements (explicit, preserved)

- D-a (steelman scope): FINDINGS §7's "all reachable with a few hundred lines
  of C effects" inherits C1's gap (hot path + lock + crash behavior unbuilt)
  and the admitted-unconfined child (FINDINGS §9). A steelman that omits its
  own §9 is the attack the redteam would write; carry the caveats in §7.
- D-b (sequencing): bend-feasibility ranks the confined-child probe first
  among runtime probes — AGREED as a ranking of probes. My dissent: the
  five-gate coordinator admission change is the precondition to all of it —
  no seat exists to confine, drive, or measure until the harness set opens.
  Sequence: admission contract, then confinement probe, then measurement
  campaign. Their ranking answers "which probe"; mine answers "which gate".
- D-c (p10 posture): "structured (non-text) call results" should read "JS-
  projected values for pure defs, encoding ad hoc" until a result-codec
  contract exists (C4).

Artifacts: this file + `gates.txt` (five gates + two added sites,eng[line]).
No shared source touched; probes only read. Live DB untouched (read-only
`help` context from prior round reused, not re-run).
