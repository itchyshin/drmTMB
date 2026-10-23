# After Task: the `engine = "julia"` control surface (`engine-control-surface`)

Leaf of the drmTMB <-> DRM.jl true-parity programme. Branch
`claude/parity-engine-control-surface`, worktree
`/Users/z3437171/local-scratch/parity-joint/wt-engine-control`, DRM.jl pinned at
`430ef64cc` (`/Users/z3437171/local-scratch/parity-joint/drmjl-430ef64cc`).

## The question

`inst/extdata/julia-capabilities.tsv`'s `engine_control_surface` row carried
`next_action = "Design engine_control explicitly before relaxing the gate."` --
which reads as pending work -- while the `cross_family_latent` row above it
cites this same row as the TEMPLATE for a permanent, owner-signed boundary
(D-179 #3). Both cannot be true. Resolve it with evidence and land whichever
side the evidence supports.

## The answer

**Permanent** -- but the boundary as written was not yet TRUE, so both halves
were needed.

The two control surfaces are not reconcilable and are not being reconciled.
`drm_control()` describes an `nlminb()`/TMB program (iteration budgets, storage
of the TMB object, delta-method SE shaping, log-sigma clamps, Newton polish,
multi-start, an `optim()` fallback). DRM.jl's `drm()` is a different program
that runs none of it. For most of the surface there is nothing to forward to,
and therefore no native comparator against which a parity claim could ever be
measured. "Design `engine_control` explicitly" was advertising work that cannot
be finished.

But the row's own boundary text already claimed "unsupported TMB controls
refuse before JuliaCall", and **that was measurably false for seven of them.**

## What was measured, option by option

Every `drm_control()` field, pushed through
`drmTMB:::drm_julia_translate_control()` on `origin/main` (pure R, no Julia).
`drm_control()` carries **17** fields.

| verdict | fields |
|---|---|
| FORWARDED | `optimizer$g_tol`, `optimizer$algorithm` (and `optimizer$q4_vcov`) |
| REFUSED (named error) | `se`, `keep_data`, `keep_model_frame`, `keep_tmb_object`, `sparse_fixed`, `aggregate_gaussian`, `optimizer_preset`, `multi_start`, `start`, and any `nlminb` name inside `optimizer` (`iter.max`, `eval.max`, `rel.tol`, `trace`) |
| **SILENTLY DROPPED** | `se_report_covariance`, `se_skip_delta_method`, `se_group_sd`, `logsigma_clamp` (including `= NULL`), `logsigma_clamp_margin`, `newton_polish`, `fallback_optimizer` |

The cause: the refusal list in `drm_julia_translate_control()` was
hand-written and named 9 of the then-16 non-optimizer fields. The other seven
fell through the loop, produced no override, and produced no error.

**Live confirmation at the pin.** `drmTMB(bf(y ~ x, sigma ~ x), data = dat,
engine = "julia", control = ...)`, `n = 120`, `set.seed(1)`:

```
BEFORE
default                    FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
newton_polish=FALSE        FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
se_group_sd=TRUE           FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
fallback_opt=BFGS          FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
logsigma_clamp=c(-20,20)   FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
se_report_cov=FALSE        FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
se_skip_delta=TRUE         FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
logsigma_margin=6          FIT logLik=-199.0299845089 coef=0.9182783040,0.5200602954,0.2307024395,0.0815072392
```

Byte-identical to the default fit in every case: the user asked for a setting
and got neither it nor an error. That is the serious case -- a silently dropped
control is indistinguishable, from the caller's seat, from a control that took
effect.

**AFTER, same fixture, same session shape:** each of those seven now aborts,
naming the field, before JuliaCall:

```
newton_polish=FALSE  REFUSED `engine = "julia"` does not support `control` setting "newton_polish".
se_group_sd=TRUE     REFUSED `engine = "julia"` does not support `control` setting "se_group_sd".
fallback_optimizer=BFGS REFUSED ... setting "fallback_optimizer".
logsigma_clamp=c(-20,20) REFUSED ... setting "logsigma_clamp".
se_report_covariance=F  REFUSED ... setting "se_report_covariance".
se_skip_delta_method=T  REFUSED ... setting "se_skip_delta_method".
logsigma_clamp_margin=6 REFUSED ... setting "logsigma_clamp_margin".
```

## The two admitted knobs really do reach the engine

Same live run, so this is not an inference from reading the bridge:

```
g_tol=1e0        FIT logLik=-199.0364652191   (default is -199.0299845089)
g_tol=1e-12      FIT logLik=-199.0299845089   (last coefficient digit moves)
algorithm=lbfgs  FIT logLik=-199.0299845089
algorithm=gls    FIT logLik=-199.0299845089
algorithm=sparse FIT logLik=-199.0299845089
algorithm=em     REFUSED (from Julia) ArgumentError: drm: algorithm = :em is
                 implemented only for the Gaussian phylogenetic-mean cell ...
                 @ DRM .../src/gaussian_core.jl:648
```

`g_tol` changes the answer, so it is consumed. `algorithm` reaches
`drm()` -- `:em` throws DRM.jl's own error naming the symbol -- so it is
consumed too; `lbfgs` / `gls` / `sparse` simply converge to the same optimum on
this fixed-effect fixture. Reported as measured, not dressed up as a
difference.

## Renames and route asymmetry (named, not fixed)

* On the bivariate q = 4 phylogenetic route `optimizer$g_tol` is forwarded as
  DRM.jl's **`q4_g_tol`** -- that route's *outer*-gradient tolerance, a
  different quantity from the base route's `g_tol` -- and `optimizer$algorithm`
  is refused there, because its optimiser has no solver-selection setting. Both
  were already implemented in `drm_julia_bridge_options()`; neither was in the
  user-facing docs. They are now.
* The **structured**, **bivariate q2 structured** and **cross-family** routes
  accept only a default `control` (`drm_julia_default_control()`, an
  `identical()` comparison against the whole `drm_control()` object), so even
  `optimizer$g_tol` is refused there. That gate is fail-CLOSED by construction;
  it was the granular translator that was fail-open. Left as it is.

## What landed

* `drm_julia_unsupported_control_fields()` (`R/julia-bridge.R`), one line:
  `setdiff(names(drm_control()), "optimizer")`. The refused set is now DERIVED
  from `drm_control()`, so a field added to the constructor is refused on the
  Julia path with no matching bridge edit. Same fail-closed shape DRM.jl's own
  `_bridge_fit` uses (`setdiff(keys(options), _BRIDGE_KNOWN_OPTION_KEYS)`, then
  throw).
* Three tests in `tests/testthat/test-julia-optimizer-controls.R`: the
  derivation guard, a **totality** test whose probe table must cover
  `names(drm_control())` exactly (a new control with no probe fails it), and a
  named regression pin on the seven formerly-dropped fields.
* The capability row, through the generator
  (`drm_julia_capability_comparison()`, regenerated into both TSVs): a
  PERMANENT `claim_boundary` naming every setting that does not cross and
  saying to use `engine = "tmb"` instead, and a `next_action` that says the
  boundary is permanent instead of asking for a design nobody intends to do.
* `docs/design/parity-matrix.md` through `tools/write-parity-matrix.R`
  (generator edited, output regenerated).
* `?drm_control` and `vignettes/julia-engine.Rmd`: the whitelist as a table,
  the q4 rename, the route asymmetry, and the full list of refused settings.
* `NEWS.md`, flagged as a behaviour change.

## `claim_status` deliberately NOT moved

It stays `experimental`, and the boundary now says that is PERMANENT. Promoting
it would need a bar this axis cannot meet: `partial` on this ledger means a
same-target point+SE parity receipt (`docs/design/192-capability-comparison-regeneration.md`),
and there is no native comparator for a control surface -- `iter.max = 500`
has no DRM.jl counterpart to be compared against. `experimental` here records
a deliberately narrow Julia-native surface, not unfinished work, and the
boundary text now says so in those words. **Whether that word is the right
permanent label is an owner decision**, flagged, not taken.

## Gates

| gate | result |
|---|---|
| G1 sweep, `origin/main` | 17 fields; 7 SILENTLY DROPPED (list above) |
| G1 sweep, branch | 0 DROPPED; only `g_tol` / `algorithm` FORWARDED |
| G2 live BEFORE/AFTER at pin `430ef64cc` | tables above, verbatim |
| G3 unit | `test-julia-optimizer-controls.R` `pass=58 fail=0 error=0 skipped=0` |
| G4 mocked neighbours | 49 `test-julia*` files, `pass=1591 fail=0 error=0 skipped=38` |
| G5 live neighbours at the pin | `test-julia-optimizer-controls.R pass=58 fail=0 error=0 skipped=0`; `test-julia-bridge.R pass=146 fail=0 error=0 skipped=0` (2 live tests ran, bridge glue exercised) |
| G6 RED CONTROL | hand-written 9-field list planted back -> `PASS=42 FAIL=16`, failures name `se_report_covariance`, `se_skip_delta_method`, `se_group_sd`, `logsigma_clamp`, `logsigma_clamp_margin`, `newton_polish`, `fallback_optimizer`; restored, `sha256 6c897016a4a99a7db8ec427de24b18fdbdaff7db13583a7331e977e2ef521ab8` identical before and after, suite back to `PASS=58 FAIL=0` |
| G7 docs | `tools::checkRd("man/drm_control.Rd")`: 0 findings. Non-ASCII on added lines of `R/`, `tests/`, `man/`, `NEWS.md`: 0 |

## Not this leaf

* No DRM.jl change of any kind.
* No new forwarded option. The whitelist is exactly what it was; what changed
  is that everything outside it now refuses.
* No `interval_status`, coverage, or performance claim.
* PR #1215 (`claude/parity-p-route-diagnostics`) is the OTHER half of #1108,
  the `check_drm()` diagnostics consumer. It states "no new `drm_control()`
  option"; this leaf adds none either, and the two touch disjoint code.
* `docs/design/261-reml-by-route.md` is untouched: `engine_control_surface` is
  `N/A` on the REML axis there ("this route is not a REML/ML fork"), and that
  stays true.

## Reported, NOT fixed

`docs/design/parity-matrix.md` was stale on `origin/main`: it recorded
"14 gates" while `inst/extdata/julia-gates.tsv` has 15 rows. The mandated
regeneration of that generated artifact corrects it as a side effect, along
with `R/julia-bridge.R` line-number citations that moved because this leaf
added comment lines above them. Neither is a claim change.
