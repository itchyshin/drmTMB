# After Task: A8c -- gaussian_response_mask convergence flag and bootstrap (DRM.jl #646)

## 1. Goal

Root-cause and fix the two defects A8 found on the `gaussian_response_mask`
route through `engine = "julia"`: `is_converged()` reading FALSE on a fit whose
coefficients and profile interval match `engine = "tmb"` to ~7e-06, and
`confint(method = "bootstrap", R = 99)` failing all 99 replicates where the TMB
engine fails 0.

## 2. Implemented

Both defects were DRM.jl's, not the bridge's, and are fixed in
`claude/parity-a8c-response-mask-drmjl` (DRM.jl PR, opened first):

1. `_nondegenerate_fit` (`src/summary.jl`) computed its scale-free degeneracy
   bar as `std(fit.obs[:mu])`. The missing-response routes deliberately keep the
   FULL-design response there, NaN in the masked rows, so `yscale` was NaN and
   `smax > 1e-6 * max(NaN, eps)` was false for every `smax` under IEEE-754. The
   bar now uses the observed (finite) entries only.
2. `_simulate_once` (`src/gaussian_core.jl`) drew `randn(rng, fit.nobs)` -- the
   likelihood row count, 54 -- against the length-60 `means`/`scales` that
   `_with_full_fixed_gaussian_rows` rebuilds over the full design. Draws are now
   per row of the design.
3. Found while fixing those: both full-row rebuilders used the 19-argument
   compatibility constructor, silently resetting `iterations` to -1 and dropping
   the MAP penalty slots. Both now pass all 22 fields.

On the drmTMB side the bridge was NOT at fault -- `R/julia-bridge.R` faithfully
mirrored the Bool DRM.jl sent. The one bridge change is the `opt` slot: a new
`drm_julia_opt_slot()` replaces `list(convergence = <0/1>)` at both Julia-fit
construction sites, adding `iterations` (`NA_integer_` when the route records
none -- never 0) and a `message`.

## 3. Mathematical Contract

No likelihood, parameterization, estimator, or formula grammar changed. The
masked route still fits the observed rows and still reports `nobs = 54`; the
fitted `theta` is bit-identical before and after the fix (max abs diff 0.0).
`fit.nobs` was deliberately NOT changed to 60 -- it is the semantically correct
observed count for `dof_residual`, AIC and BIC, and only the simulator's draw
length was wrong.

## 3a. Decisions and Rejected Alternatives

**Draw length vs re-masking.** A parametric bootstrap of a masked fit could
either draw a full-design response (refit on 60 rows) or draw and then re-apply
the mask (refit on 54). MEASURED what `engine = "tmb"` already does on this
fixture: `simulate()` returns 60 rows with 0 NA, `bootstrap_response_data()`
returns 60 rows with 0 NA, and the replicate refit reports `nobs = 60`. The
reference engine does not preserve the mask, so matching it is what parity
means here; re-masking would have made the engines disagree. Rejected.

BOUNDARY, stated rather than silently "improved": because replicates refit on
60 rows while the original fit used 54, a parametric bootstrap interval on a
masked fit is slightly narrower than a mask-preserving one. That is pre-existing
and shared by both engines. Changing it is a cross-engine design decision, not a
parity fix, and is out of this leaf's scope.

**`opt$message`.** DRM.jl sends no optimiser message string. Rather than
fabricate an Optim.jl message, the helper composes one from the two facts that
did cross the bridge (`converged`, `iterations`) and says so in its comment.

## 4. Files Touched

DRM.jl (`claude/parity-a8c-response-mask-drmjl`):
- `src/summary.jl`, `src/gaussian_core.jl`
- `test/test_bridge_response_mask_inference.jl` (new), `test/runtests.jl`
- `NEWS.md`

drmTMB (`claude/parity-a8c-response-mask`):
- `R/julia-bridge.R` (`drm_julia_opt_slot()` + both call sites)
- `tests/testthat/test-julia-missing.R`
- `docs/dev-log/evidence/julia-r-parity/p2-g3/a8c-root-cause-receipt.md`,
  `a8c-g3-requalification-receipt.md`, `a8c-g3-qualification.tsv`
- `NEWS.md`, this report

## 5. Measurements (D-139)

All measured in this run; full tables in
`docs/dev-log/evidence/julia-r-parity/p2-g3/a8c-root-cause-receipt.md`.

Masked fit vs the complete-case fit on the same 54 rows:

| quantity | masked | complete-case |
| --- | --- | --- |
| `Optim.converged` | true | true |
| `is_converged` (at the pin) | **false** | true |
| `theta` | identical, max abs diff 0.0 | -- |
| `|grad|inf` (`g_tol` 1e-8) | 6.412634312447096e-12 | same |
| `yscale = std(obs[:mu])` | **NaN** | 0.9929619129086243 |
| `niterations` (at the pin) | **-1** | 7 |

Verdict: a wrong return-code mapping. Not a loose tolerance, not a genuine
near-miss, and not a hard optimisation surface.

Bootstrap: `DRM.simulate(fit)` threw
`DimensionMismatch ... lengths 60 and 54` on one replicate, deterministically,
so `used = 0` and `_bootstrap_result` raised "all B ... failed".

Re-qualification after the fix (`tools/parity-p2-pilot.R --g3-qualify`),
`gaussian_response_mask`, target `fixef:mu:x`:

```
converged: tmb=TRUE julia=TRUE; julia estimator=ML  (== fj$bridge$estim_method)
wald      delta = [7.85573e-08, 7.85425e-08]        (< 1e-6)
profile   delta = [5.1288e-06, 7.17584e-06]         PASS(tol=1e-4)
bootstrap R=99: tmb failed=0/99, julia failed=0/99, OVERLAP=TRUE (not same-seed)
```

