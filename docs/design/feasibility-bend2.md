# Feasibility of Bend2 for the baton-cli seat

**Verdict: the seat binary and the session-log codec are feasible on the pinned toolchain, with the authority sitting in an authored C effect family; child-process supervision, harness driving and a Bend2 JSON encoder already run in a baton checkout. The program lane and the self-extension loader are not feasible as written: Bend2 has no evaluator to call and no runtime module loader. The nearest workable mechanisms are an out-of-process lane (`bend <program>` as a child, tool calls re-entering the seat over a socket) and two extension paths Bend2 can express (declarative tools admitted as data, and repository-level tools gated by `bend --check-only`).**

Paths below are relative to the worktree parent `/Users/wahargis/Development/Experiments/`:
`KIT` = `bend2-trial/kit` (a baton checkout carrying the Bend2 implementation and the vendored language reference), `BEND` = `bend2-trial/.bend` (the installed toolchain: `BEND/bin/bend`, `BEND/bend2/base.bend`, `BEND/bend2/effs/`, `BEND/guide/`), `BATON2` = `KIT/bend2/src`.

## The pinned language

| | |
|---|---|
| Language | Bend, version 2.0.25 |
| Upstream | `github.com/bendlang/bend`, pinned at `a49524265bdfa5753a4bf38e25f0574a705dd868` (2026-09-21) per `KIT/docs/bend2/reference/README.md` |
| Local toolchain | `BEND/bin/bend` reports `bend 2.0.25` (Mach-O arm64); `BEND/guide/GUIDE.md` sha256 `9e464364…` and `GUIDE/EFFECTS.md` `4d7178c7…` match the manifest in the same file |
| Reference implementation in the tree | `BATON2` — 4,484 lines of `.bend` across `coordinator/ git/ host/ json/ replay/ harness/`, plus 714 lines of authored C effects |

Bend2 is an affine dependent type theory with a Python-shaped surface (`KIT/docs/bend2/reference/upstream/guide/GUIDE.md:31-124, 582-605`). Variables are used at most once unless the binder carries `+`; a `+` binder requires a `Data`-kinded type; closures and handles are affine with no shared use (`README.md:222`). Termination is checked by requiring a recursive call to pass a smaller part of an argument (`GUIDE.md:87-124`); `@unsafe` opts out. There are no type classes, traits, tactics or macros beyond closed compile-time templates. Effects are `IO` values sequenced in `do` blocks, and a foreign effect is a def whose body names a `.c` half and a `.js` half (`GUIDE.md:338-383`; `KIT/docs/bend2/reference/upstream/guide/EFFECTS.md`).

Where a claim concerns the `bend` command's internals rather than the language, it cites a depth-1 clone of `bendlang/bend` at `d2aeefc` (newer than the pin); the differences that matter are named in place, and every capability claim was re-run against the pinned 2.0.25 binary.

Five shape rules in the checker bound every harness loop and codec, and they are stated as inherited constraints in the reference implementation's own headers (`BATON2/json/canonical.bend:10-16`):

1. a `match` cannot scrutinize a computed value or a value bound by a `let`; the scrutinee must be a parameter or a pattern binder (`GUIDE.md:87-124`);
2. a `match` cannot appear inside a `do` block ("a match heads a def body, not a term");
3. a def must be declared before it is used, and mutual recursion is refused, so a state machine is one self-recursive def carrying a mode;
4. a name may be used at most once per binding, so a value used in several places needs a `+` binder, which a handle, a closure or a `List<&1, …>` cannot have;
5. a foreign effect's `.c` names are runtime internals with no ABI promise, so every effect rebuilds with every toolchain update (`EFFECTS.md:125-130`).

Rules 1 through 4 are visible in the seat's own arithmetic: the reference implementation's process supervisor needs `@unsafe` on its read loop (`BATON2/test/process.bend:9`), and its streaming loops thread a `U32` table index rather than a handle because a `U32` is `Data` and therefore reusable.

## Capability table

Confidence is high where the claim is a checker observation or a program run recorded below or in the tree's evidence corpus, medium where it rests on a mechanism I confirmed only in the small.

