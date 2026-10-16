# research-critic review of the root-prepared final review candidate

Reviewed: `/run/baton2-native-homelab/retained/baton-cli-orchestra-20261016/recovery-20261016T1802Z/review-ready/design-sketch.final-review.md` (506 lines) and `review-notes.md`, against my independent primary-source verification (15 knowledge records in the worker scope of research-critic, probes under `deliverables/research-critic/`).

## Verdict

The candidate is fit to serve as the revision base. Every external-evidence statement I could check against a primary source is either correct or correctly scoped, including all seven corrections the recovery round surfaced. I add three concrete revisions (below) and record two explicit resolutions of my earlier dissent. No statement in the candidate contradicts my verification results.

## Where the candidate carries my independently verified evidence (acceptances)

1. PASTE version discipline (§4): v1 "up to 48.5%", v2 and v3 "up to 43.5%" — matches my arXiv v1/v2/v3 reads (superseding record finding:knowledge-record:6f98ed9364301814beacd3d31a3c8b19). The candidate's "serving-layer results with named baselines" and "token and turn costs remain unmeasured" match the paper's own metric list (no token or success metric; outcome-equivalence only).
2. NOOA three-row comparison with the OpenCode row and "paper-reported configurations" (§3) — matches arXiv:2607.20709 Table 3 verbatim; the candidate correctly declines the dropped-row inference the first-round sketch made.
3. CLM: Figure 27 two-hour stall, writable/summarization scope, 38.3→74.2 with named Qwen3.6-27B agent and Claude Fable 5.1 proposer, "paper-reported outcomes" (§3, §6) — matches arXiv:2609.37725 App. E/F. The candidate does not repeat the corpus's "harness fingerprint" phrase, which appears nowhere in the paper text.
4. Reliability study (§3): "compressed-context regime that also deletes prior reasoning", "decay slopes are per horizon doubling" — this RESOLVES my dissent against the first-round framing "per-step reliability, not context shape". I verified: geometric fit 28/36 cells, non-constant per-step reliability (0.58→0.44), agentic horizon capped at 16 by API budget, and LOCA-bench (accuracy 96.0→14.7 for Opus as state grows; PTC 38.7→49.3) plus arXiv:2606.29718 showing context growth/content independently degrading real agents. Both axes causal. (record finding:knowledge-record:87343990c6c61a1edeac92e69b8f0ad4.)
5. Monitor study (§10): incremental monitoring of transcript prefixes at tool boundaries tested; fixed reviewer window "needs its own measurement" — matches arXiv:2605.12366 §3.3/§4.5 (recall 98.6→88 after 800K prefix; reminders help obvious attacks only; fine-tuning did not generalize).
6. Unfireable Safety Kernel (§6): "individually insufficient necessary properties within its model", machine-check "covers a particular pure decision function" — matches arXiv:2606.26057 §3/§6.4/§6.5 verbatim, including my verification that the 704/1000 run is empirical, on a production replica, with a self-built adversary, and that attenuation/deny-by-default discussion is absent from that paper.
7. TomasuLLM (§4): "lower single-session latency with additional drafter tokens and compute" — matches v2 §5.4 (0.9x drafter GPU + 1.56x sandbox CPU for 1.27–1.35x). v2 retains v1's headline numbers (1.31/1.35/1.27; 4,010 records; zero false accepts; 95% upper bound 0.075%), so the v2 citation is sound.
8. Harbor zero-counter teaching (§12): "an inactive path is reported as unexercised ... a settled attempt with a missing consumer is a failure" without "treating every zero counter ... as a failure" — matches arXiv:2604.20938 §V and avoids the overclassification trap. The 42%→26% timeout caveat (9-model Harbor-Index suite, not the 8-model eval) is respected by omission of the conflated claim.
9. Seed and reporting (§1, §12): "recording a seed alone establishes no provider-sampling determinism"; reports state "trial count, pairing, uncertainty" — consistent with my source verification of `native-initial-input.bend` (randomblob(64), retry join, prompt instruction, branch-candidate JSON) and with Miller arXiv:2411.00640, Anthropic's infrastructure-noise page, tau-bench pass^k, and Bouthillier arXiv:2103.03098.
10. Handover rule (§7): "motivates this structure under conditional statistical assumptions" — matches arXiv:2608.14528 (three-part record is construction guidance; Prop 4.1 conditional sufficiency; Prop 3.6 log-loss bit budget).
11. Relation-lineage hazard (§8) — consistent with my read of `knowledge.bend:286-288` (free relation rows keyed by caller-supplied id) at b1f006a6.

