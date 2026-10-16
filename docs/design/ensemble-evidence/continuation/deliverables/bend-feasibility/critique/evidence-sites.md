# evidence-sites.md — fifth-harness gate inventory at b1f006a6

Every site below was read first-hand this round (bend2/src/coordinator/*,
canonical commit b1f006a6308bbb00e29a24322e4f7d5164774470).

## A. SQL sites carrying the closed list `harness IN ('codex','omp','muse','claude-code')`

| # | Site | Function |
|---|---|---|
| 1 | control.bend:125 | `receiver_admitted` — receiver endpoint admission |
| 2 | control.bend:198 | `start_admission` — session-start admission |
| 3 | control.bend:281 | `turn_admission_sql` — turn/dispatch admission; refusal at :286-287 |
| 4 | delivery.bend:20 | `native_receiver_sql` — native receiver eligibility for delivery |
| 5 | commands.bend:196 | `blocked_cause_sql` — 'harness-unsupported' cause in session projection |
| 6 | commands.bend:301 | `configure_admitted` — configure verb gate |
| 7 | instance.bend:58 | `supported_sql` — legacy direct-attempt support check |
| 8 | stop.bend:58 | `dirty_session_sql` — delivery sweep 'serve' vs 'refuse' |

## B. Laws pinning the generated SQL as literal strings (must be edited in lockstep or the law check fails)

| # | Site | Pins |
|---|---|---|
| 9 | control-laws.bend (receiver admission law, ~:104-115) | `receiver_admitted` exact SQL |
| 10 | control-laws.bend:36-48 (`principal_startup_checks_assignment_and_operator_scope`) | `start_admission` exact SQL |
| 11 | control-laws.bend:106 (`detached_turn_requires_a_recruited_active_supported_player`) | `turn_admission_sql` exact SQL |
| 12 | control-laws.bend:415 (`inadmissible_detached_turn_refuses_launch`) | the turn-refusal string, byte-exact |

## C. Bend-side predicates (not SQL)

| # | Site | Form |
|---|---|---|
| 13 | control.bend:177 (`configure_endpoint`) | `Bool.or` chain of four `String.eq` |
| 14 | turn.bend:1519 (`player_checked` → `supported_harness`) | `Bool.or` chain of four `String.eq(harness,"…\n")` |
| 15 | turn.bend:1001-1008 (`launch`) | nested `Bool.pick` on harness equality; **claude is the fall-through default** — a fifth harness added after the fallback silently launches Claude |

## D. Harness string comparisons that are feature flags, not gates

20 occurrences of `String.eq(harness,"omp\n")` in turn.bend (lines 245, 261,
559, 700, 737, 746, 749, 750, 752, 754, 764, 766, 778, 782, 827, 926, 941,
1002, 1077 plus the launch site) + receive.bend + laws.bend: steer/awake
paths, `omp_frame_kind` classification, event-filter handshake,
resume-file lookup. A new harness leaves all of these False, which is
correct; riding `omp` would activate them against a foreign event stream
(mechanism behind D3 agreement).

## E. Player modules (all four read in full)

- claude-player.bend (43 lines), codex-player.bend (40), muse-player.bend
  (20), omp-player.bend (90), harness/laws.bend (239).
- Content: pure defs building argv via `P.argv`;
  `start_player`/`resume_player` = `P.ProcessChild.spawn(argv,cwd,stderr)`;
  `input(handle,text)` = `P.ProcessChild.write` (muse: a `Done{}` stub —
  task delivered by argv `--prompt-file`, stdin unused). JSON is
  string-assembled with `J.string_literal` escaping; no JSON parsing, no
  loops, no state machines in any player module.
- Rough shape of a `bend2-player.bend`: muse-shaped, 20-40 lines; spawn
  the seat binary with task/session by argv; `input` stub or stdin write.

## F. Receipt/settlement machinery (harness-agnostic)

- `agent-command.bend:85-117` `acknowledge_scope`: `NoHandling{}` dies with
  exactly `{"error":"handling-context","condition":"No live recipient-owned
  native read context is available. Select the handled message explicitly
  for an administrative acknowledgement."}`; live scope → `handling_sql`
  (:79-83) with `coalesce(handled, receipt)` — first receipt wins;
  explicit selection generates `handled:<id>`.
- `message-status.bend:7-8`: `message_reads` PRIMARY KEY
  (attempt, identity, message); projection carries delivered/read/handled
  plus a per-attempt attempts array ('recorded'/'incomplete'/'unrecorded').
  A deref receipt has a different lifecycle and needs its own rows
  (F5 conclusion confirmed).
- Settlement is harness-agnostic (keyed on attempt/native/identity
  strings); wake is endpoint-based (`wake.bend` has no harness condition;
  delivery gates at delivery.bend:20).

## G. Knowledge read path foreign-schema evidence

- knowledge.bend:186 (citation synthesis `FROM nodes WHERE substr(evidence,…)`),
  :205/:209 (traverse/search `FROM nodes`/`edges`).
- No `CREATE TABLE` for `nodes`/`edges` anywhere in bend2/src (the only
  retained-tree hit is docs/reference/evidence/…/src_store_migrations.rs:435
  — a digested foreign store).
- baton-contracts' DB copy (orchestra-copy-20261016.db; read-only query this
  round): 24 tables; `SELECT count(*) FROM nodes` → "no such table: nodes".
  knowledge/knowledge_promotions/knowledge_relations exist.
- The write path (knowledge.bend:16-19) creates only the three knowledge*
  tables.

## H. Context managed-query substrate

- Domain.known carries `context` (agent-domain.bend:43); verb surface
  `context engines|install|query|result` (:198, :314).
- context/store.bend:1-10, 89-110: three-table persistent store +
  `managed_artifact_schema` — "The managed runtime binds the verified
  invocation bytes to the exact immutable [artifact]" (sha256 artifact
  identity, association rows, answers).
- context/bound-admission.bend, identity.bend, native-managed-query.bend
  (Bootstrap type with artifact_path/artifact_sha256/invocation_sha256/
  owner_witness), service.bend (SubmissionManaged with planIdentity/
  artifactSha256; SubmissionManagedUncertain): content-addressed admission
  with ownership and explicit uncertain-outcome states.