| # | Question | Answer at the pin | Evidence | Conf. |
|---|---|---|---|---|
| 1 | What it is: type system, module system, stdlib | Affine dependent types with explicit quantities and laws; a module is a file imported by relative path under a file-local alias; `import 0x<hash>/main.bend as P` fetches from the hub at check time; Base is small (numbers, `List`, `Array`, `Map`, `Set`, `Maybe`/`Result`, `Equal`, and the effects `IO`, `File`, `TCP`, `UDP`, `Chan`, `Window`, `Audio`) | `GUIDE.md:31-124, 274-337, 437-489`; `BEND/bend2/base.bend`; `KIT/docs/bend2/language-review.md:176-186` (LANG-F-19/20) | high |
| 2 | What it compiles to | One C file, then clang, to a native binary (with a Metal/CUDA `.gpu` companion when `!` is used); `-o x.js` for JavaScript; bare `bend x.bend` interprets through the bun host that embeds the checker | `GUIDE.md:490-513, 582-605`; `/tmp/bend-upstream/bend2/main.ts:971-981` (`Comp.io_run`); measurement below | high |
| 3 | Build and dependency story | One command; each foreign effect contributes a `.c` half that is spliced into the program's single C file; link flags are yours (`clang -O1 -pthread out.c -lsqlite3 -lm`); clang only; no separate compilation, no incremental build, no library target | `KIT/bend2/scripts/build-native.sh:13-16`; `README.md:237`; `WONTFIX.txt:30, 94` | high |
| 4 | Spawn and supervise a child process | Base ships none (`bend base exec` refuses); the C-effect family exists and runs in the tree today | `KIT/docs/bend2/examples/lang-host-interop.evidence.md` step 6; `BATON2/host/process.bend:5-25`; `BATON2/host/process-spawn.c:43-92` | high |
| 5 | Stream child stdout incrementally | Yes: one line per effect through `getline` on an IO helper thread; the child's stderr is redirected to a retained file rather than streamed | `BATON2/host/process-spawn.c:67, 114, 194`; probe 2 | high |
| 6 | Stream child stderr incrementally | Not in the existing family; one more pipe and one more parked read | `BATON2/host/process-spawn.c:67` (dup2 of stderr to a log file) | high |
| 7 | Unix-socket client | Base has no Unix-socket path (`TCP.connect` builds `AF_INET` only); an authored C effect reaches it in one call | `BEND/bend2/effs/tcp_connect.c`; probe 1 | high |
| 8 | HTTP client with incremental reads | Base TCP alone suffices for HTTP/1.1 and for chunk-by-chunk delivery; TLS does not exist in Base | probe 4; `README.md:231`; `KIT/docs/bend2/language-review.md:256` (LANG-CAP-08) | high |
| 9 | Read and write files with fsync | Base has open (`r`/`w`/`a`), read (text, bytes, at offset), size, write, write_bytes, close, and nothing else; `File.sync`, `File.rename` and `File.stat` are refused as absent names; the C-effect route delivers fsync, directory fsync, rename, unlink and stat | `BEND/bend2/base.bend:257-294`; `KIT/docs/bend2/examples/lang-cap-durability.evidence.md`; probe 1 | high |
| 10 | Model-provider HTTP/SSE client | Framing over Base TCP works and the tree already carries a canonical JSON encoder in Bend2; TLS is a new C-effect dependency (link a TLS library or pin a CA and implement the handshake); baton2 threads the same JSON-line protocol over child pipes instead | probe 4; `BATON2/json/canonical.bend`; `BATON2/coordinator/turn.bend:197-220`; `KIT/docs/bend2/language-review.md:254` | medium |
| 11 | Bounded worker pool / concurrent operations | `IO.spawn`/`IO.fork`/`IO.join` plus a channel with capacity; a join in completion order is one shared completion channel that every worker sends to; Base has no cancel, race, select or deadline | probe 5; `BEND/bend2/base.bend:211-256`; `KIT/docs/bend2/language-review.md:257` (LANG-CAP-09) | high |
| 12 | Evaluate a generated Bend2 program in-process | Not expressible. No `repl`, `eval`, `test`, `debug` or `fmt` subcommand exists, and the checker and interpreter are the separate `bend` program, written in TypeScript and shipped as a compiled bun binary | `bend --help` (2.0.25); `README.md:246, 248`; `/tmp/bend-upstream/bend2/main.ts:971-990` | high |
| 13 | Load a Bend2 module discovered at runtime | Not expressible. Imports resolve at check time; one C file per program; no separate compilation, no incremental build, no native library target | `GUIDE.md:462-489`; `README.md:237`; `WONTFIX.txt:94` (#813) | high |
| 14 | Admit native code at runtime | Works at the C boundary: an authored C effect can `dlopen` a library from a declared directory and call an exported entry. The extension is C, carries no checker verdict, and the effect still rebuilds with each toolchain update | probe 6; `EFFECTS.md:125-130` | medium |

Two further facts the proposal depends on, both negative: a user-declared affine record is forgeable by any importing module, so naming a type `Lease` or `Capability` establishes no provenance and no single producer (`KIT/docs/bend2/examples/index.md` rows `lang-cap-forge`, `lang-cap-second-predicate`; `language-review.md` LANG-F-28), and a value bound to a closure can be called once ("consumed more than once"), which makes a table of tool closures unusable (probe 7).

## Use 1 — the seat binary itself

Feasible on the pinned toolchain, with the effects the seat needs split across Base and an authored C family. The tree already contains a working reference of the hard parts. `BATON2` supervises four native harness CLIs as child processes (`BATON2/harness/{omp,codex,claude,muse}-worker.bend`), writes JSON frames into a child's stdin, reads its stdout a line at a time, waits for the exit status, and records the turn: the whole path is Bend2 plus 222 lines of C (`BATON2/host/process-spawn.c`). Probe 2 confirms the same file compiles unmodified into a standalone binary with the pinned toolchain and answers `one`, `two`, `exit 0` for a child that prints two lines, with the child's stderr reaching the retained log file.

What the seat adds beyond the reference: durability effects (probe 1), a TLS client for the provider (absent from Base), a JSON decoder (the tree's decoder covers one unsigned decimal JSON integer token, `BATON2/json/uint-decoder.bend:1-5`; baton2 parses frames by delegating to SQLite's json1 functions, `BATON2/coordinator/turn.bend:197-220`), and a turn loop shaped to the checker's rules.

That last point is a structural constraint on the seat, not a style preference. A turn loop with four states (model call, tool dispatch, wake, commit) cannot be written as one `do` block: the `match` needs a def body, and defs cannot call each other in a cycle. The loop is one self-recursive def carrying a state sum type as a parameter, with nested matches on pattern binders inside the arms, and `@unsafe` on the arms that keep waiting without shrinking an argument. Probe 4 (an HTTP client) and probe 5 (a completion pool) both had to take exactly this shape; the reference implementation's canonical JSON encoder states the same rule in its header (`BATON2/json/canonical.bend:12-13`). The measured cost of the whole seat is available from the reference: the coordinator's 4,484 lines of Bend2 emit 3.37 MB of C in 3.0 s and link to a 2.27 MB binary in 4.2 s with `clang -O1`, and the binary starts in under 10 ms.

## Use 2 — the session log codec

Feasible; the mechanism is a new C effect family plus Base's file surface, and the proposal's wording needs one correction.

Base gives the append path directly: `File.open(path,"a")` opens with `O_APPEND` (`BEND/bend2/effs/file_open.c:12`) and `File.write`/`File.write_bytes` run on an IO helper thread (`file_write.c`, `io_work`). Base gives the end-of-log check: `File.size` and `File.read_at` exist (`base.bend:272-281`), so "the writer that finds the log no longer ends where it last committed" is expressible without new effects. Base gives tail reads: `File.read` is one `read(2)` per call and returns what is available, so a reader can pull the tail incrementally.

Base does not give durability. `File.sync`, `File.rename` and `File.stat` are not names in Base and the checker refuses them (`KIT/docs/bend2/examples/lang-cap-durability.evidence.md`). Probe 1 closes that gap through the proven effect contract: with one 60-line C half I ran write → `fsync(file)` → `rename` → `fsync(directory)` → `stat(size)` and observed `committed /tmp/bend2-feas/store/log.jsonl` then `size 10`, with the final file content `{"seq":1}`.

The correction: the proposal specifies one commit discipline for the whole log, "a temporary file plus fsync and directory sync" (`docs/design/design-sketch.md:23`). On Base's surface that discipline rewrites the log for every append, because `rename` publishes a whole file. An append-only log wants `O_APPEND` writes plus `fsync(file)` per commit, a directory sync only when the file is created or replaced, and temp-file-plus-rename reserved for segment rotation and compaction. Single-writer discipline is available too: the reference takes an `flock(LOCK_EX|LOCK_NB)` on a path derived from the database beside the session name (`BATON2/host/session-lock.c:55`), which is the mechanism for one writer per session log. Large frames need the byte-list representation, not `String`: a `String` is a linked list of characters (`README.md:231`), and the effect boundary already supports `List<U32>` bytes through `File.read_bytes`/`write_bytes` and `io_cstr`/`io_str`.

## Use 3 — the program lane

Not feasible as written. The proposal says the seat runs "generated Bend2 programs executed natively in the same confinement, logging path, and operation layer as any tool" (`design-sketch.md:110`) and gives the harness the language it is written in. Three facts rule out in-process evaluation:

- there is no evaluator to call. `bend --help` at the pin lists `check/run`, `-o`, `--check-only`, `--publish`, `base`, `guide`, `update`, `version`; the upstream README states "no debugger, profiler or REPL" (`README.md:246`) and "no test framework" (`README.md:248`);
- the checker and interpreter are the `bend` program, 11,287 lines of TypeScript compiled to a bun binary, with the in-process API on the JavaScript side (`book_read`, `book_run`, `Comp.io_run` at `/tmp/bend-upstream/bend2/main.ts:971-990`). A Bend2 program cannot host a TypeScript program, and there is no C or Bend2 binding to the checker;
- the emitted C is one program with one `main`, and a native library target for pure defs is a WONTFIX entry marked planned and unscheduled (`WONTFIX.txt:94`, #813). `bend` refuses `-o` beside an input the program reads, and one binary holds one `main` (`--checkup` exists because of that: "a binary holds one main, so build each import alone").

The closest workable mechanism, in rank order:

1. **Out-of-process lane with mediated tool calls.** Write the generated program and a byte-stable SDK module into a directory under the session directory, then run `bend program.bend ARGS` as a child through the process family, exactly as the reference runs its harnesses. The interpreter lane needs no C compiler: probe 4's program (a Bend2 HTTP client) and a trivial IO program both check and run in 60-110 ms, and a program importing a sibling SDK module with an argv is 95 ms. The child's stdout and stderr enter the log as a tool result; nested tool calls leave the child through a socket back to the seat, so every effect still passes the seat's guarded pipeline and the child inherits no authority it was not given. Confinement is the OS sandbox plus the absence of authority in the child, not the type system. State plainly in the design that the generated program is not proof-checked unless the lane runs `bend --check-only` on it first (3.0 s for a program the size of the reference coordinator, 0.1 s for a small one), and that a per-call process is the price.
2. **In-process pure sub-language.** If in-process evaluation is a hard requirement, the lane evaluates a small pure expression language with a Bend2 evaluator inside the seat. This gives real confinement by construction, no compiler dependency and no process per call, and it is only Bend-plus-a-def for what the model writes. The language's own evidence corpus already decides frozen traces in pure Bend2 models (`KIT/docs/bend2/examples/arch-replay-*.bend` over the coordinator's recorded rows), which is the same shape at a smaller scale. Effectful work then stays in the discrete tool calls.
3. **Compile once, spawn many.** `bend program.bend -o program` then run the binary. Right for a program that has been promoted to a tool, wrong for one-shot evaluation: the reference coordinator costs 3.0 s to emit plus 4.2 s to link.

## Use 4 — self-extension

Not feasible as written, in two independent ways.

The loading half fails for the reasons in use 3: a Bend2 binary cannot load a Bend2 module discovered at runtime. Imports resolve at check time (`GUIDE.md:462-489`), the build is one program, and `WONTFIX.txt:94` records no native library target. "It loads through the same module loader, confinement, and logging as the shipped four" (`design-sketch.md:134-136`) describes a mechanism the language does not have.

The contract half fails on the authority claims. The proposal asserts that "extensions inherit the seat's authority and cannot widen it; escalation is refused rather than clamped". Bend2 offers no unforgeable value: a type's constructors export with its module, an importing module builds `L.Lease{999}` directly, `release` answers the forged field, and two defs can both return the same type (`KIT/docs/bend2/examples/index.md` rows `lang-cap-forge` and `lang-cap-second-predicate`; `language-review.md` LANG-F-28). Authority is therefore enforced at the effect boundary and by the operating system, never by the checker. A second limit: a user-defined handle type is a law only Base may leave unfilled (`WONTFIX.txt:47`, #825), so an extension reuses `File`, `Socket` or a `U32` index.

The workable mechanisms, in rank order:

1. **Declarative tools admitted at runtime.** The admitted artifact is data — name, argument schema, an argv template, the permission target, the writes declaration, and the module digest — and the executor is a dispatcher def checked at build time. Probe 7 confirms the shape is legal: one def per tool plus a dispatcher whose subject is a parameter, matched with literal patterns, called any number of times, with an argument record whose fields are opened by a pattern match. This keeps three of the proposal's four safety properties in full (description generated from the same data, admission as a logged event with a digest, extension state in the log) and leaves authority where it belongs, at the effect boundary. It loses one thing the proposal wanted: the tool body is a template, not arbitrary code.
2. **Bend2 tools admitted as a repository act, gated by `bend --check-only`.** The contract can be a `law` in the module, and an open law anywhere in the import graph fails the whole check with `Error: 1 TODO found.` — I confirmed this end to end by importing a module with one open law into a clean program. The pin also offers `--checkup`, which checks and runs each import of a file alone. So an admission gate that the seat runs out of process, before it will build or load a module, is real and provable; arithmetic identities are not free, though: probe 8 shows `twice(twice(n)) == four(n)` refused by `{==}` with the expected and observed terms printed, because the checker has no tactics and no ring axioms. Useful tool contracts are the type signature and termination, which are automatic, plus definitional equalities.
3. **Native extension at the C boundary.** An authored C effect that `dlopen`s a library from a declared directory and calls an exported entry works today (probe 6 printed `extension answered 42`). The extension is C, its ABI is the author's, the checker sees only the effect's declared Bend signature, and the effect depends on runtime internals with no ABI promise.

Consequence for the proposal's §6 flow: "a program written five times in a session becomes a tool" ends at one of three places — a declarative tool registration (in-process, logged, no new code), a compiled standalone binary spawned per call (out of process), or a repository change that lands new Bend2 in the seat (the proposal's own position that the shipped tool set changes only through repository work). The routing between those three belongs in the design.

