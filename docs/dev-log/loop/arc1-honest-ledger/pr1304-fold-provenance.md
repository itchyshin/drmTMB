# PR-D: folding itchyshin/drmTMB#1304's FOLD-NOW evidence (provenance note)

Author: Hopper, working the PR-D slice of Arc 1 (drmTMB R-Julia parity). This note lives on branch
`claude/arc1-pr1304-fold`, branched fresh from `origin/main` at `7df6631fc`. It carries out the fold
plan written earlier at `docs/dev-log/loop/arc1-honest-ledger/pr1304-absorption.md` (in the
`drmTMB-arc1-honest-ledger` worktree). #1304's own branch, `codex/071-ordinary-laplace-bridge`, was
read only (fetched with `git fetch`, read with `git show`), never checked out or edited. Nothing on
GitHub was touched. This branch is not committed here; the conductor commits it.

Every file below that is genuinely new evidence was measured against DRM.jl (DRModels)
`b2caf00f23f080fe89028966a4bfb098ef095510` (short `b2caf00f`), with drmTMB frozen at `453cff782` for
the campaign run. Nothing here is relabelled to the current pin
`da8b3f8711beb5ef3186b890544c2e7850c7f194`; that pin is not mentioned anywhere in the folded material
because none of it was measured there.

## 1. What was folded (file by file)

All paths are exactly as they land in this worktree. "#1304 commit(s)" lists the commits, oldest
first, that introduced or last touched that file on `codex/071-ordinary-laplace-bridge` (found with
`git log <merge-base>..codex/071-ordinary-laplace-bridge -- <path>`, merge-base
`1ae582c9fc9060071bb147ea4aa7206744392419`).

### The 071-ordinary-laplace evidence directory (26 files copied verbatim)

| Path | #1304 commit(s) | DRModels SHA |
|---|---|---|
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/four-fixture-contract.md` | `d51ced6c0`, `a03e3ad96`, `925ace233`, `9abb2d0f0`, `e46c2d700`, `90051c6ea`, `79d766431`, `fcf925e93`, `6f1d49d46`, `0285af445` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/cost-probe.md` | `704e2fe25` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconciled-summary.tsv` | `29773fb5d` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-coverage-summary.tsv` | `30dcb9103` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-coverage-summary.tsv.sha256` | `30dcb9103` | b2caf00f (checksum of the row above; brought along even though the fold gate's path pattern does not require a `.tsv.sha256` extension, since a checksum without its data file is useless) |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconcile-four-fixture-receipt.R` | `e58a28273`, `0094a19a6`, `627805ae1`, `90051c6ea`, `340a60c5f`, `e9eae1473` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/reconcile-four-fixture-summary.R` | `9939ace07` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/run-four-fixture-receipt.R` | `a03e3ad96`, `e58a28273`, `3efd65083`, `4ae31d5d5`, `c65355508`, `0094a19a6`, `627805ae1`, `925ace233`, `90051c6ea`, `e9eae1473`, `64c3c1fc7` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/verify-source-commit.sh` | `fcf925e93`, `d63d98387`, `0285af445` | b2caf00f (generic proof, needs no pin itself) |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/test-source-commit-proof.sh` | `fcf925e93`, `0285af445` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/prepare-s7-campaign-bundle.R` | `c2d9917f3` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/prepare-s7-campaign-manifest.R` | `07c50af0b` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-attempt-contract.R` | `0972c8670`, `c2d9917f3` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-campaign-fixture.R` | `f9a40fa60`, `46ec8a1ac`, `19d20ef1b` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-array.sh` | `d49b2b9fc` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-preflight.sh` | `a113cf029`, `e1f672db8` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-reconcile.sh` | `9a0f66297`, `854d6381c`, `0285af445` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fir-worker.sh` | `9c7ee1c47`, `947edd2f4`, `7317e1671` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fit-attempt.R` | `98113e7c4` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-fit-diagnostics.R` | `95469aac8` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-live-fit-factory.R` | `568056fbc`, `19d20ef1b` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-reconcile-campaign.R` | `621891c51`, `453cff782` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-run-attempt.R` | `952446b68`, `f7426669a` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-run-task.R` | `e474864bd`, `95469aac8`, `98113e7c4`, `568056fbc`, `947edd2f4` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-task-dispatch.R` | `568056fbc` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-write-coverage-summary-scopefix.R` | `30dcb9103` | b2caf00f |
| `docs/dev-log/evidence/julia-r-parity/071-ordinary-laplace/s7-write-coverage-summary.R` | `ade8aea08`, `9a0f66297`, `854d6381c`, `0285af445` | b2caf00f |