The other two qualifiable routes reproduce A8's numbers exactly, so the fix
moved this route and nothing else.

Timing: the qualification mode's committed estimate was ~20 min; it ran in
~1 min. No step exceeded its estimate.

## 6. Tests of the Tests (RED CONTROLS)

DRM.jl, per hunk, reverted alone and restored byte-identically
(`src/summary.jl` sha256 `14a4bcf3...b69d47a6`, `src/gaussian_core.jl` sha256
`216e1716...21b821d0` before and after):

| reverted | result |
| --- | --- |
| `_nondegenerate_fit` NaN guard | FAIL `_nondegenerate_fit`, `is_converged` (19/2) |
| `_simulate_once` draw length | ERROR `DimensionMismatch ... 60 and 54` (13/1) |
| 22-arg constructor | FAIL `niterations` x2 (19/2) |

Each hunk is load-bearing and guards distinct assertions. Fixed: 21/21.

drmTMB:
- the new block against the UNFIXED pin FAILS with `all 19 bootstrap replicates
  failed` and the same Julia stack;
- with the fixture de-masked it PASSES against the UNFIXED pin, confirming the
  assertions bite only on the masked route. Planted and restored
  byte-identically (sha256 `862fcb6b...a7a32cf8a`). The block keeps
  `expect_equal(res$n_missing, 6L)` so the fixture cannot be silently de-masked.

## 7a. Issue Ledger

- DRM.jl #646 -- fixed by the DRM.jl PR; referenced by both PRs.
- drmTMB A8 (#1184) -- this leaf clears the two blockers its receipt recorded.

## 8. Consistency Audit

- `tools/capability_ledger.py --check`: `OK (31 generated outputs)`.
- `tools/validate-mission-control.py`: 33 lines, **0 new** vs clean
  `origin/main` (`wt-main-probe`, `git pull --ff-only` in this run).
- No capability TSV, `docs/design/261`, or dashboard copy changed, so nothing
  needed regenerating.

## 9. What Did Not Go Smoothly

- The worktree was 6 commits behind `origin/main` and lacked
  `tools/write-reml-route-table.R` and `docs/design/261`; fast-forwarded.
- `--g3-qualify` does not exist on `origin/main` -- it is A8's, on the unmerged
  `claude/parity-a8`. The qualification was run from A8's script extracted to a
  scratch file, so A8's `tools/parity-p2-pilot.R` is NOT duplicated into this
  branch (it would conflict with #1184).
- The DRM.jl worktree needed `Pkg.instantiate()` before its tests would run.

## 10. Known Residuals

- **Promotion NOT done (G7 abandoned).** Moving `gaussian_response_mask`
  `partial -> supported` requires editing the `wave1_promoted` guard in
  `tests/testthat/test-julia-gate-vs-engine.R`, which is not in this leaf's
  OWNS list, and #1184 is concurrently rewriting both that guard and this row's
  `claim_boundary`. Promoting from this base would rewrite text that does not
  exist here and would conflict with #1184 on an unowned file. Follow-up, on
  top of #1184: move `"gaussian_response_mask"` from `wave1_still_partial` to
  `wave1_g3_qualified`, set `r_bridge_status` to `supported` in
  `drm_julia_capability_comparison()` and both TSVs, and rewrite that row's
  `claim_boundary` to cite the two receipts here and DRM.jl #646.
- Pre-existing DRM.jl failures, unrelated and NOT fixed here (identical on the
  clean worktree with the fix stashed): `test_bootstrap_marginal.jl`
  (`res.failed == 0` evaluates `1 == 0`; `res.used == 60` evaluates `59 == 60`)
  and `test_lss_missing_response.jl` (`Package StableRNGs not found`).
- `R/check.R:392` prefixes the optimizer message with "nlminb convergence
  message:", which is wrong for a Julia fit. Pre-existing and unowned; now more
  visible because `opt$message` is no longer empty.

## 11. Team Learning

A route can be numerically perfect and still be unusable. The point estimates
here matched the reference engine to 7e-06 while both convergence reporting and
the entire bootstrap were broken. Qualifying a route on coefficients alone would
have promoted it. The specific trap is worth remembering: `std()` of a
NaN-carrying vector is NaN, and **every** comparison against NaN is false, so a
guard written as `x > bar` fails OPEN into "reject everything" rather than
erroring. A second: keeping `nobs` and per-row vector lengths deliberately
different inside one object is a live hazard for every consumer that treats them
as interchangeable.

## 12. Cross-Product Coverage

The same `_simulate_once` fix covers the non-Gaussian missing-response
rebuilder (`_with_full_response_rows`), which had the identical `nobs`/length
pairing and the identical dropped-`iterations` defect. Not separately qualified
here -- see Not covered.

## Not covered

- The sigma-phylo and mean-phylo missing-response routes were not re-qualified;
  only `test_gaussian_phylo_mean_missing_response.jl` (45 assertions) was run
  and passes.
- The non-Gaussian missing-response route inherits both fixes structurally but
  has no bootstrap qualification receipt here.
- Bootstrap intervals are reported OVERLAP-ONLY; the engines use independent RNG
  streams, so no same-seed numerical claim is made.
- No interval-coverage claim. This is pipeline and parity qualification only.
- The full DRM.jl suite was not run -- a 21-file blast-radius subset was.
- The full drmTMB `R CMD check` was not run; `filter = "julia"` (1304 pass) and
  a live subset (413 pass) were.