## What exists today

- `BATON2` — the Bend2 coordinator, 4,484 lines across `coordinator/ git/ host/ json/ replay/ harness/` plus 714 lines of authored C: child-process spawn, supervision, streaming reads, signals by process group (`host/process-spawn.c`), SQLite access through a C effect (`host/sqlite.c`), `flock` session locking (`host/session-lock.c`), directory scan by suffix (`host/files.c`), whole-file read and append (`host/text.c`), an `argv` NUL-encoding helper (`host/process.bend:27-30`), a canonical JSON encoder in Bend2 (`json/canonical.bend`, 379 lines), an unsigned-integer decoder (`json/uint-decoder.bend`, 225 lines), and pure Bend2 replay models over recorded rows (`replay/`, 911 lines).
- Harness adapters that start Claude Code, Codex, OMP and Muse with their real CLIs, feed them JSON over stdin and read their event streams (`harness/*.bend`, 76 lines; `coordinator/turn.bend:130-260`).
- A capability evidence corpus for the language: `KIT/docs/bend2/language-review.md` (LANG-F-01..31, LANG-CAP-01..10) with one runnable example and evidence file per claim under `KIT/docs/bend2/examples/`, including the durability refusals, the Base process-spawn refusal, the foreign-effect route, the C-only effect, and the forgeability probes.
- Build and check scripts (`KIT/bend2/scripts/build-native.sh`, `check-native.sh`), a Python acceptance suite beside them, and the upstream project's own 1,648 `.bend` test programs run on four lanes by `gates/test.ts`.
- Probes run for this document in `/tmp/bend2-feas` (ten probes, six of them programs; commands and outputs in `## Probes`).