That is 27 files (the table above lists 26 rows; `test-source-commit-proof.sh` and
`verify-source-commit.sh` are each their own row, so the full set is: four-fixture-contract.md,
cost-probe.md, reconciled-summary.tsv, s7-coverage-summary.tsv, s7-coverage-summary.tsv.sha256,
reconcile-four-fixture-receipt.R, reconcile-four-fixture-summary.R, run-four-fixture-receipt.R,
verify-source-commit.sh, test-source-commit-proof.sh, prepare-s7-campaign-bundle.R,
prepare-s7-campaign-manifest.R, s7-attempt-contract.R, s7-campaign-fixture.R, s7-fir-array.sh,
s7-fir-preflight.sh, s7-fir-reconcile.sh, s7-fir-worker.sh, s7-fit-attempt.R, s7-fit-diagnostics.R,
s7-live-fit-factory.R, s7-reconcile-campaign.R, s7-run-attempt.R, s7-run-task.R, s7-task-dispatch.R,
s7-write-coverage-summary-scopefix.R, s7-write-coverage-summary.R). Two files needed their
executable bit restored after copying (`git show <ref>:<path> > <path>` writes plain content and
drops the mode): `test-source-commit-proof.sh` and `verify-source-commit.sh` were `100755` on
#1304 and are `chmod +x` here to match. The other four `.sh` files were `100644` on #1304 itself
(they are only ever invoked through `bash <script>` in both the test suite and Slurm, never executed
directly), so they keep their original mode.

### Check-log and after-task entries (9 files copied verbatim, dates unchanged)

| Path | #1304 commit(s) |
|---|---|
| `docs/dev-log/after-task/2026-09-12-071-source-subset-proof-reconciliation.md` | `0285af445` |
| `docs/dev-log/check-log.d/2026-09-09-071-native-profile-thread-control.md` | `64c3c1fc7` |
| `docs/dev-log/check-log.d/2026-09-09-071-nb2-free-target-manifest.md` | `e9eae1473` |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-current-pin-boundary.md` | `e46c2d700` |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-summary-gate.md` | `9939ace07` |
| `docs/dev-log/check-log.d/2026-09-09-071-ordinary-laplace-task-provenance.md` | `90051c6ea`, `340a60c5f` |
| `docs/dev-log/check-log.d/2026-09-11-071-ordinary-laplace-active-campaign-pins.md` | `148baeb98` |
| `docs/dev-log/check-log.d/2026-09-11-071-source-commit-proof.md` | `fcf925e93` |
| `docs/dev-log/check-log.d/2026-09-12-071-source-subset-proof-reconciliation.md` | `0285af445` |

### The folded test (adapted, not copied byte for byte)

`tests/testthat/test-071-four-fixture-summary.R` is folded from #1304 commits `9939ace07`,
`9519f9ff2`, `07c50af0b`, `f9a40fa60`, `0972c8670`, `952446b68`, `f7426669a`, `c2d9917f3`,
`e474864bd`, `95469aac8`, `98113e7c4`, `568056fbc`, `9c7ee1c47`, `947edd2f4`, `7317e1671`,
`a113cf029`, `621891c51`, `46ec8a1ac`, `d49b2b9fc`, `e1f672db8`, `19d20ef1b`, `764ceaf9b`,
`ade8aea08`, `217f5bcdf`, `9a0f66297`, `854d6381c`, `ddf16873e`, `fcf925e93`, `453cff782`,
`30dcb9103`, `0285af445`, `0dfbbbb31`, `9e959fc8a`, measured at DRModels b2caf00f. It is not a
byte-for-byte copy. Three adaptations were made, all on the test side, none touching R/ or src/:

1. **Nine of the original 38 `test_that()` blocks are not folded**, because they exercise code this
   Arc 1 fold deliberately does not port (see "what was left out" below). Running them here, with
   today's `origin/main`, would fail them for reasons that have nothing to do with whether the
   FOLD-NOW evidence itself is sound. Their titles are recorded in a comment at the top of the file
   and repeated below for a single point of truth. The remaining 29 blocks are unchanged from
   #1304's text.
