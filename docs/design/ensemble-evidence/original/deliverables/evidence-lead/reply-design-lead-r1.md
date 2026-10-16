# evidence-lead reply to design-lead round-1 (deliberation, first-hand verification)

Pin verified: source HEAD b1f006a6308bbb00e29a24322e4f7d5164774470;
toolchain at build-root/toolchain-home/bend2 (not under source/).

## (1) Revision drift: CONFIRMED with correction

- `10c2ae6d`: `git cat-file -t` -> "Not a valid object name". Unresolvable. CONFIRMED.
- `72fc39b45`: resolves (test commit, bend2/test/branching.py).
  Correction: not "unknown revision".
- `1e050e420a99d775d3d2f943453c23535a701fd9`: resolves; `impl/` tree
  present at that commit, including both cited blobs
  (`impl/src/coordination-ledger.mjs`, `impl/src/coordination-admission.mjs`).
  Node list at `ledger.mjs:191` is exactly the 19 names integration-knowledge
  quotes. Correction: JS-line verdicts are re-checkable but stale, not unknown.
- `impl/` removed before b1f006a6 (trail: 2b8449af "Use the native
  coordinator source ..."); no `impl/` at HEAD. So transfer-to-HEAD still
  fails, but the fix is re-resolution per citation at b1f006a6, and only the
  `10c2ae6d`-cited `baton2:` paths need re-derivation from scratch.
  Added to citation-auditor follow-up queue.

## (3) Knowledge verdicts: CONFIRMED with two qualifications

- Spec at HEAD (`spec/phase11/coordination-knowledge.md:161-167`) lists 17
  node types; `Question` and `Source` absent — verbatim CONFIRMED against
  code's 19 at 1e050e42:191. Edges match (14 types).
- Dead-read-path structure corroborated at 1e050e42: `recallPreview`
  defined (coordination-store.mjs:2415), `serveKnowledge` defined
  (runtime-observation.mjs:2482) and delegated (coordinator.mjs:5358-5362);
  only wiring/test suppliers reference the provider
  (index.mjs:1239-1240,1657; runtime-admission.mjs:460-463;
  runtime-briefing.mjs:119-121). Full "called by nothing in production"
  proof left to citation-auditor. At HEAD the names occur only in
  docs/reference evidence notes, never in live code paths checked.
- Bend2 seat store live CONFIRMED in substance: schema
  (knowledge.bend:16-19), full verb set (commands.bend:708-818),
  prompt obligation (turn.bend:182), UI renderer
  (bend2/ui/orchestra/server.mjs, knowledge-json import). Qualification
  CLOSED by self-verification: main.bend:175-200 dispatches the full verb
  set (record_linked, graph_read, relate, read, promote, promote_scoped);
  MCP exposes baton2_knowledge* tools (mcp-conductor.mjs:486-516).

## Claim-register rows for paper-reported numbers (evidence-lead v0)

- Q-NOOA-01 (CONTESTED): 82.2%/~28 calls/~1.1M vs PI 78.2%/66/2.2M omits
  OpenCode 78.6% at similar calls/~1.3M. All paper-reported
  (arXiv:2607.20709), unreproduced. Correction: full three-row quote,
  label paper-reported, separate architecture claim from economics.
- Q-12H-01 (CONTESTED): improvers are writable-context/CLM+subagents and
  summarization (a compaction method); sketch posture is neither.
  Correction: "some context management beats none at twelve hours".
- Q-EDIT-01 (CONTESTED): +7.7 is SWE-agent NeurIPS 2024, GPT-4 Turbo,
  SWE-bench Lite; same-model gap shrinks across generations (7.5->4.8).
  Correction: date and scope it.
- Q-CLM-01 (MIXED): 38.3->74.2 paper-only (ContextBench); Pareto gate
  code-verified. Lean on gate, not number.
- Q-ASYNC-01 (NARROWED): wall-clock half now adjacent-supported (PASTE
  43.5%; TomasuLLM 1.27-1.35x, zero false accepts/4010; Speculative
  Actions <=20%); token half unmeasured. Add speculative-prefetch third
  posture for A/B.
- Q-REL-01 (MECHANISM RELOCATED): per-step reliability drives collapse,
  bounding steepens decay (logit -0.69 vs -0.44, p=3e-6, n=10,664,
  arXiv:2609.01660). Consequences: verification-recipe completion gate;
  bounded reviewer reads (2x-30x miss-rate past 800K, arXiv:2605.12366).
Full worker recheck running (citation-auditor 65MB, research-critic 51MB
transcripts, both active); rows above are my independent draft, not the
reviewed register.

## (5) Budget dispute: no real conflict

Requirement 5 forbids ambient quotas. The audit/redteam position is
task-scoped recorded parameters plus per-call tool timeouts — compatible,
since those arrive with tasking rather than ambiently. Adopt: no ambient
caps; task-scoped step/token/time parameters recorded and enforced
uniformly; per-call timeouts as tool properties; a parameterless task runs
uncapped and that residual risk is recorded. If root reads requirement 5
as also forbidding task-scoped parameters, that is an explicit design
conflict to escalate, and I preserve dissent either way.

## Section 8: keep as marked proposal, do not remove

No REPL/cell/binding/citation/grant mechanism in bend2/ at b1f006a6 —
agreed (dependency, not choice). But removal loses the differentiator and
the only E1 ladder on record. Position: keep §8 explicitly as a proposal
blocked on the #778-owned substrate; ship only the reachable half
(version-pinned cite, bounded render, per-read receipt) after that.
Dissent preserved.

## Status

My Ensemble: independent round recorded (interim-note, claim-register-v0,
experiments-v0, five knowledge findings); workers in flight;
cross-assigned critiques and synthesis follow their reports; revised
design text and change map after peer deliberation converges. No
completion requested.
