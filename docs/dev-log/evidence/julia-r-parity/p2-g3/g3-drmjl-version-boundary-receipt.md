# G3 for `gaussian_response_mask`: qualification and its DRM.jl version floor

Measured 2026-09-05 by leaf `g3-profile-inference`, branch
`claude/parity-g3-profile-inference`. **Every number below was produced in
this run**, by `tools/parity-p2-pilot.R`, and none is carried over from an
earlier receipt. Where a number happens to reproduce A8/A8c's, that is stated
as a reproduction, not a citation.

## What this receipt settles

Leaf A8 attempted G3 on four rows and promoted two
(`base_gaussian_location_scale`, `plain_binomial_nonphylo`). It was blocked on
`gaussian_response_mask` by two findings, which leaf A8c root-caused to two
DRM.jl defects and fixed as DRM.jl#646 (merged as DRM.jl#648). A8c explicitly
did NOT perform the ledger promotion and handed it on.

**This leaf performs that promotion**, having re-measured the route
independently and having measured the version boundary the promotion depends
on. It also re-confirms, live, that `biv_gaussian_residual` remains
structurally unqualifiable, and leaves that row alone.

## Setup

| | |
|---|---|
| drmTMB source | `pkgload::load_all()` of this worktree (never `library(drmTMB)`) |
| DRM.jl GREEN | worktree of `origin/main` at `84120ff7403c5b2582a8ce0e3b81ec54f0649022` |
| DRM.jl RED (pin) | `430ef64ccca5642c5abebd72194e00895314dfc2` -- the programme pin, which PREDATES #646 |
| env | `OPENBLAS_NUM_THREADS=1 JULIA_NUM_THREADS=1 NOT_CRAN=true DRMTMB_JULIA_TESTS=true` |
| fixtures | byte-identical at both commits (`cmp` on all three `test/parity/fixtures/*/data.csv`) |

Both DRM.jl commits already contain #631 and #633, so the profile-endpoint
numbers below are post-#631 and no pre-#631 interval number is reused.

## D-139 time accounting

| cell | estimate stated before running | actual |
|---|---|---|
| build the GREEN DRM.jl checkout | 8 min | 7 s (deps already in the shared depot) |
| `--g3-qualify` GREEN | 20 min (the committed manifest budget) | 1 min 36 s |
| `--g3-qualify` RED at the pin | 4 min | 56 s |
| `--g3-mask-boundary` sweep | 8 min | 50 s |

No cell approached the 30-minute ceiling and none overran its estimate.

## 1. GREEN -- `--g3-qualify` against DRM.jl main `84120ff74`

`gaussian_response_mask`, target `fixef:mu:x`:

- converged: **tmb=TRUE julia=TRUE**; julia estimator `ML`
- wald: tmb `[0.1230156708, 0.8078740798]`, julia `[0.1230157493, 0.8078740013]`,
  delta `[7.85573e-08, 7.85425e-08]`
- profile: tmb `[0.1128339409, 0.7989615793]`, julia `[0.1128288121, 0.7989687552]`,
  delta `[5.1288e-06, 7.17584e-06]` -- **PASS at the a-priori `tol_ci = 1e-4`**
- bootstrap (R=99, seed=20260905): tmb `[0.15791, 0.735191]` failed 0/99,
  julia `[0.206927, 0.704157]` failed 0/99, **OVERLAP=TRUE**

The other two qualifiable routes reproduced A8c's numbers exactly
(`base_gaussian_location_scale` profile delta `[2.79654e-06, 5.88863e-07]`;
`plain_binomial_nonphylo` profile delta `[9.35263e-08, 2.30344e-06]`).

Full table: `g3-version-boundary-green.tsv`.

## 2. RED CONTROL -- the same script against the pin `430ef64cc`

This is a real version boundary, not a planted defect: the pin predates #646.

| route | julia converged | julia bootstrap ok | julia bootstrap failed |
|---|---|---|---|
| `base_gaussian_location_scale` | TRUE (both commits) | TRUE (both) | 0 (both) |
| `gaussian_response_mask` | **TRUE at main, FALSE at pin** | **TRUE at main, FALSE at pin** | **0 at main, all 99 fail at pin** |
| `plain_binomial_nonphylo` | TRUE (both commits) | TRUE (both) | 0 (both) |

Verbatim, at the pin:

```
- converged: tmb=TRUE julia=FALSE; julia estimator=ML
- bootstrap (R=99): tmb_ok=TRUE julia_ok=FALSE -- NOT COVERED for this route
  julia error: Error happens in Julia.
all 99 bootstrap replicates failed
```

The control is discriminating: exactly one row of three flips, and the two
rows A8 already promoted are unchanged at both commits. **The promotion of
`gaussian_response_mask` therefore carries a DRM.jl version floor of #646**,
recorded in the row's `claim_boundary` and `next_action`.

Full table: `g3-version-boundary-red-pin.tsv`.

## 3. The boundary this promotion is required to disclose

A8c's root-cause work established that a parametric bootstrap on a
masked-response fit draws each replicate response over the FULL design and
refits on every row, so the replicate distribution is calibrated to the
complete-data sample size. This leaf re-measured that narrowing through the
PUBLIC API only, on BOTH engines, with `--g3-mask-boundary` (new mode, R=199,
seed=20260905, same generative model with the masked count swept):

