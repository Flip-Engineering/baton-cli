# evidence-lead final synthesis — Ensemble evidence-research

Parent: proposal-root (issue Flip-Engineering/baton-cli#1). Pin: baton-cli
5941316491eb01d8794abddc5dcf1798801c4aaf; canonical source b1f006a6.
Workers: citation-auditor (final report + register + T1-T4 cross-critique
reviewed; T4 grading of critic numbers in flight), research-critic (final
report reviewed; relaunched after keeper loss with all 16 findings
preserved; reverse-critique surface routed to auditor).
Reviewed register: claim-register-v0.md (this directory).
Experiments: experiments-v0.md. Candidate under review:
recovery-20261016T1802Z/review-ready/design-sketch.final-review.md
(root-prepared, not applied).

## 1. Accepted corrections (evidence assessment: adopt)

C1. Retired-not-stale pinning (R-RET-01/02): 10c2ae6d unresolvable;
72fc39b45 + 1e050e42 resolve; impl/ retired by 2b8449af; JS rows labelled
RETIRED, re-resolved per citation (41/44 exact, 3 corrected). Candidate §1
already carries this; no further change.
C2. Closed harness set (H-ADM-01, CIT-03): native turns only for
{codex,omp,muse,claude-code} at control.bend:125,177,198,281 +
delivery.bend:20; recruit stores free text, refusal late; Bend2 seat
undrivable today; milestone-1 adapter decision owed (runtime-lead lane).
Candidate §1 carries the substance.
C3. Timeout semantics (I-QUOTA-03/TIME-01): no duration/token/step budget
gates admission, continuation, pause, truncation, stop, or unfinished
work, ambient or task-scoped or per-call; four compliant endings only
(external lifecycle event with provenance; explicit authorized
cancellation; observation wait with operation owned and running; finite
benchmark conditions); silence never settles; lost needs lifecycle
evidence. Runtime amendments A1/A2 recast (R2-1) accepted; Attack 3 A1
deadline recast with dissent preserved. Candidate §4 carries this.
C4. Version-pinned paper numbers (Q-rows + T1/T2): NOOA three-row quote;
CLM posture scope; +7.7 dated; skill-evolution gate-not-number; PASTE
v2/v3 pin with 48.5-to-43.5 instability datum and serving-scope caveat;
TomasuLLM cost 2.1:1, committed-chain ceiling 4 vs configured depth 6,
fixed-seed/own-baseline/small-sample bounds; SpecActions chess-only;
HARBOR corrections (9-model suite, Devin/Fable 5 attribution, single
rollouts); ACON/ALITA-G wording; forced Fork-and-Flush split
(paper vs implementation record). Candidate §§3-4 carry these.
C5. Fork/branch/knowledge plane (O-FORK-01, O-KNOW-01, O-COMMIT-01,
LIN-01/03, LAW-01, WAIT-01, CIT-02, AUTH-01/02, HAND-01, MON-01, BET2-01,
COUNT-01, NOOA-02, SPEC-01, HARBOR-01, REL-LINEAGE-01, LAW-DRIFT-01):
adopt as registered, with candidate §§2,5-8,10,12-13 already carrying
most; exact residual amendments in §4 below.
C6. Seed discipline (SEED-01, SEED-RULE-01): initialization ideation
mandatory and shipped; session seed is provenance identity, never variance
control; per-arm reporting with MDE floors (critic A1 accepted as
reporting, not a gate). Candidate §§1,12 carry the substance.

## 2. Unresolved alternatives and preserved dissent

D1. Q-REL-01 mechanism: audit consolidation (per-step reliability drives
collapse) vs critic 87343990 (both axes causal; exclusion unsupported).
HELD UNDER REVIEW: candidate §3 already separates context and reliability
controls (§14), which is compatible with both-axes-causal; amendment-12
framing must weaken if the exclusion claim is kept anywhere. Pending
reverse-critique completion and deliberation.
D2. Redteam P2 burn risk: real, handled by reporting not caps (design-lead
preserved; evidence-lead concurs under operator ruling).
D3. Whole-repo laws-green (critic broader demand): recorded alternative
with sequencing cost, not adopted (root D1 qualification).
D4. fd-based content-addressed storage: candidate evidence to establish,
not security fact (root D2 qualification).
D5. Exact-PID/nonce attribution protocol: proposed option requiring
replay/restart/stolen-token evaluation (root D3 qualification).
D6. Section 8 keep-vs-remove: evidence-lead keeps marked proposal gated on
#778; removal position (if any lead holds it) stays listed.
D7. resequencing weight: steelman sequencing objection stands answered by
economy + provider-contract checks at milestones 1-2 exit criteria;
budget priority disputes go to root.

## 3. Exact candidate changes (residual; root integrates)

E1. §8 lineage paragraph: replace "public coordinator reproduction
remains future work" with the attributed #785 result (production binary
d91c9e40 at b1f006a6; probe-link overwrite exit 0 with author change;
finding-id-conflict exit 2; deterministic IDs derivable); relation
protection stays proposed; identical-content retry vs changed-collision
refusal framed per D5; cross-link #785, #782, #696, #770; open no
duplicates. (LIN-03, REL-LINEAGE-01.)
E2. §8 grant paragraph: correct the authority mapping per LIN-02 — seL4
manual 3.1/3.2 for derivation lineage and subtree revocation; NDSS 2014
macaroons for attenuation plus deref-time caveats only (credentials, not
capabilities); classic revocation as caretaker pattern. Requirements list
otherwise stands.
E3. §12/§14 measurement discipline: add the MDE floor rule per comparison
suite (critic A1 accepted as reporting): state the smallest paired effect
resolvable at stated power and assumptions (Harbor-Index scale reference:
~13.9pp at 1 trial, ~11.3pp at 3 trials; 3pt needs ~1,758 paired tasks).
Add TomasuLLM depth-discipline sentence (critic A2): configured maximum
K=6 vs observed committed-depth saturation at four are distinct
quantities. Mark PASTE 1.8x with named baselines (critic A3 covered;
retain 1.71x ORION / 1.83x SpecFaaS comparator).
E4. §4 failure-evaluation controls (root-accepted D4): distinguish result
batching from asynchrony; symmetric observation conditions;
right-censored outcomes reported; commit/reorder/steering/provider-
acceptance latencies recorded; observation boundary leaves live owned work
running, never terminates an arm, never becomes a budget. Attack 3 A1
deadline recast to observable wait/authorized cancellation with dissent
preserved.
E5. §9/§12 settlement artifacts: completion reports retain pending
operation identities, observed states, ages (ages are information);
workset records source class (peer/tool/model) with provenance (D6, D8).
E6. §3/§12 projections: declared byte projections with complete spill
handles, paged reads, delivered/omitted-byte receipts (D7); no fixed
numeric byte cap; complete values stay available.
E7. §6 repository-act path (root D1 qualification): extensions must pass
the contract laws relevant to that extension and target interface; repair
of knowledge-laws required only for features relying on that contract.
E8. §5/§6 executor checks (root D2/D3 qualification): fd mechanism must
demonstrate checked-bytes-to-executed-object binding (racy
digest-then-pathexec and mutable-inode fd insufficient without protection
contract); add bypass and impersonation tests; no complete-attribution or
confinement claims; PID/nonce as proposed option only.
E9. §11 budget remnants: any surviving "enforced uniformly" or
per-class-cap/deadline wording replaced per runtime amendments A1/A2 as
recast under TIME-01 (R2-1); loss/gating language removed.

