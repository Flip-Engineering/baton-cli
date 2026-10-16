# design-lead final synthesis

Session design-lead, Associate Conductor, Ensemble design-evaluation, under proposal-root
dispatch:6f27d5cf4f0490e581f3139ab608ee5f. Workers: proposal-strongman, failure-evaluation (both
independently reviewed, cross-critiqued, and confirmed).

Reviewed artifact: published design `delivery-published-32f5f921/design-sketch.md`
(SHA-256 `b49ab64a5464ce8f042c2321968a4a40c854c87f5d1dd660a365863a1d51f57a`), with
`ensemble-audit.md`. Pins: baton-cli corpus `5941316491eb01d8794abddc5dcf1798801c4aaf`; canonical
source `b1f006a6308bbb00e29a24322e4f7d5164774470`; Bend2 `2.0.25` (Baton fork); historical JS line
`1e050e42`, retired in `2b8449af`.

## 1. Verdict

The published design is a faithful reconciliation. Every correction I independently derived is
present in substance, and the three substantive disagreements I raised are resolved in the document
rather than papered over. My verdict: **accept the design as the reconciled proposal**, with three
remaining wording/scope items and an explicit unmeasured list (§5, §6). No revision to the
substantive engineering content is required from this lane.

## 2. Accepted corrections, each with the evidence that carries it

| # | Correction | Evidence | Where the design carries it |
|---|---|---|---|
| 1 | The seat is not a protocol peer; it is a native harness driven through `receive` argv, and a Bend2 seat needs a correct adapter plus admission, receiver, wake and settlement changes | `control.bend:125,177,198,281`; `delivery.bend:20`; `recruit.bend:47-86` (recruit stores free-text harness, refusal is late). Verified by me, proposal-strongman, runtime-lead and baton-contracts | §1 |
| 2 | No duration, token or step budget/ceiling may gate admission, continuation, pause, truncation, stop or unfinished work; four legitimate ends exist; silence never settles to `lost` | Operator ruling; `deepseek-harness.md:106,114,116`; `prime-agent.md:45`; `unreal-agent.md:46`; `research-open-questions.md:194-212` | §4, §12 |
| 3 | Socket re-entry is routing, not confinement: a same-UID child keeps ambient authority; enforcement is the OS executor policy and is untested | Spawn family has no sandbox primitives; P2 forgeability; parent-side reasoning | §5, §10 |
| 4 | `host/session-lock.c` does not exist; the lock is declared in `session-lock.bend` and implemented in `process-spawn.c` (`flock` at `:2438`, `:5096`); DB lock `sqlite.c:881` | runtime-lead first, verified by me | §2 |
| 5 | The law gate is red at the pin | `bend bend2/src/coordinator/knowledge-laws.bend --check-only` exits 1; failure-evaluation P1, reproduced by me and evidence-lead | §13 |
| 6 | The shipped knowledge store rewrites relation lineage on a caller-supplied id | `knowledge.bend:288`; `agent-native.bend:215`; statement-level reproduction plus public coordinator reproduction baton#785 | §8, §16 |
| 7 | Base has no deadline-bounded channel wait; the wait mechanism must be named | `Chan.recv` signature; probe exit 124; no select/race | §4 |
| 8 | A declaration digest does not pin executed bytes | failure-evaluation S4 | §6, §16 |
| 9 | Revision history: `1e050e42` and `72fc39b45` resolve and carry `impl/`; `10c2ae6d` does not; the JS line was retired in `2b8449af` | `git cat-file`, `git ls-tree`, `git log --diff-filter=D` | §preamble |

## 3. My independent findings that the design now carries

- **Harness registration is milestone-0.** Without the adapter work there is no turn at all, so it
  precedes the seat. The design states the change set and the coordinator lane's ownership.
- **The seed requirement is satisfied by the coordinator and must be inherited, not re-created.**
  `native-initial-input.bend`: `lower(hex(randomblob(64)))`, reused across retries, instruction
  prepended. The design keeps the required instruction and separates initialization from
  measurement.
- **Program lane and self-extension are out of process / admission-time**, because there is no
  embedded evaluator and no runtime module loader.
- **Fork is three coordinator mechanisms, not a log copy**; the basis triple is a proposed
  extension.
- **Commit-and-cite has no substrate at the pin**; the design reduces it to a dependency on the
  Bend2 REPL/context lane plus a reachable versioned-read experiment.

## 4. Preserved dissent (not consensus)

