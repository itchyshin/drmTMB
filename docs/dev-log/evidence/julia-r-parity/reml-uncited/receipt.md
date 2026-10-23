# Three UNCITED REML capabilities, measured

Leaf `uncited-reml`, 2026-09-05. Reader: whoever quotes the parity scoreboard's
UNCITED count, and whoever next widens `drm_julia_reml_supported()`.

## What was UNCITED and why

`docs/design/parity-scoreboard.md` reported **23 of 45** drmTMB-native
capabilities UNCITED on the bridge axis. Three of them are REML cells:

| capability | why UNCITED |
|---|---|
| `REML (Gaussian fixed-effect location-scale)` | its matrix `bridge_route` cited no ledger row at all |
| `REML with ordinary random effects (Gaussian mean)` | same |
| `REML bivariate phylogenetic location-scale (q4, all axes)` | cited `biv_q4_phylo_reml`, which carried no receipt row at the ref |

All three routes already **fitted** through `engine = "julia"`. What was missing
was never the admission; it was a same-target comparison against
`engine = "tmb"` that a later reader could cite. No REML row existed in **any**
of DRM.jl's four `capability_id`-keyed evidence tables (`parity-se.tsv`,
`parity-fixtures.tsv`, `parity-classc.tsv`, `parity-phylo-nongaussian.tsv`).

## Build under test

- drmTMB: worktree `claude/parity-uncited-reml`, `devtools::load_all()`,
  `drmtmb_code_hash` **3bbe615e88e512a8dc62b120a146f5e916258a986bad61e96e8087ebf3756f64**.
- DRM.jl: **aee371cc9627c24945859f4caa749e0d5b691782**.
  The programme pin `430ef64cc` was **not** used: it predates DRM.jl #646 and
  #648 and two other leaves independently measured it as unusable tonight.
- Env: `OPENBLAS_NUM_THREADS=1 DRMTMB_JULIA_TESTS=true NOT_CRAN=true`.
- Julia 1.10.0. Every number below was measured in this run.

## Cell 1 -- REML (Gaussian fixed-effect location-scale)

`bf(y ~ x, sigma ~ z)`, `gaussian()`, `REML = TRUE`, n = 60, seed 1.
Verdict: **RECEIPT** (point), **written boundary** (SE).

| quantity | engine = "tmb" | engine = "julia" | difference |
|---|---|---|---|
| REML logLik | -72.439950302880 | -72.439950302880 | 7.105427357601e-14 |
| ML logLik | -69.622071438574 | -69.622071438574 | 7.105427357601e-14 |
| `mu_(Intercept)` | 0.477010504673 | 0.477010504673 | 6.682987e-13 |
| `mu_x` | 0.828569981984 | 0.828569981983 | 7.021050e-13 |
| `sigma_(Intercept)` | -0.273171456667 | -0.273171456676 | 9.114265e-12 |
| `sigma_z` | 0.283407199639 | 0.283407199630 | 9.466983e-12 |
| **max abs coef diff** | | | **9.466982753281e-12** (4/4 names identical) |
| nobs / df | 60 / 4 | 60 / 4 | -- |

**Estimator honesty.** `fit$estimator == "REML"`, `fit$effective_REML == TRUE`,
and DRM.jl's own `fit$bridge$estim_method == "REML"`. With `REML = FALSE` all
three read `ML`. The **ML/REML gap is 2.817878864306 on BOTH engines** -- an ML
fit relabelled REML would show a gap of zero, so this rules out the specific
failure this leaf was told to watch for.

**SE: the boundary.** Not a pass, and the row says so.

| SE | tmb | julia | relative |
|---|---|---|---|
| `mu_(Intercept)` | 0.096209734501 | 0.095912838985 | **3.085920e-03** |
| `mu_x` | 0.102556192495 | 0.102248528678 | **2.999954e-03** |
| `sigma_(Intercept)` | 0.093910378014 | 0.093910407580 | 3.148319e-07 |
| `sigma_z` | 0.107016016229 | 0.107016083239 | 6.261663e-07 |

