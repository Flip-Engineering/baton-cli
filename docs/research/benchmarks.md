# Agent-Harness Benchmarks: What They Say About Harness Design

## Summary

This report surveys the agent benchmarks that measure harness (scaffold) effects rather than model quality alone: SWE-bench Verified and its siblings, Terminal-Bench 2.x, Aider's polyglot benchmark, METR's time-horizon measurements, mini-SWE-agent, published harness-ablation studies on a fixed model, and tau-bench/tau2-bench. The consistent finding is that the agent loop around a fixed model moves measured scores by 5 to 20+ points on the same benchmark: on SWE-bench Verified, a bash-only 100-line loop scores within single-digit points of vendor scaffolds on current frontier models (mini-SWE-agent 64.9% vs Anthropic's bash+edit scaffold 72.4% on Claude Sonnet 4, both single-attempt), while interface-quality details (edit affordances, guardrails, output summarization) account for several points each in controlled ablations. Terminal-Bench 2.0 shows the same pattern on terminal tasks (GPT-5.4-mini: 37.8% on Terminus 2 vs 57.8% on Codex CLI). The report closes with evidence-backed guidance for baton-cli (a minimal Bend2 harness for the Bend2 orchestrator): keep the toolset at shell plus one reliable edit mechanism, make step/time limits explicit harness parameters, record sessions as discrete events, and treat streaming/async tool execution as an unvalidated design bet with indirect supporting evidence.

Numbers below were captured on 2026-10-14; leaderboards change. Where a claim rests on a leaderboard snapshot, the source is the leaderboard data itself.

## SWE-bench Verified and related benchmarks

### What it measures

SWE-bench [1] contains 2,294 real GitHub issues from 12 Python repositories; each task gives the agent a repository checkout before the fix and grades the agent's patch against the hidden unit tests from the human pull request. SWE-bench Verified [2] is a 500-instance subset human-validated with OpenAI (clear problem statements, correct test patches, solvable tasks). Related splits: SWE-bench Lite (300 instances, used for ablations), Multilingual (300 instances, 42 repositories, 9 languages), Multimodal (480 instances) [3]. The metric is % Resolved (pass@1). DeepSWE (May 2026) audits SWE-bench Pro's verifiers at 8% false positives and 24% false negatives and reports Pro tasks average 120 reference lines changed vs 10 for Verified, indicating the harder siblings trade verification reliability for scope [4].

### Harness sensitivity

The official Verified leaderboard [5] tags each entry with the models used and an attempt count ("Attempts - 1" or "Attempts - 2+"). Same-model, single-attempt pairs from the leaderboard JSON [5]:

- Claude Sonnet 4 (claude-4-sonnet-20250514): Anthropic's bash+edit-tool scaffold 72.4%; mini-SWE-agent (bash-only) 64.9%. Difference: +7.5 points for the dedicated edit tool.
- Claude Opus 4 (claude-4-opus-20250514): Anthropic's scaffold 73.2%; mini-SWE-agent 67.6%. Difference: +5.6 points.
- Claude Opus 4.5 (claude-opus-4-5-20251101): live-SWE-agent 79.2%; mini-SWE-agent 74.4%. live-SWE-agent is a scaffold-evolved descendant of mini on the same model: +4.8 points [5][6].
- Gemini 3 Pro preview: live-SWE-agent 77.4%; mini-SWE-agent 74.2%. Difference: +3.2 points [5][6].

Anthropic's own ablation, published in the Claude 3.7 Sonnet announcement [7]: with a minimal single-session scaffold (bash tool + string-replacement edit tool), Claude 3.7 Sonnet scores 63.7% on the n=489 solvable Verified subset; adding parallel sampling, rejection of patches that break visible regression tests, and a scoring-model rerank raises the same model to 70.3%. All of that +6.6 is scaffold: multi-attempt compute, no model change.

Anthropic's engineering post on the 3.5 Sonnet scaffold [8] states the design plainly: a prompt, a Bash tool, and a `str_replace`-based Edit tool with a uniqueness requirement on `old_str`, sampling until the model finishes or hits 200k context. It reports 49% for the upgraded 3.5 Sonnet on that scaffold (vs 33% for the older 3.5 Sonnet on the same scaffold), and states that agent performance "can vary significantly based on this scaffolding, even when using the same underlying AI model."

Cross-scaffold spread on one model is largest when attempt counts are allowed to differ. On Claude 3.7 Sonnet (20250219), Verified leaderboard entries range from mini-SWE-agent 52.8% (Attempts - 1) through SWE-agent 62.4% (Attempts - 2+) to TRAE 75.2% (Attempts - 2+) [5]. Many high-scoring commercial entries list multiple models in their tags (Warp's entry lists Claude Sonnet 4, Gemini 2.5 Pro, GPT-4.1, and Claude 3.7), so leaderboard rank mixes model and harness effects; the strict single-model pairs above are the reliable comparisons.

### Published harness ablations on a fixed model

The SWE-agent paper (NeurIPS 2024) [9] is the cleanest controlled study. All rows use GPT-4 Turbo on SWE-bench Lite, 300 instances:

- Full SWE-agent ACI: 18.0%. Shell-only agent (raw Linux shell interaction): 11.0%. Shell-only without a demonstration: 7.33%. Retrieval-augmented single-shot (RAG): 2.67%. On the full 2,294-instance test set: SWE-agent 12.47% vs prior RAG state of the art 3.8%.
- Editing interface ablations: no dedicated edit action 10.3% (-7.7); edit without linting guardrails 15.0% (-3.0); full editor with linting 18.0%.
- Search interface ablations: summarized search 18.0%; iterative (pager-style) search 12.0% (-6.0, worse than no search tool at 15.7%).
- File viewer window: 100 lines 18.0%; 30 lines 14.3% (-3.7); full file 12.7% (-5.3).
- Context management: last-5-observations truncation 18.0%; full history 15.0% (-3.0); without a demonstration 16.3% (-1.7).

Anthropic's Claude 3.7 ablation [7] (63.7% to 70.3%, same model, test-time-compute scaffolding) is the other published fixed-model pair on Verified.

### Implications for a minimal harness

The loop with a shell is the load-bearing component; everything above it adds single-digit points on current models, and the points are concentrated in a few known places: a reliable edit operation with guardrails (+7.7 for having one at all in 2024; +3.0 for linting in 2024), concise summarized tool output (+6.0 for summarized search vs pager-style), and bounded observation windows (±4-5 points either side of a 100-line window). Multi-attempt and rejection-sampling scaffolds add the largest single jump (+6.6 for Anthropic's 3.7 high-compute configuration), but they change the system's cost and latency profile and make model attribution ambiguous. For baton-cli, the Verified data supports: one shell tool, one string-replacement edit tool with a uniqueness check and an error message on failure, bounded and summarized tool output, and no multi-attempt machinery in the core loop.

## Terminal-Bench and its 2.x evolution

### What it measures

Terminal-Bench (May 2025) evaluates agents on terminal tasks: each task ships a Docker environment, a human-verified solution, and test scripts; agents get one attempt per task with accuracy averaged across runs [10]. Terminal-Bench 2.0 (Nov 2025) is a harder, re-verified 89-task suite distributed through the Harbor framework, with the harness handling container orchestration, logging, and verification [11].

### Harness-aware methodology

Terminal-Bench is explicit that the harness is part of the measurement. Its announcement names three reasons third-party agents (Claude Code, Codex CLI, Goose) are poor scientific instruments: they ask for user approval mid-run, they bind to one vendor's models, and they run inside the environment they are supposed to be measuring [10]. The team built Terminus, a reference agent with exactly one tool, an interactive tmux session: the agent sends keystrokes, can run interactive editors, launch additional shells, and run commands in the background; Terminus runs in a separate process and connects remotely to the container, so agent logic never lives inside the buggy environment [12]. Leaderboard rows are model+agent pairs, and the 2.0 leaderboard reports resolution rate with a ± spread across runs [13].

The 2.x evolution is also integrity-aware. The April 2026 policy update requires ATIF trajectory files for every passing trial, rescores reward-hacked trials to 0, and removes submissions that alter the benchmark; documented cases include an agent that modified task timeouts in a 1.0 submission, an agent with encrypted solutions in its binary, and an agent that uploaded each task's `tests/` folder into its own context [14]. In May 2026, Terminal-Bench 2.1 fixed 28 of the 89 tasks (external dependency drift, resource-budget mismatches, test/instruction misspecification); after the fixes no task is unsolved [15].

### Harness-vs-harness numbers on the same model

From the Terminal-Bench 2.0 leaderboard [13] (resolution rate, ± spread across runs):

- GPT-5.4 mini: Codex CLI 57.8%; Terminus 2 37.8% (both 2.0 values from the 2.1 release chart [15]). A 20-point harness gap on the same model.
- GPT-5.3-Codex: Droid 77.3% ± 2.2; Codex CLI 73.3% (per the 2.1 post's 2.0 values [15]); Terminus 2 64.7% ± 2.7.
- Claude Opus 4.6: Meta-Harness 76.4% ± 2.4; Capy 75.3% ± 2.4; Droid 69.9% ± 2.5; Terminus 2 62.9% ± 2.7; Claude Code 58.0% (2.1 post's 2.0 value [15]).
- Claude Sonnet 4.6: Claude Code 51.9%; Terminus 2 48.0% [15].
- GPT-5.5: NexAU-AHE 84.7% ± 2.1; Codex CLI 82.2% ± 2.2; clnkr 66.1% ± 2.5.
- Gemini 3 Pro: Ante 69.4% ± 2.1; SageAgent 65.2% ± 2.1; II-Agent 61.8% ± 2.8.

The reference harness (Terminus 2) sits below specialized harnesses on the same models by 8-14 points at the top and by 20 points on a small model. The task-fix release shifted scores by up to 12 points for a fixed agent+model pair (Opus 4.6 + Claude Code: 58.0% to 70.1% on 2.1) [15], a reminder that benchmark-side changes move scores as much as harness-side changes.

### Implications for a minimal harness

Terminal-Bench's design decisions validate three baton-cli directions: a reference harness with a single terminal tool is a legitimate measurement instrument (Terminus scores competitively); the harness should run outside the environment it drives and connect remotely (Terminus's independent process, Harbor's remote containers); and sessions should be recorded as inspectable trajectory events sufficient for post-hoc judging (ATIF requirement). The tmux design also shows the value of one interactive tool over many narrow tools: keystroke-level access to a terminal lets the model run background jobs, interactive programs, and extra shells without the harness defining a tool for each.

## Aider's polyglot benchmark

### What it measures

Aider's polyglot benchmark [16] runs 225 hard Exercism exercises across C++, Go, Java, JavaScript, Python, and Rust (selected as the exercises that at most 3 of 7 frontier models solved in a calibration pass). It measures pass@1 instruction-following code editing through aider's own harness, which prompts the model for edits in a specific format and parses the response.

### Harness sensitivity

The harness is the experimental variable by design: the leaderboard [17] records, per entry, the edit format the harness used and the "percent using correct edit format" (the share of responses the harness could parse). Format adherence ranges from 64.4% to 100% across entries and tracks the score. Same-model pairs from the leaderboard:

- Qwen2.5-Coder-32B-Instruct: 16.4% in `whole` edit format vs 8.0% in `diff` format (via a different inference provider; provider and format change together).
- QwQ-32B: 20.9% in `diff` (67.6% format adherence) vs 26.2% in `architect` mode, where a second model (Qwen 2.5 Coder) writes the edits (100% format adherence).
- chatgpt-4o-latest (2025-03-29): 45.3% with `diff` despite only 64.4% format adherence, the clearest case of format failures suppressing a score.
- claude-opus-4-20250514: 72.0% with 32k thinking tokens vs 70.7% without, same model and format [17].

The calibration table in the benchmark announcement [16] also documents that difficulty filtering (excluding 258 of 697 exercises solvable by all 7 models) was needed to keep the metric informative.

### Implications for a minimal harness

A harness that parses model output into actions owns part of the score: when the harness's expected output format fights the model's habits, up to a third of responses can fail to parse (chatgpt-4o case above). Two readings for baton-cli: first, native tool-calling or a highly conventional output convention (fenced shell commands) reduces format losses relative to bespoke text formats; mini-SWE-agent's v1-to-v2 move from parsing actions out of fenced strings to native tool calling is the same lesson [18]. Second, any edit format the harness prescribes must match what the model was trained to emit; measuring "format adherence" separately from task success is cheap and diagnostic, and baton-cli's session log should record it.

## METR time horizons

### What it measures

METR's time horizon is the task duration (measured by human expert completion time) at which an agent succeeds with a given probability [19]. The task suite (HCAST 97 tasks, RE-Bench 7, SWAA 66) is auto-scored; humans with ~5 years of experience baseline the tasks; agents run 8 times per task; a logistic fit over human-time-vs-success yields the 50% and 80% horizons [19].

### Headline numbers

From the original paper (v4 revision) [19]: the 50% time horizon has doubled every ~207 days since 2019 (95% CI 166-240 days); the 80% horizon doubles at the same rate but sits 4-6x lower; GPT-2 sits at 2 seconds, o3 at 110 minutes. The replicated trend on SWE-bench Verified has a doubling time near 70 days vs 143 days on METR's own suite, attributed to how Verified's human-time estimates operationalize task length [19]. The TH1.1 data release (Jan 2026) gives per-model point estimates [20], in minutes: Claude 3.5 Sonnet (Oct 2024) 20.5; Claude 3.7 Sonnet 60.4; Claude Opus 4 100.4; Gemini 3 Pro 224.3; Claude Opus 4.5 293.0; GPT-5.3-Codex 349.5; Claude Opus 4.6 718.8. The stitched doubling estimate is 187.8 days, and 128.7 days for models from 2023 on [20].

### How scaffolding shifts the metric

METR treats scaffold choice as part of the methodology, not a constant. The time-horizons page documents that for each model METR runs elicitation on a dev set and "choose[s] an appropriate scaffold (ReAct, Triframe, Claude Code, Codex, etc.)" with tweaks for spurious failures before the scored runs [21]. The raw TH1.1 data shows the split: most models run under METR's ReAct scaffold, while GPT-5.3-Codex and Gemini 3.1 Pro run under Triframe, which generates three plan-following and three free candidate actions, scores all six, and executes the top pick [20][22]. The paper's appendix states that "properly eliciting models can make a very large difference in their performance," that the two most-elaborated models (o1, original Claude 3.5 Sonnet) each received 2-3 engineer-weeks of scaffold iteration while all others used the same scaffold with minor changes, and that METR's numbers are therefore "a reasonable lower bound" [19]. METR does not publish a controlled scaffold-ablation quantifying how much the horizon moves per scaffold on one model; the elicitation cost (engineer-weeks) is the only published sizing of that variable [19]. METR also finds agents fail more on "messier" tasks (unclear feedback, missing information) at fixed task length [19].

### Implications for a minimal harness

Time horizons are a property of model+scaffold pairs; a harness evaluation story for baton-cli should name its scaffold alongside model names. The Triframe pattern (propose multiple candidate actions, score, execute one) is published evidence that inference-time selection inside the loop raises capability, at the cost of multiple model calls per step. The elicitation finding cuts against heavy scaffolds: METR improved results most for two models with modest, targeted scaffold work, not with large frameworks.

## mini-SWE-agent

### What it actually claims and scores

mini-SWE-agent (Princeton/Stanford SWE-agent team) claims, verbatim, "What if our agent was 100x simpler, and still worked nearly as well?" and scores ">74% on SWE-bench verified" [18]. The agent class is about 100 lines of Python; v1 has no tools other than bash and does not use the tool-calling API (actions are parsed from fenced blocks); history is strictly linear (trajectory equals the message list); each action runs via a fresh `subprocess.run`, so there is no persistent shell state [18]. The FAQ documents the rationale: no shell session means no ambiguity about command termination, no dead sessions after a bad command, and no interrupted-output corruption [23]. The SWE-bench site notes v1 and v2 are not comparable (v2 uses tool calling; temperature handling differs) [2].

The claim to verify here is the strong version, "most gains come from the loop, not scaffolding." The README argues the weaker, defensible version: modern agentic models need "no fancy dependencies" and a bash-only loop "still worked nearly as well" (its Verified results sit within single-digit points of the best scaffolds on the same models) [18]. The leaderboard data in the SWE-bench section above quantifies the residual gap: +5.6 to +7.5 points for Anthropic's scaffold on Sonnet 4/Opus 4, +3.2 to +4.8 for live-SWE-agent on Opus 4.5/Gemini 3 Pro [5][6].

### Adoption as the standardized harness

The SWE-bench "Bash Only" leaderboard runs every model through mini-SWE-agent "in a minimal bash environment. No tools, no special scaffold structure; just a simple ReAct agent loop," explicitly to make apples-to-apples model comparisons [2]. DeepSWE (May 2026) runs "all models on mini-swe-agent for consistency" and reports GPT-5.5 70% ± 3, Claude Opus 4.7 54% ± 5, Gemini 3.1 Pro 10% ± 3 [4]. SWE-bench's July 2025 news item records mini-SWE-agent at 65% on Verified in 100 lines of Python at launch [3]; the bash-only leaderboard now shows frontier models at 70-77% under it [5]. The mini-SWE-agent README also reports that mini beat Claude Code and Codex as harnesses on the DeepSWE evaluation [18].

### Implications for a minimal harness

mini-SWE-agent is the strongest published existence proof that a minimal harness is within single-digit points of heavy scaffolds on SWE-bench-class tasks, and its stateless per-action execution (`subprocess.run` per step, no shell session) is a deliberately chosen reliability trade: it forfeits working-directory and environment-variable persistence in exchange for sandboxability and crash isolation [18][23]. Its linear-history claim (trajectory equals messages) is directly relevant to baton-cli's session-as-events design: when the session log is the model input, replay, debugging, and fine-tuning all operate on the same artifact [18].

## tau-bench and tau2-bench

### What they measure

tau-bench [24] evaluates tool-agent-user interaction in retail and airline domains: the agent talks to an LLM-simulated user and calls database API tools under a written domain policy; success is binary on the final database state plus required user-facing information. Its signature metric is pass^k: the probability that all k independent trials of a task succeed, averaged over tasks. tau2-bench [25] adds a dual-control telecom domain (modeled as a Dec-POMDP) where the user also acts on the world through tools.

### Harness and loop effects

- Interface mode: with GPT-4-class models, native function calling consistently outperforms text-formatted agent modes, and adding reasoning traces (ReAct vs Act-only) consistently helps; the paper reports direction and figures, with function-calling GPT-4o at 61.2% pass^1 on retail and 35.2% on airline, and pass^8 under 25% on retail [24].
- Prompt content as harness parameter: removing the domain policy from the system prompt drops GPT-4o from 61.2% to 56.8% on retail and from 33.2% to 10.8% on airline [24].
- Step limits: the benchmark's default cap is 30 agent actions; Anthropic's published tau-bench results for Claude 3.7 Sonnet raise the cap to 100 and add a "planning tool" prompt addendum, and state that this scaffold change is what produced the reported scores [26].
- Dual control: tau2-bench measures a ~20-point pass^1 drop when the same agents shift from no-user autonomous mode to dual-control mode; pass^1 on new telecom tasks is 34% (GPT-4.1), 42% (o4-mini), 49% (Claude 3.7 Sonnet) [25]. The paper also reports user-simulator reliability by construction: 16% error rate (6% critical) in telecom vs 40% (12% critical) in retail, showing that harness-side simulator design changes measurement noise [25].

### Implications for a minimal harness

tau-bench's harness variables are exactly the ones baton-cli must pin: tool interface mode (native tool calling), what sits in the system prompt, and action-step budgets. The 30-to-100 step-limit change is documented evidence that a harness limit can move a published score by double digits. The pass^k framing argues for a session format that can be replayed from a fixed initial state k times, which is the same property the orchestrator needs to fork a seat at a turn boundary.

## Synthesis: design guidance for baton-cli

Evidence-backed conclusions, each traceable to a number above:

1. Ship the loop, keep it honest. A bash-only loop is within 3-8 points of the best scaffolds on the same frontier models on SWE-bench Verified (mini vs Anthropic's scaffold: 64.9% vs 72.4% on Sonnet 4, both single-attempt) [5]. Nothing in the surveyed data suggests baton-cli needs subagents, RAG, routers, or MCTS to be useful; those appear as test-time-compute scaffolds (Anthropic's 63.7-to-70.3 jump) whose cost profile belongs in the orchestrator's hands, not hardcoded in the harness [7].
2. Spend the small scaffolding budget on three things. First, one edit mechanism with a uniqueness check and error feedback (+7.7 points in the SWE-agent ablation; Anthropic's `str_replace_editor` is the production version) [8][9]. Second, bounded, summarized tool output (file-viewer window and search-summarization ablations, ±4-6 points) [9]. Third, linting-style guardrails on edits (+3.0) [9]. Tool proliferation is not supported: a single interactive terminal tool (Terminus) is a competitive instrument, and SWE-agent's iterative search tool scored below having no search tool at all [9][12].
3. Make limits first-class, recorded parameters. Published scores move with step budgets (tau-bench 30 to 100) [24][26] and with task timeouts set by the harness (Terminal-Bench treats timeout manipulation as cheating) [14]. Baton-cli's tasking protocol should carry explicit step/token/time budgets per task, record them in the session, and enforce them uniformly.
4. Record the session as discrete events with replay semantics. Four independent benchmark ecosystems depend on this: pass^k re-rolls from a fixed state (tau-bench) [24], trajectory files required for audit (Terminal-Bench ATIF) [14], rollout capture for RL/SFT (Harbor) [11], and trajectory-equals-messages debugging/fine-tuning (mini) [18]. An append-only event log of turns, tool calls, and tool outputs is the format that satisfies all four consumers.
5. Run the harness outside the environment it drives. Terminus's independent-process, remote-connection design exists specifically because in-container agents fail in broken environments [12], and Harbor generalizes it to remote containers at scale [11]. For baton-cli this supports a process boundary between the agent loop and the sandbox, addressed over the baton2 protocol rather than shared state.
6. Support background and interactive execution inside the single tool. The verified evidence is indirect: Terminus's tmux session lets agents run additional shells and background jobs [12], and Anthropic's bash tool description instructs the model to run long-lived commands in the background [8]; Terminal-Bench tasks include kernel builds, server configuration, and network setup where a blocking wait wastes wall time [10][15]. No surveyed benchmark directly measures streaming or parallel tool execution against blocking execution on the same model, so this remains a design bet with supporting context, not a measured result (see Unknowns).
7. Measure format adherence. Aider's leaderboard shows harness-parse failures suppressing a model's score by design (64.4% format adherence on a top model) [17]; baton-cli's session log should record parse-failure events so harness-vs-model attribution stays clean.
8. If baton-cli is used for evaluation, keep the loop neutral and versioned. The bash-only leaderboard's ground rules: fixed shared configuration, no tuning for score, version numbers that make runs comparable, and explicit notes when versions are not comparable (mini v1 vs v2) [2][18].

### Explicit unknowns

- Streaming vs blocking tool execution: no published controlled comparison exists in the sources surveyed. The Terminus tmux design and Anthropic's background-command guidance are the closest evidence; treat baton-cli's async-streaming default as unvalidated until a Terminal-Bench-style A/B exists.
- Scaffold variance on a strictly fixed model is documented for only a handful of pairs (Anthropic's scaffold vs mini; mini vs live-SWE-agent; SWE-agent's internal ablations). Leaderboard spreads that mix multi-model routing or multi-attempt systems overstate harness effects.
- METR time horizons conflate scaffold, elicitation effort (2-3 engineer-weeks on two models), and model quality; no public number isolates the scaffold contribution to the horizon.
- Terminal-Bench per-entry spreads of ±2-3 points mean harness differences under ~3 points are within run noise; the largest harness gaps (8-20 points) are the reliable signals.
- The polyglot edit-format effects were measured inside one harness with text-formatted edits; whether they persist under native tool calling is unmeasured.
- The 5-20 point harness spreads measured in 2024-2025 may shrink as models absorb more agentic training; the Verified spread for a given model pair is not stable across model generations (compare the Sonnet 4 gap of 7.5 points with the Opus 4.5 gap of 4.8 points to live-SWE-agent).

## Core architectural concepts

The benchmark evidence reduces to six concepts that recur across every harness the data rewards:

1. **Neutral versioned loop as measurement instrument.** The same minimal agent loop, pinned by version and configuration, makes model comparisons valid (SWE-bench's bash-only leaderboard, DeepSWE's all-models-on-mini rule, Terminus as reference agent) [2][4][12][18]. A harness that tunes itself to a score stops being an instrument.
2. **One interactive tool, many verbs.** Terminus's mono-tool tmux session, which exposes keystrokes rather than narrow commands, is competitive with multi-tool agents; SWE-agent's ablations show that extra narrow tools (pager-style search) can score below having none [9][12]. The design optimizes for letting the model compose primitives.
3. **Stateless per-action execution.** mini's fresh `subprocess.run` per step trades shell-state persistence for deterministic termination, crash isolation, and trivial sandboxing (swap `subprocess.run` for `docker exec`) [18][23]. The loop is arranged so every action is an isolated fact to record and replay.
4. **Append-only event session with replay semantics.** Four ecosystems independently require it: pass^k re-rolls from a fixed state, ATIF trajectory audits, Harbor RL/SFT rollouts, and mini's trajectory-equals-messages debugging [11][14][18][24]. The session log is the model input, the audit artifact, and the training data in one format.
5. **Limits as recorded harness parameters.** Step budgets (tau-bench 30 to 100) and task timeouts (Terminal-Bench integrity policy) are first-class, uniform, and logged; scores move with them and unauthorized changes void results [14][24][26].
6. **Edit reliability as the first scaffold investment.** The only tool beyond the shell that consistently pays for itself is one edit operation with a uniqueness check, error feedback, and optional linting (+7.7 points in the SWE-agent ablation; Anthropic's `str_replace_editor` in production) [8][9].

For baton-cli these six define the target shape: a small versioned loop, one interactive execution surface plus one edit surface, stateless action execution, an append-only event session the orchestrator can fork at turn boundaries, explicit per-task limits, and no further scaffolding until a measured gap justifies it.

## Sources

1. SWE-bench paper: https://arxiv.org/abs/2310.06770
2. SWE-bench Verified page and bash-only methodology: https://www.swebench.com/verified.html
3. SWE-bench leaderboards and news: https://www.swebench.com/
4. DeepSWE benchmark post (May 2026): https://deepswe.datacurve.ai/blog/deepswe
5. SWE-bench Verified leaderboard data (leaderboards.json): https://raw.githubusercontent.com/SWE-bench/swe-bench.github.io/master/data/leaderboards.json
6. live-SWE-agent (scaffold evolution on the mini base): https://arxiv.org/abs/2511.13646
7. Anthropic, Claude 3.7 Sonnet announcement with scaffold appendix: https://www.anthropic.com/news/claude-3-7-sonnet
8. Anthropic engineering, "Raising the bar on SWE-bench Verified with Claude 3.5 Sonnet": https://www.anthropic.com/engineering/swe-bench-sonnet
9. SWE-agent paper (ACI ablations): https://arxiv.org/abs/2405.15793
10. Terminal-Bench announcement: https://www.tbench.ai/news/announcement
11. Terminal-Bench 2.0 and Harbor announcement: https://www.tbench.ai/news/announcement-2-0
12. Terminus reference agent: https://www.tbench.ai/news/terminus
13. Terminal-Bench 2.0 leaderboard: https://www.tbench.ai/leaderboard/terminal-bench/2.0
14. Terminal-Bench leaderboard integrity update: https://www.tbench.ai/news/leaderboard-integrity-update
15. Terminal-Bench 2.1 release (2.0 vs 2.1 pair data): https://www.tbench.ai/news/terminal-bench-2-1
16. Aider polyglot benchmark announcement: https://aider.chat/2024/12/21/polyglot.html
17. Aider polyglot leaderboard: https://aider.chat/docs/leaderboards/
18. mini-SWE-agent repository and README: https://github.com/swe-agent/mini-swe-agent
19. METR, "Measuring AI Ability to Complete Long Software Tasks" (paper): https://arxiv.org/abs/2503.14499 and blog: https://metr.org/blog/2025-03-19-measuring-ai-ability-to-complete-long-tasks/
20. METR TH1.1 raw results: https://metr.org/assets/benchmark_results_1_1.yaml
21. METR time-horizons methodology and FAQ: https://metr.org/time-horizons/
22. Triframe scaffold description (METR paper appendix, same URL as 19)
23. mini-SWE-agent FAQ (no shell session rationale): https://mini-swe-agent.com/latest/faq/
24. tau-bench paper: https://arxiv.org/abs/2406.12045
25. tau2-bench paper: https://arxiv.org/abs/2506.07982
26. Anthropic tau-bench scaffolding note (in the Claude 3.7 announcement, same URL as 7)