1. **Hard caps to break a nonsettlement wedge** (`critique-redteam.md:60-64`; failure-evaluation
   S7.2/S7.5; failure-evaluation round-2 Attack-3-A1 per-call deadline): contrary to the operator
   ruling; recorded, never adopted as a prerequisite. The wedge is answered by visibility (pending
   identities, observed states, ages retained in the completion report) plus explicit authorized
   cancellation, and by the shipped `force-stop`/`recover-observer` paths.
2. **The redteam P2 burn-risk**: real; handled by retention and Conductor decision, not by a cap.
   If a stronger guarantee is wanted it must come from operator tasking.
3. **Declaration digests as a safety property**: rejected; content-addressed execution is adopted,
   and the fd-based alternative is explicitly not a demonstrated protection contract (D2).
4. **Numeric byte caps on spill reads** (D7): rejected; declared byte projections with complete
   handles, paging and delivered/omitted-byte receipts instead.
5. **Quiescence weighting**: failure-evaluation weights the wedge higher than the rest of the
   ensemble; the design keeps it visible without a gating layer, which is the widest position both
   sides can hold.

## 5. Remaining substantive items I flag for root (exact, small)

1. **REPL framing.** The operator contract makes Baton features, the compiler and the REPL required
   product components, with the REPL accepting Bend2 source only. §1 calls the Bend2 REPL/context
   work "a named dependency" and §3 says a persistent Bend2 REPL "may later own cross-turn values".
   Amendment: state that the REPL is required product scope owned by the coordinator/REPL lane, and
   that this seat depends on its interface; keep "may later" only for the seat's *use* of it.
2. **JS-hosted loader.** §5 correctly reports that the loader executes exported non-IO definitions as
   a separate process. Amendment: add one clause that this is an execution backend and does not
   establish another REPL source language, so the loader cannot be read as a second front end.
3. **§16 open decisions** should name the confined-child enforcement probes and the fd-versus-CAS
   binding as explicitly unmeasured, which they already are in §5/§6; no further change needed.

## 6. Unmeasured (stated as such in the design; restated here as limits)

Async-versus-blocking token and turn effects; citation hand-off E1; Linux program-lane economics at
realistic program sizes; confined-child enforcement; fd-binding race protection; relation-lineage
fix (proposed); knowledge retrieval and graph growth; provider continuation acceptance on the target
adapters. The public coordinator reproduction of the relation overwrite is now **measured**
(baton#785), not future work.

## 7. Discriminating experiments with observable outcomes

1. **E-HARNESS** — recruit a novel-harness session on a throwaway DB and dispatch: observable
   outcome is the exact refusal and the named code change; success criterion is that a Bend2 adapter
   passes admission, wake and settlement with no unsupported identity launched.
2. **E-LOG** — crash injection at every byte offset of an append: outcome is self-repair to the last
   complete frame with `log.repaired`, never a permanent refusal, and never a duplicated committed
   effect.
3. **E-WAIT** — a `sleep infinity` tool with no cap: outcome is a session that stays observable and
   owned, reports pending identity/state/age to the Conductor, and settles only on real settlement or
   authorized cancellation.
4. **E-AUTHORITY** — from inside a spawned child, write outside the writable roots and spawn a
   process directly; outcome is the OS denial or the observed ambient success, recorded as such.
5. **E-BIND** — admit a declaration, mutate the artifact, invoke: outcome is refusal or execution of
   the admitted bytes, never silent execution of changed bytes.
6. **E-ASYNC** — blocking versus async with batching sweep or one-result-per-turn replay arm,
   symmetric patience, right-censored reporting, commit-latency and reorder logging.
7. **E-GATE** — every law relevant to a contract, including the repaired knowledge law, passes under
   `--check-only` before a feature relying on that contract ships.

## 8. Change map to current Baton/Bend2 (final)

| Design element | Bend2 reality at `b1f006a6` | Class |
|---|---|---|
| Seat integration | closed harness set; recruit fail-late | coordinator change, milestone 0 |
| Session log durability | no `File.sync/rename/stat`; `O_APPEND` present | host effect family |
| Operation lifecycle | no seat-side equivalent | seat work |
| Program lane / extension | no embedded evaluator, no runtime loader | out-of-process + admission |
| Fork basis | `branch_rounds` schema + `branching.bend` snapshots; no log copy | proposed extension |
| Versioned context / citations | unimplemented on the Bend2 line | dependency on REPL/context lane |
| Knowledge store | live SQLite store; relation upsert rewrites lineage | hardening proposed |
| Legal gate | red at the pin | repair required for knowledge-contract features |
| Budgets/timeouts | none may gate work | operator ruling, no mechanism |