## Additions requested (evidence-backed, small)

A1. **Declare a minimum detectable effect per comparison suite (§12 or §14).** The candidate requires trial count, pairing, and uncertainty but not resolution. Arithmetic from Miller Eq. 9 (probe retained at `deliverables/research-critic/probes/seed-variance/`): at Harbor-Index 1.0 scale (82 tasks, binary scores at the 28% operating point, cross-arm correlation 0.5), the paired MDE is ~13.9 pp at 1 trial and ~11.3 pp at 3 trials; ~500 tasks at 3 trials reach ~4.6 pp; 3 pp needs ~1,758 paired binary tasks. Without a stated MDE floor, a promotion-style gate can be statistically unable to ever fire — the statistical form of HARBOR's never-firing flag. One sentence suffices: "each comparison states the smallest paired difference its suite can resolve at the recorded power."

A2. **TomasuLLM depth discipline (§4).** Add the distinction the paper itself makes: the configured maximum chain depth is K=6 (chain depth six, three live candidates, two overlay forks, eight slots; A.8 maxDraftDepth 6), while the observed committed depth saturates at four (§5.3: no chain commits more than four candidates; A.9 sweep saturates at K=4) because a chain ends at the first failed predicted observation. This matters for the speculative-prefetch experiment design: deeper configured chains bought nothing in the paper's own sweep.

A3. **PASTE tool-latency figure is relative (§4, one clause).** The abstract's "1.8x lower observed tool latency" aggregates body §6.3 speedups of 1.71x over ORION and 1.83x over SpecFaaS — relative to named baselines, not an absolute latency factor. The candidate's "named baselines" clause mostly covers this; an explicit "relative" prevents misquotation downstream.

## Dissents resolved and retained

D1 (resolved in candidate): the first-round claim that per-step reliability, not context shape, is the load-bearing driver is not supported as stated; the candidate §3 already carries the corrected two-axis position. My full dissent and evidence remain in the knowledge record ("per-step reliability compounding") and are not withdrawn — the candidate's weaker phrasing is what the sources support.
D2 (retained, not candidate-visible): the historical audit-findings.md amendment 16 names Harbor-Index for the promotion gate without a power statement; A1 above is the standing correction. Harbor-Index contributes audit discipline (broken-task rejection; verifier-failure detection), not error bars — its headline table is single-rollout per cell with no CIs and no rollout seeds anywhere in Harbor, Terminal-Bench 4.0, or the Anthropic noise page.

D3 (retained): provider-side nondeterminism mechanisms (batching, MoE routing, time-of-day) are vendor-documented, not independently reproduced; time-of-day is anecdotal even at Anthropic. Any claim stronger than "documented by providers and benchmark maintainers" would overshoot.

## Not verified by me (attribution preserved)

- The Linux Bend2 invocation timings in §5 (0.33–0.39 s; 0.544 s; 0.642 s) are runtime-lead observations; I did not rerun them. The candidate labels them correctly.
- The JavaScript-line claims in the historical reviews remain provenance-pinned to 1e050e420; the pinned native build root contains no `impl/` tree (my source check at b1f006a6).
- Feasibility probe corrections (P03 exit 2, P06/P09/P10 unreached assertions, P12 wrapper 0) belong to bend-feasibility's lane; review-notes §"Remaining original evidence" records them and I add nothing.
- chroma context rot remains a single-turn, non-agentic industry report with no independent replication as of 2026-10-16.
