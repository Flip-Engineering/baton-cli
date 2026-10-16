# Proposal audit tasks

Tracking issue: [Audit the harness proposal with nested Baton Ensembles](https://github.com/Flip-Engineering/baton-cli/issues/1).

Source baseline: `5941316491eb01d8794abddc5dcf1798801c4aaf`. The review includes the research corpus, design sketch, seven-agent review, current Baton, Bend2, and relevant primary research. Later edits to the sketch require a separate revision check.

- [ ] Run an evidence and research Ensemble. Check primary sources, citation accuracy, benchmark comparisons, counterexamples, and evidence limits.
- [ ] Run a runtime and integration Ensemble. Check Bend2 feasibility, Baton task and knowledge contracts, durability, recovery, authority, and agent command grammar.
- [ ] Run an adversarial design and evaluation Ensemble. Develop the strongest proposal, concrete failure cases, competing designs, and falsifiable experiments.
- [ ] Have each Associate Conductor collect independent findings, exchange critiques, and preserve revisions and dissent.
- [ ] Deliberate across the three Conductors and publish a claim-to-evidence register, revised proposal, implementation dependencies, and experiment plan.
- [ ] Create cross-referenced follow-up issues and tasks for accepted changes. Commit and push the reviewed result.

Related work in Baton: [knowledge retrieval audit](https://github.com/Flip-Engineering/baton/issues/779), [Bend2 REPL](https://github.com/Flip-Engineering/baton/issues/778), [context snapshots](https://github.com/Flip-Engineering/baton/issues/777), [ordinary delivery](https://github.com/Flip-Engineering/baton/issues/668), and [release qualification](https://github.com/Flip-Engineering/baton/pull/772).

The orchestra runs through existing authorized native clients on the homelab. Baton stores task text in its database. Reports must distinguish implemented behavior, proposed changes, measured results, paper-reported results, and unresolved claims. The audit preserves source work and current release inputs.
