# Brief — drmTMB REVERSE-parity lane (Claude), 2026-09-01

From: the DRM.jl parity lane (session "DRM.jl2", Shannon/Fable), same day, live.
Mission, in one sentence: **make drmTMB catch up to DRM.jl where the Julia twin is ahead, and
drill the specific drmTMB-side holes the R↔Julia bridge programme is blocked on.**

## First actions (non-negotiable)
1. `~/shinichi-brain/tools/lane_preflight.sh .` in your checkout — name YOUR lane; at least two
   others are live in drmTMB today (this parity lane on `codex/rebase-julia-optimizer-controls`,
   plus codex docs lanes with open PRs #1111/#1110/#1033). Do not touch their files or ours.
2. Read, in order: this file · `docs/dev-log/coordination-board.md` (2026-09-01 entry) ·
   `docs/dev-log/plan/2026-09-01-parity-programme-estimate.md` (the G0–G8 costing) ·
   `docs/dev-log/evidence/julia-r-parity/ayumi-target/2026-09-01-rose-verdict.md`.
3. Work as branch + PR per slice; **no merges to drmTMB main without Shinichi** (lane law), and
   the release fences stand regardless: D-164 holds CRAN; nothing you do implies a release.

## The reverse-parity backlog, ranked by leverage for the twin programme

1. **`start=` warm-start + `objective_at()` in drmTMB()** — the diagnosis layer. Cross-starting
   was impossible during today's #575 forensics (`drm_control()`'s own error says warm-start is
   unimplemented). The Julia half landed today (`reml_objective_at`, branch
   `feat/575-objective-at` in DRM.jl, test-first); the intended R surface is written for you at
   `docs/dev-log/evidence/julia-r-parity/ayumi-target/objective-at-bridge-note.md` (commit
   882b54dfc). Build to that note. TDD: failing testthat first.
2. **Coefficient-naming contract for transformed formula terms** — write the spec page
   (docs/design/) for what `I()`, `factor`, `poly`, crossed-poly, powers, and `scale()` columns
   are CALLED through the bridge, then align drmTMB's emission to it. Receipts: DRM.jl#467
   comment 5501007899 — 6/8 formula-construct parity cells fail on NAMES alone, invisible to CI.
   This is also Ayumi's limitation #4.
3. **A documented "matched comparison" control mode** — a named control set both engines honour
   (the `robust` preset deliberately has no Julia equivalent; that is fine, but "default" needs a
   written contract so cross-engine receipts stop arguing about controls).
4. **Comparable convergence diagnostics** — expose drmTMB's final gradient / convergence state in
   a stable form the bridge's `fit$bridge$diagnostic` can be compared against (Ayumi's
   limitation #6; a G3 gate we currently cannot run).
5. **One native mixed-family bivariate cell** (e.g. gaussian × poisson) — gives the permanently
   "partial" ledger row `cross_family_latent` a real parity route instead of simulation-only.
6. **Export build provenance** — formalise `tools/drmtmb_provenance.R` (DRM.jl#473): "0.7.0"
   spans 16+ shipped-file commits; fixtures need a build anchor, not a version string.
7. Longer arcs (coordinate before starting): missing-response through the bridge route
   (gaussian_response_mask's open gap) · sdreport/pdHess robustification on the cells where
   DRM.jl produces valid CIs and drmTMB's Hessian fails.

## Lane boundaries (ours vs yours)
- OURS (do not claim): DRM.jl#575 optimum fix + q4 promotion gate · the parity scoreboard
  (DRM.jl PR #576) · the Parity Standing artifact · the Ayumi reply drafts (205 gate: draft-only,
  posting blocked) · branch `codex/rebase-julia-optimizer-controls` (PR #1112 — awaiting
  Shinichi's review; do NOT rebase or edit it).
- YOURS: everything in the ranked list above, on fresh `claude/rev-parity-*` branches.
- SHARED LEDGER: `inst/extdata/julia-capabilities.tsv` is the joint claim registry — edit only
  with a receipt, never hand-type counts, and diff `docs/dev-log/coordination-board.md` before
  appending (it has unshared versions on several refs).

## Discipline carried over
Evidence before claims (every "fixed" needs a retained receipt) · TDD on every slice · local
checks over CI · D-139: estimate before any run, >30 min needs a pre-run gate · after-task +
check-log per slice · Rose audit before anything user-facing.

Questions to this lane: message the session named `DRM.jl2` (ListAgents → SendMessage).