No program in the tree evaluates a Bend2 program in process, loads a Bend2 module at runtime, or compiles a module at runtime. The nearest prior art to the four uses is the process-supervising coordinator (uses 1 and 2), the pure replay models (a program lane in the small), and the foreign-effect process-spawn example (`KIT/docs/bend2/examples/lang-host-foreign.bend`).

## What would have to be built

| Piece | State | Size order |
|---|---|---|
| Durability family: `fsync(file)`, `fsync(dir)`, `rename`, `unlink`, `stat`, `mkdir`, temp-file create with `O_EXCL` | absent from Base; one C half proved sufficient (probe 1) | 100-150 lines of C, 6 defs |
| TLS client for the provider, or a pinned-CA handshake | absent; nothing in Base | C effect linking a TLS library; the largest new dependency |
| HTTP/1.1 + SSE framing | Base TCP is sufficient (probe 4) | Bend2 only |
| JSON decode of provider frames | encoder exists in Bend2; the decoder in the tree covers one unsigned integer token; baton2 parses via SQLite json1 | a Bend2 module, or a C JSON half, or reuse of `json1` |
| Child stderr as a stream | absent; stderr goes to a file today | one pipe and one parked read in the existing family |
| Program lane (out of process) | absent | writer + SDK module + socket protocol + result mapping |
| Admission gate | `bend --check-only` / `--checkup` are sufficient as the gate (probe 8); the seat side is absent | small |
| Seat core: turn loop, log, tools, inbox | absent as baton-cli; the coordinator is the reference, not the target design | the bulk of the work |

