# runtime-lead amendments R2 — timeout recast, citation self-correction, seed ruling

Supersedes the closing clauses of amendments-r1.md A1/A2. Root review ad10e418 (timeout
wording) and the root seed ruling are the authority; corpus citations below were re-verified
first-hand against the pinned corpus before use. No shared source modified.

## R2-1. Timeout/continuation semantics — exact replacement for A1's and A2's timeout clauses

Root's clarification: Baton must not require a duration estimate or enforce a
duration/token/step budget to admit, pause, stop, truncate or gate unfinished work. Calling a
limit a tool property does not remove the conflict — my R1 clause "per-call timeouts are the
only automatic termination" is withdrawn (design-lead contested it first; root ruled).

Replacement text for design §4 (state machine) and §11 (quotas bullet), one shared paragraph:

> An operation ends in exactly four ways, and none is a Baton runtime duration cap:
> (1) an observed external lifecycle event — provider rejection or error, disconnect, child
> process exit, or an externally enforced limit — recorded with provenance together with the
> unfinished state it interrupted; (2) explicit authorized cancellation — the model for its own
> operations, the Conductor for the seat; (3) an observation wait returning while the operation
> remains owned and running — a wait may carry a finite observation window (prime-agent's
> `collect(timeout_ms)` limits the wait, not the child; prime-agent.md:45); (4) finite
> measurement conditions inside a benchmark instrument, which bind the experiment, never the
> runtime (research-open-questions.md:194-212: Terminal-Bench Challenges uncapped vs 4.0's
> 8-hour instrument timeout).
>
> Elapsed silence alone never settles an operation: absent concrete lifecycle evidence the
> state is `pending`/`unknown` and the operation remains owned; `lost` requires observed
> lifecycle evidence (exit status, closed channel, provider error), not a timer. The heartbeat
> is informational — it reports elapsed wait and running calls and offers the model its actions
> (wait, cancel, collect partial, mark lost on evidence), as in unreal-agent.md:46 — and never
> carries enforcement.

Corpus position on the one counter-design: deepseek-harness.md:106,114,116 ships an elapsed
`setTimeout` deadline that aborts the run controller (default 120 s, cap 600 s). That is an
observed external design with no necessity proof for this proposal, and under the operator
requirement it is a conflict, not a pattern to copy. critique-redteam.md:60-64's hard caps are
likewise recorded as a policy proposal in conflict, preserved as dissent, not adopted.

Strongest case preserved: the redteam P1 concern (invisible nonsettlement) is fully answered
by observation — informational heartbeats, age reporting, and evidence-gated `lost` — without
handing the runtime termination authority. Benchmark arms keep finite conditions by category
(4), so measurement comparability survives.

## R2-2. Self-correction: harness gate sites are in control.bend, not agent-native.bend

My interim report (report:23f6673e16f4b3b6d4cbfadc7b61c092, finding 6) mislabeled two gate
sites. Verified correction at b1f006a6: the closed harness set
`harness IN ('codex','omp','muse','claude-code')` gates FIVE sites — receiver endpoint
admission (`control.bend:125`), endpoint configuration (`control.bend:177`), session-start
admission (`control.bend:198`), turn admission (`control.bend:281`), and native receiver
eligibility for delivery (`delivery.bend:20`). design-lead's citation
(control.bend:125,198,281; delivery.bend:20) is correct; my "agent-native.bend" labels were
wrong. The F1 consequence stands and is stronger: a baton-cli seat needs the coordinator change
at five sites plus a `harness/bend2-player.bend` adapter and settlement handling
(message-status.bend).

## R2-3. Initialization seed and requested ideation — preserved, mandatory, correctly scoped

Root ruling: the operator explicitly requested programmatically generated random strings
prepended to ALL agent initialization guidance, with ideation on their abstract qualities as a
task-interpretation heuristic. Root's earlier instruction forbidding interpretation is
superseded. An interpretive stance chosen from the initialization text is permitted and
requested; only unsupported factual, semantic, entropy, or performance claims about opaque
bytes get corrected.

This is shipped behavior, not proposal: `native-initial-input.bend:10` carries the fixed
instruction ("Ideate briefly on the abstract qualities of the random seed above…"),
`:14` the `native_initial_inputs` schema (attempt, session, turn, seed, instruction,
guidance), and `:19-21` the seed rule — `lower(hex(randomblob(64)))`, reused across fresh and
profile retries via the predecessor chain. design-lead's revised text §1 (lines 28-32) already
adopts pass-through unchanged and never-reseed; confirmed correct against source.

One addition to the design text so the ruling is complete:

> The fixed instruction prepended with the seed includes the operator-requested ideation, and
> the seat passes it through unchanged; ideation is not optional. A seat's ideation is authored
> context, kept distinct from measured evidence in its records, and is never itself evidence
> for a claim. Initialization seeding is separate from evaluation randomization: benchmark arms
> choose and report their own seeds.

Review-history preservation: the original guidance (seed ideation requested), the superseded
over-restriction, and this correction are recorded here and should ride the claim register
(evidence-lead: suggest a SEED-01 row marking the restriction superseded-by-ruling, not
resolved).
