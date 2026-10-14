# Minimal Agent Harness Survey: Ecosystem Beyond Pi, DSH, FX, and Prime

This report surveys fifteen agent harnesses outside the four covered by sibling reports in this directory (pi.md, prime-agent.md, fx.md, and the DeepSeek harness dsh report). It covers the nine harnesses named in the task brief (mini-SWE-agent, Aider, goose, OpenCode, OpenHands, OpenAI Codex CLI, Gemini CLI, smolagents, Open Interpreter) plus six more that explicitly market a small core (gptme, Hugging Face Tiny Agents, Sebastian Raschka's mini-coding-agent, OpenAI Swarm, PocketFlow, Charm Crush), and Anthropic's published guidance on building agents. Each project section records language/runtime, core loop shape, tool set size and composition, session persistence, subagent support, context management, and one distinctive design decision. The closing sections compare all of them and analyze which ideas transfer to a Bend2-native minimal harness with asynchronous streaming tool execution, a discrete-event session format, and the existing baton2 CLI protocol.

Every load-bearing claim links to its source. Items I could not verify are marked uncertain or listed as open questions at the end.

## Anthropic's published guidance

Anthropic's engineering post [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) (published Dec 19, 2024, updated 2026) is the most-cited published position on minimal agent construction, and its claims line up with what the minimal harnesses below actually do.

- Definitions: **workflows** orchestrate LLMs and tools through predefined code paths; **agents** are systems where the LLM dynamically directs its own process and tool usage. Agents are "typically just LLMs using tools based on environmental feedback in a loop" ([source](https://www.anthropic.com/engineering/building-effective-agents)).
- Recommendation: find the simplest solution possible and add complexity only when it demonstrably improves outcomes. Start with LLM APIs directly; many patterns need "a few lines of code". Frameworks add abstraction layers that obscure prompts and responses ([source](https://www.anthropic.com/engineering/building-effective-agents)).
- Three implementation principles: maintain simplicity, prioritize transparency by explicitly showing the agent's planning steps, and invest as much effort in the agent-computer interface (ACI) as in human-computer interfaces ([source](https://www.anthropic.com/engineering/building-effective-agents)).
- ACI appendix: keep tool input formats close to text the model has seen in the wild, avoid formats requiring exact line counts or heavy escaping, poka-yoke the arguments (their example: require absolute filepaths after observing model errors with relative paths), and report spending more time optimizing tools than the overall prompt ([source](https://www.anthropic.com/engineering/building-effective-agents)).
- The post also names the composable workflow patterns (prompt chaining, routing, parallelization, orchestrator-workers, evaluator-optimizer) that later harness subagent systems resemble ([source](https://www.anthropic.com/engineering/building-effective-agents)).

## mini-SWE-agent

- Language/runtime: Python; v2 as of late 2025, with v1 preserved on the [v1 branch](https://github.com/SWE-agent/mini-swe-agent/tree/v1). Repo: [SWE-agent/mini-swe-agent](https://github.com/SWE-agent/mini-swe-agent) ("The 100 line AI agent that solves GitHub issues").
- Core loop: prompt the model, parse actions, execute, append, repeat until the model emits the literal finish command `echo COMPLETE_TASK_AND_SUBMIT_FINAL_OUTPUT`; step limit 0 (unlimited), default cost limit 3.0 ([README](https://github.com/SWE-agent/mini-swe-agent), [CLI docs](https://mini-swe-agent.com/latest/usage/mini/)).
- Tool set: one tool, bash. The agent "doesn't even use the tool-calling interface of the LMs"; actions are parsed from triple-backtick blocks, so any model works ([README](https://github.com/SWE-agent/mini-swe-agent), [FAQ](https://mini-swe-agent.com/latest/faq/)).
- Execution model: every action runs via `subprocess.run`; there is no persistent shell session, so actions cannot change directories or export environment variables across steps ([FAQ, "Why no shell session"](https://mini-swe-agent.com/latest/faq/)).
- Session persistence: completely linear history — the trajectory and the messages sent to the model are the same object; `mini` writes the full last-run trajectory as JSON to the global config directory (`last_mini_run.traj.json`) ([README](https://github.com/SWE-agent/mini-swe-agent), [CLI docs](https://mini-swe-agent.com/latest/usage/mini/)).
- Subagents: none documented ([README](https://github.com/SWE-agent/mini-swe-agent)).
- Context management: an observation template truncates command output over 10,000 chars to a 5,000-char head plus 5,000-char tail with an elided-char count ([default config](https://mini-swe-agent.com/latest/usage/mini/)).
- Interaction modes: `confirm` (approve each action), `yolo`, and `human` (user takes over), switchable mid-run with `/c`, `/y`, `/u` or Ctrl+C ([CLI docs](https://mini-swe-agent.com/latest/usage/mini/)).
- Distinctive decision: no persistent shell. The FAQ documents the failure modes this eliminates: flaky termination detection when pasting into a live shell, commands that kill the shell, and interrupts that corrupt subsequent output ([FAQ](https://mini-swe-agent.com/latest/faq/)).
- Reported performance: >74% on SWE-bench Verified with this surface ([README](https://github.com/SWE-agent/mini-swe-agent)).

## Aider

- Language/runtime: Python ([repo](https://github.com/Aider-AI/aider), [site](https://aider.chat)).
- Core loop: chat turns in which the model emits edits in a structured text format that aider parses, applies, and reports on; supports multiple [edit formats](https://aider.chat/docs/git.html) — search/replace blocks, unified diff, and whole-file output (secondary descriptions: [agent-safehouse](https://agent-safehouse.dev/docs/agent-investigations/aider), [deska.dev](https://deska.dev/blog/aider-repo-map-explained)).
- Tool set: no JSON tool schemas in the default flow; the "tool" is the edit format parser plus in-chat commands (`/undo`, `/diff`, `/commit`, `/git`) ([git docs](https://aider.chat/docs/git.html)).
- Session persistence: git-native. Every edit is committed with a descriptive message; pre-existing dirty files are committed first so user work is never mixed with aider edits; a weak model drafts Conventional-Commits messages from diffs plus chat history; `/undo` discards the last change ([git docs](https://aider.chat/docs/git.html)).
- Subagents: no subagent mechanism appears in the documented architecture (observation from the docs surveyed; marked uncertain).
- Context management: the [repo map](https://aider.chat/docs/repomap.html) — tree-sitter parses definitions and references, a symbol-reference graph is ranked with PageRank seeded from the active files, and the top entries render into a token-budgeted elided overview ([repo map docs](https://aider.chat/docs/repomap.html), [initial blog post](https://aider.chat/2023/10/22/repomap.html)).
- Distinctive decision: git as the session substrate — undo, review, and history all ride on commits the harness itself creates ([git docs](https://aider.chat/docs/git.html)).

## goose (Block / Agentic AI Foundation)

- Language/runtime: Rust; desktop app, CLI, and API; moved to the Agentic AI Foundation at the Linux Foundation in April 2026 ([repo](https://github.com/block/goose), [docs banner](https://goose-docs.ai/docs/guides/sessions/session-management)).
- Core loop: a general-purpose agent loop over 15+ model providers, extended through MCP: "Connect to 70+ extensions via the Model Context Protocol open standard" ([README](https://github.com/block/goose)).
- Tool set: few built-ins; capability comes from MCP extensions, with permission gating for tool calls ([README](https://github.com/block/goose)).
- Session persistence: sessions auto-save on exit; desktop and CLI sessions resume interchangeably because all sessions live in the same local database; sessions can be duplicated, deleted, exported and imported as JSON, and resumed via history search ([session management docs](https://goose-docs.ai/docs/guides/sessions/session-management)).
- Subagents: lead/worker mode — a lead model orchestrates and delegates execution to worker models, keeping worker tool noise out of the lead context ([docs guide](https://goose-docs.ai/docs/guides/sessions/smart-context-management/), secondary: [zylos.ai analysis](https://zylos.ai/research/2026-03-31-context-window-management-session-lifecycle-long-running-agents/)).
- Context management: `GOOSE_MAX_CODE_BLOCK_LINES` truncates long command output with full payloads spilled to temp files; `.goosehints` files inject persistent project instructions; `.gooseignore` excludes paths ([environment variables docs](https://github.com/block/goose/blob/main/documentation/docs/guides/environment-variables.md), [goosehints guide](https://dev.to/goose_oss/whats-in-my-goosehints-file-and-why-it-probably-shouldnt-be-3j8p)).
- Distinctive decision: **fork session** — editing a message creates a new session containing history up to that message, exploring a different branch from a turn boundary ([session management docs](https://goose-docs.ai/docs/guides/sessions/session-management)).

## OpenCode

- Language/runtime: TypeScript/Bun; the repo moved to [anomalyco/opencode](https://github.com/anomalyco/opencode); v2 shipped 2025-2026 ([docs](https://opencode.ai/docs/tools/)).
- Core loop: client-server. `opencode serve` runs a headless server exposing an OpenAPI 3.1 spec; the TUI is one client; multiple clients (browser, IDE, SDK scripts) attach to the same server ([server docs](https://opencode.ai/docs/server/), secondary: [architecture writeup](https://medium.com/@falexm/inside-opencode-understanding-the-architecture-behind-the-ai-runtime-01236d9370ff)).
- Tool set: twelve built-ins — bash, edit, write, read, grep, glob, lsp (experimental), apply_patch, skill, webfetch, websearch, question — plus custom tools and MCP servers; grep/glob run on ripgrep ([tools docs](https://opencode.ai/docs/tools/)).
- Session persistence: server-owned sessions with message logs, states, and file modifications; API routes create, list, fork, summarize, revert, and delete sessions ([server docs](https://opencode.ai/docs/server/)).
- Subagents: primary agents (build, plan) with distinct permission defaults, plus subagents (general, explore, scout) that run as foreground or background child sessions with scoped context; custom agents defined in `opencode.jsonc` with prompts, models, and tool restrictions ([agents docs](https://opencode.ai/docs/agents/), [tools docs](https://opencode.ai/docs/tools/)).
- Context management: session summarize over the API; child sessions isolate exploration from the main transcript ([server docs](https://opencode.ai/docs/server/), [agents docs](https://opencode.ai/docs/agents/)).
- Distinctive decision: sessions as an HTTP resource — fork/summarize/revert are documented REST operations on `/session` routes, matching the control-plane pattern baton's orchestrator protocol targets ([server docs](https://opencode.ai/docs/server/)).

## OpenHands (Software Agent SDK)

- Language/runtime: Python; the agent core now lives in [OpenHands/software-agent-sdk](https://github.com/OpenHands/software-agent-sdk); the [OpenHands repo](https://github.com/OpenHands/OpenHands) is "Agent Canvas", a frontend that drives the SDK through its Agent Server ([README](https://github.com/OpenHands/OpenHands)).
- Core loop: the SDK Agent "implements the reasoning-action loop"; a Conversation manages state and lifecycle; the same agent code runs locally (`LocalWorkspace`), in Docker (`DockerWorkspace`), or remote (`RemoteAPIWorkspace`) by swapping the workspace type ([architecture overview](https://docs.openhands.dev/sdk/arch/overview)).
- Tool set: `openhands.tools` ships BashTool, FileEditor, GrepTool, TaskTrackerTool (and more); every tool follows an Action/Observation/Executor pattern ([architecture overview](https://docs.openhands.dev/sdk/arch/overview), [SDK README quickstart](https://github.com/OpenHands/software-agent-sdk/blob/main/README.md)).
- Session persistence: conversations are typed **events** (actions, observations, user messages, state updates) — an event-sourced transcript — and the Agent Server exposes them over REST and WebSocket ([architecture overview](https://docs.openhands.dev/sdk/arch/overview)).
- Subagents: the Agent Server runs multiple agents on one host and clients dispatch to them; a per-loop delegation tool in the new SDK is not verified here (open question) ([architecture overview](https://docs.openhands.dev/sdk/arch/overview)).
- Context management: **Condenser** is a first-class SDK component for conversation-history compression to manage tokens ([architecture overview](https://docs.openhands.dev/sdk/arch/overview)).
- Distinctive decision: components are stateless and immutable (Pydantic typed), with conversation state carried entirely by the event stream ([architecture overview](https://docs.openhands.dev/sdk/arch/overview)).

## OpenAI Codex CLI (codex-rs)

- Language/runtime: Rust ("Lightweight coding agent that runs in your terminal"), Apache-2.0 ([repo](https://github.com/openai/codex)).
- Core loop: turn-based tool-calling loop; built-in tools include `shell`, `apply_patch`, `update_plan`, `view_image`, and `web_search` ([tool descriptions](https://learn.chatgpt.com/docs/config-file/config-advanced), [apply_patch guide](https://developers.openai.com/api/docs/guides/tools-apply-patch)).
- Safety model: two explicit layers — **sandbox mode** (what Codex can technically do: read-only or workspace-write) and **approval policy** (when it must ask). OS-level mechanisms enforce the sandbox; defaults include no network access and writes limited to the active workspace; `.git` inside a writable root is protected read-only ([agent approvals & security docs](https://learn.chatgpt.com/docs/agent-approvals-security.md)).
- Session persistence: every run persists as a **rollout** JSONL file under `~/.codex/sessions/YYYY/MM/DD/rollout-<timestamp>-<thread-id>.jsonl`; resume rebuilds context by parsing the transcript; `codex resume --last`, `--all`, and a `/resume` picker; forking branches a thread into a new lineage without altering the original log ([secondary: verdent.ai guide](https://www.verdent.ai/guides/codex-cli-resume-continue-save-chat), [developer commands docs](https://learn.chatgpt.com/docs/developer-commands)).
- Context management: auto-compaction when token usage crosses thresholds plus manual `/compact`; on compaction the rollout file may be rewritten in place, stripping raw tool output and replacing it with compacted state markers ([secondary: compaction writeup](https://justin3go.com/en/posts/2026/04/09/context-compaction-in-codex-claude-code-and-opencode), [issue #44363](https://github.com/openai/codex/issues/44363)).
- Subagents: not part of the documented stable surface in the pages reviewed (open question; experimental work exists in the repo).
- Distinctive decision: OS-enforced sandboxing plus approval policy as a two-layer, user-visible model, with network access off by default and a domain-allowlist `network_proxy` when enabled ([agent approvals & security docs](https://learn.chatgpt.com/docs/agent-approvals-security.md)).

## Gemini CLI (Google)

- Language/runtime: TypeScript, Apache-2.0; core in `packages/core` ([README](https://github.com/google-gemini/gemini-cli), [tools docs](https://google-gemini.github.io/gemini-cli/docs/tools/)).
- Core loop: the core presents tool schemas to the Gemini API, validates and executes requested tools (with user confirmation for sensitive operations), and returns outputs for the next model call ([tools docs](https://google-gemini.github.io/gemini-cli/docs/tools/)).
- Tool set: file system tools, `run_shell_command`, `web_fetch`, `google_web_search`, `read_many_files`, `save_memory`, plus MCP servers; all tools operate under a sandboxing layer when enabled ([tools docs](https://google-gemini.github.io/gemini-cli/docs/tools/)).
- Session persistence: **checkpointing** writes a git snapshot into a shadow repo at `~/.gemini/history/<project_hash>` before any file-mutating tool runs, together with conversation history and the pending tool call; `/restore` reverts files and conversation to a chosen tool call ([checkpointing docs](https://geminicli.com/docs/cli/checkpointing/)). `/chat save|resume|list|share` stores tagged conversation snapshots under `~/.gemini/tmp/<project_hash>/` ([commands docs](https://google-gemini.github.io/gemini-cli/docs/cli/commands.html)).
- Subagents: yes — custom subagents are Markdown files with YAML frontmatter placed in `.gemini/agents/` or `~/.gemini/agents/`; each subagent runs in its own isolated context window and returns a compressed summary; built-ins include `generalist`, `cli_help`, and `codebase_investigator`; invoked via `@agent` or automatic delegation ([announcement](https://developers.googleblog.com/subagents-have-arrived-in-gemini-cli/), [subagents docs](https://geminicli.com/docs/core/subagents/)).
- Context management: `/compress` replaces chat history with an AI-generated summary; `GEMINI.md` files provide persistent grounding; the CLI advertises a 1M-token context window ([checkpointing docs](https://geminicli.com/docs/cli/checkpointing/), [README](https://github.com/google-gemini/gemini-cli)).
- Distinctive decision: checkpointing at the file level — every approved mutating tool call creates a restorable (files + conversation + tool payload) snapshot ([checkpointing docs](https://geminicli.com/docs/cli/checkpointing/)).

## smolagents (Hugging Face)

- Language/runtime: Python; "the logic for agents fits in ~thousand lines of code" ([docs index](https://huggingface.co/docs/smolagents/index)).
- Core loop: step-based cycle of Thought/Code/Observation; `CodeAgent` writes Python code snippets as actions; `ToolCallingAgent` emits structured JSON tool calls; the run terminates on a `final_answer` call, optionally validated by `final_answer_checks` functions ([guided tour](https://huggingface.co/docs/smolagents/main/en/guided_tour), [building good agents](https://huggingface.co/docs/smolagents/main/en/tutorials/building_good_agents)).
- Tool set: tools are Python functions via the `@tool` decorator; descriptions are baked into the system prompt; base tools include DuckDuckGo search, a Python interpreter, and a transcriber; MCP servers load via `ToolCollection.from_mcp` ([docs index](https://huggingface.co/docs/smolagents/index), [guided tour](https://huggingface.co/docs/smolagents/main/en/guided_tour)).
- Execution safety: generated code runs in an interpreter with an import allowlist (`additional_authorized_imports`) or in sandboxes — Blaxel, E2B, Docker — selected with `executor_type` ([guided tour](https://huggingface.co/docs/smolagents/main/en/guided_tour)).
- Session persistence: memory is the in-process step log (`agent.logs`, `agent.memory`); `agent.write_memory_to_messages()` serializes steps into model-visible messages; the guided tour documents no built-in session database or resume command (marked uncertain for anything beyond that) ([guided tour](https://huggingface.co/docs/smolagents/main/en/guided_tour)).
- Subagents: **managed agents** — a sub-agent is callable "similarly to calling a tool: provide the task description as the 'task' argument", surfaced through the system-prompt template ([building good agents](https://huggingface.co/docs/smolagents/main/en/tutorials/building_good_agents)).
- Context management: optional periodic planning steps (`planning_interval`); variable state persists between code executions inside the interpreter ([building good agents](https://huggingface.co/docs/smolagents/main/en/tutorials/building_good_agents)).
- Distinctive decision: code-as-action with an explicit import allowlist — the tool surface becomes Python functions and the model composes them with real control flow ([guided tour](https://huggingface.co/docs/smolagents/main/en/guided_tour)).

## Open Interpreter

- Language/runtime: Rust (2026); the project restarted as "a coding agent optimized for low-cost models" and "a fork of OpenAI's Codex" ([README](https://github.com/openinterpreter/open-interpreter), [blog announcement, Jul 13 2026](https://www.openinterpreter.com/blog/open-interpreter)).
- Core loop: Codex-derived loop, retargeted to open-weight models such as Kimi K3 and GLM 5.3 ([README](https://github.com/openinterpreter/open-interpreter)).
- Distinctive decision: **harness emulation as a feature** — `/harness` switches the active harness among `native`, `claude-code`, `claude-code-bare`, `zcode`, `kimi-code`, `kimi-cli`, `qwen-code`, `deepseek-tui`, `swe-agent`, and `minimal`; the same runtime reproduces other harnesses' prompt and tool protocols to measure what low-cost models actually need ([README](https://github.com/openinterpreter/open-interpreter)).
- Tool set / sessions / subagents: inherited from the Codex fork baseline; specifics beyond the harness list were not verified here (open question) ([README](https://github.com/openinterpreter/open-interpreter)).
- Integration: speaks [ACP](https://agentclientprotocol.com/get-started/clients) for editor embedding and is "Codex compatible" ([README](https://github.com/openinterpreter/open-interpreter)).

## gptme

- Language/runtime: Python; one of the earliest agent CLIs (initial release March 2023) ([README](https://github.com/gptme/gptme)).
- Core loop: chat loop with tool execution and self-correction; tools are markdown-protocol blocks; confirmations controllable from interactive (`-y` watches and can interrupt) through non-interactive (`-n`, JSONL output) modes ([README](https://github.com/gptme/gptme)).
- Tool set: built-ins per the tools table — shell, ipython, read, save/append, patch/morph, browser, vision, screenshot, rag, gh, tmux, computer, subagent, chats, memory, lessons, todo, mcp ([README tools table](https://github.com/gptme/gptme)).
- Session persistence: conversation logs stored locally, listable and resumable (`-r` resumes the most recent); in-session `/undo`, `/backtrack`, `/compact`, `/tokens`; JSONL machine-readable output for CI ([README](https://github.com/gptme/gptme)).
- Subagents: a `subagent` tool for parallel or isolated tasks, plus a subagent planner mode (v0.30) and background jobs (v0.31) ([README](https://github.com/gptme/gptme)).
- Context management: context compression (v0.30) and `/compact`; a "context-scout pre-pass" (v0.34); token awareness tooling ([README](https://github.com/gptme/gptme)).
- Distinctive decision: **cross-harness memory** — a local Markdown memory store shared by gptme, Claude Code, and Codex via `gptme-util memory`, so learned state survives harness switches ([README](https://github.com/gptme/gptme)).
- Minimality posture: "Trying to stay tiny — minimal core, extend as needed", with [a dedicated page](https://gptme.org/docs/arewetiny.html) tracking core size ([README](https://github.com/gptme/gptme)).

## mini-coding-agent (Sebastian Raschka)

- Language/runtime: Python 3.10+, standard library only; model backend is Ollama; the whole agent is one script, `mini_coding_agent.py` ([README](https://github.com/rasbt/mini-coding-agent), [companion tutorial](https://magazine.sebastianraschka.com/p/components-of-a-coding-agent)).
- Core loop: a readable local agent loop where the model emits either `<tool>...</tool>` or `<final>...</final>` tags; default `--max-steps 6` ([README](https://github.com/rasbt/mini-coding-agent)).
- Tool set: structured named tools with checked inputs, workspace path validation, and approval gates (`ask` / `auto` / `never`) for risky tools ([README](https://github.com/rasbt/mini-coding-agent)).
- Session persistence: full durable transcript plus a smaller distilled **working memory**, saved under `<workspace>/.mini-coding-agent/sessions/`; `--resume latest` or by session id ([README](https://github.com/rasbt/mini-coding-agent)).
- Subagents: bounded delegation — subtasks go to helper agents that inherit limited context and operate within limits ([README](https://github.com/rasbt/mini-coding-agent)).
- Context management: long outputs clipped, repeated reads deduplicated, older transcript entries compressed; a **stable prompt prefix** is kept separate from the changing request so repeated model calls reuse cached static parts ([README](https://github.com/rasbt/mini-coding-agent)).
- Distinctive decision: the six-component decomposition itself (repo context, prompt shape/cache reuse, structured tools/permissions, context reduction, transcripts/memory/resumption, bounded delegation) is presented as the canonical minimal harness anatomy ([companion tutorial](https://magazine.sebastianraschka.com/p/components-of-a-coding-agent)).

## OpenAI Swarm

- Language/runtime: Python; explicitly "experimental, educational"; superseded by the production OpenAI Agents SDK ([README](https://github.com/openai/swarm)).
- Core loop: `client.run()` executes: get a completion from the current Agent, execute tool calls and append results, switch Agent if necessary, update context variables, return when no new function calls remain; stateless between calls, like Chat Completions ([README](https://github.com/openai/swarm)).
- Tool set: plain Python functions auto-converted to JSON Schema from type hints and docstrings; no file or shell tools — it is an orchestration skeleton, not a coding harness ([README](https://github.com/openai/swarm)).
- Session persistence: none — `run()` returns updated messages plus context variables and the caller re-feeds them ([README](https://github.com/openai/swarm)).
- Subagents: **handoffs** — any function can return an `Agent`, transferring the conversation; multi-agent coordination in two primitives (Agent, handoff) ([README](https://github.com/openai/swarm)).
- Context management: `context_variables` dictionary threaded through instructions and functions ([README](https://github.com/openai/swarm)).
- Distinctive decision: agent switching expressed as a function return value, making multi-agent orchestration inspectable as ordinary Python control flow ([README](https://github.com/openai/swarm)).

## PocketFlow

- Language/runtime: Python; "100-line minimalist LLM framework", zero dependencies; ports exist in TypeScript, Java, C++, Go, Rust, and PHP ([README](https://github.com/The-Pocket/PocketFlow)).
- Core loop: not a chat loop — a nested directed graph of Nodes with a `prep`/`exec`/`post` lifecycle and labeled action edges; agents are nodes that decide the next action label until a terminate action ([README](https://github.com/The-Pocket/PocketFlow), [design patterns](https://the-pocket.github.io/PocketFlow/design_pattern/agent.html)).
- Tool set: none — callers write plain utility functions for LLM calls, search, and vector DBs ([README](https://github.com/The-Pocket/PocketFlow)).
- Session persistence: the **shared store**, a dict threaded through nodes; nothing durable is built in ([README](https://github.com/The-Pocket/PocketFlow)).
- Subagents: multi-agent and supervisor patterns built from nested flows (flow-as-node) ([README](https://github.com/The-Pocket/PocketFlow)).
- Context management: whatever the application stores in the shared store ([README](https://github.com/The-Pocket/PocketFlow)).
- Distinctive decision: the 100-line source is the artifact — small enough to paste into a coding agent's context so the agent can extend the framework itself ("agentic coding") ([README](https://github.com/The-Pocket/PocketFlow)).

## Tiny Agents (Hugging Face)

- Language/runtime: JavaScript/TypeScript (`@huggingface/mcp-client`, `@huggingface/tiny-agents` packages) with a Python variant; runnable with `npx @huggingface/mcp-client` ([blog](https://huggingface.co/blog/tiny-agents), [Python variant](https://huggingface.co/blog/python-tiny-agents)).
- Core loop: "an AI agent is fundamentally just a `while` loop running on top of an MCP client" — fetch tool definitions from MCP servers, pass them to the LLM, execute requested tools, repeat — in roughly 50 to 100 lines ([blog](https://huggingface.co/blog/tiny-agents)).
- Tool set: whatever the connected MCP servers expose (the demo bundles a filesystem server and a Playwright browser) ([blog](https://huggingface.co/blog/tiny-agents)).
- Session persistence / subagents / context management: none documented — the point of the project is the minimal loop ([blog](https://huggingface.co/blog/tiny-agents)).
- Distinctive decision: MCP as the entire tool layer; the harness contributes only the loop ([blog](https://huggingface.co/blog/tiny-agents)).

## Crush (Charmbracelet)

- Language/runtime: Go; source-available FSL-1.1-MIT; the codebase continues OpenCode, whose original repository was archived when its maintainer joined Charm; the OpenCode name continued as a community MIT fork ([HN discussion](https://news.ycombinator.com/item?id=45901274), [README license](https://github.com/charmbracelet/crush), secondary: [tomrochette.com summary](https://tomrochette.com/agents/crush/)).
- Core loop: TUI agent over many providers; sessions are per-project with model switching mid-session while preserving context ([README](https://github.com/charmbracelet/crush)).
- Tool set: built-in tools with a permission system (`permissions allow|deny`, `--yolo` to skip prompts), LSP integration for code context, and MCP extension (stdio, http, sse transports) ([README](https://github.com/charmbracelet/crush)).
- Session persistence: state stored under `~/.local/share/crush` (JSON state; a SQLite local database with a dot-file-locking build-tag note); multiple TUI clients can attach to one `crush serve` backend and share the session list, message history, and permission queue through workspaces keyed by cwd ([README](https://github.com/charmbracelet/crush)).
- Subagents: none documented in the README reviewed (open question).
- Context management: `AGENTS.md` global and project context files, `.crushignore`, Agent Skills discovery ([README](https://github.com/charmbracelet/crush)).
- Distinctive decision: configuration is a Bash script (`crushrc` with builtins like `provider add`, `permissions allow`), executable identically on every platform including Windows ([README](https://github.com/charmbracelet/crush)).

## Comparison table

| Project | Language | Loop shape | Built-in tools | Session persistence | Subagents | Context management |
|---|---|---|---|---|---|---|
| mini-SWE-agent | Python | linear; parse backticks, `subprocess.run`, append | 1 (bash, no tool-calling API) | trajectory JSON, linear history | none | output head/tail truncation (10k) |
| Aider | Python | chat; parse edit format, apply, commit | edit-format parser + git commands | git commits, `/undo` | none documented | tree-sitter + PageRank repo map |
| goose | Rust | agent loop over providers + MCP extensions | few built-in; 70+ MCP extensions | local database, resume, export/import JSON | lead/worker delegation | truncation to temp files, `.goosehints` |
| OpenCode | TS/Bun | client-server loop over OpenAPI | 12 built-ins + MCP + custom | server-owned sessions; fork/summarize/revert API | primary + child-session subagents | summarize op; child sessions |
| OpenHands SDK | Python | reasoning-action loop over typed events | Bash/FileEditor/Grep/TaskTracker (Action/Observation/Executor) | typed event stream; REST/WebSocket server | multi-agent via Agent Server (per-loop delegation unverified) | Condenser compression component |
| Codex CLI | Rust | turn-based tool-calling loop | shell, apply_patch, update_plan, view_image, web_search | rollout JSONL; resume; fork; in-place compaction rewrite | none in stable docs | auto-compaction + `/compact` |
| Gemini CLI | TypeScript | core-managed tool-calling loop | ~6 built-ins + MCP | shadow-git checkpoints + `/chat` save/resume | Markdown-defined subagents, isolated context | `/compress` summary; GEMINI.md |
| smolagents | Python | Thought/Code/Observation steps; `final_answer` | @tool functions; base toolbox; MCP | in-process step log; serialize to messages | managed agents callable like tools | planning steps; import allowlist interpreter |
| Open Interpreter | Rust | Codex-derived loop for open models | Codex baseline | Codex baseline (unverified) | not verified | per-harness prompt/tool protocol |
| gptme | Python | chat loop, protocol-block tools | ~18 built-ins incl. subagent, tmux | JSONL logs; resume; `/undo`/`/backtrack` | `subagent` tool; planner mode | `/compact`; context-scout pre-pass |
| mini-coding-agent | Python (stdlib) | tag-protocol loop (`<tool>`/`<final>`), max 6 steps | structured named tools + approval gates | full transcript + distilled memory; resume by id | bounded delegation | clip, dedupe reads, compress old turns; stable prefix |
| Swarm | Python | completion → tools → handoff → repeat | none (functions only) | none; stateless between calls | handoff by returning an Agent | `context_variables` dict |
| PocketFlow | Python | graph nodes with prep/exec/post | none (DIY utilities) | shared store dict | nested flows (multi-agent, supervisor) | shared store only |
| Tiny Agents (HF) | JS/TS + Python | while loop over MCP client | all from MCP servers | none | none | none |

## What transfers to a Bend2-native minimal harness

**Tool set — the floor is bash; the practical surface is a dozen.** mini-SWE-agent ships one tool (bash, parsed from backticks, no tool-calling API) and still scores >74% on SWE-bench Verified ([README](https://github.com/SWE-agent/mini-swe-agent)). OpenCode's twelve built-ins (read, write, edit, bash, grep, glob, webfetch, apply_patch, skill, question, lsp, websearch) are nearly identical to the tool set baton plans (read/write/edit/shell plus the orchestrator inbox) ([tools docs](https://opencode.ai/docs/tools/)). Both endpoints of the spectrum support a minimal fixed tool set; the orchestrator-inbox tool that baton adds is the differentiator, and no surveyed harness treats the orchestrator as a tool surface — it is the closest thing to an open design slot.

**The loop is everywhere the same three statements.** Every surveyed harness reduces to Anthropic's definition — model, tools, environmental feedback, loop ([Anthropic](https://www.anthropic.com/engineering/building-effective-agents)). The two variants worth copying for Bend2: mini's finding that a completely linear history (trajectory equals messages) is the simplest correct session shape ([FAQ](https://mini-swe-agent.com/latest/faq/)), and smolagents' demonstration that tool descriptions should be baked into the prompt mechanically from tool metadata ([guided tour](https://huggingface.co/docs/smolagents/main/en/guided_tour)).

**Session format: append-only JSONL is the dominant on-disk choice.** Codex writes one event per line (user prompts, model responses, tool invocations, outputs, token counts) and rebuilds state by replay ([secondary source](https://www.verdent.ai/guides/codex-cli-resume-continue-save-chat)); OpenHands conversations are typed event streams ([arch overview](https://docs.openhands.dev/sdk/arch/overview)); gptme logs JSONL ([README](https://github.com/gptme/gptme)). This validates baton's plan to record turns, tool calls, and tool outputs as discrete events. OpenHands' typed event taxonomy (action / observation / user message / state update) is a tested naming scheme for exactly those event kinds ([arch overview](https://docs.openhands.dev/sdk/arch/overview)).

**Resume and fork at turn boundaries are proven product surfaces.** Two major harnesses ship fork-at-a-point as a first-class operation: goose's fork session (new session with history up to an edited message) ([session docs](https://goose-docs.ai/docs/guides/sessions/session-management)) and OpenCode's documented `/session` fork/summarize/revert routes ([server docs](https://opencode.ai/docs/server/)), with Codex adding thread forking ([developer commands](https://learn.chatgpt.com/docs/developer-commands)). A Bend2 orchestrator resuming or forking a seat at turn boundaries is implementing, at the protocol level, something the ecosystem already validates at the product level.

**Prompt-cache-aware session design.** Raschka's harness splits a stable prompt prefix from the changing request explicitly to reuse cached prompt parts ([README](https://github.com/rasbt/mini-coding-agent)), and smolagents bakes tool descriptions into the system prompt once ([guided tour](https://huggingface.co/docs/smolagents/main/en/guided_tour)). A Bend2 session format should therefore keep the stable prefix (system prompt, tool schemas, repo context) as its own append-once section, so per-turn events never reorder the prefix.

**Subagents = isolated child sessions returning summaries.** Gemini CLI's subagents each get their own context window and return "a clean, concise summary" ([announcement](https://developers.googleblog.com/subagents-have-arrived-in-gemini-cli/)); OpenCode's subagents are child sessions with scoped context ([agents docs](https://opencode.ai/docs/agents/)); goose's lead/worker keeps worker noise out of the lead ([context guide](https://goose-docs.ai/docs/guides/sessions/smart-context-management/)). For baton, a subagent seat is a session entry with its own event stream plus a completion receipt into the parent's inbox — the receipt shape baton's protocol already defines.

**Observation bounding at the tool boundary.** mini's observation template (10k char cutoff, head+tail) ([usage docs](https://mini-swe-agent.com/latest/usage/mini/)) and goose's truncation-with-temp-file-spill ([env vars docs](https://github.com/block/goose/blob/main/documentation/docs/guides/environment-variables.md)) both bound observation size deterministically, before any summarization. That is the cheapest context-management layer and belongs in Bend2's tool executors, not in the model loop.

**Compaction as an explicit operation on the event store.** OpenHands makes Condenser a named SDK component ([arch overview](https://docs.openhands.dev/sdk/arch/overview)); Codex and Gemini CLI expose `/compact` and `/compress` ([compaction writeup](https://justin3go.com/en/posts/2026/04/09/context-compaction-in-codex-claude-code-and-opencode), [checkpointing docs](https://geminicli.com/docs/cli/checkpointing/)). With baton's event-sourced sessions, compaction can emit a `summary` event and only alter the prompt view, leaving the event log intact — the property that makes resume and fork cheap.

**ACI discipline for the edit tool.** Anthropic's appendix (absolute paths, formats close to natural text, no line-count arithmetic in the format, poka-yoke) ([Anthropic](https://www.anthropic.com/engineering/building-effective-agents)) plus Aider's fuzzy-matching self-correction loop for edit formats ([secondary](https://agent-safehouse.dev/docs/agent-investigations/aider)) apply directly to baton's edit tool design.

## What does not transfer

- **`subprocess.run` per action.** mini's stateless execution model exists to make sandboxing trivial and to dodge shell-termination detection ([FAQ](https://mini-swe-agent.com/latest/faq/)). Bend2's async streaming tool execution and the orchestrator's need to stream tool output live are incompatible with one-shot per-action processes; the shell must be a stateful, streamable tool. mini's FAQ nonetheless documents real shell-management hazards worth engineering around.
- **Edit-format parsing as the primary write path.** Aider's search/replace and diff formats are a model-compatibility layer with its own failure modes ([secondary](https://agent-safehouse.dev/docs/agent-investigations/aider)); harnesses with structured tools (OpenCode edit, Codex apply_patch) push format handling into a validated tool. Baton's edit tool should be a validated tool with Anthropic-style poka-yoke arguments.
- **Framework-shaped orchestration.** PocketFlow's graph primitives and Swarm's handoff-object pattern put orchestration in code paths ([PocketFlow README](https://github.com/The-Pocket/PocketFlow), [Swarm README](https://github.com/openai/swarm)); baton's orchestrator drives seats through messages, tasking, receipts, and completion requests, which OpenCode's session API and Gemini's subagent model show is viable as message-shaped control.
- **Interactive confirm/yolo REPL modes.** mini's confirm/yolo/human modes assume a human attached to the loop ([CLI docs](https://mini-swe-agent.com/latest/usage/mini/)). The baton orchestrator runs seats asynchronously; safety has to be expressed as protocol-level properties (sandbox policy, receipts) in the style of Codex's two-layer sandbox+approvals model ([security docs](https://learn.chatgpt.com/docs/agent-approvals-security.md)), as prompt-time configuration at seat start, or both.
- **Harness emulation.** Open Interpreter's `/harness` switching is a compatibility and research tool for measuring what low-cost models need ([README](https://github.com/openinterpreter/open-interpreter)); it is instructive as evidence that harness prompt/tool protocol choices measurably affect weak-model performance, and as a measurement method to borrow when tuning Bend2 for cheap models.
- **Zero-dependency purism as a goal.** PocketFlow optimizes for pasting its source into a model ([README](https://github.com/The-Pocket/PocketFlow)); a Bend2 harness gains nothing from that constraint, though the underlying lesson — the whole core should fit in one reviewable context — matches why baton wants a minimal core at all.

## Core architectural concepts

The surveyed harnesses converge on six concepts. Each is stated as the pattern it names, with the code paths and sources above that ground it.

1. **The constant minimal loop.** Every harness, from mini-SWE-agent's ~100-line agent class to Tiny Agents' while-loop over an MCP client to Codex's turn-based core, is the same three statements — call the model, execute the tool requests, feed observations back — which is exactly Anthropic's published definition of an agent. The concept this shapes: harness code is a thin envelope; capability lives in the prompt and the tool surface, and anything the model cannot express through that surface does not belong in the loop.
2. **Append-only event log as the session.** Codex rollout JSONL, OpenHands typed events, gptme JSONL logs, and mini's trajectory-equals-messages invariant all record turns, tool calls, and outputs as discrete appended events. The concept: the session is the transcript. Prompt construction, resume, and the UI are functions of the log, never parallel state, which is what makes resume correct by construction.
3. **Fork, summarize, and compaction as prefix operations.** goose's fork-session, OpenCode's fork/summarize/revert `/session` routes, Codex thread forking, and compaction that rewrites a rollout in place all mutate sessions only at defined boundaries of the event log; rasbt's stable prompt prefix shows the prompt-side consequence of keeping that prefix append-once. The concept: turn boundaries are the only safe mutation points, so every session operation is expressible as a prefix cut or a suffix replace.
4. **Subagent = child session plus summary receipt.** Gemini CLI subagents, OpenCode child sessions, goose lead/worker, and smolagents managed agents all give the child an isolated event stream and hand the parent a compressed result. The concept: delegation is a context-capital transfer — the child's transcript stays invisible to the parent, so parallel exploration costs the parent one summary, not one token stream.
5. **Context control in two layers: bound at the tool boundary, compact at the session boundary.** mini's head/tail observation template and goose's truncate-and-spill are deterministic and per-observation; OpenHands Condenser and the `/compact`/`/compress` commands are LLM-mediated and per-session. The concept: cheap deterministic bounding runs first at the tool executor, LLM summarization runs second over the event log, and neither consults hidden state.
6. **Safety as policy layers over a small tool surface, with rollback on the same substrate as persistence.** Codex expresses sandbox mode plus approval policy around a fixed tool set with the network off by default; aider and Gemini CLI make undo (git commits, shadow-git checkpoints) ride on the same store as history; mini exposes the policy as interaction modes. The concept: restricting the tool list is not the safety mechanism — policy around execution and reversible persistence is, which lets the tool surface stay minimal.

For the Bend2 harness this is the coherence argument in one line: a minimal loop over a small validated tool set, an append-only event store where fork/compact/subagent are prefix operations, and safety expressed as policy layers — each concept reinforces the others, and the baton orchestrator's tasking/messages/receipts protocol is the message-shaped version of concept 4.

## Open questions and uncertainties

- Codex CLI: whether the stable codex-rs surface includes any multi-agent mechanism; the pages reviewed document sandbox, approvals, tools, and sessions only.
- OpenHands: whether the new SDK retains the old CodeAct delegation action (delegate to browsing/readonly agents); the current architecture pages document multi-agent at the Agent Server layer.
- smolagents: durable session persistence beyond the in-process step log; the guided tour documents serialization to messages but no session store.
- Aider: chat-history storage details beyond git commits were not verified in the pages read.
- Open Interpreter: tool set, session storage, and subagent status of the current Rust core beyond its Codex fork claim.
- All line-count claims ("100 lines", "~1000 lines", "50-100 lines") are the projects' own descriptions of their cores at the cited pages, re-checked October 2026 against the linked sources.

## Sources

- mini-SWE-agent: https://github.com/SWE-agent/mini-swe-agent · https://mini-swe-agent.com/latest/faq/ · https://mini-swe-agent.com/latest/usage/mini/
- Aider: https://aider.chat/docs/git.html · https://aider.chat/docs/repomap.html · https://aider.chat/2023/10/22/repomap.html · https://agent-safehouse.dev/docs/agent-investigations/aider · https://deska.dev/blog/aider-repo-map-explained
- goose: https://github.com/block/goose · https://goose-docs.ai/docs/guides/sessions/session-management · https://goose-docs.ai/docs/guides/sessions/smart-context-management/ · https://github.com/block/goose/blob/main/documentation/docs/guides/environment-variables.md · https://dev.to/goose_oss/whats-in-my-goosehints-file-and-why-it-probably-shouldnt-be-3j8p
- OpenCode: https://opencode.ai/docs/server/ · https://opencode.ai/docs/tools/ · https://opencode.ai/docs/agents/ · https://medium.com/@falexm/inside-opencode-understanding-the-architecture-behind-the-ai-runtime-01236d9370ff
- OpenHands: https://github.com/OpenHands/OpenHands · https://github.com/OpenHands/software-agent-sdk/blob/main/README.md · https://docs.openhands.dev/sdk/arch/overview
- Codex CLI: https://github.com/openai/codex · https://learn.chatgpt.com/docs/agent-approvals-security.md · https://learn.chatgpt.com/docs/developer-commands · https://learn.chatgpt.com/docs/config-file/config-advanced · https://developers.openai.com/api/docs/guides/tools-apply-patch · https://www.verdent.ai/guides/codex-cli-resume-continue-save-chat · https://justin3go.com/en/posts/2026/04/09/context-compaction-in-codex-claude-code-and-opencode · https://github.com/openai/codex/issues/44363
- Gemini CLI: https://github.com/google-gemini/gemini-cli · https://google-gemini.github.io/gemini-cli/docs/tools/ · https://geminicli.com/docs/cli/checkpointing/ · https://google-gemini.github.io/gemini-cli/docs/cli/commands.html · https://developers.googleblog.com/subagents-have-arrived-in-gemini-cli/ · https://geminicli.com/docs/core/subagents/
- smolagents: https://huggingface.co/docs/smolagents/index · https://huggingface.co/docs/smolagents/main/en/guided_tour · https://huggingface.co/docs/smolagents/main/en/tutorials/building_good_agents
- Open Interpreter: https://github.com/openinterpreter/open-interpreter · https://www.openinterpreter.com/blog/open-interpreter
- gptme: https://github.com/gptme/gptme · https://gptme.org/docs/tools.html · https://gptme.org/docs/arewetiny.html
- mini-coding-agent (Raschka): https://github.com/rasbt/mini-coding-agent · https://magazine.sebastianraschka.com/p/components-of-a-coding-agent
- Swarm: https://github.com/openai/swarm
- PocketFlow: https://github.com/The-Pocket/PocketFlow · https://the-pocket.github.io/PocketFlow/
- Tiny Agents (HF): https://huggingface.co/blog/tiny-agents · https://huggingface.co/blog/python-tiny-agents
- Crush: https://github.com/charmbracelet/crush · https://news.ycombinator.com/item?id=45901274 · https://tomrochette.com/agents/crush/
- Anthropic: https://www.anthropic.com/engineering/building-effective-agents
