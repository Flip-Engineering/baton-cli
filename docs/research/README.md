# Research

Research reports informing baton-cli's design: a minimal Bend2 agent harness for the baton
orchestrator (possibly renamed Orchestra). Authored October 2026 by GLM 5.3 Flash subagents;
single-harness reports are grounded in code-level analysis of shallow clones at recorded HEAD
commits, and the benchmark figures come from primary sources. Start with
[synthesis.md](synthesis.md).

| Report | Subject | Lines |
| --- | --- | --- |
| [pi.md](pi.md) | Pi (pi-mono, Mario Zechner): package boundaries, event-tree sessions, tool loop, pi-durable | 208 |
| [deepseek-harness.md](deepseek-harness.md) | DeepSeek Harness (`dsh`): plugin seams, runtime modes, PTC, session log, sandbox, approvals | 231 |
| [fx.md](fx.md) | fx (Vercel Labs): single-binary Zig harness, fenced session log, tool streaming, subagents, ACP | 272 |
| [prime-agent.md](prime-agent.md) | Prime Agent (Prime Intellect): RLM context-as-variable kernel, recursive subagents, continual harness | 150 |
| [minimal-harness-survey.md](minimal-harness-survey.md) | 15 further minimal harnesses (mini-SWE-agent, Aider, goose, opencode, Codex CLI, and others) | 255 |
| [benchmarks.md](benchmarks.md) | Agent-harness benchmarks: same-model harness variance, ablations, time horizons | 208 |
| [synthesis.md](synthesis.md) | Evaluation of the harness-engineering approaches and how their architectures achieve them | 210 |

Method notes: single-harness reports cite repo-relative file paths from the cloned source
(HEAD sha recorded per report); survey and benchmark claims link primary sources; uncertainties
are marked in each report's open-questions section.
