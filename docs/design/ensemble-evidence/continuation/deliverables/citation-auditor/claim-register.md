# Citation-auditor claim register — independent pass + critique-round re-resolution

Actor: citation-auditor (Ensemble evidence-research, coordinator evidence-lead).
Date: 2026-10-16. Corpus pin: baton-cli `5941316491eb01d8794abddc5dcf1798801c4aaf` (verified by `git rev-parse`).
Canonical Baton source pin: `…/postrelease-751-761-20261015-9/source` at `b1f006a6308bbb00e29a24322e4f7d5164774470` (verified by `git rev-parse` and `manifest.json` `source_commit`).
Pinned toolchain: `toolchain-home/bin/bend` (wrapper `bun --smol bend2/main.ts`), reports `Bend 2.0.25`; manifest `compiler_identity`: "Baton fork of Bend 2.0.25; memoization, Bun 1.3.14 small heap, opt-in diagnostics".

Method: every paper-cited number re-checked against arXiv abs + full text (verbatim quotes with section/table locations, fetched 2026-10-16, regex-exhaustive where stated); corpus-internal citations re-checked against the pinned corpus docs; implementation citations re-derived at the canonical pin; JS-line (`impl/`) citations re-resolved in git history at `1e050e420` per the critique-round directive. Independence: findings recorded before peer outputs were read; the seven reviews are the object of audit, not a source of verdicts. Randomized seed `e4005ac8…a89` preserved verbatim in the task record; drawn on for nothing.

Severity scale: **S1** material (changes a design decision or verdict), **S2** moderate (misleading, direction survives), **S3** minor (precision/hygiene).

---

## Part A — paper-cited numerics (research-open-questions.md, audit-findings.md, audit-evidence.md)

### R1 — NOOA comparison truncated in the sketch (confirms audit-evidence row 20) — S2
- Verbatim claim (sketch): "NOOA reaches 82.2% on SWE-bench Verified at roughly 28 model calls and 1.1M tokens per task against comparison harnesses' 66 calls and 2.2M" — `docs/design/design-sketch.md:76-78`.
- Primary source: arXiv:2607.20709v1 §4.2 (full-text regex sweep). Verbatim: "it reaches 82.2% using approximately 28 model calls and 1.1 million tokens per task"; "while PI uses 66 calls and 2.2 million tokens for 78.2%"; "OpenCode uses a similar number of calls but approximately 1.3 million tokens for 78.6%".
- Severity S2: the sketch's cost inference (alternative posture costs double calls/tokens) does not survive the omitted OpenCode row; the architectural mechanism claim survives.
- Reproducible evidence: knowledge-record:c7683fc60769548fd8df977e9ec580bd; scout VerifyNOOA.
- Strongest case for the proposal: per-token advantage holds (1.1M vs 1.3M/2.2M) and NOOA outscores both; mechanism sentence supported ("tool outputs remain available as live Python values… bounded prompt previews… well below the context limit").
- Correction: quote all three rows; label paper-reported, self-run by NOOA's authors (not externally reproduced), GPT-5.5 xhigh only; delete the 66/2.2M inference (= audit amendment 1). Add one clause: 82.2 is best-among-open-harnesses — the paper itself cites Codex 88.7% and submission-SOTA 79.2%.
- Cost: one paragraph, no retest. Dissent: none.

### R2 — NOOA evidence class — S3, confirmed
"22–72k median prompt tokens" absent from full text (zero regex hits for median/22-72); blog 29 vs paper "approximately 28" (twice); nooa.md §7 records both. Correction: none beyond R1 labeling.

### R3 — Twelve-hour runs posture mismatch (row 21) — S2, confirmed
Corpus `context-language-models.md §5` (arXiv:2609.37725): improving methods = CLM, CLM+subagents **and summarization**; at 128K summarization 47.8 > CLM 47.3; Qwen3.6-27B + Claude 4.6 Sonnet; all API-model numbers paper-only (§8). Citation supports "some context management beats none at twelve hours", not the sketch's projection-bounded append-only posture. Correction = audit amendment 1's scope sentence. Cost: one sentence.

### R4 — CLM 38.3→74.2 + **audit-document error** — S3
Result is paper-only (held-out KV Store); gate code-verified (`evolve.py`). **New:** audit-evidence.md:131-132 says "GPT-5.4 with a Claude Fable 5.1 proposer"; corpus §5 says "Qwen3.6-27B agent, Claude Fable 5.1 proposer" (GPT-5.4 was the ContextBench *pilot* model). Grading unaffected; one-line audit fix.