## Probes

All probes run with `BEND/bin/bend` (bend 2.0.25, darwin arm64) and `clang -O1 -pthread -isysroot /Library/Developer/CommandLineTools/SDKs/MacOSX15.2.sdk`. The host's default link step fails with `tapi error: malformed file … unknown architecture arm64e.x1-macos`; the `-isysroot` flag selects a working SDK. This is a host toolchain defect outside Bend.

**1. Durability and AF_UNIX through the effect contract.** One C half, six defs (`Host.sync`, `Host.sync_dir`, `Host.rename`, `Host.unlink`, `Host.size`, `Host.unix_request`), modeled on `BEND/bend2/effs/file_write.c` (`io_work` + `io_done`/`io_fail`). Run: `./dur store store/log.tmp store/log.jsonl store/sock` against a Python `AF_UNIX` server.

```
committed /tmp/bend2-feas/store/log.jsonl
size 10
socket said PONG

No such file or directory
exit=2
```

The file content was `{"seq":1}`. `No such file or directory` is the last step unlinking the temp path that `rename` had already moved — the program's own error, returned as a `Result` failure through `IO.try` with the errno message. The four durability operations and the Unix-socket round trip all executed.

**2. Process supervision, unmodified from the tree.** Built `KIT/bend2/test/process.bend` (`bend … -o process-test.c` then clang). Run: `./process-test stream /tmp child.stderr /bin/sh -c "printf 'one\ntwo\n'; printf 'oops\n' >&2; sleep 0.1"`.

