# bend-feasibility probes — Bend 2.0.25 on Linux x64

Worker: bend-feasibility (Ensemble runtime-integration). Assignment:
independent recheck of `docs/design/feasibility-bend2.md` and the
Bend2-dependent claims of `docs/design/design-sketch.md` against the actual
pinned compiler and current canonical Baton source. Issue: baton-cli#1.

## Toolchain under test (single source of truth for every probe)

- `bend` wrapper: `postrelease-751-761-20261015-9/toolchain-home/bin/bend`
  (129-byte sh script exec'ing `bun --smol bend2/main.ts`); `bend version`
  prints `bend 2.0.25`.
- Checker `bend2/bend.ts` sha256 `93c2a43deeb82c15…` and `base.bend`
  `e5639663177f2de9…` are byte-identical to the upstream v2.0.25 release
  sources recorded in `source/bend2/toolchain/bend-2.0.25-baton741/pins.json`.
  `main.ts` `92dcdb49…` likewise. Only `comp.ts` carries local patches:
  upstream `ad8b8213…` → #741 memoization `d600b125…` → #776 opt-in
  diagnostics `1956f2e2…` (`toolchain-home/fork-manifest.json`,
  schema `baton-bend-776-smol-diagnostics-v1`,
  `official_release_artifact: false`, `qualification: false`).
- The prior feasibility audit's guide hashes match exactly:
  `GUIDE.md` `9e464364…`, `EFFECTS.md` `4d7178c7…` — the reviewed language
  documentation is unchanged.
- Checker delta vs the prior audit's a4952426-era vendored copy
  (`source/bend2/context/bend2/upstream/bend.ts`): 30 diff lines — a
  compile-template instantiation-depth guard (`z` counter, 64 levels,
  "a template that stops instantiating itself") and a 32768-cap on `~`
  argument growth. `base.bend` identical, `main.ts` 4 diff lines.
- Host: Linux 6.14 x64, AMD EPYC 7551; clang-19 (`/usr/bin/clang-19`).
  Every probe exports `BEND_NO_TELEMETRY=1` (the CLI otherwise performs a
  daily version GET and prints an update notice on stderr).

## Index

| Probe | Question | Outcome (see each `output.txt`) |
| --- | --- | --- |
| p01_base_surface | Base inventory and absent-name refusals | `File.sync/rename/stat/mkdir`, `Json`, `exec`, `Regex`, `HTTP`, `TLS` all refused verbatim (`bend: Base has no X`); IO/Chan/File/TCP/UDP inventories captured. |
| p02_shape_rules | Checker shape rules | `match`-in-`do` refused ("a match heads a def body, not a term"); computed scrutinee refused ("a match cannot scrutinize a local binder"); closure double-use refused ("f (consumed more than once)"); dispatcher on Data parameter checks and runs (3 calls); `@unsafe` self-recursive state loop checks and runs. Side finding: constructor names are one global namespace (`Done{}` collided with `Result.Done{}`). |
| p03_durability | Authored C effect family: fsync(file), fsync(dir), rename, unlink, stat-size, mkdir | Checks; emits C; links with clang-19; native AND interpreted runs both: write → fsync → rename → dir-fsync → stat "size 9" → committed file `hello-log`. Trailing `unlink` of the already-renamed temp fails ENOENT **by construction of the probe** (same as the prior audit's probe 1) and exits 2. |
| p04_unix_socket | AF_UNIX round trip via authored C effect | `socket said PONG`, client exit 0; server serves one connection and exits. The loopback mediation lane for nested program-lane tool calls works on Linux. |
| p05_supervision | Child-process supervision via the audit-era 222-line `process-spawn.c` (canonical source commit `bdc234c3`) | Native run streams `one`/`two`, waits `exit 0`, child stderr captured in file (`oops`). Matches the prior audit's probe 2 on Linux. |
| p06_http_tcp | HTTP/1.1 framing + incremental reads over Base TCP only | Request sent; chunks arrive incrementally as sent (300 ms apart, interleaved with the server log); EOF detected; exit 0. Finding: `TCP.poll` answers `Some{""}` (empty string) on peer close — `None{}` is the timeout, so EOF must be detected by the empty-read pattern `Done{Some{SNil{}}}`. First run iterated on EOF (output truncated with a provenance note; kept). |
| p07_chan_pool | Completion-order join over `Chan`/`IO.fork` | Three workers (30/20/10 ms) join in completion order on both lanes; `pool drained`; exit 0. Loop shape: one self-recursive def, nested matches in arms, closure re-entry. |
| p08_dlopen | Runtime native extension at the C boundary | Separately built `libext.so`; `dlopen`+`dlsym`+call prints `extension answered 42`, exit 0. |
| p09_law_gate | Law-gated admission; record forgeability | Open law in an import fails `--check-only` ("Error: 1 TODO found."); `--checkup` prints per-import markers; reflexivity proof attempt prints expected/observed (`U32.add(U32.add(n, n), U32.add(n, n))` vs `U32.mul(n, 4)` — no ring axioms); forged `Mk{999}` record checks and runs ("forged capability released level 999"). |
| p10_js_loader | In-process evaluation of Bend2 defs from a JS host | bun + `--preload bend2/main.ts`: module exports its non-IO defs under `default`; `double(21) = 42`; constructors cross as `{"$":"Some","value":7}`. Proves the JS-side in-process evaluator contract (main.ts:1-10, GUIDE.md:378-382). |
| p11_costs | Build/run costs on this host | Trivial IO program: `--check-only` 353 ms; emit C 420 ms (89,898 B); clang -O1 link 855 ms (1.09 MB binary); native startup+run 32 ms; interpreted run 409 ms; emit JS 429 ms (12,693 B). ~4-6x the Darwin audit figures; consistent with runtime-lead's 0.33-0.64 s observations. For scale: the production coordinator build at this pin recorded 2101 s emit and 142,651,376 KiB max RSS for 43,412 lines of Bend2 + 7,897 lines of C (`build-result.json` in the build root). |
| p12_template_guard | Checker delta behavior | Non-`@unsafe` self-call: refused ("a decreasing self-call…"). `@unsafe` self-instantiating template: checks clean (`bend_exit=0`). The 64-level instantiation guard exists in the v2.0.25 checker (code diff above) but was not triggered by this shape — trigger shape left open. |

## Reproduce

Each directory: `sh run.sh > output.txt 2>&1`. Sources, C/JS halves,
servers, and captured outputs (with actual exit codes) are retained
alongside. p06's first-run blowup is documented inside its `output.txt`.

## Corrections relative to the reboot-time snapshot

Root's `probe-evidence-review.json` (recovery-20261016T1802Z) describes the
interrupted original outputs and is preserved as accurate for that packet.
This continued session re-ran everything it flagged: P03 (durability family
succeeds on both lanes; exit 2 is the probe's own unlink-after-rename
assertion), P04 (now captured), P06 (now captured, plus the EOF finding),
P09 (all intended assertions now captured: TODO refusal, checkup markers,
reflexivity mismatch, forge), P10 (loader demonstrated), P11 (now
captured), P12 (wrapper-status mismatch fixed; both outcomes captured).