Both mean-block SEs sit just past the 1e-3 bar while both scale-block SEs agree
to about 3e-07. **CONTROL A localises the cause instead of guessing it:**
refitting the same data with `sigma ~ 1` makes the mean block agree *exactly*.

```
## CONTROL A sigma ~ z (the receipt cell)
   SE mu_(Intercept)       tmb=0.096209734501 julia=0.095912838985 rel=3.085920e-03
   SE mu_x                 tmb=0.102556192495 julia=0.102248528678 rel=2.999954e-03
## CONTROL A sigma ~ 1 (control)
   SE mu_(Intercept)       tmb=0.109373055646 julia=0.109373055646 rel=0.000000e+00
   SE mu_x                 tmb=0.127949581295 julia=0.127949581295 rel=2.169259e-16
```

So the gap is carried by the **sigma covariate**, not by REML. Under drmTMB's
REML construction `beta_mu` lives in TMB's random set, so `sdreport` propagates
variance-parameter uncertainty into the mean block; DRM.jl reports the canonical
plug-in REML covariance. Both are defensible; here they differ by under 0.31%.
**No interval or coverage claim is made on this route in either direction.**

## Cell 2 -- REML with ordinary random effects (Gaussian mean)

`bf(y ~ x + (1 | g), sigma ~ 1)`, `gaussian()`, `REML = TRUE`,
n = 150 (15 groups x 10), seed 11. Verdict: **RECEIPT** (point and SE).

| quantity | engine = "tmb" | engine = "julia" | difference |
|---|---|---|---|
| REML logLik | -127.153393170864 | -127.153393170863 | 1.065814103640e-12 |
| ML logLik | -124.041918662515 | -124.041918662515 | 1.278976924368e-13 |
| `mu_(Intercept)` | 0.115413418255 | 0.115413418257 | 1.548775e-12 |
| `mu_x` | 0.889606554596 | 0.889606554690 | 9.362755e-11 |
| `sigma_(Intercept)` | -0.730165884621 | -0.730165884621 | 6.550316e-15 |
| **max abs coef diff** | | | **9.362755015729e-11** (3/3 names identical) |
| SE `mu_(Intercept)` | 0.167667004565 | 0.167667004565 | 1.787831e-14 rel |
| SE `mu_x` | 0.043108485585 | 0.043108485586 | 1.889535e-11 rel |
| SE `sigma_(Intercept)` | 0.061082888344 | 0.061082908704 | 3.333301e-07 rel |
| **max rel SE diff** | | | **3.333300652762e-07** over 3 SEs |

Estimator REML on both sides; ML/REML gap 3.111474508349 (tmb) /
3.111474508348 (julia).

Note the contrast with cell 1: here the mean-block SEs agree to 1.8e-14, because
`sigma ~ 1` leaves no variance-parameter uncertainty to propagate. The same
control explains both rows.

## Cell 3 -- REML bivariate phylogenetic location-scale (q4, all axes)

Verdict: **RECEIPT** (point-only) on the DENSE layout, **written boundary plus a
new defect** on the block-diagonal layout.

The ledger row `biv_q4_phylo_reml` asserted that "the `engine='julia'` path for
this cell is halted by design". **That is measurably false at this pin**: the
call fits.

### The dense layout -- receipt

One shared phylo label `p` on all four axes, `rho12 ~ 1`; 100 tips x 5 = 500
observations, seed 3.

