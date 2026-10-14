# baton-cli

A minimal agent harness written in Bend2, built for the Bend2 orchestrator (baton; the
orchestrator may be renamed Orchestra). The harness runs one agent seat: it receives tasking,
runs model turns against a small tool set, and reports back through the orchestrator's message
protocol.

## Goal

One seat, one loop: read the assigned task, run a model turn, execute the tool calls the model
requests, append the results to the session, repeat until the task reports completion. The loop,
the tool dispatch, and the session format are written in Bend2.

## Scope

- The turn loop, tool dispatch, and session persistence are written in Bend2.
- The tool set is small: read files, write files, edit files, run shell commands, and read the
  orchestrator inbox.
- The harness speaks the orchestrator's existing CLI protocol (baton2) for task assignment,
  messages, receipts, and completion requests.
- One session maps to one agent seat. The session format records turns, tool calls, and
  tool outputs as discrete events so the orchestrator can resume a seat at any turn boundary.

## Inspirations

Each project below is prior art worth studying for a specific set of decisions. The links are the
canonical repositories.

- [Pi](https://github.com/badlogic/pi-mono) (Mario Zechner) — a minimal coding-agent harness
  decomposed into small packages: a multi-provider model gateway, a stateful agent-loop core, a
  terminal UI, and the CLI that binds them. Study its package boundaries and its small default
  tool set (read, write, edit, shell).
- [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) — separates model
  weights from harness scaffolding and defines the harness as loop, tools, session storage,
  permissions, and security boundaries. Its named runtime modes (standard, programmatic tool
  calls, minimal) are worth studying, especially the minimal mode: a file editor, a shell, and a
  compact system prompt.
- [fx](https://github.com/vercel-labs/fx) (Vercel Labs) — a coding-agent CLI implemented in Zig
  and shipped as a single native binary that streams conversation output into terminal scrollback
  and delegates work to subagents. Study its single-binary footprint, its native tool primitives,
  and its use of the terminal as a plain Unix stream.
- [Prime Agent](https://github.com/PrimeIntellect-ai/prime-agent) (Prime Intellect) — a
  long-horizon harness built around a persistent code kernel: context is a variable the model can
  read and rewrite, subagents spawn programmatically from inside that kernel, and durable agent
  state (memories, skills, prompts) is updated through small evidence-backed edits. Study its
  recursive-subagent model and its continual-session design.

## Open research questions

- What is the minimal tool set that keeps an agent effective on the orchestrator's task profile?
- How should programmatic tool calls (generated code that batches tool operations) compare with
  discrete tool calls on this workload, and where is the crossover?
- What Bend2-native session format records turns, tool calls, and outputs so the orchestrator can
  resume or fork a seat at a turn boundary, and compact a seat's history without losing tasking?
- How should inbox wake delivery and history compaction interact so a degraded session cannot be
  overfilled while it cannot respond? baton#718 and baton#720 document this failure in the
  current codex-based harness: notification delivery continued during a connectivity outage,
  overfilled the session context, and blocked remote compaction; worker status loops amplified
  it.
- What does a minimal permission and sandbox model look like in Bend2, given that all compiler and
  test gates already run remotely on designated build hosts?

## Status

Design phase. No implementation yet. The first milestone is a Bend2 session format and a turn
loop that can complete one orchestrator-assigned task end to end.