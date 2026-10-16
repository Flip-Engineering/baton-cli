# baton-contracts raw evidence (2026-10-16)

Worker: baton-contracts, Ensemble runtime-integration, reporting to runtime-lead.
Assignment: audit Bend2 Baton task dispatch / inbox / receipt / completion /
roles / ensembles / branching / recovery / knowledge / external-seat contracts
at the canonical pin versus the proposal and the prior audit.

## Pinned revisions

- Proposal corpus: `/run/baton2-native-homelab/retained/baton-cli-orchestra-20261016/baton-cli`,
  commit `5941316491eb01d8794abddc5dcf1798801c4aaf` (verified `git rev-parse HEAD`).
- Canonical source: `.../postrelease-751-761-20261015-9/source`,
  commit `b1f006a6308bbb00e29a24322e4f7d5164774470` (verified `git rev-parse HEAD`;
  message "build: pin the compiler with Bun small heap"). Newer than the checkout
  the prior audit cited (`10c2ae6d`), so every prior claim below was rechecked,
  not copied.
- Live tool: Baton 2.0 release binary used only for read-only `help` probes and
  a read-only file copy of `orchestra.db`. No live store was mutated, no turn
  was started, no message was sent.

## Source file:line evidence (all paths under canonical `source/`)

- Seat verbs: `bend2/src/coordinator/agent-actions.bend:225-273`
  (`parse_action`/`classify_verb`: inbox, send, report, ask, guide, finish,
  confirm, read, acknowledge, session, player, assignment, completion-request,
  completion-confirmed). Bare `report`/`ask` route to Domain with `--text`
  (`:318-329`); unknown seat verbs fall through to Domain when `Domain.known`
  (`:309-316`).
- Domain verb universe: `bend2/src/coordinator/agent-domain.bend:43`
  (`known`: session player players assignment completion-request
  completion-confirmed guide acknowledge status pending orchestra role ensemble
  ensemble-member section section-member attempt attempts outbox receiver
  configure resume stop force-stop recover-observer continue-task turn receive
  profile-bind connect bind report ask native-reply dispatch recruit join
  worktree land push remote-tip knowledge project context models observed-usage
  logs). No `repl`, `cell`, `cite`, `commit`, `grant`, `caveat` verb.