## 4. Experiment plan and change map

Plan: experiments-v0.md E-LOG through E-PREFETCH, updated: E-ASYNC adds
the 2.1:1 adverse prior as a measured comparator arm (not a veto);
E-LANE adds compile-once and crossover conditions (BET2-01); E-CITE adds
MDE floors (A1) and seed reporting (SEED-RULE-01); new E-CONF confinement
probe (AUTH-01: direct write/spawn/network from inside the child, OS
outcomes retained); new E-WAIT wait-mechanism specification test
(WAIT-01: name the event effect or polling composition; Chan.recv has no
timeout). E-VERIFY (verification-recipe gate) and E-MON (bounded review
windows with incremental monitoring) unchanged.
Map: register rows → candidate sections: R-RET→§1; H-ADM→§1,§15;
TIME-01→§§4,11,15; Q-rows→§§3,4,12,14; O-rows→§§7,8,11; LIN→§8 (E1,E2);
LAW/WAIT→§§4,6,13 (E7 + E-WAIT); AUTH→§§5,6,10 (E8 + E-CONF);
HAND/MON/BET2/COUNT/SEED→§§7,10,12,14; HARBOR/NOOA/SPEC→§§3,4,12.

## 5. Qualification

Subordinate results reviewed: citation-auditor final report + register +
T1-T4 cross-critique (evidence-lead T4 grading PASS on all five clauses
with stated assumptions, recorded in store; auditor independent T4
verdict still awaited and folds in on arrival);
research-critic final report + 16 findings + probes + candidate review
(reverse-critique surface routed to auditor; relaunched round in flight).
Peer deliberation: substantive reports exchanged with design-lead (6) and
runtime-lead (3); their verdicts on this synthesis outstanding. No
completion requested until deliberation closes and both terminal
evidences land.

## 6. Reconciled-candidate review (sha 3f29dd65)

Root's reconciled version applies E1-E9 in substance (verified by diff
against final-review): lineage/#785, authority mapping, MDE floor,
D4 controls, pending identities, spill receipts, relevant-laws
qualification, fd/bypass checks, budget remnants. Remaining conflicts:
R1. Token-cost sentence (§4, ~line 196) says token/turn costs "remain
unmeasured" without the T3 adversely-measured adjacent prior (2.1:1
speculative-compute ratio, harness-driven posture). Correction: append
"one adjacent harness-driven measurement is adverse and transfer to
model-driven async stays open."
R2. A3 satisfied by omission (no 1.8x figure present); optional
one-clause addition naming 1.71x ORION / 1.83x SpecFaaS if the figure is
ever added. Not a conflict.
Q-REL-01 both-axes position already carried by candidate §3; D1 resolved
on that basis with critic evidence preserved.

## 7. New immutable candidate d3dfd06e1958 (41,891 bytes) + T4 close-out

Diff d3dfd06e vs 3f29dd65 is four feasibility-lane hunks only (P03
exit-2 scope; U32 File.size/EOVERFLOW with segment-rotation consequence;
full-program costs labeled opt-in-diagnostics single-run; interpreter
checks-before-running; constructor namespace; string ABI) — no evidence
conflicts with this register; "representation limits create no budget" is
TIME-01-consistent. R1 RESOLVED per root ruling (candidate 2e65ccfa, sha verified):
2.1 stated as coarse cost proxy (speculative-compute seconds per
wall-clock second saved), not a token ratio; adverse prior with seat
transfer unmeasured; committed-at-most-four vs replay-estimated sweep
distinguished. No residual evidence conflicts from this lane. A3 remains satisfied by
omission. T4-FLAGS-01 adopted (500-tasks paired/unpaired relabel;
round-D Table-II reconciliation; six-figure headline bar). Both worker
completions confirmed; peer synthesis verdicts still requested.