| quantity | engine = "tmb" | engine = "julia" | difference |
|---|---|---|---|
| REML logLik | -930.145130378492 | -930.165353375125 | **2.022299663270e-02** |
| `mu1_(Intercept)` | 0.397364202945 | 0.397133519460 | 2.306835e-04 |
| `mu2_(Intercept)` | 0.567536493129 | 0.568201427909 | 6.649348e-04 |
| `sigma1_(Intercept)` | -0.398312193071 | -0.397565148933 | 7.470441e-04 |
| `sigma2_(Intercept)` | -0.754181078251 | -0.754474067983 | 2.929897e-04 |
| `rho12_(Intercept)` | 0.050628405898 | 0.050963519551 | 3.351137e-04 |
| **max abs coef diff** | | | **7.470441383797e-04** (5/5 names identical) |
| df | 15 | 15 | -- |

`2.0223e-02` is inside this row's **own** recorded `atol_loglik` of 0.03
(DRM.jl #477), and the coefficient agreement is about 4x tighter than the
`0.002889` the row already banks. Native REML convergence code 0.

**POINT-ONLY.** Neither engine returns usable fixed-effect SEs on this fit
(`engine = "tmb"` reports `NA`, `engine = "julia"` reports none), so no SE
comparison exists and none is claimed. The ML control is **not** clean either --
native ML convergence code was 1 -- so the ML/REML gap (3.988715500260 tmb /
3.989332608348 julia) is reported for the estimator-honesty read only.

### The block-diagonal layout -- the defect

A block-diagonal q4 call uses **two** phylo labels: `phylo(1 | p | sp)` on the
means and `phylo(1 | ps | sp)` on the scales, i.e. no mean-scale
cross-covariance. `tests/testthat/test-reml-bivariate.R` pins this layout as
natively admitted and convergent. Given that formula, the bridge answers a
**different question**, on the same data:

```
## CONTROL B  same data, three fits
   tmb  BLOCK-DIAG        logLik=-934.738393347 df=11 convergence=0
   tmb  DENSE             logLik=-930.145130378 df=15 convergence=0
   julia BLOCK-DIAG call  logLik=-930.165353375 df=15 convergence=0
   |julia(blockdiag call) - tmb BLOCK-DIAG| = 4.573039972
   |julia(blockdiag call) - tmb DENSE     | = 0.020222997
```

The bridge, handed the **block-diagonal** formula, returns the **dense** answer
(to 0.0202, the same distance as the dense-vs-dense receipt above) and reports
`df = 15`, the dense parameter count, where the native block-diagonal fit has
`df = 11`. Its fixed-effect SEs are `NaN` in all 5 entries.

**Boundary.** `engine = "julia"` does **not** cover the block-diagonal q4
layout. A user who writes two distinct phylo labels gets a fit of the dense
model without being told. Until `engine = "julia"` refuses that layout, use
`engine = "tmb"` for a block-diagonal q4 REML fit. This is recorded as the
`next_action` on the matrix row and in `docs/design/261-reml-by-route.md`.

## One finding that is not about REML

On an `engine = "julia"` REML fit, `summary(fit)$coefficients` carries **no**
`std_error` column, while `vcov(fit)` returns a usable matrix. `engine = "tmb"`
carries both. Measured on the cell-2 fixture while writing the test for this
leaf: the first version of `drm_reml_named_se()` read `summary()` only and
errored with `"std_error" %in% colnames(s) is not TRUE`. A reader who tries
only `summary()` would conclude the bridge reports no standard errors on this
route, which is wrong. The helper now falls back to `vcov()` and says why.
Not fixed here -- reported.

## Red controls

1. **The SE check is not vacuous.** Perturbing one Julia SE by +10% moves cell
   1's max relative difference from 3.086e-03 to **9.660548831922e-02** and
   cell 2's from 3.333e-07 to **9.999999999998e-02** -- the `rtol = 1e-3`
   comparison **FAILS (as it must)** in both cases. Both perturbations are
   banked as `NEGATIVE_CONTROL_OK` rows in DRM.jl's `parity-se.tsv`. Note the
   discrimination this gives on cell 1: a real 10% error reads 31x larger than
   the 0.31% convention gap.
2. **The matrix generator refuses a citation it cannot verify.** Citing the new
   receipts with `rec()` while generating at the artefact's own DRM.jl pin
   (`d3efbad2f`, which predates them) aborted:
   `Error: receipt capability_id=gaussian_reml_location_scale matches 0 rows in
   docs/dev-log/evidence/parity-fixtures.tsv at the pin (need exactly 1)`.
   That is why the matrix quotes the numbers inline and leaves the
   `capability_id -> receipt` join to the scoreboard, which performs it at
   whatever ref it reads.
3. **The ledger test and the matrix generator both fail on a planted defect.**
   Renaming one new capability_id to
   `gaussian_reml_random_intercept_mu_TYPO` in
   `drm_julia_capability_comparison()` -- exactly the silent-rename failure the
   scoreboard join is vulnerable to -- makes
   `tests/testthat/test-julia-reml-uncited.R` report
   `FAIL=1 ERR=0 SKIP=2 PASS=6` (it was `FAIL=0 ERR=0 SKIP=0 PASS=41`), and
   makes the matrix generator abort:
   `Error: TSV capability_id not found: gaussian_reml_random_intercept_mu`.
   `R/julia-bridge.R` restored byte-identically afterwards: sha256
   `1a3196d0d7c9e7dcadc2451b5437d2205a5844f12b6266119f187c079eaa583d`
   before and after, and `inst/extdata/julia-capabilities.tsv` regenerated to
   the same bytes.
4. **`R/julia-bridge.R` restored byte-identically** after a first insertion
   attempt anchored its column blocks from the top of the file and landed two
   lines inside `drm_julia_intentional_gates()`. Restored with
   `git show HEAD:R/julia-bridge.R > R/julia-bridge.R` (sha256
   `36fb2decc42edb520e4e1998c09be9d74b01b143e180a205491223c1cba204f7`,
   `git diff` empty) and redone with function-scoped anchors.

## What this changes on the scoreboard, and what still gates it

The scoreboard reads receipts from **DRM.jl's** evidence tables. With the
companion DRM.jl PR applied, all four affected cells clear:

```
wrote 45 scoreboard rows ... (19 UNCITED on the bridge axis) at DRM.jl c88da2e6
```

23 -> **19**. The four cells that flip UNCITED -> RECEIPT are the three above
plus `Bivariate structured random effect on all four axes (q4 PLSM)`, which
shares the `biv_q4_phylo_reml` ledger row. The full generated output is
`scoreboard-with-drmjl-pr.md` in this directory.

**Until that DRM.jl PR merges, this drmTMB change is BLOCKED, not done.** The
committed `docs/design/parity-scoreboard.md` in this PR is regenerated at the
unchanged ref `aee371cc` and still reads 23 UNCITED -- with a more accurate
message, because the ledger rows now exist. Reporting 19 before the receipts are
on DRM.jl's `main` would be exactly the false-capability failure this programme
has already been caught by.

## Not covered

Interval coverage on any of the three cells; more than one draw or seed per
cell; a random slope `(1 + x | g)` under REML (DRM.jl refuses it and the bridge
still forwards it as a raw Julia `ArgumentError` -- an unfixed interface defect
recorded on the `gaussian_random_slope_mu` ledger row, not fixed here); a
sigma-side random effect under REML (refused before Julia); any non-Gaussian
REML route; the block-diagonal q4 layout; and the `_q4_fd_vcov`-on-REML question
(DRM.jl #624 item 3), which is untouched.

## Files

- `receipt-run.R` / `receipt.log` -- cells 1 and 2 point receipts, cell 3 first attempt.
- `se-and-blockdiag-run.R` / `receipt2.log` -- SE comparisons and the block-diagonal q4 run.
- `controls-run.R` / `controls.log` -- CONTROL A (sigma ~ 1) and CONTROL B (dense vs block-diagonal).
- `dense-q4-run.R` / `cell3.log` -- the dense q4 receipt.
- `scoreboard-with-drmjl-pr.md` -- the scoreboard generated against the DRM.jl branch that carries the receipts.
