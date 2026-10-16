# Proposal audit tasks

Tracking issue: [Audit the harness proposal with nested Baton Ensembles](https://github.com/Flip-Engineering/baton-cli/issues/1).

Source baseline: `5941316491eb01d8794abddc5dcf1798801c4aaf`. The review includes the research corpus, design sketch, seven-agent review, current Baton, Bend2, and relevant primary research. Later edits to the sketch require a separate revision check.

- [x] Run an evidence and research Ensemble. Check primary sources, citation accuracy, benchmark comparisons, counterexamples, and evidence limits.
- [x] Run a runtime and integration Ensemble. Check Bend2 feasibility, Baton task and knowledge contracts, durability, recovery, authority, and agent command grammar.
- [x] Run an adversarial design and evaluation Ensemble. Develop the strongest proposal, concrete failure cases, competing designs, and falsifiable experiments.
- [x] Have each Associate Conductor collect independent findings, exchange critiques, and preserve revisions and dissent.
- [x] Deliberate across the three Conductors and publish a claim-to-evidence register, revised proposal, implementation dependencies, and experiment plan.
- [x] Create cross-referenced follow-up issues and tasks for accepted changes. Commit and push the reviewed result.

The reviewed [proposal revision](design-sketch.md), [audit report](ensemble-audit.md), and
[137-file evidence packet](ensemble-evidence/manifest.json) are published with root's assessment.
All three leads' formal finals are reviewed and their exact completion requests confirmed.
All six workers have retained independent reports and reciprocal material. The
[recovery supplement](ensemble-recovery/manifest.json) retains the original runtime and design
continuations, native acknowledgments, natural exit-0 receive results, custody and handling
evidence. The final wording corrections are reconciled. Issue 1 remains open and the seat remains
unimplemented.

- [x] Recover the original runtime and design lead continuations under their recorded identities;
  reconcile their actual formal final syntheses and preserve unresolved dissent.
- [x] Record the final native lifecycle and handling evidence for the interrupted original attempts.
- [x] Reconcile the final reports into the published proposal and audit report in a follow-up.

Accepted implementation work: [native seat integration](https://github.com/Flip-Engineering/baton-cli/issues/2),
[uncertain external tool effects](https://github.com/Flip-Engineering/baton-cli/issues/3), and
[checked artifact execution](https://github.com/Flip-Engineering/baton-cli/issues/4).

Related work in Baton: [knowledge retrieval audit](https://github.com/Flip-Engineering/baton/issues/779), [Bend2 REPL](https://github.com/Flip-Engineering/baton/issues/778), [context snapshots](https://github.com/Flip-Engineering/baton/issues/777), [ordinary delivery](https://github.com/Flip-Engineering/baton/issues/668), and [release qualification](https://github.com/Flip-Engineering/baton/pull/772).

The orchestra runs through existing authorized native clients on the homelab. Baton stores task text in its database. Reports must distinguish implemented behavior, proposed changes, measured results, paper-reported results, and unresolved claims. The audit preserves source work and current release inputs.

## Operator rulings

- 2026-10-16: **the seat is Bend2 only.** Native compilation plus the pinned toolchain's own
  interpreter are the entire execution story. The JS-hosted loader that the runtime audit raised as
  a separate execution backend is not a design option, and that accepted finding ("evaluate the
  JS-hosted option as a separate process relative to the native seat") is superseded. The P10
  observation remains a property of the reviewed toolchain. The design of record states the ruling
  in its status block and in §5.
- 2026-10-16: the rewrite context behind sketch revision `52f35b2` — the seven review documents in
  this directory plus `audit-findings.md` — is dispatched to the audit ensemble, which is asked to
  determine whether it alters any accepted finding, research correction, or retained dissent.