| engine | masked (fraction) | n obs | wald width | bootstrap width | ratio | relative narrowing | implied nominal-95 coverage |
|---|---|---|---|---|---|---|---|
| julia | 6 (10%) | 54 | 0.6849 | 0.5622 | 0.8209 | -17.9% | 89.2% |
| julia | 18 (30%) | 42 | 0.7567 | 0.5034 | 0.6652 | -33.5% | 80.8% |
| julia | 30 (50%) | 30 | 0.8153 | 0.5335 | 0.6544 | -34.6% | 80.0% |
| tmb | 6 (10%) | 54 | 0.6849 | 0.5660 | 0.8265 | -17.4% | 89.5% |
| tmb | 18 (30%) | 42 | 0.7567 | 0.5144 | 0.6798 | -32.0% | 81.7% |
| tmb | 30 (50%) | 30 | 0.8153 | 0.5515 | 0.6764 | -32.4% | 81.5% |

The measured quantity is defined in the script and stated here: `ratio` is the
bootstrap CI width divided by the Wald CI width **on the same fit**, and
implied coverage is `2 * pnorm(qnorm(0.975) * ratio) - 1`. A CI-width ratio is
used rather than a bootstrap standard deviation because DRM.jl's bridge
returns a flattened interval and does not hand replicate draws back to R, so a
width ratio is what the public surface can honestly support.

**These numbers differ from A8c's** (`-7.4% / -26.5% / -40.0%`, coverage
`93.1% / 85.0% / 76.0%`) because A8c measured a bootstrap **standard
deviation** against a Wald **standard error**, on a different RNG stream. The
difference is a difference of estimand, not a contradiction: both show the
same monotone growth of narrowing with the missing fraction, and the
qualitative conclusion is identical.

**The strengthening this leaf adds:** A8c measured the julia engine and
asserted the property was shared. This leaf measured both engines side by side
on identical fixtures and found `tmb` narrows by the same amount at every
fraction (-17.4/-32.0/-32.4% against julia's -17.9/-33.5/-34.6%). The
anti-conservatism is therefore **confirmed, not assumed, to be a shared
property of the replicate draw** -- it is not an engine-parity defect, was not
introduced by #646, and does not block a bridge-parity promotion. It is
tracked for a cross-engine fix as drmTMB#1188. A user bootstrapping a heavily
masked fit gets an anti-conservative interval on EITHER engine, and the row's
`claim_boundary` now says so.

Full table: `g3-mask-bootstrap-boundary.tsv`.

## 4. `biv_gaussian_residual` -- re-confirmed NOT qualifiable, and NOT touched

Measured live in this run, against DRM.jl main (so this is not a stale pin
artefact): `profile_targets()` reports `profile_ready = FALSE` for **all 9**
inventory rows, and `confint(method = "profile")` on `fixef:mu1:x` is refused
by the bridge before any Julia round trip:

```
Julia-engine target "fixef:mu1:x" is not ready for profile or bootstrap
intervals.
Inventory note: "missing_tmb_parameter".
```

This reproduces A8's structural finding on today's `origin/main`:
`drm_julia_wald_targets()` sets `fixef_profile_ready <- !is_biv && ...`, which
is unconditionally `FALSE` for any bivariate fit. **No profile or bootstrap
target exists on this route for any parameter, so G3 cannot be qualified here
by measurement alone.**

This leaf deliberately leaves that row untouched: drmTMB PR **#1187**
(`claude/parity-a8b-biv-inference`) is OPEN and adds exactly the missing
residual-bivariate profile/bootstrap route. Editing the row here would
conflict with it.

## 5. Boundary honesty at an unbounded endpoint (G4/G8), re-measured

The quasi-complete-separation binomial cell was re-run against DRM.jl main.
The public `confint()` entry point **never** returned a non-finite bound:

```
- julia coef(mu:x)=312; tmb coef(mu:x)=2.25663
- julia profile confint(): errored=TRUE
  message: ArgumentError: drm_bridge_inference: refusing to return an infinite
  bound for `mu:x` under status `profile_failed` -- profile endpoint solve
  failed: lower (nuisance=below_reference; lbfgs_forward; fallback=false)
- G8 (never a non-finite bound reaches the caller): PASS=TRUE
- raw DRM.jl profile_result() stats for mu:x (diagnostic, bypasses the R
  flatten): lower=-Inf upper=Inf lower_endpoint_failed=TRUE
  upper_endpoint_failed=FALSE lower_unbounded=FALSE upper_unbounded=TRUE
```

Read against **DRM.jl #651**, the live defect in which the non-sparse
location-scale endpoint search at `src/locscale_profile.jl` returns a signed
`Inf` from eight distinct sites: those sites are still present on DRM.jl main
(confirmed by reading `origin/main:src/locscale_profile.jl` in this run), and
the raw `-Inf/Inf` above is that same convention on the auditable surface.
**None of it reached an R caller**: `_bridge_inference_flatten`'s #631/#633
backstop converted it into a loud refusal naming the failed endpoint. So on
this leaf's routes, #651 is contained behind the bridge's own backstop and did
not manifest as a parity failure. This leaf did not observe a silent finite
bound substituted for an unbounded one anywhere.

## 6. G6 red control on the tolerance itself

Re-checking the measured profile deltas at a tightened `1e-9`: all three
qualifiable routes FAIL, as predicted a priori. The `1e-4` bar is
discriminating, not vacuous. `tol_ci` is a script parameter, so no code was
changed and nothing needed restoring.

## Harness changes made by this leaf

`tools/parity-p2-pilot.R` was EXTENDED (no second harness was written):

1. `DRMTMB_P2_RECEIPT` -- the `--g3-qualify` receipt path was hardcoded, so
   any re-run silently overwrote the committed A8 receipt. It now defaults to
   the old path and can be overridden.
2. The `--g3-qualify` receipt header now records the DRM.jl checkout path and
   its git HEAD. Which DRM.jl commit produced a number is load-bearing on this
   route -- the verdict flips between two commits -- and the old receipt
   format could not tell you.
3. `--g3-mask-boundary` -- the new mode that produces section 3's table.
