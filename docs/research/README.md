# Research

Research reports informing baton-cli's design: a minimal Bend2 agent harness for the baton
orchestrator (possibly renamed Orchestra). Authored October 2026 by GLM 5.3 Flash subagents;
single-harness reports are grounded in code-level analysis of shallow clones at recorded HEAD
commits, and the benchmark figures come from primary sources. Start with
[synthesis.md](synthesis.md). The synthesis carried into a design direction:
[../design/design-sketch.md](../design/design-sketch.md).

| Report | Subject | Lines |
| --- | --- | --- |
| [pi.md](pi.md) | Pi (pi-mono, Mario Zechner): package boundaries, event-tree sessions, tool loop, pi-durable | 208 |
| [deepseek-harness.md](deepseek-harness.md) | DeepSeek Harness (`dsh`): plugin seams, runtime modes, PTC, session log, sandbox, approvals | 231 |
| [fx.md](fx.md) | fx (Vercel Labs): single-binary Zig harness, fenced session log, tool streaming, subagents, ACP | 272 |
| [prime-agent.md](prime-agent.md) | Prime Agent (Prime Intellect): RLM context-as-variable kernel, recursive subagents, continual harness | 150 |
| [minimal-harness-survey.md](minimal-harness-survey.md) | 15 further minimal harnesses (mini-SWE-agent, Aider, goose, opencode, Codex CLI, and others) | 255 |
| [nooa.md](nooa.md) | NVIDIA NOOA: agent as a Python object, pass-by-reference context, the no-compaction architecture | 152 |
| [no-compaction-approaches.md](no-compaction-approaches.md) | Published approaches to compaction-free contexts: Manus, Anthropic, Letta, ACE, external memory, mega-context, Folding/ReFold, Cloudflare | 150 |
| [context-language-models.md](context-language-models.md) | Meta Context Language Models: the context as a read-write file, edit-priced with serving-layer Suffix Cache Reuse | 164 |
| [unreal-agent.md](unreal-agent.md) | Unreal Agent: async tool-call contract, exactly-once crash recovery over an event-sourced runtime journal | 151 |
| [arcee-nac.md](arcee-nac.md) | Arcee NAC (Slate): tool-less orchestrator, fresh-process worker episodes, structurally compaction-free workers | 350 |
| [no-compaction-harnesses.md](no-compaction-harnesses.md) | Shipping harnesses operating without compaction: Letta, deepagents, Claude Code memory/editing, Manus, Amp, Magentic-One, Mastra | 193 |
| [context-networking.md](context-networking.md) | Evaluation of two posed compositions: native context passing and networked infinite context; idea-population as a fifth posture | 184 |
| [addressing-and-authority.md](addressing-and-authority.md) | Prior art for the addressing + authority primitives: object capabilities, macaroons, Git/Datomic isomorphism, blackboard, Plan 9 | 154 |
| [deref-and-consistency.md](deref-and-consistency.md) | Prior art for deref budgets, passivation consistency (MVCC), and the shared-live-context question; measurement design | 180 |
| [networked-context-program.md](networked-context-program.md) | The consolidated research program: five primitives with candidate designs, the experimental ladder, what baton needs | 141 |
| [benchmarks.md](benchmarks.md) | Agent-harness benchmarks: same-model harness variance, ablations, time horizons | 208 |
| [synthesis.md](synthesis.md) | Evaluation of the harness-engineering approaches and how their architectures achieve them | 210 |

Method notes: single-harness reports cite repo-relative file paths from the cloned source
(HEAD sha recorded per report); survey and benchmark claims link primary sources; uncertainties
are marked in each report's open-questions section.