- dispatch: help `agent-domain.bend:291` ("Admit the complete input as the
  current actor and wake its recorded recipient. Omitted kind is task.");
  native mapping `agent-native.bend:353`
  (`"dispatch"` -> `["message",id,session,to,kind, text]`, kind defaults `task`);
  auto-id when `--id` omitted (`agent-native.bend:207`); task text + setup
  outcomes retained (`docs/bend2/architecture.md`, "Task dispatches retain
  their complete text and setup outcomes in the database").
- Message admission + route gate: `commands.bend:428-445` (`message_route`:
  parent-child either direction, conductor-descendant, tight peers,
  operator/top-conductor; denied route stores nothing and wakes nobody).
  dispatch maps to the message action, so dispatch is route-gated, not a
  bypass. Refusal strings: `message-route-denied`, `session-stopped`.
- inbox/acknowledge: `agent-command.bend:85-117`
  (`acknowledge_scope` over the current native turn's complete recipient-owned
  reads; explicit selection otherwise; "No live recipient-owned native read
  context" refusal); first receipt preserved (`commands.bend:334`,
  `architecture.md:86-91`); successful completed turn auto-receipts, failed
  turns and unread input stay pending (`docs/bend2/agent-commands.md:17-20`).
  Live `help acknowledge` text matches source verbatim.
- report/completion: `agent-command.bend:203-269`; `agent-commands.md:67-84`
  (finish -> recorded parent; parentless -> structured refusal; `confirm`
  infers the sole current request; `completion-confirmed --request ID --to`
  selects exactly). Live `help completion-request` matches.
- roles/ensembles/sections: `commands.bend:27-32,73-75,469-498`;
  `agent-commands.md:86-109` (loose default; tight permits non-operator peers
  with different parents; peers need equal depth, no ancestor relation).
- Turn/harness gate: `control.bend:281`
  (`turn_admission_sql`: `parent IS NOT NULL AND workspace<>'' AND harness IN
  ('codex','omp','muse','claude-code')` and not stopped); refusal
  `control.bend:286` and law `control-laws.bend:415`. Fifth harness names are
  refused at turn time. recruit itself stores free-text harness
  (`recruit.bend:47-86`) — fail-late boundary.
- Harness players: `bend2/src/harness/{claude,codex,muse,omp}-player.bend`
  (only four). Per-harness wake: OMP native `steer` frames; others get
  instructions via next explicitly started turn (`architecture.md:175-182`).
  receiver builds the native endpoint for a registered Codex/OMP/Muse session;
  Claude uses channel transport requiring Node (`architecture.md`, Conductor
  delivery).
- Branching: `branching-model.bend:13-17` (`branch_rounds` columns:
  id, ensemble, owner, source, ancestor, workspace, branch_count, snapshot,
  task, inputs, knowledge, includes, evaluator, direction, harness, model,
  effort, command; plus candidates/operations/evaluations/selections). No log
  prefix, no harness-state vector. Selection: settled custody, no explicit
  stop, one accepted evaluation, unique best score
  (`docs/bend2/branching-ensembles.md:60-90`, verified live text above).
- Recovery: `commands.bend:594-609,707-762` (resume/stop/force-stop/
  recover-observer); refused native identity -> recovery input with workspace
  Git status + fresh retained attempt (`architecture.md`, receive section);
  failed turn retains unacknowledged input.
- Knowledge: `knowledge.bend:16-19` (tables), `:77-110` (scopes worker/group/
  universal/all), `:191-234` (lexical search + cycle-terminating traversal),
  `:300-339` (promote: destination-owner-only + source-carry + idempotent +
  owner notice as `question` message). Kinds/relations are authored strings
  (`knowledge.bend:380` help). Seat prompt obligation is prompt text only:
  `turn.bend:180-188` (`task_instructions` + `knowledge_instructions`; no
  completion gate). No Cairn/closed-kind/grounding machinery anywhere in
  `bend2/src`.
- REPL/grants absent: `grep -rni` over `bend2/src` for grant/capability/
  macaroon/attenuat returns only `context/codec.bend` effect-grant internals
  (unrelated to authority delegation); only `citation:` string synthesis is
  `knowledge.bend:186`. No `repl.` namespace, cell, manifest, binding,
  claimGrant symbols in `bend2/src`.

## Live read-only probes (installed Baton 2.0, orchestra.db context)

- `help dispatch|inbox|acknowledge|report|knowledge|receiver|join|recruit|
  land|completion-request`: all present; outputs saved in §Live below and
  match source help strings (dispatch/inbox/acknowledge/report/receiver/join/
  recruit/land verified verbatim-compatible).
- Read-only DB copy `orchestra-copy-20261016.db` (cp, no live mutation):
  tables include sessions, messages, message_reads, turns,
  task_input_requests, knowledge, knowledge_promotions, knowledge_relations,
  ensembles, sections, session_roles; **no** `repl*`/`cell*`/`grant*`/
  `branch_*` tables; sessions=11, messages=17. `sessions` DDL carries
  harness/model/effort/native/observed_* /endpoint/workspace/branch/base
  columns. Branch tables are ensured lazily at first branch use.

## Prior-audit recheck (all seven reviews read in full or by section)

- `integration-baton.md` (two lines, fork triple, REPL reachability, grant
  gap, wake landed, 12 unreachable items): all re-verified at `b1f006a`;
  one text drift — seat knowledge prompt is now `turn.bend:180-188` wording,
  same obligation. Its cited base commit differs; conclusions hold.
- `integration-knowledge.md` (two stores, dead read path, promote gates):
  Bend2-side claims re-verified line-for-line above; JS/Cairn side not
  re-audited (out of specialty scope, prior evidence preserved).
- `feasibility-bend2.md` (program lane / self-extension not expressible):
  consistent with contracts findings (no evaluator/loader verbs in
  `Domain.known`; declarative-tools path is the only runtime admission shape).
- `audit-evidence.md`, `critique-redteam.md`, `steelman.md`,
  `research-open-questions.md`: preserved as evidence; agreement/dissent is
  recorded per-item in `report.md`.
