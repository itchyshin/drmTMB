# Formula-construct fidelity across the `engine = "julia"` bridge (DRM.jl #467, #609)

Leaf `jl-467-609-factors`. Everything below was measured on 2026-09-05 in this
worktree; nothing is carried over from a prior receipt.

## Build under test

| Piece | Value |
|---|---|
| drmTMB | branch `claude/parity-jl-467-factors`, off `origin/main` `eccb10299` |
| drmTMB native DLL | `src/drmTMB.so`, sha256 `c9d3eae7c08687260a7ce261c33e1a7fd363b54b1885732e5686fc4b3f1b864d`, built from the byte-identical `src/` tree `af410d866748eb55a1abfc695ed083179bdb8840` |
| DRM.jl (pin) | `/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc` (430ef64cc) |
| DRM.jl (main) | worktree at `84120ff74`, used for the cross-check below |
| R | R version 4.6.0 (2026-04-24), `LC_COLLATE` = `en_AU` (locale collation, not code point) |

## 1. The reported #609 prediction failure does NOT reproduce

`Rscript tools/parity_prediction.R <drmTMB worktree> <DRM.jl pin> <out.json>`
(DRM.jl's own runner, unedited):

```
numeric PASS
factors PASS
default_scale PASS
known_variance PASS
PREDICTION_CONTRACT_PASS cases=4 predictions=32
```

Issue #609 recorded `PREDICTION_CONTRACT_FAIL cases=4 predictions=32` with the
`factors` case failing, against drmTMB `f53e06b1` (2026-09-02). On current
`origin/main` it passes. That item of #609 is closed by measurement, not by a
change in this leaf.

## 2. Construct battery: 58 cases, both engines, one fixture

`construct_battery_1.R` and `construct_battery_2.R`; results in
`construct-battery.tsv`. One Gaussian location-scale fixture, n = 120, seed
46709. Verdicts compare `engine = "julia"` against `engine = "tmb"`: coefficient
NAMES (identical, in order, and equal to base-R `model.matrix()` names) and
VALUES (`max|coef diff|`).

| Verdict | Count |
|---|---|
| FAITHFUL (names identical, `max\|coef diff\|` <= 1e-6; the largest observed was 2.675e-10) | 46 |
| Refused by the bridge (`JULIA_REFUSE`) | 9 |
| Refused by BOTH engines | 1 |
| **MISLABELLED_SILENT** (identical names, coefficients differ) | **2** |

The two silent cells are the finding this leaf exists for:

| Case | max\|coef diff\| |
|---|---|
| `y ~ gmixchar` (bare character column, values `"a" "B" "c"`) | 0.178476 |
| `sigma ~ gmixchar` | 0.104597 |

Diagnosed directly: R's locale collation gives levels a, B, c and codes against
`"a"` (intercept 0.30402452, the mean of group a); the column crosses as a plain
Julia `Vector{String}`, DRM.jl sorts by code point to B, a, c and codes against
`"B"` (intercept 0.39326249, the mean of group B). Both engines converged, both
reported `logLik = -126.6003`, both returned the names `(Intercept) gmixcharB
gmixcharc`. On a second fixture (n = 150) the same shape gave `max|coef diff| =
1.103571`.

Probing the marshalled columns in the live Julia session explains why a FACTOR
column is safe and a CHARACTER column is not:

| R column | Julia type | Julia `sort(unique(...))` | R levels |
|---|---|---|---|
| `factor(c("a","b","c"))` | `CategoricalVector` | pool `["a","b","c"]` | a,b,c |
| `factor(..., levels = c("c","b","a"))` | `CategoricalVector` | pool `["c","b","a"]` | c,b,a |
| `factor(..., levels = c("a","b","c","zz"))` | `CategoricalVector` | pool keeps `"zz"` | a,b,c,zz |
| `c("a","B","c")` (character) | `Vector{String}` | `["B","a","c"]` | a,B,c |
| `c("A","a","b")` (character) | `Vector{String}` | `["A","a","b"]` | a,A,b |
| logical | `BitVector` | continuous | FALSE,TRUE |

(`marshalled_level_probe.R`.)

## 3. Independent design oracle: 37 constructs, element-wise

`design_oracle.R` bypasses fitting entirely: it builds the payload drmTMB would
send, then calls `DRM._bridge_formula` + `DRM._design` on it and compares the
resulting matrix element by element against R's `model.matrix()`.

All 37 constructs are **DESIGN_IDENTICAL** (`design-oracle.tsv`): 31 at
`max|diff| = 0`, and the QR-based bases at floating-point noise --
`poly(x, 2)` 8.33e-16, `poly(x, 3)` 8.26e-16, `scale(x)` 4.44e-16. That settles
#467's flagged high-risk case: DRM.jl reproduces R's ORTHOGONAL (`raw = FALSE`)
polynomial basis, not a raw-power stand-in.

Covered: `x`, factor columns (alphabetical, reversed, mixed-case, numeric-label),
`factor()` over an integer column, character columns, logical columns,
`x * g`, `x:g`, `g1 * g2`, `I(x^2)`, `I(x*z)`, `I(x^2 + z)`, `I(x)`, `I((x))`,
`log(I(x + 2))`, `poly(x, 2)`, `poly(x, 3)`, `poly(x, 2) * g`, `scale(x)`,
`scale(x) + scale(z)`, `(x + z)^2`, `(x + z + g)^2`, `(x + z + g)^3`, `x - 1`,
`0 + x`, `x:z`, `x + z + x:z - z`, `(x + z)^2 - x:z`, `x + g - x`,
`poly(x, 2) + z - z`, `I(x^2):g`, `x + factor(gi) + x:factor(gi)`,
`log(x + 2) * g`, `sqrt(x + 2)`.

## 4. Refusals, and how good they are

| Construct | Refused by | Message names the construct? |
|---|---|---|
| ordered factor (contr.poly) | drmTMB, before Julia | yes -- `g_ord: an ordered factor (R codes it with contr.poly)` |
| factor with a `contrasts` attribute | drmTMB, before Julia | yes |
| non-default `options("contrasts")` | drmTMB, before Julia | yes |
| **factor with an unused level** | Julia, raw count error | **no** -- named neither the column nor the fix. Now refused by drmTMB, before Julia (this PR); DRM.jl's own count message also gained the cause (companion PR). |
| **character column, divergent level order** | at the pin: NOTHING (silent). On DRM.jl main: the engine's echo check | Now refused by drmTMB, before Julia (this PR). |
| `I(log(x + 2))` | Julia | yes -- "`I(...)` only supports the arithmetic operators +, -, *, /, ^ ... got `log`" |
| `x * z - x:z` (`-` over an unexpanded `*`) | Julia | yes -- names `-` and `*` and gives the expansion to write |
| single-level factor | both engines | Julia's message is StatsModels' raw "only one level found" |
| user column literally named `__bridge_scale_1` | Julia | no -- raw StatsModels parse error. Contrived; NOT fixed here. |

## 5. Cross-check against DRM.jl main

Re-running the interesting cells with `DRM_JL_PATH` pointed at DRM.jl
`origin/main` (`84120ff74`) instead of the pin: both character-column cells are
REFUSED there by `_bridge_check_coef_labels_fidelity`
(`R supplied ["(Intercept)", "gmixcharB", "gmixcharc"] but DRM.jl renders
["(Intercept)", "gmixchara", "gmixcharc"]`), the unused-level cell is refused by
the count check, and `y ~ g3` stays FAITHFUL at 1.11933e-12. The silent
mislabel is therefore a PIN-VERSION exposure -- which is exactly why the guard
this PR adds sits in drmTMB, upstream of any engine build.

## 6. Not covered

- One fixture per construct. This is a design/parity contract, not a coverage
  or recovery study.
- Gaussian only, fixed effects only, `mu`/`sigma` only. Constructs inside
  random-effect bars or structured markers were not exercised.
- A level made empty by rows `model.frame()` drops for an NA in ANOTHER
  predictor is caught by the new model-frame emptiness check, but the case was
  not exercised live because `engine = "julia"` gates missing predictors.
- The full drmTMB suite was not run. A 12-file live subset was: 3 failures, all
  reproduced on unmodified `HEAD` (two family-fence message-wording drifts, one
  DRM.jl-pin bootstrap defect fixed on DRM.jl main), none touched by this leaf.