2. The shared helper `r071_skip_unless_source_tree()` now attaches the `drmTMB` package
   (`library(drmTMB)`, guarded so it is a no-op if already attached) before its skip check. #1304's
   suite ran under `devtools::test()`, which attaches the package under test automatically before any
   test file runs; running this file standalone with `testthat::test_file()` (as this fold's G4 gate
   does) does not do that automatically, and one block (`S7 campaign fixture factory is deterministic
   and preserves scalar-RI shapes`) calls a helper that in turn calls `bf()`, which is only defined
   once drmTMB is attached. This is a plain `library()` call, not a change to R/ or to drmTMB's own
   behaviour.
3. `inst/extdata/env-skip-census.tsv` was regenerated (not hand-edited) with
   `Rscript --no-init-file tools/write-env-skip-census.R` after the test file above was in place. It
   now carries one new row, `test-071-four-fixture-summary.R  build-premise  build  skips  1`.
   #1304's own version of this census carried two new rows for this file (`build-premise` and
   `engine-drm-jl`); the second row came from the `DRM_JL_PATH`-gated skip inside one of the two
   `test_that()` blocks this fold leaves out ("scoreboard requires materialized S7 evidence before
   current ordinary-Laplace rendering"). Since that block is not folded, its skip site is gone, and
   the regenerated census correctly has one row instead of two. This is the generator working
   correctly on the file actually present, not a discrepancy to fix.

Verification: `Rscript --no-init-file -e 'r <- as.data.frame(testthat::test_file("tests/testthat/test-071-four-fixture-summary.R", reporter="silent")); stopifnot(sum(r$failed)==0, !any(r$error), sum(r$passed) >= 1); cat("PRD-G4-OK", sum(r$passed), "\n")'`
(the exact G4 gate command) prints `PRD-G4-OK 182` in a fresh R session with no other setup beyond
the one-time `pkgload::load_all(recompile=TRUE)` build already on disk.

## 2. What was left out, and why

- **`docs/dev-log/after-task/2026-09-12-071-ordinary-laplace-closeout.md`** is not folded. The
  absorption note tags this file ARC-2 (its "Implemented" section is the two new capability-registry
  rows and the `marginal=`-keyed rendering, not the GHQ-32 finding itself), and Arc 1 does not widen
  coverage. It is left out.
- **`tools/write-parity-scoreboard.R`** is not touched here. #1304's patch to it adds
  `sb_ordinary_laplace_summary()`, `sb_ordinary_laplace_source_drift()`,
  `sb_ordinary_laplace_s7_collectors()`, `sb_ordinary_laplace_s7_aggregate()`, and related
  functions, all keyed to the two new (Arc 2) capability rows. Arc 1's own S1a/S1b slices are
  rewriting this generator's honest-state logic from scratch; the fail-closed
  reader/staleness-check pattern in #1304's version (read a frozen summary TSV, refuse to render
  it if the source has drifted on a protected path) is worth reusing, but as a pattern to
  reimplement against whichever `capability_id` Arc 1's own ledger assigns, not as code to copy
  here. It is adopted in Arc 1 PR-A, not copied in PR-D.
- **`tools/source-tree-tests.txt`** is not touched here. It needs exactly one added line
  (`test-071-four-fixture-summary.R`) once this test lands on `main`, generated by
  `tools/run-source-tree-tests.R --update`, not by hand. That file is outside this slice's OWNS list
  (`leaf-PRD.md` scopes this worktree to the evidence directory, the test, the check-log and
  after-task entries, and the env-skip census) and is left for whichever slice regenerates it next
  (most likely alongside PR-A or PR-B, when the honesty-gate tooling changes touch the same
  generated-file family). #1304's own version of this file also dropped two lines
  (`test-dinnage-audit-wave1.R`, `test-pkgdown-public-surface.R`) that still exist on `origin/main`
  today; that part of #1304's patch was already stale and would not be picked up even if this file
  were in scope here.