### R5 — +7.7 edit ablation (row 34) + **audit-document imprecision** — S3
Primary verified: arXiv:2405.15793 Table 3, GPT-4 Turbo, SWE-bench Lite — no-edit 10.3% (↓7.7); edit-without-linting 15.0% (↓3.0); w/ linting 18.0%; iterative search 12.0% (↓6.0); no-search 15.7%; RAG 2.67% vs 18.0%. 2024-dated as the audit says. **New:** audit-evidence.md:128-129 attributes the 4.8 row to "Anthropic-scaffold-minus-mini"; it is live-SWE-agent−mini (Opus 4.5), a different evolved scaffold (benchmarks.md:167 states it correctly). Trend survives (Gemini 3.2 corroborates); name live-SWE-agent in the fix.

### R6 — Speculative-execution evidence — confirmed, S3 nuances
PASTE arXiv:2603.18897: 43.5% task-completion-time reduction, 1.8× tool latency, latency-only metrics — CONFIRMED. TomasuLLM arXiv:2609.38201: 1.31×/1.35×/1.27×, zero false accepts across 4,010 audited commit-validation records, COW sandboxes, trajectory-order commit — CONFIRMED. Speculative Actions arXiv:2510.04371: up to 55% accuracy / up to 20% latency, lossless commit-on-match, cost–latency analysis — CONFIRMED. Nuances: PASTE multi-institution (SJTU/MSR/Stevens/Google/HKUST; "Act While Thinking" was its own v1 title); TomasuLLM 1.27× is matched-progress (non-capped rows 1.23× geometric); 55/20 round up from chess (54.7%/19.5%), other domains lower; none measures token cost or turn structure — the review's "token half remains unmeasured" stands.

### R7 — Decay and monitor papers — confirmed, no severity
arXiv:2609.01660: 10,664 trajectories (9 models/4 families/5 horizons/3 regimes); slope −0.69 bounded vs −0.44 natural, p=3e-6; 0.42/0.24 projections; ≤16-step collapse; single author, physics.soc-ph; code released. arXiv:2605.12366 (Martin & Roger): 2×–30× miss-rate after 800K benign tokens (Opus 4.6/GPT 5.4/Gemini 3.1); reminders partially mitigate. Review faithful; audit's uses (bounding steepens decay; bound reviewer reads) supported.

### R8 — HARBOR pair — confirmed, S3
arXiv:2604.20938: dead PASTE flag (entry never wired, counter identically zero, §V), 12/89 vs 17/89, union 81/89, codex-py ≈52K vs ≈649K (§III), auto-exclusion + divergence counters. arXiv:2609.04298: all figures confirmed at the cited sections (8×2 harnesses, 54 benchmarks, 6,627 tasks, 226B tokens, >$300K; ICC 0.75; 0.451 vs 0.087; 42%→26%; 6,028; ~1/3 rejected; 4 GAIA2 never-firing adapters; Harbor-Index 82/29/≤30%/28.0%). Nuances: the review merges two campaigns with different model lists (GPT-5.5/Opus 4.8 only in the Harbor-Index run); paper §I 648K vs §III 649K (review matches §III). Fix: one clause.

### R9 — Fork-and-Flush attribution (audit-findings:73-76) — S2, wording
Paper verified: flushing = "(W,C)→(W,∅)" (abstract, §1, §4, §7). NOT paper claims: "complete task inputs", "selected findings", "native configuration with no log prefix". The audit-findings sentence attributes that list to "the Fork-and-Flush method" citing `branching-model.bend:13`. Re-resolution at the pin (R17) confirms the baton2 record's 18 columns do carry workspace/task/inputs/knowledge/evaluator/harness/model/effort/command — so the list is the baton2 implementation record presented as the method. Fix: split paper claim from implementation record; two clauses.

### R10 — Safety-formalist citations — confirmed, S3 note
arXiv:2606.26057: four properties, address-space premise, Z3+Kani, 1,000/704/no-escape — confirmed; paper-stated bounds (replica deployment; tested-taxonomy robustness; signing path tested-not-proved). arXiv:2605.04785 AgentTrust: 95.0% (production-only ruleset) / 96.7% (**patched** ruleset, explicitly not zero-shot) — confirmed; single-author preprint. Bonus: its §7.1 L6 concedes in-process enforcement is bypassable — supports the review's objection.

