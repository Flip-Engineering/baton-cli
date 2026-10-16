# Probe interpretation notes (research-critic, 2026-10-16)

`probe_output.txt` is the retained raw output of `probe.py` (commands and exit=0 recorded).
Two interpretation corrections surfaced after full-text verification of the papers the
probe arithmetic was aimed at. Retained here so the raw output and the corrected reading
both survive.

## Correction 1 — arXiv:2609.01660 slope units (resolves Probe 3's flagged inconsistency)

The probe flagged that a pure geometric law success(k)=p^k has logit slope log(p) per
STEP, so a reported logit slope of -0.44 would imply p=e^-0.44=0.644 and success@100=0,
contradicting the paper's own projected 0.24@100.

Verified resolution (DecayPaperScout full-text read of arXiv:2609.01660 §4.5): the
paper's slopes are **per horizon DOUBLING**, not per step: "the logit slope per horizon
doubling is -0.44 for natural, -0.69 for compressed". Under a logit ~ log2(horizon)
regression, a -0.44-per-doubling slope does not map to a constant per-step p, so there
is no contradiction with the 0.42@8 / 0.24@100 projections (which the paper derives from
mean measured per-step reliability r=0.61; the probe's p=target^(1/k) column shows the
implied effective per-step reliabilities 0.91-0.97, i.e. r is heterogeneous across task
families, consistent with the paper's own finding that mean per-step accuracy falls
0.58 -> 0.44 from first to last third of a trajectory).

Also verified: the agentic family has FOUR horizons (H=2..16), not five; the H=32 arm
was cut by API budget, so "collapse within 16 steps" is a lower bound; and the
"compressed regime" that produces the steeper -0.69 slope strips the agent's OWN
reasoning (the paper calls it "a different failure mode entirely"), so the
bounded-window vs unbounded contrast does not isolate window size from content deletion.

## Correction 2 — Probe 1/2 MDE numbers are paired-difference MDEs, one-sided scope

The MDE figures (11.3-13.9 pp at Harbor-Index scale; 1758 paired tasks for 3 pp) assume
Miller's (arXiv:2411.00640) Eq. 9 paired design, alpha=0.05, power=0.80, binary scores
at p=0.28, cross-arm question correlation 0.5. They are the minimum effect a
promotion-style gate could detect at that suite size; they are NOT the SE the gate would
compute (which would simply refuse to promote), and they scale with the assumed
correlation. The load-bearing conclusion stands: an 82-task suite at 3 trials resolves
only ~11 pp paired deltas, so audit amendment 16's "adopt Harbor-Index as the external
suite for the promotion gate" needs an explicit power statement — real edit-tool-class
effects (+7.7 pp in the 2024 ablation) are below its resolution floor.

## Raw inputs

- Harbor-Index 1.0 (82 tasks, best config 28.0%, 3 trials): arXiv:2609.04298 (verified
  by EvalPaperScout; see report).
- Miller Eq. 9 and the resampling factor Var(mu|K>1)=Var(mu|K=1)*(1+2/K)/3:
  arXiv:2411.00640 sections 3.1, 5 (verified from arXiv HTML v1 in this session).
- Geometric-law numbers: arXiv:2609.01660 §4.1-4.7 (verified by DecayPaperScout).
