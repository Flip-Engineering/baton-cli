# Original lead recovery

This supplement records the original runtime and design leads' completed recovery on
2026-10-16. Their formal syntheses, exact completion requests and confirmations, native
acknowledgments, and natural receive results are retained separately. The seat remains
unimplemented and [audit issue 1](https://github.com/Flip-Engineering/baton-cli/issues/1)
remains open.

- [Runtime final synthesis](runtime-lead/final-synthesis.md): 12,039 bytes, SHA-256
  `38810c8ff826512b6243c2b16231ac6af939d262cf5efd0efbf8f5409d8e64f8`.
- [Design final synthesis](design-lead/final-synthesis.md): 9,507 bytes, SHA-256
  `50d259320c16a5c198becbf981dc5215c2b7fef053441dbc63a069d74d3cd37d`.
- [Runtime completion](runtime-completion.json) and [design completion](design-completion.json)
  identify the actual requests, confirmations and acknowledgments.
- [Final custody](final-custody.json) records both ordinary receives' natural exit 0, unchanged
  original identity/parent records, and unchanged explicit stops.
- [Records](records.json) retain later authored messages, findings, lifecycle metadata and
  handling evidence. [Recovery observations](recovery-observation.json) preserve original
  stream sizes, checkpoint verification, process birth/UID and CPU/RSS observations.
- [Roster](roster.json) preserves all nine original model identities. The three Muse seats are
  Muse Spark 1.3, contributor mode.

Both leads reviewed design SHA-256
`b49ab64a5464ce8f042c2321968a4a40c854c87f5d1dd660a365863a1d51f57a`.
Their original verdicts and dissent remain unchanged. Design-lead requested two narrow wording
corrections: required product scope for the compiler and persistent Bend2 REPL, with Bend2-only
REPL source; and the demonstrated JS-hosted loader's execution-backend qualification. Root
accepted those corrections. The reconciled design SHA-256 is
`094353b74d8702b490a9cef5d99fa76b7df13114cfe3b06740481e0497a622f7`.
These wording changes establish no implementation or execution result.

The original runtime and design attempts retain their actual unknown-after-keeper-loss outcomes.
Normal receives reconciled their retained streams and resumed each original native history.
Runtime's ordinary receive ended at 19:09:19 UTC; design's ended at 19:31:12 UTC. Complete native
conversation histories remain in private custody. Public native lifecycle events use an explicit
metadata allowlist.

The [original evidence manifest](../ensemble-evidence/manifest.json) records the approved
publication-history cleanup and its verification scope. Build, release and live acceptance
require their own exact-source evidence.
