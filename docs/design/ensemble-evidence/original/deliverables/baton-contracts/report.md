# baton-contracts: Bend2 Baton contract audit (independent round)

## 0. Seed note (brief, as tasked)

The seed is 128 uniform hex digits with no runs, words, or structure: its
qualities are uniformity, opacity, and lack of intrinsic authority — no
sub-string means anything without a decoder, and the string itself authorizes
nothing. I applied the same three qualities as method: one uniform verification
bar for proposal claims and prior-audit claims alike (recheck, don't copy);
treat every claim as opaque until decoded against pinned source; and treat
unprovenanced strings — including authoritative-sounding ones — as carrying no
authority until lineage is shown. That last point turned out to be the audit's
load-bearing theme: several proposal mechanisms are strings without a
counterpart in the pinned source.

## 1. Verdict: which assumed primitives exist at the pin

Pin: canonical source commit `b1f006a6308bbb00e29a24322e4f7d5164774470`
(paths below as `bend2/src/coordinator/*` unless noted). Live Baton 2.0 `help`
probes agree in every row marked LiveOK.

| Proposal-assumed primitive | Status at pin | Evidence |
|---|---|---|
| dispatch (admit input + wake recipient) | SHIPPED, route-gated | `agent-domain.bend:291`; `agent-native.bend:353`; `commands.bend:442-445`; LiveOK |
| inbox (pending bodies, read preserves receipts) | SHIPPED | `commands.bend:696,976`; `agent-commands.md:17-20`; LiveOK |
| acknowledge (handling receipts) | SHIPPED, narrower than assumed | `agent-command.bend:85-117`; `agent-actions.bend:374`; LiveOK |
| report / ask / send / guide | SHIPPED | `agent-actions.bend:225-258`; `commands.bend:447,560-562`; LiveOK |
| completion request + confirm (finish/confirm) | SHIPPED | `agent-command.bend:203-269`; `agent-commands.md:67-84`; LiveOK |
| knowledge record / read / search / traverse / relations / promote | SHIPPED against the SQLite seat store, NOT Cairn | `knowledge.bend:16-19,77-110,191-234,300-339`; LiveOK (`help knowledge`) |
| receiver (register endpoint) | SHIPPED for 4 harnesses | `commands.bend:613`; `agent-domain.bend:276`; LiveOK |
| join / recruit | SHIPPED | `recruit.bend:47-86`; `agent-domain.bend:292-293`; LiveOK |
| land (fast-forward w/ checks) | SHIPPED | `land.bend`; `agent-domain.bend:295`; LiveOK |
| roles / ensembles / sections + coupling | SHIPPED | `commands.bend:27-32,73-75,428-430,469-498`; LiveOK |
| recovery (resume/stop/recover-observer/continue-task) | SHIPPED | `commands.bend:594-609,707-762`; receive recovery input |
| branching (rounds, evaluate, select, continue) | SHIPPED as workspace-only Fork-and-Flush | `branching-model.bend:13-17`; `branching-ensembles.md:60-90` |
| cells / manifests / bindings / `repl.cite` / fences | ABSENT — proposed extension | no `repl.`/cell/manifest/binding symbols in `bend2/src`; no such tables in live DB copy |
| grants / caveats / attenuation / revocation / claimGrant | ABSENT — proposed extension | only effect-grant internals in `context/codec.bend`; unrelated |
| KG search/traversal as the proposal means it (Cairn-backed) | SHIPPED form, WRONG store — treat as proposed dependency | search/traverse exist over SQLite authored-kind rows, no grounding/admit gate |
| Bend2 REPL work the sketch depends on | ABSENT — proposed dependency | no evaluator/loader verbs in `Domain.known` (`agent-domain.bend:43`) |

Net: every seat-side verb the sketch's §§1/4 needs exists; everything in §8
past a version-pinned read does not exist on this line. The prior audit's
"orchestrator plane describes surface that does not exist" is CONFIRMED at the
newer pin, with one wording drift (seat knowledge prompt is now
`turn.bend:180-188`, same prompt-only obligation).

## 2. Findings (severity-ranked)

### F1 (High): fifth-harness turn gate — a baton-cli seat cannot be driven today
- Evidence: `control.bend:281` admits turns only for
  `harness IN ('codex','omp','muse','claude-code')` with parent + workspace and
  no stop; refusal `control.bend:286`, law `control-laws.bend:415`. Only four
  player modules exist (`bend2/src/harness/`). `receiver` builds endpoints for
  registered Codex/OMP/Muse sessions (architecture.md); Claude needs Node.
- Reproducible failure (source-derived, NOT executed live — live dispatch
  would mutate the shared DB, which is forbidden): recruit a Player with
  `harness='baton-cli'`, then turn/dispatch → `IO.die` with "Dispatch requires
  an active recruited Player with a supported harness and recorded workspace".
- Correction: the design must name a fifth-harness coordinator change (player
  module + turn-gate row + receiver path + wake path) with an owner, or ride an
  existing harness identity (wrong — poisons route identity and observed
  fields). This is the largest hidden cost in the sketch's §5.
- Alternative hypothesis considered: harness string is free text at recruit
  (`recruit.bend`), so registration succeeds — rejected as sufficient, because
  the gate is at turn time (fail-late boundary; worth its own test).

### F2 (High): no seat-side commit lane — §8's "commit cells at turn boundaries" has no verb
- Evidence: `Domain.known` (`agent-domain.bend:43`) contains no cell/manifest/
  binding/commit verb; live DB copy has no `repl*`/`cell*` tables; §8's
  `worker:<seat>` layers and `repl:<scope>:<name>@<version>` grammar exist only
  on the JS line per prior evidence (preserved, not re-audited).
- Correction: restate §8 as (a) reachable now: nothing to commit through —
  seat emits reports/evidence refs, orchestrator derives; (b) proposed:
  worker-scoped admission verb + tables + lease rule, owned by the coordinator
  lane. Milestone 4 cannot start before (b) lands.
- Strongest case for the proposal (steelman, preserved): commit-and-cite is
  still the one unoccupied slot in the corpus map; the correction is about
  ownership and sequencing, not value.

### F3 (High): grant plane is proposal over a nonexistent mechanism
- Evidence: §1 grep results in `evidence.md` (this round, at `b1f006a`).
  No caveats, derivation lineage, subtree revocation, persistability, or any
  deref grant anywhere in `bend2/src` or the live schema.
- Correction: §8 grants become "claimGrant-or-equivalent, proposed, owner
  needed"; the seat-side rule until then is attenuation-by-absence (child
  holds no authority it was not given, enforced at the effect boundary and by
  the OS — consistent with `feasibility-bend2.md`'s forgeability result).

### F4 (Medium): knowledge store identity — the reachable store is SQLite, not Cairn
- Evidence: `knowledge.bend` (authored kinds/relations, four scopes,
  destination-owner + source-carry promotion, prompt-only seat obligation).
  No closed kinds, no grounding set, no admit gate, no `ReadBy`/`VerifiedBy`
  minting on this line.
- Correction: §11's "standing store is the orchestrator's knowledge layer"
  must name the SQLite store with its actual guarantees, plus the pollution
  rules that survive the translation (never write Contradicts/Supersedes from
  a seat; settlement-time emission only; untrusted framing on read). KG
  search/traversal are shipped verbs over a weaker store — cite them as the
  read path, not as the Cairn-backed dependency the sketch implies.

### F5 (Medium): acknowledge is recipient-owned and turn-scoped, not general
- Evidence: `agent-command.bend:85-117`; standalone use requires explicit
  message selection; first receipt wins.
- Correction: the seat's "read the tail" obligation must go through inbox +
  turn settlement or explicit acknowledge; cross-seat "mark read" has no
  primitive. Any §8 deref-receipt design must mint its own receipt rows rather
  than reuse message receipts.

### F6 (Medium): dispatch is route-gated (confirmed, closes an alternative)
- Evidence: `agent-native.bend:353` maps dispatch onto the message action;
  `commands.bend:442-445` gates all message admission on `message_route`.
  A worker cannot dispatch/steer outside parent/conductor/tight-peer/operator
  routes; denied routes store nothing and wake nobody.
- Correction: §4's "orchestrator inbox" tool and any seat-to-seat steering
  must declare the route they travel; tests must cover `message-route-denied`.

### F7 (Low): fork triple has no counterpart; branch record is workspace+inputs
- Evidence: `branching-model.bend:13-17`; selection rules
  (`branching-ensembles.md`); resume reuses the same conversation
  (architecture.md:234-241 area). No log-prefix copy, no version vector
  anywhere. Live DB copy has no `branch_*` tables (lazily ensured).
- Correction: §7's triple is a proposal to extend `branch_rounds`; until then
  the seat's fork-relevant surface is: workspace snapshot + complete task
  inputs + selected findings + native config, fresh conversation.

## 3. Concrete contract tests (runnable against a scratch DB)

1. `recruit --session t1 ... --harness baton-cli` succeeds; subsequent turn
   refuses with the exact `control.bend:286` string. Pins F1.
2. `dispatch --to` across a non-route (two loose-coupled peers, different
   parents) returns `message-route-denied` and stores nothing (`commands.bend:444`).
3. `dispatch --to` parent->child wakes the child's endpoint; `task-input-read`
   returns the complete text (dispatch stores complete input).
4. Double `acknowledge` with different receipts keeps the first
   (`commands.bend:334`); `acknowledge` with no owned read context and no IDs
   returns the `handling-context` refusal (`agent-command.bend:88`).
5. `finish` on a parentless session returns the structured refusal;
   `confirm` with two pending requests requires disambiguation
   (`agent-commands.md:67-84`).
6. `knowledge promote` by a non-owner of the destination refuses
   (`knowledge.bend:306-339`); legal promote is idempotent and emits the owner
   `question` notice.
7. `branch select` with a tied top score refuses and requires an explicit
   `--player` decision (selection rules).
8. `land` without the owned workspace / selected checks refuses
   (`agent-domain.bend:295` "selected-check requirements").
9. Bare `knowledge` read as an unregistered session refuses
   (`knowledge.bend:107` area, reader-must-be-registered).
10. Unknown verb `repl.cite` / `cell.commit` parses to `Invalid` (no such
    `Domain.known` member) — pins F2/F3 as absence tests so a future
    implementation flips them deliberately.

## 4. Costs

- Fifth harness (F1): one player module + turn-gate edit + receiver/wake path
  + rollout to existing DBs; plus a harness-identity decision (route tuples,
  observed fields). Owner: coordinator lane.
- Seat-side commit lane (F2): new tables/verbs/admission/lease rules; the
  fence/cache-invalidation story must be designed, not assumed.
- Grant plane (F3): green-field authority design; do not let seat work block
  on it — ship the report/evidence-ref path first.
- Knowledge hardening (F4): receipted, bounded, version-pinned reads; growth/
  retention answer for the SQLite store (currently unstated — see dissent).

## 5. Unresolved dissent (kept, not smoothed)

- D1: SQLite knowledge-store growth/retention is unbounded and pruned by
  nothing (by analogy with the cited Cairn finding; not yet proven against
  `knowledge.bend` — needs a `laws`/docs answer).
- D2: Whether per-turn seat knowledge writes should be forbidden by mechanism
  or by discipline; I hold mechanism (admit gate), the sketch implies
  discipline.
- D3: Whether a Bend2 seat should ride `omp` harness identity as a bootstrap.
  I hold no: it falsifies route identity, observed fields, and steer semantics
  (OMP-only `steer`); a bootstrap should be explicit and labeled.
- D4: The JS-line half of the prior audit (Cairn counts, `impl/` citations)
  is preserved evidence, not re-verified here — a JS-line worker should
  countersign before amendments 1-2 of `audit-findings.md` are executed.

## 6. Relation to the prior audit

`audit-findings.md` verdict (mechanical core survives; program lane,
self-extension loader, orchestrator plane, and fork do not survive as
written) is UPHELD at the newer pin for all contract-surface items, with
exact line-number drift noted in `evidence.md`. Its amendment plan items
1,2,7,8,13,18 are the ones this specialty confirms; item 9 (`harness.change`)
is additionally confirmed absent (no such event in `bend2/src`). No prior
verdict was copied without a fresh grep or probe — see `evidence.md`.