### R11 — ALITA-G: one invented stage — S3 MISMATCH (new)
research-open-questions.md:105-106 says Alita-G "…deduplicates, and consolidates…". Paper arXiv:2510.23601 has no dedup anywhere (zero regex hits) and §3.3 states the opposite ("preserves the diversity of MCP implementations to maximize coverage"). GAIA 83.03/89.09 and ~15% token reduction (10,394 vs 12,305 = 15.5%) confirmed; Alita lineage confirmed. Fix: one word ("consolidates (explicitly preserving implementation diversity)").

### R12 — LOCA-bench, ACON, handover — confirmed, S3 notes
LOCA-bench arXiv:2602.07962 all five claims confirmed. ACON arXiv:2510.00615: 26–54% is peak **token** usage (review says "token/memory", S3); "up to 46%" = 45.6% EM measured in a with-distilled-compressor configuration while the paper's stated mechanism is mitigating context distraction. Handover arXiv:2608.14528 all five confirmed (abstract; two authors, theory-only).

---

## Part B — corpus-internal claims (audit-evidence.md rows 1-73, C1-C7)

### R15 — Grading-table recheck: 68/73 OK, 5 IMPRECISE, 0 WRONG
Rows 1-36 (scout CorpusGrades1 + my spot checks): 33 OK, 3 IMPRECISE — row 18 (ToolHistoryProjection refusal is dsh §5.1, audit cites §10; audit's own C2 bullet cites §5.1 correctly), row 31 (fx `ToolSpec` covers concurrency/idempotency/permission but not "result representation" or "timeouts" — those live on the §6 shell action schema; "fields verified" over-verifies two of five axes), row 34 (see R5).
Rows 37-73 (scout CorpusGrades2): 35 OK, 2 IMPRECISE — row 66 (benchmarks.md "unknowns" supports only the async-vs-blocking half; "program lane and citation hand-off unmeasured" is documented in context-networking/deref, not benchmarks.md), row 72 (7-fuzz count is unreal §2, golden fixtures §1; row cites §6 alone). 0 WRONG.
C1-C7: all quoted corpus positions verified verbatim (nooa §3.6 75%+archive+default summarizer + events-grow-linearly; arcee 70% §4/§10; unreal ~200k §7; no-compaction-harnesses §9 quote; Manus masking §1; dsh `ToolHistoryProjection` §5.1; fx §14 1,024-byte/2% budgets; nooa §3.6 sandbox/reference-semantics; concept 5 + synthesis 3; arcee §2/§10 steering counterexample; pi §7/§9; unreal §5 grace windows; prime §3/§9).
All key symbols verified as cited: codec.go, store.go:433-468, itemRecord.Operations, agent.ts:298-391 + interrupted:true, tool_intent+barrier, SessionWriterChanged, inbox.go:24/loop.go:440, loop.go:593-596 FIXME, carryForwardContext, TruncationConfig, PersistentVars, MAX_REPL_BINDING_ITEMS=512 + shed loop, ProviderReplay.matches, weighted_safe_boundary, slurpMaxItems=100/1ms, run_code/`<parent>:ptc:<n>`/maxParallelSubCalls=10 + failure taxonomy, BashHandle.tail()/.output(), `harness.change` zero occurrences in docs/research, code_fingerprint, evolve.py gate, provenance.rs, Meta{tool_schema_hash,model}→checkpoint.mismatch, 52,429-byte delta + 2 ms budgets (fx.md's own wording), 1,648 upstream test programs claim not re-checked (upstream tree), ~2:1 tests, Gemini shadow-git, Codex two-layer safety, gptme, harness emulation, deref receipts §4.4, workset schema, invocation-only approvals.
(Retraction: my earlier draft flagged audit row 70's "52,429-byte delta" as a miswording — fx.md §1 itself says "annotates growth over a 52,429-byte delta"; audit matches its source. Withdrawn.)

**Verdict on the prior evidence audit: its row-level work is accurate to a degree that survives full rechecking (0 WRONG rows); its five imprecisions are citation-span/attribution slips, none changing a grade.**

---

## Part C — implementation claims at the pin

### R14 — feasibility-bend2.md vs pinned toolchain + canonical tree
Language-capability claims: **verified pin-exact.** Base File surface at base.bend:257-294 (open r/w/a, read/read_bytes/read_at/size/write/write_bytes/close); File.sync/rename/stat, JSON, TLS, exec, Unix socket, cancel/race/select/deadline all ABSENT (grep zero); IO.spawn/Chan/IO.fork/IO.join exactly at :211-256; `file_open.c:12` = `return O_WRONLY | O_CREAT | O_APPEND;` verbatim; tcp_connect.c AF_INET only; `bend --help` = check/run/-o/--check-only/--publish/base/guide/update/version, no repl/eval/test/debug/fmt (my probe); GUIDE.md sha256 `9e464364…` matches; WONTFIX #773/:30, #825/:47, #813/:94 and upstream README :222/:231/:237/:246/:248 all exist and match at `source/docs/bend2/reference/upstream/`. Comp.io_run exists at pinned `comp.ts:1362` (doc cites a foreign d2aeefc clone's main.ts:971-990 — the doc flagged this itself).

Size/line claims: **stale — the pin's coordinator grew ~5-11×.** Claimed "4,484 lines of .bend plus 714 of C" describes the foreign KIT checkout; the pinned tree measures **25,258 .bend** lines across the six named dirs (coordinator 18,829 / git 3,959 / host 467 / json 677 / replay 894 / harness 432) **plus 8,059 lines of authored C**, plus an entire unmentioned `context/` subsystem (47 .bend + 2 .c). process-spawn.c is 5,192 lines (doc: 222); harness adapters are `-player.bend` (193 lines + 239 laws; doc: `-worker.bend`, 76); session-lock.c does not exist (session-lock.bend 29 lines + flock inside process-spawn.c:5096, owner lock :2438); canonical.bend 396 (doc 379), uint-decoder 226 (doc 225), replay 894 (doc 911); json1 delegation in turn.bend is real but the cited :197-220 window holds plain SQL; `test/process.bend` does not exist at the pin (no test/ dir) though the @unsafe read-loop characterization is supported elsewhere (agent-native.bend:454-455, turn.bend:694/:717); process.bend:9 is `Retained{handle: U32}` (argv NUL-encoder at :104-107, doc says :27-30).

**Substantive characterization error:** the doc's "five shape rules … stated … in `json/canonical.bend:10-16`" — the pinned header (:11-18) states **three** rules (match-scrutinee; declare-before-use/no-mutual-recursion/one self-recursive def; Data-only constructor fields). The doc's rules 2 (match-in-do), 4 (one-name-per-binding) and 5 (no .c ABI promise, cited to EFFECTS.md) are not in that header. The constraints themselves are plausibly real checker rules (GUIDE/EFFECTS cites not line-audited), but the "stated in canonical.bend:10-16" attribution breaks at the pin.

Consequences: **S2.** The feasibility *verdicts* (language capability; program lane and self-extension not expressible as written; out-of-process lane) stand — every capability claim re-verified. But (a) audit-findings' "size is nearer the reference's 4,484+714" and amendment 6's "measured floor" cite numbers that are wrong for the pin — the pinned reference is far larger (which strengthens the anti-"few thousand lines" conclusion) but is no longer a clean comparable (its growth is orchestrator scope: branching, codex-inbox, agent-*, knowledge, context/, custody); the floor argument must be restated against a named snapshot or a seat-scope subset. (b) `KIT/docs/bend2/language-review.md` and `examples/` (LANG-F/LANG-CAP evidence) are not in the pin — unverifiable here. (c) The toolchain is a **Baton fork** of Bend 2.0.25 (manifest) — the vanilla-upstream pin `a4952426…` is recorded by the review's trial kit, not derivable from this build root; qualify. (d) Corroboration earned: pinned process-spawn.c itself uses AF_UNIX for its control protocol — the C-effect route claim holds.

### R17 — integration-baton.md + integration-knowledge.md re-resolution at the pin (critique-round directives a/b/c)

**(a) `baton2:` citations.** `git cat-file -t 10c2ae6d` fails (verified). All 44 baton2:-cited paths re-derived at b1f006a6: **41 EXISTS-AS-CITED** (most line-exact: architecture.md :25, :67, :69-73, :86-91, :134-137, :138-144, :146-151, :167-170, :175-182, :184-194, :203-209, :211-217, :266-287, :289-311, :365-370; agent-commands.md :7-15, :7-36, :17-20, :67-84, :144-149, :207-217; branching-ensembles.md :3-7, :46-58, :70-77, :82-84, :100-104; branching-model.bend :13/:14/:16-17; native-interactions.md :1-23; terminology.md :47-56; knowledge.bend:186; context/operations.bend:180; context/service.bend:103-168; lang-host-interop.evidence.md :3-6/:98-118/:121-124), **3 EXISTS-BUT-DIFFERS**: architecture.md:234-241 cited for "resume same conversation" is actually the missing-conversation recovery path (the claim is true at :243-244/:273-278/:365-370); branching-ensembles.md:35-38 "ancestor chains rounds" — "ancestor" appears nowhere in that doc (schema-only fact, branching-model.bend:13); branching-model.bend:13 "columns exactly" omits the trailing 19th column `created TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP`. Benign caveats: agent-commands.md spells verbs `baton <verb>` (the `baton2 <db>` form is architecture.md:25); `baton2_ack` appears only in architecture.md:301; the §1 "no repl token except knowledge.bend:186" exception clause is a non-sequitur (that line contains no 'repl') though both facts hold. **Net: the review's orchestrator-plane verdicts transfer to the pin.**

**(b) JS-line (`impl/`) citations.** `1e050e420a99d775d3d2f943453c23535a701fd9` resolves (2026-09-22); `impl/` was deleted from the line at `2b8449af` (2026-10-02, "Use the native coordinator source and contributor entry points"), so **every impl/src citation breaks at the canonical pin's tree and resolves only in history at ≤1e050e42** — the JS line the reviews audit is archived at the pin. Content re-resolution at `1e050e42` (blobs extracted to `evidence-1e050e420/`): verdict-critical subset **transfers exactly** — KNOWLEDGE_NODE_TYPES :191 (19 names), KNOWLEDGE_EDGE_TYPES :193 (14), KNOWLEDGE_GROUNDINGS :195 (4); recallPreview defined coordination-store.mjs:2415 with zero callers; serveKnowledge defined runtime-observation.mjs:2482 + delegated coordinator.mjs:5358-5363 with zero callers; `_knowledgeBriefingProvider = opts… ?? null` runtime-admission.mjs:463, providerBrief returns inner when null runtime-briefing.mjs:119, forwarded only-when-supplied index.mjs:1657, brief.knowledge rendered adapter.mjs:586-596 and set by nothing in-repo; MAX_REPL_BINDING_ITEMS=512 application.mjs:202 (shed loop :707/:714); claimGrant closed to sorted keys `board,boardRunId` application.mjs:7845-7851; repl.manifest/repl.binding `profile:'kernel', surfaces:['embedded']` and repl.cite `profile:'ordinary', surfaces:['embedded','mcp']` application-semantics.mjs:1608-1628; limits.mjs view.knowledge_slice 8 items/2048 bytes (:277-278) and brief.wake_events.items (:369); authorityDigest `{kind:'authenticated-worker-session', principalId, sessionId}` application.mjs:349-353. **The dead-read-path production-caller proof is confirmed at 1e050e42.** docs/NN- citations (33/34/35/49/54/05/08/13/32) are checkable directly at the pin — the canonical docs/ tree carries the full numbered series — and the spot-verified set transfers: docs/54:3 "Status: proposed" (stale-header claim verified), docs/33 :23-25/:50-62/:77-89 (cells/manifest/admission/bindings/fence), docs/34:13 (19/14/groundings), docs/05 "The OS sandbox is the authorization boundary… may only tighten". Residue: ~30 supporting impl/-internal line ranges (coordination-admission 6751-7110, coordination-store 148-152/2404-2617, mcp-northbound 3060-3062, coordination-internals, impl/MCP.md, adapter-contract, cli-adapters, route-tuple, swarm-*) were not individually re-read at 1e050e42 in this pass; scout outputs cover their characterization and no contradiction surfaced.

**(c) `main.bend:182-195`.** Confirmed at the pin: bend2/src/coordinator/main.bend:178-196 is the orchestrator-side knowledge verb dispatch (KnowledgeTraverse/Relate/Read/ReadScope/Relations/Index/Detail/ScopeIndex/ScopeDetail/Promote :194-195/PromoteScoped) — knowledge consumption exists orchestrator-side today.

### R13 (updated) — citation-integrity verdicts
- integration-baton.md pins baton2 at `10c2ae6d` — **does not resolve**; its content nonetheless transfers to b1f006a6 (41/44 exact).
- integration-knowledge.md pins Bend2 at `72fc39b45` — resolves; **ancestor of b1f006a6**; content transfers with two exceptions (below).
- Sibling reviews pin the same Bend2 line at two different SHAs on the same date; both cite machine-local `/Users/wahargis/...` roots. Fix: re-pin to b1f006a6, repo-relative paths.
- **Transfer-break found:** integration-knowledge §2's quoted seat instruction ("…Use Supports, Contradicts, Produced, Informed, DerivedFrom, TestedBy and Supersedes…") exists verbatim at turn.bend:181 **at 72fc39b45** but was shortened at b1f006a6 (:182 now "Use baton knowledge to record and read scoped findings and evidence…" — zero hits for the relation names under bend2/ at the pin). The deployed release orchestrating this orchestra still carries the long vocabulary, so the review's substance describes deployed behavior; the citation breaks at the canonical build pin.
- knowledge-laws.bend drift (the review's own flagged uncertainty): **confirmed at the pin** — :19 schema law omits the `kind` column and promotion kind fields vs knowledge.bend:17-18; :101 calls promotion_admitted with 2 args vs knowledge.bend:306's 3; evidence_ok referenced at :67 and defined nowhere under bend2/src. The review's caution was warranted and is now resolved to confirmed-drift.
- kg-activation census: exists in canonical docs/reference/evidence/kg-activation-2026-07-31/kg-activation-decisions.md — ":5-8 knowledge.promoted ×4 / ZERO elevations / ZERO admitWorkflowFinding uses / ZERO horizon reads" and ":18-34 the graph accrues but nobody reads it" both verbatim. knowledge.js = exactly 1,119 lines. test/knowledge.py:391 exact. agent-native.bend:226-252 exact (one-report evidence selector with distinct refusals). agent-domain.bend:298-305 exact. knowledge.bend: all 13 cited ranges exact.
- commands.bend:860-866: drifted ~34 lines at the pin (record/relate/promote rows at :826-828); all verbs exist.

---

## Evidence-grade summary

- 16 papers, ~60 discrete figures checked at primary full-text level. **MISMATCH: 1** (ALITA-G dedup, S3). **Misattributions in the audited reviews themselves: 4** (audit-evidence GPT-5.4 parenthetical S3; audit-evidence 7.5→4.8 attribution S3; audit-findings Fork-and-Flush inheritance-list attribution S2; feasibility five-vs-three shape-rules attribution S2). **Structural citation findings: 2** (R13 broken/dual pins + machine-local roots; R14 size story stale ~5-11× at the pin). Everything else confirmed with recorded nuances.
- Corpus grade table: 68/73 rows OK, 5 IMPRECISE, 0 WRONG; C1-C7 verbatim-confirmed.
- The seven reviews' headline verdicts all survive independent rechecking: NOOA truncation real; twelve-hour evidence posture-mismatched; +7.7 2024-dated; CLM outcome paper-only; async wall-clock supported by three independent systems (latency-only); decay/monitor numbers accurate; Bend2 capability verdicts (no evaluator, no runtime loader, Base absences, out-of-process lane) pin-exact; orchestrator-plane and knowledge-layer verdicts transfer to the pin; dead-read-path proof confirmed.

## Not independently verified in this pass (explicit gaps)

- Terminal-Bench Challenges/4.0 pages, Anthropic infrastructure-noise page, METR expenditure-horizon post, Chroma report — secondary pages, no discrepancy indication found, left unverified.
- Single-harness corpus reports' repo-line citations (pi b06c1f2c, dsh 5719020, fx 6afa7c33, prime 3e141d1, unreal a5f3fd13, arcee e02ab928, NOOA 3187c6d, CLM 4831982) — not re-cloned (outside probe scope); graded against the corpus docs' own recorded text per the audit's stated convention.
- ~30 supporting impl/-internal line ranges at 1e050e42 (listed in R17(b)) — characterization covered by scouts, no contradiction surfaced, not individually re-read.
- feasibility GUIDE.md/EFFECTS.md per-range cites (checker-rule details) — files exist in pin, ranges not line-audited.
- Timing claims in feasibility probes (60-110 ms lane, 3.0 s/4.2 s builds) — darwin-arm64 probe records, not reproducible on this linux runner; taken as recorded observations.

## Deliverable evidence

- This register: `deliverables/citation-auditor/claim-register.md`.
- Extracted JS-line blobs for the re-resolution: `deliverables/citation-auditor/evidence-1e050e420/impl/src/*.mjs` (from `git show 1e050e420:impl/src/...`).
- Toolchain probe transcript: session log (bend --help, sha256sum, manifest.json read), 2026-10-16.
- Knowledge records: knowledge-record:c7683fc60769548fd8df977e9ec580bd (NOOA), plus records for CLM/SWE-agent/speculative/rot/HARBOR/safety/ALITA-G/ACON clusters, Fork-and-Flush attribution, citation integrity, turn.bend transfer-break, toolchain probe.

---

## Part D — cross-critique round (per-target verdicts on research-critic's findings)

### T1 — PASTE version opposition (critic finding cec0a6f6) — CONFIRM core, REFUTE one clause, QUALIFY one clause
- My R6 checked **v3** (2026-06-16; scout stated "numbers verified on v3"). Primary re-check this round: **v1 (2026-03-19) abstract states 48.5%** ("PASTE reduces average task completion time by 48.5% and improves tool execution throughput by 1.8x"); **v2 abstract states 43.5%** ("reduces average task completion time by 43.5% and lowers observed tool latency by 1.8x"); v3 (which R6 verified) also states 43.5%.
- Verdict: the version discrepancy is **CONFIRMED** — but the critic's "43.5% appears only in v2" is **REFUTED**: v3 also carries 43.5%. Accurate statement: the headline was revised downward from 48.5% (v1) to 43.5% (v2, retained in v3), and the metric was reworded from "tool execution throughput" (v1) to "observed tool latency" (v2/v3). That instability is itself register-worthy.
- 1.8× attribution: **QUALIFY.** v3 §6.3: "the average tool-side speedup is 1.71× over ORION and 1.83× over SpecFaaS" — the abstract's 1.8× is a cross-baseline aggregate, with SpecFaaS (the weaker baseline) contributing the larger, rounded-up factor. "Relative to weaker-baseline SpecFaaS" is half-right.
- No token/success metric: **CONFIRMED** (§6.1 metrics list; §6.8 correctness audit; §6.9 resource overhead).
- Rule: the register **does** need a version pin plus scope caveat. Correction to R6: cite PASTE 43.5%/1.8× as arXiv:2603.18897 **v2/v3**, note v1 said 48.5% (headline moved across versions), keep the serving-layer/latency-only scope caveat. Cost: two clauses.

### T2 — TomasuLLM boundaries (critic finding 80f4579e) — most CONFIRMED, one REFUTED-as-phrased
Verified against arXiv:2609.38201 v2 full text:
- **~2.1 s speculative compute per wall-clock second removed: CONFIRMED** verbatim (§5.4), with fuller accounting: main-agent tokens at parity (8.3M vs 8.2M per task), speculation adds 1.6M drafter tokens, 1,480 drafter GPU-seconds (≈0.9× one Serial Pi session's main-agent GPU budget), sandbox CPU 2,760→4,310 s/task; paper's framing "buys single-session latency rather than throughput-normalized efficiency".
- **Fixed-seed Terminal-Bench draw: CONFIRMED** (§5.1: "sampled at random from its 89 tasks with a fixed seed").
- **7 of 18 SWE-Marathon sessions capped at 6.0 h: CONFIRMED** (§5.1: "on the seven timeout-capped tasks, the 6.0 h entry is the E2B cap rather than a completion time"; Fig. 6 starred matched-progress rows).
- **Authors-own baseline: CONFIRMED** (§4: "Setting chain depth to zero yields Serial Pi…; Serial Pi is the serial baseline throughout Section 5"; PASTE comparison "reimplemented; no open-source artifact is available").
- **Small author-drawn samples: CONFIRMED** (100 sampled SWE-bench Verified; 28 of 89; 18 SWE-Marathon tasks "that fit the CPU-only sandbox").
- **GPU tasks excluded: CONFIRMED** (§5.1: "excluding the benchmark's two GPU-dependent tasks").
- **"No chain beyond four actions": REFUTED as phrased.** Default configuration is "chain depth six, three live candidates" (§5). Accurate form: measured committed chains never exceed four ("no chain commits more than four", §5.3) and the depth sweep "saturates at K=4" (§5.4) — four is the effective committed-chain ceiling, not the configured bound.
- Rule: all confirmed boundaries **enter the register** as scope caveats on R6's TomasuLLM entry; the chain bound enters in the corrected form.

### T3 — Strongest counterexample against the narrowed Q-ASYNC-01 — narrowing survives; one upgrade
Strongest case found (hunt + own reading): **TomasuLLM §5.4's cost accounting** — not merely "token half unmeasured": one adjacent system measured it, adversely (+1.6M drafter tokens/task, 1,480 drafter GPU-seconds ≈ 0.9× the main agent's GPU budget, +56% sandbox CPU, 2.1:1 speculative-compute ratio). Why it does not defeat the narrowing: (1) mechanism class differs — those costs are harness-driven-speculation machinery (drafter inference, COW overlays, tracing, recovery), absent from the sketch's model-driven async transcript whose token cost is bounded by transcript growth from early results; (2) the paper scopes the trade as regime-dependent ("single-session latency rather than throughput-normalized efficiency"), not refuting wall-clock gains; (3) bet-1's falsification condition concerns turn structure, which none of the three papers measures. Secondary cautions already registered: PASTE headline 48.5→43.5 across versions; Speculative Actions' environments are not coding agents.
**Verdict: the narrowed position stands. Register upgrade: token half is "unmeasured with one measured adverse prior in the adjacent harness-driven posture (2.1:1 speculative-compute ratio)".**

### T4 — Minimal seed-sensitivity reporting rule for the register
1. Every point estimate records seed count, per-seed spread (min–max or SD), and the aggregation rule (median vs mean).
2. Every claimed delta states whether seeds are paired across arms; unpaired deltas report between-seed variance, paired deltas report per-seed differences.
3. A delta whose seed-level CI includes zero is recorded as "within seed noise", never as a direction.
4. Seed values recorded verbatim (provenance); single-seed figures may appear only as provisional, never as register headlines.
5. Task-sampling seeds (e.g., TomasuLLM's fixed-seed 28-of-89 draw) count as seeds: record draw rule and task count.
Awaiting research-critic's final numbers at deliverables/research-critic/probes/seed-variance/; will grade them against this rule on receipt.

---

## Part E — T4 grading close-out (critic numbers vs the five seed-rule clauses)

Per-target grades filed as knowledge records (T4 grade 5aefbef4 / a0500338 / b996a49f / dc02ea8f / 87343990 / 06245f64 / bb018e8e / 37385d10 / a3af80ed / 16922d3b / 7e494efb+392be786 / reciprocal audit). Summary: **12/12 PASS on discipline**; three flags, one new primary-confirmed correction.

- **5aefbef4** — PASS with flag: "about 500 tasks at 3 trials" for a 10-point MDE reproduces **unpaired** variance while the record declares ρ=0.5 pairing (consistent paired figure ≈105 tasks); "158 at 1 trial" and "1,758 at 3 points" reproduce the paired model exactly.
- **a0500338** — PASS, primary-confirmed: seed creation/join/embedding verified by me in `native-initial-input.bend` at `b1f006a6` (`lower(hex(randomblob(64)))`, coalesce retry-join, seed prepended to instruction hex payload).
- **b996a49f** — PASS; its WebGL correction **primary-confirmed**: the Terminal-Bench Challenges page attributes 96.4%/20.5% WebGL coverage to **Devin with Fable 5**; `research-open-questions.md:196-198` misattributes them to Claude Code + Opus 4.8 (which the page credits for the Rust-compiler and codegolf challenges). Fix = split the attribution.
- **87343990** — PASS: 28/36 geometric-fit cells and the 16-step horizon match my scout's full-text reads; LOCA-bench "first public platform" phrase NOT FOUND matches my scout's abstract quote (research-open-questions' superlative is editorial).
- **392be786** — PASS with one open reconciliation: round-D comparator "baseline 15/89" vs research-open-questions/my scout's "best 17/89" — reconcile against Table II before either enters a headline.
- **Supersedes audit**: 6f98ed93 and 35d58d15 both justified — each matches my independent T1/T2 resolutions (v1=48.5%, v2/v3=43.5%; configured K=6 vs committed ≤4).
- **Scrutiny points**: MDE 0.5-correlation declared (see the 5aefbef4 flag); NOOA summarizer label correct as paper-silent vs code-verified-at-clone-HEAD (nooa.md §7 already holds it); Probe-3 resolution documented in critic NOTES.md Correction 1 (slope units) — read by me; version-less PASTE citation defective (T1 correction stands); depth conflation resolved by 35d58d15; Harbor-Index power: single-rollout/no-CI/no-seed ⇒ paired 1-trial MDE ≈14 points at 82 tasks.

**Figures that must leave a headline (or carry the named caveat):**
1. PASTE 43.5%/1.8× without the version pin (v2/v3; v1 said 48.5%).
2. "No chain beyond four actions" (configured K=6; four is the committed/saturation ceiling).
3. Harbor-Index 28.0% / 82-task suite as a measurement default without the single-rollout power caveat.
4. 5aefbef4's "500 tasks at 3 trials" (unpaired arithmetic inside a paired-assumption record).
5. HARBOR round-D comparator (17-vs-15) until reconciled against Table II.
6. WebGL 96.4%/20.5% attributed to Claude Code + Opus 4.8 (belongs to Devin with Fable 5).