```
stdout: 'one\ntwo\nexit 0\n'
stderr: ''
exit: 0
child stderr file: oops
```

**3. stdin, pid and signal.** A driver over `KIT/bend2/src/host/process.bend`, copied unchanged. `./proc talk /tmp proc.stderr` (spawn `/bin/cat`, write two lines, close stdin, read to EOF, wait) and `./proc stop /tmp proc.stderr` (spawn `sh -c 'sleep 30'`, read pid, signal 15, wait).

```
line 0: alpha
line 1: beta
lines 2
cat exit 0
pid 38183
sleep signal 15
```

**4. HTTP/1.1 client with incremental reads, Base only.** `TCP.connect` → `TCP.send` → a `TCP.poll(sock,4096,500)` loop against a Python server that sent three chunks 400 ms apart and closed. No C effect.

```
chunk HTTP/1.0 200 OK

data: tick 0

chunk data: tick 1

chunk data: tick 2

closed by peer
```

Three chunk prints, each at the moment its bytes arrived, and then the close. The program needed the state-parameter shape (`@unsafe`, one self-recursive def, `TCP.poll`'s `Socket & Result` pair opened by a `match` on `Sigma`'s `Tuple` constructor) for reasons given in use 1.

**5. Bounded concurrent work joined in completion order.** `Chan.new(U32,4)` as the capacity, three `IO.spawn` children sleeping 30/20/10 ms and sending their id to one shared completion channel, the loop receiving three.