- The nine `test_that()` blocks removed from `test-071-four-fixture-summary.R` (eight for Arc-2
  dependencies, one more found only by actually running the suite):
  - "the scoreboard has a distinct ordinary-Laplace classification path"
  - "ordinary-Laplace coverage rows are emitted from the capability registry"
  - "S7 coverage accepts only the declared original writer or scope-fix collector"
  - "ordinary-Laplace summary rejects a semantic successor commit"
  - "ordinary-Laplace source-drift guard rejects semantic input changes"
  - "scoreboard requires materialized S7 evidence before current ordinary-Laplace rendering"
  - "scoreboard renders ordinary-Laplace source provenance after S7 materialization"
  - "scoreboard keeps S7 coverage outside the generic receipt tier"

    These eight all source `tools/write-parity-scoreboard.R` and call one of the
    `sb_ordinary_laplace_*()` functions just described, or call
    `drmTMB:::drm_julia_capability_comparison()` and expect the two new (Arc 2) rows to be present.
    Running them against today's `main`, unmodified, fails them for a reason that has nothing to do
    with whether the underlying evidence is sound: the functions and rows they need are Arc 2, not
    ported here.
  - "S7 source-pinned install declares its compiled TMB shared object"

    This one checks that `DESCRIPTION` declares `NeedsCompilation: yes`. `origin/main`'s `DESCRIPTION`
    does not carry that field at all (confirmed: `grep NeedsCompilation DESCRIPTION` finds nothing),
    so the check would fail with `NA` where it expects `"yes"`. The commit that added this field,
    `764ceaf9b`, is tagged ARC-2 in the absorption note (declaring compiled-object metadata tied to
    the new coupled-NB2 C++ code), and this fold does not touch `DESCRIPTION`. Removed for the same
    reason as the eight above: the fix it depends on is out of scope here, not because the check
    itself is wrong.

## 3. What went to the Arc 2 list

Unchanged from the absorption note; repeated here for a single point of truth in this branch:

- A public `marginal = "Laplace"` argument on `drmTMB()` for `engine = "julia"` (`R/drmTMB.R`,
  `R/julia-bridge.R`). Provenance: #1304, commits `a03e3ad96`, `46ec8a1ac`, `19d20ef1b`.
- A native (TMB) coupled NB2 `mu`/`sigma` labelled random-intercept pair (`src/drmTMB.cpp`,
  `R/drmTMB.R`). Provenance: #1304, commit `6bb773332`.
- The native coupled-Cholesky profiling path for that route (`R/profile.R`). Provenance: #1304,
  commit `4ae31d5d5`.
- The two new `julia-capabilities.tsv` rows, `ordinary_ri_scalar_laplace` and
  `ordinary_nb2_coupled_laplace`. Provenance: #1304, commit `0285af445`.
- Design, vignette, and man-page coverage of the above. Provenance: #1304, commits `0285af445`,
  `0dfbbbb31`, `0581bc877`.
- Tests for the above (`test-julia-bridge.R`, `test-julia-bridge-coef-labels.R`,
  `test-nbinom2-location-scale.R`), plus the `DESCRIPTION` `NeedsCompilation` declaration.
  Provenance: #1304, commits `a03e3ad96`, `4ab0486eb`, `764ceaf9b`.
- `tools/write-parity-scoreboard.R`'s `sb_ordinary_laplace_*()` reader/staleness-check pattern,
  adopted (not copied) in Arc 1 PR-A against whichever capability_id Arc 1's own ledger uses.

## 4. Draft comment for #1304 (NOT posted; only after Shinichi says yes)

> Thanks for this. Arc 1 of the R-Julia parity programme read through this PR in detail while
> auditing the parity ledger for honesty, and has now folded the reusable part of it into a fresh
> branch.
>
> The finding that DRModels' default ordinary random-intercept route reports GHQ-32 integration, not
> Laplace, for a scalar mu-only (1 | g) Binomial, Poisson, or NB2 random intercept is genuinely new
> and useful, and it describes a route the bridge can already reach. The four-fixture campaign
> evidence for that, the reconciliation and coverage-summary tooling that produced it, and the source
> subset verifier that checks a staged campaign archive against its declared Git commit, are folded
> onto a new branch with full provenance back to this PR's commits and the DRM.jl pin they were
> measured at (b2caf00f).
>
> The new `marginal = "Laplace"` argument, the coupled NB2 mean-scale random-intercept route, and the
> two new ledger rows they introduce are new public API and new coverage. Arc 1 is deliberately
> scoped to making the existing ledger honest before any coverage widens, so that part moves to a
> separate follow-up arc rather than landing here. It is listed in full, with this PR named as its
> source, so nothing is silently dropped.
>
> This PR itself is not being merged, edited, or closed as part of that work. Thank you for the
> careful, source-pinned evidence trail, it made folding the useful part straightforward.
