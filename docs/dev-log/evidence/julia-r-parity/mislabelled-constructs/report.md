# mislabelled-constructs — the two silent cells, re-measured off one fixture

All numbers measured 2026-09-05 in this worktree. Every row states its commits.

- drmTMB `origin/main` `2fcbb0fbf` (the leaf branch is that plus a test file)
- DRM.jl `aee371cc9` (the live reference; the standing pin `430ef64cc` is dead)
- DRM.jl leaf branch `claude/parity-mislabelled-constructs-drmjl`, off `origin/main` `345892520`
- drmTMB PR #1227 branch `claude/parity-jl-467-factors` at `77cead050`

## 1. What PR #1227 measured, and what is left of it

#1227 ran 58 formula constructs through `engine = "julia"` on **one** Gaussian
location-scale fixture and classified two of them **MISLABELLED_SILENT** at
the pin `430ef64cc`: a character column whose R locale-collated level order is
not Julia's code-point order, and a factor level no row uses.

**Neither reproduces as silent at a live engine.** Re-measured here at
`2fcbb0fbf` + `aee371cc9`, on the same Gaussian location-scale route:

```
chr_collation          REFUSED   drm_bridge: coef_labels["mu"] does not match the design DRM.jl built ...
factor_chr_collation   REFUSED   (same)
unused_level           REFUSED   coef_labels["mu"] supplies 5 names but the mu formula part has 4 ...
CONTROL_factor         FAITHFUL  max|coef diff| = 3.72524e-12
CONTROL_poly2          FAITHFUL  max|coef diff| = 2.60902e-14
```

DRM.jl's own `_bridge_check_coef_labels_fidelity` catches the first two. It is
absent from the dead pin, which is why #1227 saw silence. #1227's own R-side
guard is a second, earlier line of defence and is independently useful — see §4.

## 2. Extending the battery: the classification HOLDS on mu and sigma

Both shapes, five families, both dpar sides, at `2fcbb0fbf` + `aee371cc9`
(`probe_2_routes.R`). Every cell **REFUSED**; every declared-factor control
**FAITHFUL**:

| control | route | max\|coef diff\| |
|---|---|---|
| declared factor | poisson `mu` | 1.04943e-11 |
| declared factor | nbinom2 `mu`+`sigma` | 1.07389e-11 |
| declared factor | cumulative_logit `mu` | 5.57598e-12 |

One pre-existing boundary surfaced in passing: **any** factor on a
random-effect route (`y ~ x + g + (1 | grp)`) is refused, alphabetical or not,
because DRM.jl supplies no `bridge_formula_labels_v1` there. Honest, not
silent, and not this leaf's to fix.

## 3. Where it does NOT hold: the LSS `sd(<group>)` block

`_bridge_check_coef_labels_fidelity` iterates
`_bridge_rendered_regression_blocks`, which skips every `sd_<group>` /
`sdphy_<group>` block by construction:

```julia
_bridge_lss_form_key(param) === nothing || continue
```

So the location-scale-scale group-level SD formula was echoed with R's names
and never compared. Measured at `2fcbb0fbf` + `aee371cc9`
(`probe_3_lss_sd_block.R`), `bf(y ~ x + (1 | study), sigma ~ z, sd(study) ~ s_chr)`:

```
logLik  tmb -69.917488   julia -69.917488   (diff 2.98e-13)
mu      max|diff| 2.12299e-11   (Intercept) -0.002187 / -0.002187   x 0.439066 / 0.439066
sigma   max|diff| 5.19876e-12   (Intercept) -0.907845 / -0.907845   z 0.158952 / 0.158952
sd      max|diff| 1.3853
        (Intercept)  tmb -1.374558  julia -0.681910
        s_chrBeta    tmb  0.692648  julia -0.692648
        s_chrgamma   tmb  0.219661  julia -0.472987
VERDICT: MISLABELLED_SILENT
```

Converged on both engines, identical logLik, identical names. `s_chrBeta` came
back with its **sign flipped**, because the baseline moved from `alpha` to
`Beta`. The two blocks that *are* checked agreed to 2e-11 in the same fit.

The mechanism is the level order and nothing else: declaring the same column
as a factor in R makes the same model **FAITHFUL to 1.46144e-10**, and
`sd(study) ~ 1` is faithful to 3.47833e-13.

## 4. Both fixes verified independently

| stack | verdict on `sd(study) ~ s_chr` |
|---|---|
| `2fcbb0fbf` + `aee371cc9` | MISLABELLED_SILENT, 1.3853 |
| **#1227** `77cead050` + `aee371cc9` | REFUSED — `cannot reproduce R's design for the `sd(study)` formula: "s_chr" would be coded against a different baseline level` |
| `2fcbb0fbf` + **DRM.jl #730** | REFUSED — `coef_labels["sd"] does not match the design DRM.jl built for the `sd_study` formula` |

#1227's guard reaches this route although #1227 never claimed or tested it —
its "Not covered" says Gaussian, fixed effects, `mu`/`sigma` only. That is a
genuine widening of its evidence, not a re-run of it.

## 5. Files

- `probe_1_baseline.R` — §1, the Gaussian location-scale re-measurement.
- `probe_2_routes.R` — §2, both shapes across five families and both dpar sides.
- `probe_3_lss_sd_block.R` — §3, block-by-block LSS comparison.
- `route-classification.tsv` — every cell above, one row each.
- `testfile-live-with-drmjl-730.log` — 31 pass / 0 fail / 0 skip.
- `testfile-live-without-either-guard.log` — 30 pass / 1 skip (the skip states its dependency).
- `testfile-RED-control-skip-removed.log` — the RED control, 1 fail, verbatim.