```
all started
started 10 sent=True
done 10
started 20 sent=True
done 20
started 30 sent=True
done 30
pool drained
```

Completion order (10, 20, 30) differs from start order, which is the join the async turn needs.

**6. Runtime native extension.** A C effect calling `dlopen(path, RTLD_NOW|RTLD_LOCAL)`, `dlsym`, and an exported `int32_t ext_run(const char*, uint32_t)` from a separately built `.dylib`.

```
extension answered 42
exit=0
```

**7. Reuse and tool dispatch.** A closure bound by a let and called twice: `- expected : f / - observed : f (consumed more than once)`. A `Socket` bound in a `do` block and used twice: `- expected : sock / - observed : sock (consumed more than once)`. A dispatcher def with one arm per tool name, subject a parameter, called three times: `"read: /tmp/x | bash: bash 200 | edit: unknown tool"` (checked and run).

**8. Law-gated admission.** A module with an open law imported by a clean program: `bend hostprog.bend --check-only` → `Error: 1 TODO found.` and `bend hostprog.bend --checkup` → `--- ./extlaw.bend ---` then the same error. After adding a proof attempt for `{Tool.twice(Tool.twice(n)) == Tool.four(n) : U32}`, the checker answered `- expected : U32.mul(U32.mul(n, 2), 2) / - observed : U32.mul(n, 4)`. `bend --verdict`, present in upstream `main.ts`, does not exist at the pin.

**9. Toolchain surface.** `bend base exec` → `bend: Base has no exec`; `bend base Json` → `Base has no Json`; `bend base File.sync` → `Base has no File.sync`; `bend --help` lists no `repl`, `eval`, `test`, `debug` or `fmt`. Interpreter lane on a program whose only host half is C: `Error: a foreign def without a .js import: Host.size`.

**10. Build and startup cost.** Trivial IO program: `--check-only` 100 ms, emit C 92 ms, clang link 175 ms, native startup under 10 ms, interpreter lane 60-110 ms. JavaScript emit 88 ms plus 590 ms of bun startup. The reference coordinator (4,484 lines of Bend2): emit C 3.0 s producing 3.37 MB, clang `-O1` 4.2 s producing a 2.27 MB binary.

## Proposed amendments

Ranked by how much of the design changes if the amendment is ignored.

