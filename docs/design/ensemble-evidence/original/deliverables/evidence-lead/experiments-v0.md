# Discriminating experiments v0 (evidence-lead independent draft)

Costs are order-of-magnitude; evidence limits stated per experiment.
Console: Harbor-Index for suite-based gates; LOCA-bench for posture A/Bs.

1. E-LOG (cheapest, no model calls): log durability under fault injection.
   Fuzz + crash sequences proving §2 invariants; fork==crash-repair at
   different causes. Template: unreal-agent fixtures/fuzz. Exit criterion
   for milestone 1.
2. E-PROV: provider contract for async stub form. One seat, minutes of
   model time: replacement-vs-second-item acceptance per target provider;
   prefix-cache hit rates for three-region prompt + masked catalog.
   Milestone 1-2 exit criterion (unreal-agent.md §12 records
   provider-dependent rejections).
3. E-BOUND: projection bounding vs transcript growth. Same task set, same
   model, pinned harness: bytes/tokens per task, spill-hit rates,
   truncation events, bounding on/off. Async out of picture.
4. E-ASYNC (bet 1): async vs blocking A/B through emulation switch;
   tokens, turns, wall-clock. Falsification per design-sketch §14.
5. E-LANE (bet 2): program lane on/off on same task set, priced against
   60-110 ms/call lane cost and compile-once alternative; then one
   compile-after-five promotion through CLM-shaped gate (paired-SE,
   held-out touched once) on Harbor-Index.
6. E-CITE (bet 3, most expensive, needs orchestrator): two-seat task with
   inline-transcript and re-derivation baselines; token cost, receiver
   cache under commit cadence, replay-exactness across restarts.
7. E-VERIFY: completion gated on workset verification recipe vs ungated;
   long-horizon success and step-reliability slope (addresses
   arXiv:2609.01660 mechanism relocation).
8. E-MON: reviewer miss-rate over bounded windows vs full transcript
   (addresses arXiv:2605.12366); justifies bounded-read rule.
9. E-PREFETCH: speculative-prefetch (copy-on-write sandbox, in-order
   validated commit) vs model-driven async vs blocking; latency + tokens.

Instrumentation obligations on every run: divergence counters per
switchable mechanism (write-side + consumer-side; silent mechanisms
auto-excluded, arXiv:2604.20938 §V); per-deref receipts; provider-counted
vs estimated tokens kept separate; parse-failure events; METR expenditure
framing (tokens/dollars) for publication-ready cost data.
