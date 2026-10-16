# Nested proposal audit

Status: reviewed proposal revision. This contributor report accompanies the proposed
[design sketch](design-sketch.md). The runtime and design leads' formal final syntheses remain
pending recovery. The seat remains unimplemented.
Tracking: [baton-cli issue 1](https://github.com/Flip-Engineering/baton-cli/issues/1).

The audit checked proposal baseline `5941316491eb01d8794abddc5dcf1798801c4aaf`, the
research corpus, and the seven earlier reviews. Current-source claims refer to Baton
`b1f006a6308bbb00e29a24322e4f7d5164774470`. The reviewed native toolchain is the recorded
Baton fork of Bend 2.0.25. The revision targets baton-cli
`26beba64b0d10336ff7783dcee58e78e5bb13c56`. Build, release, and live acceptance need separate
exact-source evidence.

## Contributors and review structure

Each Ensemble had one Associate Conductor and two workers. Workers performed independent reviews,
then received opposing findings for critique. The three Conductors exchanged substantive reports
through the `proposal-deliberation` peer group. All nine records specify effort `high`; the observed
effort field is empty. The exact observed model ID matches the recorded ID for all nine contributors.
The three Muse contributors used Muse Spark 1.3, contributor mode.

| Ensemble | Recorded identity | Role | Exact recorded model |
| --- | --- | --- | --- |
| evidence-research | evidence-lead | Associate Conductor | `muse-spark-1.3-contributor` |
| evidence-research | citation-auditor | Primary citations and evidence grading | `zai/glm-5.3-flash` |
| evidence-research | research-critic | Counterexamples and evaluation design | `zai/glm-5.3-flash` |
| runtime-integration | runtime-lead | Associate Conductor | `kimi-code/k3` |
| runtime-integration | bend-feasibility | Pinned compiler and host-effect probes | `zai/glm-5.3-flash` |
| runtime-integration | baton-contracts | Task, receipt, branch, and knowledge contracts | `muse-spark-1.3-contributor` |
| design-evaluation | design-lead | Associate Conductor | `deepseek/deepseek-flash` |
| design-evaluation | proposal-strongman | Competing designs and sequencing | `muse-spark-1.3-contributor` |
| design-evaluation | failure-evaluation | Concrete failure cases and experiments | `zai/glm-5.3-flash` |

The recovery used the original records, parent routes, endpoints, and native identities. An
authored report, a native execution result, reciprocal critique, and Conductor confirmation are
separate evidence. The retained record identifies each one. A root-prepared revision records
root's assessment and does not establish a contributor's agreement.

## Accepted findings

| Claim | Evidence and limit | Proposal consequence |
| --- | --- | --- |
| The historical JavaScript review remains reproducible at its own pin. | `72fc39b45` and `1e050e42` resolve; `10c2ae6d` remains unresolved. The native source removed `impl/` in `2b8449af`. The citation auditor re-resolved 41 of 44 native paths exactly and corrected three. | Cite historical and native contracts separately. Re-resolve each source statement. |
| A new native seat needs coordinator integration. | At `b1f006a6`, admission, configuration, projection, and delivery predicates recognize `codex`, `omp`, `muse`, and `claude-code`; recruitment first stores a free-text harness string. The direct-turn predicate, launch dispatcher, and relevant laws also require matching changes. | Specify a correctly identified Bend2 adapter, its admission checks, receiving, wake, control, and settlement. Test unsupported identity refusal before the dispatcher's final Claude Code branch. |
| Baton already owns task inputs and native handling. | The contracts review traced the assumed primitives through source, read-only help, and a database copy. It specified ten scratch-database tests; that list establishes no execution result. | Keep complete task text in Baton and use native ownership, routing, and receipt contracts. |
| Source size and startup costs depend on revision, scope, and host. | The citation auditor's source count excludes `context/`; the runtime lead's count includes it. Linux diagnostic timings differ from the earlier macOS measurements. The retained full-coordinator C-emission run used opt-in diagnostics and records 2101.119 s and 142,651,376 KiB maximum RSS. | State source, fork, counted tree, host, and diagnostic configuration. Compare interpreted, discrete, and compile-once execution. |
| The interpreter checks before running. | The feasibility continuation's interpreted refusals and the pinned `main.ts` check/report path agree. P10 demonstrates JS-projected values from exported non-IO definitions in a JS host. | Correct the root draft's earlier checker sentence. Evaluate the JS-hosted option as a separate process relative to the native seat; a typed result-codec contract remains untested. |
| Host primitives are demonstrated with specific limits. | Twelve feasibility probes include authored durability effects, supervision, AF_UNIX, incremental TCP, completion-order join, dynamic C loading, law checks, and JS hosting. P03 exercises whole-file publication and retains its deliberate unlink-after-rename exit 2. | Append-mode writes with per-commit sync, single-writer locking, crash recovery, and OS confinement need separate tests. |
| Base file interfaces and authored effect ABI impose concrete implementation requirements. | `File.size` returns `EOVERFLOW` above `UINT32_MAX`; `File.read_at` uses U32 offsets. Constructor names share a global namespace. `io_cstr`'s length excludes its appended NUL. | Specify segmented or wider-offset log access, declaration naming, and exact multi-string ABI tests. |
| Operation intents leave an external-effect crash window. | An intent can survive while an external effect succeeds before its result commit. | Retain uncertain outcomes, original identities, and tool-specific idempotency or an authorized re-execution decision. |
| Elapsed duration does not establish operation settlement. | The operator ruling applies to task-scoped and per-call duration, token, and step controls. | Keep live owned work through observation waits. Retain external lifecycle evidence and explicit authorized cancellation. |
| SDK routing has limited authority coverage. | A same-UID generated process retains ambient filesystem, process, and network access. | Separate SDK mediation, artifact identity, attribution, and tested OS confinement. |
| Admission needs a checked-bytes-to-execution contract. | A checked digest followed by pathname execution is racy; a descriptor to a mutable inode also needs protection. | Evaluate protected execution mechanisms and interpreter behavior with mutation tests. |
| Native branches have fresh conversation state and explicit inherited material. | Schema and branch construction independently identify workspace, complete task inputs, selected scoped knowledge, and native configuration. | Keep crash recovery in its original lineage. Record branch inheritance and selection provenance. |
| The native knowledge store has live consumers. | The authored SQLite store has CLI, MCP, and browser readers requiring explicit pulls. The task prompt supplies knowledge instructions. Historical Cairn findings describe their source revision. | Retain the target-store distinction; define automatic briefing composition and any new admission restriction as proposed work. |
| Relation authorship can be replaced through a caller-supplied relation ID. | Isolated SQL and the attributed production-binary public reproduction in [Baton 785](https://github.com/Flip-Engineering/baton/issues/785) are separate evidence. Changed finding content refuses with `finding-id-conflict`. | Protect lineage-sensitive relations and retain original rows on changed collisions. |
| The knowledge contract law has source drift. | The runtime lead's `--check-only` reaches a compiler error; source inspection also finds missing helpers and arity drift. [Baton 782](https://github.com/Flip-Engineering/baton/issues/782) tracks repair. | Require passing laws relevant to the extension and target interface. Features using this contract need its repaired law evidence. |
| REPL cells, commit admission, and grants remain proposed. | The reviewed native source lacks the proposed substrate. | Preserve the intended interface and name [Baton 778](https://github.com/Flip-Engineering/baton/issues/778) and [777](https://github.com/Flip-Engineering/baton/issues/777) as dependencies. |
| Initialization seeds and evaluation randomization have different contracts. | The coordinator records `lower(hex(randomblob(64)))`, the required brief abstract ideation instruction, and retry reuse. | Preserve the operator-required initialization behavior. Report evaluation seeds and measured variation separately. |

## Research corrections

The citation auditor checked sixteen papers and approximately sixty quantitative claims. Its
recheck of the earlier grading table found 68 of 73 rows precise, five imprecise, and none wrong.
These counts describe that table and its grading rules. The complete register retains the
individual qualifications and withdrawn flags.

| Source | Correction and transfer limit |
| --- | --- |
| NOOA | Preserve the full GPT-5.5 xhigh comparison: NOOA 82.2%, OpenCode 78.6%, PI 78.2%, with their reported calls and tokens. The reference implementation establishes its own object identity and tool behavior. |
| CLM | The append-only baseline stopped improving after roughly two hours. The 38.3-to-74.2 KVStore comparison used a Qwen3.6-27B agent and Claude Fable 5.1 proposer. Context-management conditions and skill evolution need separate attribution. |
| PASTE | Version 1 reports up to 48.5%; versions 2 and 3 report up to 43.5%. The throughput comparisons use named serving baselines. These establish no Baton model-driven async result. |
| TomasuLLM | Section 5.4 reports a coarse proxy of about 2.1 speculative-compute seconds per wall-clock second saved. Seat-specific resource effects remain unmeasured. Configured maximum depth six, measured chains committing at most four candidates, and replay-estimated depth sensitivity are separate evidence. Fixed seeds, samples, exclusions, and its own baseline constrain transfer. |
| Speculative Actions | The largest reported 19.8% gain is a particular chess configuration, five thirty-step runs, three predictions, and GPT-5 actor/speculator settings. |
| ALITA-G | Preserve implementation diversity and validation-set/configuration limits. The earlier mandatory deduplication description was unsupported. |
| Reliability analysis | Both context conditions and per-step reliability affect the reported outcomes. The compressed regime also removes prior agent reasoning; decay slopes are per horizon doubling. |
| Monitoring | Incremental tests observe transcript prefixes at tool boundaries. A fixed reviewer window requires its own missing-context and distributed-attack evaluation. |
| Safety kernel | Four necessary properties and the pure decision-function proof have explicit scope. Full seat enforcement, OS confinement, signing, and integration require distinct evidence. |
| Authority references | seL4 supplies a derivation/revocation comparison; macaroons supply credential attenuation and contextual caveats. Baton grants require their own implementation evidence. |
| Handover | Conditional statistical sufficiency motivates task-appropriate projections. Complete original observations remain available. |
| Harbor and Harbor-Index | Preserve suite/model/posture and statistical assumptions. Zero counters need path and settlement classification. Report each comparison's resolvable effect size at its stated power and assumptions. |

The versioned primary-source checks accompany this report. The revised sketch links the primary
papers for its material measurements. Paper results are hypotheses and comparison inputs for the
seat's experiments.

The citation auditor's final reciprocal pass graded twelve seed-rule applications as passing with
three retained qualifications. A roughly 500-task statement used unpaired arithmetic alongside
paired assumptions; the paired estimate needs its declared correlation and power assumptions.
The Harbor round-D comparator requires its Table II reconciliation. The WebGL percentages belong
to Devin with Fable 5 in the primary challenge report. These qualifications remain visible in the
register and records; the pass count does not make every numeric statement precise.

## Retained artifacts

[The manifest](ensemble-evidence/manifest.json) identifies exact bytes, hashes, capture lineage,
and the status of each retained body. [Database records](ensemble-evidence/records.json) retain
native identities, model records, original message bodies, findings, relation lineage, actual
execution outcomes, completion requests, and handling records. Original and continuation files
have separate paths. Raw authored bodies retain their original wording, including positions
subsequently corrected or withdrawn; the claim assessments in this report identify the adopted
meaning.

The first publication included private native conversation bodies in ten lifecycle events.
The corrected packet projects all 28 lifecycle events through an explicit metadata allowlist.
All 315 authored message bodies and the authored reports are preserved. Complete original
records remain in private custody. The manifest records the correction, original digest,
replacement digest, and the structural audit of all 137 packet files. The configured credential
patterns found no matches.

The packet includes the citation auditor's complete register, evidence lead's reviewed register
and experiments, contracts review and scratch-database evidence, competing designs and reciprocal
critiques, feasibility findings and probe sources/outputs, and the original root diagnostic review.
[Primary checks](ensemble-evidence/primary-source-checks.json) retain paper versions and limits.
[The TomasuLLM continuation check](ensemble-evidence/tomasullm-primary-check.json) records the
adjacent compute-cost qualification and the measured versus replay-estimated depth distinction.
[Compiler source checks](ensemble-evidence/compiler-source-checks.json) and the
[original build result](ensemble-evidence/compiler-build-result.json) preserve the configuration
behind the large-program observation. Their hashes identify the actual retained toolchain.
[Integration source excerpts](ensemble-evidence/integration-source-review.json) check the narrow
contract corrections. The [knowledge CTE review](ensemble-evidence/knowledge-cte-root-review.json)
rejects the reciprocal critique's absent-table allegation: `graph_ctes` defines `nodes` and `edges`
before search and traversal use them. The author's raw objection remains retained. The separate
[Main9 public reproduction](https://github.com/Flip-Engineering/baton/issues/779#issuecomment-6222094104)
exercises the graph paths at the same source pin.

## Competing designs and dissent

The strongman developed a minimal crash-safe blocking design and an ephemeral generated-program
design. Their useful mechanisms remain comparison arms. The failure evaluator tested their
claims against crash ambiguity, retained work, caller identity, and enforcement requirements.

| Position | Root assessment and retained uncertainty |
| --- | --- |
| Implement only the blocking design first. | Keep a blocking comparison and minimize the first native adapter. Independent log, tool, provider, and extension work can proceed concurrently. Integration depends on the contracts each feature actually uses. |
| A generated program can express multi-step orchestration. | Preserve that mechanism and test compile-once economics. Its ordinary same-UID process has ambient authority; stronger confinement and complete-attribution claims require execution evidence. |
| Remove the proposed cross-seat context section until its substrate ships. | Keep the intended scope with explicit dependencies and unimplemented status. A report/evidence-reference flow can be evaluated on current contracts. |
| Per-call deadlines settle unfinished work. | The operator ruling excludes this mechanism. Observation waits, actual lifecycle outcomes, and explicit authorized cancellation remain available. The original conflicting proposal is preserved in the source report. |
| Require every repository law to pass before any extension. | Require the laws relevant to that extension and target interface. The broader requirement has additional sequencing cost and remains a recorded alternative. |
| An fd or content-derived path proves execution identity. | Require actual protection against mutation and an execution-path test, including interpreters. The design options remain unproven. |
| Exact PID and a nonce prove caller identity and complete attribution. | Treat this as a protocol option requiring replay, restart, impersonation, and stolen-token tests. SDK calls and captured output have observable attribution; ambient effects need their own observations. |
| Protect relation IDs by changing ownership or namespaces. | Compare those policies explicitly. Preserve identical retries and refuse changed authorship/content while retaining the original records. |
| Limit delivered spill bytes. | Declare each projection and retain complete handles, paging position, and delivered/omitted-byte receipts. A projection creates no operation or work budget. |
| Knowledge search needs schema tables named `nodes` and `edges`. | Rejected by exact-source inspection: both names are SQL common table expressions composed into the read query. The standalone absent-table query in the critique does not exercise that path. |

## Experiments and dependencies

The implementation plan retains three independent comparisons: async versus blocking effects,
generated programs versus discrete calls and compile-once execution, and versioned cross-seat
context versus inline context and re-derivation. Each comparison reports quality, turns, latency,
provider-counted and estimated tokens, compute, and recovery behavior separately.

Required controls include result batching or a one-result-per-turn replay arm, actual provider
continuation acceptance, per-operation commit and reorder latency, steering/control latency,
initialization provenance, evaluation seeds, and resolvable-effect assumptions. Symmetric
observation conditions identify right-censored outcomes while preserving live owned work.

Fault tests cover torn log frames, writer conflicts, external effects before result commit,
surviving children, repeated observation recovery, duplicate effects, artifact mutation, direct
log writes, unrelated-process SDK requests, and relation-ID collisions. OS outcomes and actual
native statuses remain part of the evidence. Wait-mechanism tests must name their effect or
polling composition; the reviewed `Chan.recv` has no timeout or Base `select`/`race` contract.

The first integrated milestone needs the native adapter and the log/tool/provider contracts it
exercises. REPL/context substrate is required for the commit-and-cite experiment. Lineage-sensitive
knowledge features need a protected relation contract and the relevant law evidence. Separate
implementation lanes can prepare their interfaces and experiments concurrently.

Accepted seat work is tracked in [native adapter integration](https://github.com/Flip-Engineering/baton-cli/issues/2),
[uncertain external-effect recovery](https://github.com/Flip-Engineering/baton-cli/issues/3), and
[binding admitted bytes to execution](https://github.com/Flip-Engineering/baton-cli/issues/4).

## Recovery and publication evidence

The pre-recovery packet retained 176 messages, 102 knowledge rows, 380 verified files, and 25 probe
directories. Thirteen complete authored reports and nine complete knowledge bodies had already
been recovered from the original command record. Seven native attempts were interrupted, and two
retained natural status 0. Original bodies and probes remain preserved independently of later
continuations.

Ordinary scoped receives reconcile those attempts under the original identities. Lifecycle
uncertainty, an authored final report, and a successful native result are recorded independently.
Partial probes retain their actual compiler and wrapper outcomes. A diagnostic wrapper returning
zero does not establish that its intended assertion ran.

[Recovery observations](ensemble-evidence/recovery-observations.json) retain the UTC observation,
boot, UID, recorded native PID and birth bytes, CPU/RSS snapshots, and exact stream sizes. At
18:40:12 UTC the runtime stream held 225,937,046 bytes and the original design stream held
967,455,208 bytes. Stream size and historical observer errors alone establish no replay-algorithm
cause. These resource observations remain distinct from compiler-build costs.

The evidence lead reviewed candidate `2e65ccfae24e`, adopted the remaining cost qualification,
reported no residual evidence conflicts, and received confirmation of its exact completion
request. At the 2026-10-16 publication, the runtime and design leads' formal final syntheses and
native continuation remain pending; homelab access is unavailable. The latest observed runtime
native was composing its synthesis. The design lead's original pre-reboot stream was undergoing
observer reconciliation; its advancing checkpoint establishes no live native authorship. The
remaining raw cursor was not obtained before host access failed.

Root source review and the retained worker reports support this proposal revision. They establish
no missing Conductor verdict or confirmation. Tracking issue 1 remains open. Recovery will retain
the original identities, reconcile the actual final reports in a follow-up, and preserve dissent.
The artifact manifest records hashes and source/capture lineage. Implementation, build, and live
acceptance require their respective evidence.
