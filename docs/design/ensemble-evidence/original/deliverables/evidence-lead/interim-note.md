# evidence-lead interim working note (independent round, workers running)

Session seed e4005ac8...: abstract qualities are uniform high-entropy hex,
fragmented, content-free, collision-resistant, provenance-carrying but
semantically empty. Working rule: preserve verbatim, draw no content
conclusions from it, prefer inspected evidence over inference, keep
authority/lineage/alternatives intact. Verified at canonical source
`source/bend2/src/coordinator/native-initial-input.bend:14,20,43`
(production commit b1f006a6308bbb00e29a24322e4f7d5164774470): seed is
`lower(hex(randomblob(64)))`, stored per attempt in `native_initial_inputs`,
reused across retries via coalesce. Knowledge records filed this turn:
seed mechanics; branching-model columns with no log prefix
(`branching-model.bend:13-17`); toolchain TCP AF_INET-only
(`toolchain-home/bend2/effs/tcp_connect.c:27`) and no `File.sync/rename/stat`
in Base.

Dispatched 2026-10-16: citation-auditor (`dispatch:2d7ff6fa-cdbc-4950-a014-e021d910c62a`)
and research-critic (`dispatch:6434340d-a446-4bac-ad3b-968dbd4d2eda`) with
complete shared scope plus specialty guidance, first-round independence
required, critique round to follow.

Independent reading so far (pinned corpus baton-cli @ 5941316491eb01d8794abddc5dcf1798801c4aaf):
README, design-sketch (full), audit-findings (full), audit-evidence (full),
feasibility-bend2 (full), steelman (full), integration-baton (full),
research-open-questions (full). Provisional stance, subject to worker
rechecks: the mechanical core (session-log invariants rows 1-11, async
operation records, tool contracts, safety vocabulary) is code-verified in
the corpus and survives; the load-bearing quantitative justifications
(NOAA 82.2% truncated comparison, twelve-hour posture mismatch, +7.7
2024-dated ablation, CLM numbers paper-only) do not support the inferences
drawn; program lane and runtime module loader are not expressible in Bend2
as written (out-of-process lane plus declarative/repository admission are
the workable paths); fork triple contradicts baton fork/branch/resume and
Fork-and-Flush workspace-only inheritance; orchestrator plane describes
surfaces a seat cannot reach (no seat-side commit lane; only `repl.cite`
is ordinary/MCP); three internal contradictions (compaction dormancy,
catalog masking vs self-extension, no-quotas vs recorded-parameters)
stand as stated in audit-evidence C1-C6. Strongest case for the proposal:
steelman sequencing objection is the load-bearing attack (evidence and
novel mechanisms do not overlap; measurement scheduled last) and needs
deliberation, not dismissal.

Outstanding: worker independent reports; cross-assigned critiques;
synthesis with claim register, revised design text, concrete experiments,
follow-up issues/todos, accepted corrections, unresolved alternatives,
map of changes to Baton/Bend2; deliberation with design-lead and
runtime-lead plus proposal-root. No completion requested.
