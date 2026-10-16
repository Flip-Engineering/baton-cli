# Recheck dispatch: rewrite context for the audit ensemble

Status: prepared, not delivered. The audit ensemble that produced
[ensemble-audit.md](ensemble-audit.md) no longer has a runtime. Its orchestra database, instance
home, client runtimes, and checkout all lived under `/run/baton2-native-homelab/` (tmpfs); on
2026-10-16 the instance root was recreated holding only a compiler build
(`retained/baton2-compiler-741-20261015`), `retained/baton-cli-orchestra-20261016/` is absent, and no
muse, kimi, glm, or deepseek client runtime remains provisioned for the instance users. The
contributors' identities, models, and invocation contracts survive in
[ensemble-evidence/records.json](ensemble-evidence/records.json); their seats do not. Delivery
therefore requires re-provisioning the round. This file is the body to hand to it.

Recipients and structure are the recorded ones: three Associate Conductors with owned Ensembles —
evidence-research (`muse-spark-1.3-contributor`; workers `zai/glm-5.3-flash` ×2), runtime-integration
(`kimi-code/k3`; workers `zai/glm-5.3-flash`, `muse-spark-1.3-contributor`), design-evaluation
(`deepseek/deepseek-flash`; workers `muse-spark-1.3-contributor`, `zai/glm-5.3-flash`) — each
developing independent findings, exchanging critiques, and preserving dissent, per the structure in
[ensemble-audit.md](ensemble-audit.md) §"Contributors and review structure".

## The question

The audit checked proposal baseline `5941316491eb01d8794abddc5dcf1798801c4aaf` and then published a
revised design. Between those two moments, a separate rewrite landed:

- `5941316` — the seven-agent review ([audit-findings.md](audit-findings.md) plus the seven review
  documents in this directory: `audit-evidence.md`, `critique-redteam.md`, `steelman.md`,
  `feasibility-bend2.md`, `integration-baton.md`, `integration-knowledge.md`,
  `research-open-questions.md`).
- `52f35b2` — the sketch rewrite that applied 23 ranked amendments from that review, changed the
  target to baton2, introduced the out-of-process program lane and the three extension paths,
  corrected fork, grants, catalog, compaction, and knowledge participation, and resequenced the
  milestones.

The ensemble audited the pre-rewrite baseline but edited the post-rewrite file. Its own
[audit-todo.md](audit-todo.md) records that later edits require a separate revision check. This
dispatch is that check.

**Determine, for each item below, whether the rewrite context alters the audit's view — confirming
it, revising it, superseding it, or leaving it unaffected — with evidence, and state whether the
design of record needs further change.**

1. Every row of [ensemble-audit.md](ensemble-audit.md) §"Accepted findings" (18 claims).
2. Every row of §"Research corrections" (13 sources) and the qualifications in the reciprocal pass.
3. Every row of §"Competing designs and dissent" (10 positions), including the positions the audit
   marked rejected.
4. The revised design itself ([design-sketch.md](design-sketch.md), SHA-256
   `094353b74d8702b490a9cef5d99fa76b7df13114cfe3b06740481e0497a622f7`): state which sections the
   rewrite context would change, if any.

## Known supersession, so effort is not spent twice

Operator ruling, 2026-10-16: **the seat is Bend2 only.** Native compilation plus the pinned
toolchain's own interpreter are the entire execution story. The JS-hosted loader the runtime audit
raised as a separate execution backend is not a design option, and the accepted finding "evaluate
the JS-hosted option as a separate process relative to the native seat" is superseded. The P10
observation stands as a property of the reviewed toolchain. The design of record states the ruling in
its status block and §5; [audit-todo.md](audit-todo.md) §"Operator rulings" records it.

## What the determination must contain

- A per-item verdict with the evidence that decided it, distinguishing implemented behavior,
  proposed change, measured result, paper-reported result, and unresolved claim, as the audit's own
  reporting discipline requires.
- Any item the rewrite context does not affect, stated as such rather than restated.
- Retained dissent, with the dissenters' identity.
- Any further change to the design of record, as a concrete edit, and the evidence for it.
- Publication under this directory with the evidence packet's discipline: authored bodies preserved,
  hashes recorded, private material excluded.

## Delivery note

The rewrite context is fully readable from the repository at `52f35b2` and its parents; no separate
transfer is required. When the round is re-provisioned, dispatch this file as the task text and let
the Ensembles work from the repository at that revision, with the operator rulings applied.