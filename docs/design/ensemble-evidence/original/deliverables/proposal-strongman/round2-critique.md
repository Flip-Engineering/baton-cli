# Round 2 critique (proposal-strongman, vs new evidence, no restatement of round 1)

Seed `148d3ea5…3142f`: 128 hex chars (64 bytes), all 16 digits present (counts 5-15), no runs or words. Same reading as round 1: uniform, fragmented, content-free, collision-resistant, provenance-carrying but semantically empty. Method unchanged: preserve verbatim, decode claims only against the pin, treat unprovenanced strings as carrying no authority.

## A. Revision drift — confirmed first-hand, verdict strengthened, citation corrected

- `git cat-file -t 10c2ae6d` in SRC: "Not a valid object name". No `impl/` tree at b1f006a6 (top level: AGENTS.md, CLAUDE.md, bend2, docs, reviews, spec). Zero `repl.` hits anywhere under `bend2/`. Section 8 re-derived: no seat-side commit lane exists in this checkout, full stop.
- Round-1 verdict does not change in substance; it gets stronger and its citation changes. My round-1 finding cited "1e050e4 and 10c2ae6d" borrowed from the audit without rechecking — that citation is withdrawn. Replacement evidence: b1f006a6 first-hand greps (no `repl.` in `bend2/`; `Domain.known` per baton-contracts has no cell/manifest/binding/commit verb; live-schema absence per baton-contracts F2/F3). The honest statement is no longer "JS line only" (itself a claim about a checkout not under review) but: absent on the target line, JS claims marked inherited/unverifiable here.
- One correction to design-lead in return: "cites checkouts that do not exist" overstates for the baton commit — `git cat-file -t 1e050e420` in SRC returns `commit`. The object exists; what is absent is the `impl/` tree at the pin and the 10c2ae6d object plus the author-local paths. Conclusion (unknown relative revision) stands; wording should be exact.

## B. Closed harness set — confirmed, position (b)

Confirmed at all four gates: `receiver_admitted` (control.bend:125), `start_admission` (:198), `turn_admission_sql` (:281), `native_receiver_sql` (delivery.bend:20) each require `harness IN ('codex','omp','muse','claude-code')`; `recruit.bend:47-86` stores harness as free text with no gate (fail-late). Only four player modules ship (`bend2/src/harness/{omp,codex,claude,muse}-player.bend`).
Position: (b) — add `harness/bend2-player.bend`, extend the admission sets and settlement (`message-status.bend`), with a named owner in the coordinator lane. Strongest case: riding `omp` identity falsifies route identity, observed fields and OMP-only `steer` semantics (baton-contracts D3, concurred); the omp `--mode rpc` wire shape contradicts requirement 2; the change is small and named while a seat that cannot receive a turn is the largest hidden cost. Falsification: a shim speaking `omp-player.bend` RPC passes turn admission, settlement, wake and route accountability with zero coordinator edits on a scratch DB — then (a) wins.

## C. Section 8 stays, reduced to dependency + interface + experiment

Keep design-lead's revised §8 dependency statement and reachable order; trim one thing: the `context/` "cell" hits are a different mechanism (managed-query JSON array cells, operations.bend:180), never cite them as substrate. Reduced form: (1) absent-on-this-line statement with #778 owner; (2) reachable first step only — version-pinned read, bounded render with untrusted framing, per-read receipt minted as its own rows (baton-contracts F5: never reuse message receipts); (3) seat-side commit admission and every grant/caveat/tree/fence as named proposal, not mechanism. Removing §8 entirely forfeits the unoccupied slot and the E1 ladder; keeping it as description ships fiction.

## D. Attack: the uncapped-and-silent tail of position 1

Positions 2 (compaction trigger) and 3 (target the Bend2 line) are the stronger two — direct corpus measurements behind 2, and SRC containing only the Bend2 line behind 3. The weakest is position 1's tail: "a task with no parameters runs uncapped, residual risk accepted." Requirement 5 forbids ambient caps, not failure handling: Prime parks durably on provider quota and resumes (prime-agent.md §9) — a behavior, not a cap — and reporting provider-quota state as a ledger fact plus durable park/resume closes the redteam burn-silently mode halfway while staying req-5-compatible. "Runs uncapped" stays; "burns silently" should go. Corroborating note: uncapped runs are also incomparable as measurements (tau-bench cap sensitivity cuts both ways).

## Wrong-or-overstated claim in design-lead review

The "checkouts that do not exist" framing (section 1), per the 1e050e420 correction above. Closest runner-up I checked instead of asserting: the knowledge-laws drift follow-up actually understates — first-hand, `knowledge-laws.bend` M1 law pins the schema without `kind`/`source_kind`/`destination_kind` while `knowledge.bend` ships them, and line 67 references `K.evidence_ok`, which has no definition anywhere under `bend2/src/`. The law file would fail its own gate, which is stronger than drift.

## Probes retained (deliverables/proposal-strongman/probes/)

- `trivial.bend`, `timings.txt`: check-only 0.324 s, run 0.350 s on linux x64 — corroborates C5 (darwin 60-110 ms constants are platform-bound).
- `extlaw.bend`, `hostprog.bend`, `lawgate.txt`: open law → `--check-only` refuses "Error: 1 TODO found.", rc=1 — law gate real.
- `bend --help`: no repl/eval/test/debug/fmt; `bend version` = 2.0.25 (also advertises 2.0.37 — do not update the pinned toolchain).