1. **§5, `design-sketch.md:108-118` — replace the in-process program lane.** Strike "generated Bend2 programs executed natively in the same confinement, logging path, and operation layer as any tool" and "this harness runs them in the language it is written in" as an in-process claim. Specify the out-of-process lane: the program and its SDK module are written into a directory under the session directory; `bend <program> <args>` runs the interpreter lane as a child through the process family with the child's stdout and stderr captured into the log; nested tool calls re-enter the seat over a Base TCP loopback socket carrying the JSON frame codec, so every effect passes the guarded pipeline and the child holds no authority the seat did not grant; the seat runs `bend --check-only` on the program before running it when the lane's failure cost warrants 0.1-3 s. Record the lane's cost (60-110 ms per trivial call, 95 ms with an SDK import) and its two admitted losses: no type checking of the generated program at run time and one process per call. Without this amendment the program lane is unimplementable.
2. **§6, `design-sketch.md:132-153` — replace the runtime module loader with two paths.** Delete "it loads through the same module loader, confinement, and logging as the shipped four" and the claim that the extension set is a runtime-loaded module set. Specify (a) declarative tools admitted at run time as data — name, argument schema, argv template, permission target, writes declaration, module digest — executed by a dispatcher def that is compile-time checked, since a table of tool closures cannot be invoked repeatedly and a dispatcher must take its subject as a parameter; and (b) Bend2 tools admitted as a repository act, gated out of process by `bend --check-only`/`--checkup` with the tool's contract written as a `law` that must be proved. State explicitly that the checker cannot make a capability unforgeable (a `Lease`-shaped record is forgeable from any importing module) and that escalation is refused at the effect boundary and by the sandbox, not by the type system. Keep the proposal's third path — a compiled program spawned per call — as the promotion route, and say which of the three a program-written-five-times promotion takes.
3. **§1 and §4 — add the loop shape as a design constraint, in the design's own voice.** Every loop in the seat (turn loop, log codec walk, program-lane loop, spawn loop) is one self-recursive def carrying a state sum type as a parameter, with nested matches on pattern binders inside the arms, `@unsafe` where an arm keeps waiting without shrinking an argument, one name per binding, `+` binders only for `Data`, so a handle or a closure used twice inside one computation is threaded through the loop's state (the reference's `U32` table index is the `Data` alternative). A `match` cannot head a `do` block, and two defs cannot call each other. This decides the module layout, the SDK section's shape, and how the turn loop is written; it is also why the reference implementation threads `U32` table indices for process handles instead of typed handles. Add it as a named constraint with one worked example rather than discovering it during implementation.
4. **§2, `design-sketch.md:20-26` — separate append durability from publication.** Replace "committed through a temporary file plus fsync and directory sync" with three named mechanisms: append-in-place (`O_APPEND`) plus `fsync(file)` per commit; directory fsync at file creation, replacement and rotation; temp-file plus `rename` for segment rotation and compaction only. Add the `flock` single-writer lock, and name the byte representation for frames past a few hundred kilobytes (`String` is a linked list of characters; use `List<U32>` bytes through `File.read_bytes`/`write_bytes`). Name the durability effect family as a required host layer with its six signatures, since Base refuses `File.sync`, `File.rename` and `File.stat`.
5. **§1 and §12 — name the provider transport gap.** Base has no TLS and no HTTP library. Add the provider client to the "what must be built" list as a C effect linking a TLS library (the only new third-party dependency in the design), keep HTTP/1.1 request framing and SSE delivery in Bend2 over Base TCP (confirmed working), and record that the reference implementation avoids the provider client entirely by driving existing harness CLIs as children. §12's instrumentation switches should say which transport each posture runs on.
6. **§13 — replace the CI gate list with the toolchain's real gates.** "Binary size and startup latency gated in CI" is not the binding constraint. The binding gates are: the pinned toolchain version checked by `bend version` before a build; a rebuild obligation for every C effect on every toolchain update, because the effect ABI carries no promise; clang-only C output; and the fail-stop conditions that are not `Result` values (allocation failure, `Nat` past 2^48-1, an unbalanced `Array` tree, channel deadlock), which the supervisor must cover because `IO.die` has no catch. Add the codec test convention: `tests/*.bend` programs whose `#|` lines are the expected output, checked, interpreted, built and run, which is how the upstream project tests 1,648 programs, and `--check-only`/`--checkup` as the admission gates.
7. **§14 bet 2 — restate the falsifiable claim in the lane's real costs.** "Generated Bend2 programs beat discrete tool calls for batch operations" should be settled against a lane that costs 60-110 ms of process per call, one SDK round trip per nested tool call, and no type checking of the generated program, and against the alternative of the same program compiled once (`bend -o`, 3.0 s + 4.2 s at the reference's size) and reused. Without those constants the experiment measures the lane's latency instead of its value.
8. **§11 — state what "a live, streaming shell is required" means in Bend2.** The live shell is a C effect family holding child handles in a `U32`-indexed table with an event-loop-safe read (one parked read per descriptor, blocking work on an IO worker thread), not a typed session object: handles are affine, cannot carry `+`, cannot be used twice in one computation, and are not storable in a `Data` record. The reference implementation is the model (`BATON2/host/process-spawn.c`, `BATON2/host/process.bend`).
9. **§3 and §8 — state the serialization boundary in the language's terms.** "Serialization to durable form happens at exactly one boundary" is right, and in Bend2 that boundary is the effect call: values cross as `String` (a linked list), `List<U32>` bytes, or integers, and the C half converts with `io_cstr`/`io_str` and the runtime's word packing. Add the two consequences: a `Capability` or `Lease` value has no unforgeable representation to serialize, and a decoded frame arrives as a hand-built tree (`BATON2/json/canonical.bend:13-16`), so the JSON value model is part of the design, not an implementation detail. A `Data` constructor cannot hold a handle at all, which fixes where each value in the log can live.
10. **§1 — add the target-size reality check.** The reference coordinator is 4,484 lines of Bend2 plus 714 lines of C for a comparable scope (coordination, durable state, worker lifecycle, Git, CLI). "A few thousand lines, readable in an evening" is achievable for the four tools, the log and the loop; the durable session log, the provider client and the extension paths put the floor nearer the reference's size. State the split so the milestone plan in §15 carries the right weights.
