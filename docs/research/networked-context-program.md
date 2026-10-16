# Networked infinite context: research program

This document consolidates the networked-context research into a program: the verdict, the
five missing primitives with their prior-art-supported candidate designs, the experimental
ladder, and the open design questions. Inputs:

- The evaluation: [context-networking.md](context-networking.md) — verdicts on the two posed
  compositions, the five missing primitives, the load-bearing risks.
- Prior art on addressing and authority: [addressing-and-authority.md](addressing-and-authority.md).
- Prior art on deref budgeting and passivation consistency:
  [deref-and-consistency.md](deref-and-consistency.md).
- The substrate: baton's REPL layer (content-addressed cells `cell:<sha256>`, version-CAS
  bindings with per-scope fences, `repl:<scope>:<name>@<version>` citations, principal-pinned
  `ReplManifest`, server-minted non-transferable grants, one-attachment wake plane), analyzed
  at HEAD `1e050e420` and filed as [baton#777](https://github.com/Flip-Engineering/baton/issues/777)
  for the first primitive.

## The verdict, restated

Native context passing (hypothesis 1) is coherent under the weak reading — transfer with the
transcript body left out of the message envelope — and the missing substrate is what baton's
REPL layer provides: versioned, content-addressed bindings with principal-pinned admission and
a citation grammar. Live-context dereference across processes (the strong reading) is a
category error against every primary system's recorded decisions: what crosses a process
boundary is always a value with a reference-shaped address. Networked infinite context
(hypothesis 2) is buildable from parts that all exist; "infinite" accrues to the addressable
store (append-only ledgers, content-addressed cells), while each participant's effective
context stays a budgeted function of commit, deref, and authority boundaries.

## The five primitives

### 1. Cross-session addressing

Git supplies the isomorphism: cells ≡ blobs, bindings ≡ refs, citations ≡ tags
([addressing-and-authority.md](addressing-and-authority.md) §2.1, stated point by point). What
the isomorphism exposes is what a cross-run design must add deliberately: Git's refs are
unauthenticated (baton's binding digests already differ, in the right direction), and Git has
no reachability rule for objects cited across repositories — baton needs an explicit
reachability rule for cells cited across runs (what keeps a cited cell alive when its owning
run's retention policy would reclaim it). Datomic's as-of reads and immutable database values
are the prior art for version-pinned citations across lanes; its delta — no cross-lane
snapshot — is exactly the primitive baton must define. Design questions: run-scoped grant
versus deployment-scoped namespace for the citation grammar; whether cross-run citations
re-pin (copy-forward the cited version into the reader's run) or resolve live through the
orchestrator.

### 2. Read grants

The capability record gives the grant shape and its honest limits. seL4's mint operation with
the capability derivation tree provides attenuation-only derivation, recorded lineage, and
one-operation subtree revocation — the exact shape for extending baton's closed `claimGrant`
into a revocable, derivable grant record. The caveat the literature states plainly:
capabilities deliver attenuation and revocation but never non-transferability — confinement is
a separate, harder property that comes from server-side minting plus channel binding.
Macaroons are the only prior art that makes a bearer-shaped grant safe enough to hand to
another session: chained HMACs with first-party caveats (run, binding, version bound, byte
budget, expiry) evaluated by the enforcing orchestrator at deref time, third-party discharge
for delegated validation, and four revocation strategies whose ledger-seq cursor and scope
fences are baton's equivalents of external authoritative state. Design questions: per-deref
grants versus per-scope leases; revocation versus version pinning (the pinned read still
succeeds after revocation — decide whether that is intended).

### 3. Deref read budgets

Byte-denominated, enforced at projection time by the orchestrator. The calibration mechanisms
every analyzed harness uses (NOOA's provider-calibrated chars-to-tokens EMA, fx's
`request_token_calibration`) need a completed provider response, and a dereference between
calls has none — so exact bytes plus a post-hoc token estimate is the only enforceable
combination ([deref-and-consistency.md](deref-and-consistency.md) §1.3). Accounting needs
three keys together: per-seat (token-bucket lineage, RFC 2697/2698), per-citation, and
per-scope aggregate, with Prime's child-usage-folded-into-parent transcript row as the
attribution precedent. The search-state posture (below) refines this: when the committed store
is treated as a population under idea-operators, arbitrary dereferences become ranked reads of
a frontier, and the budget question changes from "how many bytes" to "which ranked slice" —
which also gives commit-time loss a selection-driven policy.

### 4. Passivation consistency

MVCC is the read semantics, not new machinery: Reed's 1978 snapshot reads and Berenson's
snapshot isolation map directly onto baton's binding history plus version-pinned citations,
and pi-durable's "only committed state is observable" is the in-corpus precedent. For a
mid-turn read — the one state baton's turn-boundary instincts do not yet answer — the
recommended answer is serve last-committed with the version marked in the deref receipt;
queued-to-boundary and typed-reject both couple the reader to the owner's turn lifecycle. The
residual design item: whether the receipt marks a committed version (clean) or a
last-committed-so-far version mid-turn (dirty read, named as such). Crash consistency takes
the durable-execution record (Temporal's event-history replay, Azure Durable Task, Unreal
Agent's exactly-once journal) as the reference, and Prime's passivation/adoption with the
daemon-owned spawn ledger is the closest in-set mechanism.

### 5. Shared live context

Ruled out, with the failure record behind the ruling: distributed shared memory's coherence
traffic (Li & Hudak) and false sharing (Eggers & Katz) reappear as KV-cache invalidation
driven by the scope fence on every commit — the fence IS the coherence protocol. Three
alternatives are consistent with baton's recorded non-goals, ranked by cost: the append-only
shared ledger (each seat appends, nobody mutates — a pure namespace-and-grant extension over
already-immutable versioned cells, and the knowledge-graph pattern baton already runs) is the
lowest-cost consistent extension; shared derived artifacts (converged summaries committed as
new cells) add a lossy commit-time boundary; orchestrator-arbitrated commit (the blackboard
scheduler's role, Hearsay-II lineage) adds a serialization point. Whole-transcript convergence
via CRDT/OT applies to convergent objects, not to session contexts.

## The experimental ladder

1. **E1 — commit-and-cite (H1 prototype, per baton#777).** A seat commits its context-as-variable
   as cells into its `worker:<id>` layer at turn boundaries under a declared snapshot schema;
   briefs and reports carry `repl:` citations; the orchestrator promotes one committed version
   to `shared` by rebind. Two-seat task where seat B's work requires seat A's intermediate
   state. Measure: token cost against an inline-transcript baseline; prefix-cache behavior on
   the receiving seat.
2. **E2 — one navigation path.** Extend E1 with seat B dereferencing a binding in seat A's
   layer through an orchestrator-mediated read, authorized by a server-minted,
   non-transferable grant, under a declared per-dereference byte budget, appended at B's
   context tail. Task classes where B's answer requires A's committed state, against a
   re-derivation baseline (B recomputes A's work).
3. **E3 — the measurement campaign.** Per [deref-and-consistency.md](deref-and-consistency.md)
   §4 and the [benchmarks.md](benchmarks.md) methodology: task-class matrix (deref wins /
   re-derivation wins), metrics (tokens, wall-clock, dependent-task correctness, cache
   behavior), failure injection (lost artifact, stale version, revoked grant, mid-turn deref),
   and the log fields required for the evidence to be publishable.

## What the program needs from baton

In the order the ladder needs it: the #777 build items (seat-side commit path, snapshot
content convention, receiver projection, cross-seat read authorization); then the grant record
(mint/derive/revoke per seL4's shape, caveats per macaroons), the deref budget accounting
(three keys), the mid-turn read decision, and the reachability rule for cross-run cited cells.
The append-only shared ledger needs only namespace and grants over existing cells.

## Open questions

- Grant shape: per-dereference grants versus per-scope leases; revocation semantics versus
  version pinning.
- Namespace: run-scoped grants versus a deployment-scoped context namespace; which preserves
  the run-locality instincts docs/33 records.
- Cross-lane consistency: whether a reader's projection cache may survive a rebind of a cited
  scope (fence-keyed invalidation is the current behavior).
- Non-transferability: channel binding versus bearer-with-caveats; what the discharge path is
  when the orchestrator itself is the only verifier.
- Measurement: the deref-versus-re-derivation task matrix is unwritten; no published evidence
  exists for any of these mechanisms under load.