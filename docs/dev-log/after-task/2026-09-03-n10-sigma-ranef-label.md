# N10: labelling an ordinary (non-phylo) `sigma ~ (1 | g)` random intercept

**Reader**: anyone touching `drm_julia_bridge_payload_coef_labels()`
(`R/julia-bridge.R`), `tests/testthat/test-coefficient-labels.R`,
`tests/testthat/test-julia-bridge.R`, or design 258's S7.8; anyone wondering
why a PLAIN lme4-style random intercept on `sigma` (no `phylo()` marker
anywhere) used to abort `engine = "julia"` with `coef_labels is missing an
entry for dpar "resd"`.

## The gap, as given

`bf(y ~ x, sigma ~ (1 | g))` -- a plain, non-phylo random intercept on
`sigma` -- aborted on both `origin/main` and N9's head (758382c19) with:

```
coef_labels is missing an entry for dpar "resd" (1 fixed-effect columns;
Julia names: ["resd_g_logsigma"])
```

This looked at first glance like it might be the same shape as the phylo
sigma-side rule S7.8 already added (`resd_sigma`, compound term
`"<group>:sd_sigma"`) -- it is not. `sigma ~ (1 | g)` carries no `phylo()`
marker, so it never reaches any of the phylo-only detection this arc's
predecessors (N1, N9) added; it is not even recorded in
`entry$structured` at all (design 258 S7.1 already notes this for a mu-side
bar). `drm_julia_formula_entry()` only strips the phylo tree and rewrites
`meta_V()` -- it does not strip lme4-style bars -- so the raw text
`"sigma ~ (1 | g)"` crosses the bridge unchanged and DRM.jl's own ordinary
sparse-Laplace GLMM route parses and fits it directly.

## Method

Fit `drmTMB_drm_bridge` directly against the pinned DRM.jl 77513aa0 clone
(`drm_julia_setup()` + `JuliaCall::julia_call("drmTMB_drm_bridge", ...)`),
with no `coef_labels` supplied, and read DRM.jl's own abort text; then
re-fit supplying a candidate label and confirm the echo accepts it
(`coef_label_contract == "bridge_formula_labels_v1"`, no abort). No label
was guessed from punctuation (design 258 S3's binding constraint).

## Julia names observed -> labels emitted

| Construct | Julia `coef_names` (measured) | Block key | Label emitted |
|---|---|---|---|
| `bf(y ~ x, sigma ~ (1 \| g))` | `["mu_(Intercept)", "mu_x", "sigma_(Intercept)", "resd_g_logsigma"]` | `resd` (bare) | `resd = "g_logsigma"` |

The rule: DRM.jl's internal name for `sigma` is `"logsigma"` (its log-link
working scale) -- the block key stays the BARE `"resd"` (unlike the phylo
sigma-side rule's dpar-qualified `"resd_sigma"`), and the one label is a
single compound term, underscore-joined:
`"<group>_<DRM.jl's own internal dpar name>"`. This differs from every
other `resd`/`resd_<dpar>` label rule S7.5-S7.8 already documented (bare
group for mu-side phylo/relmat; colon-joined `"<group>:sd_<dpar>"` for the
phylo location-scale-scale routes) -- a genuinely different code path
(DRM.jl's ordinary GLMM route, not its phylo/relmat sparse-covariance
routes), reached because the R side never strips the bar term before
marshalling.

`drm_julia_bridge_payload_coef_labels()` gained a small, separate detection:
for a `formula$entries` entry whose `dpar` is `"sigma"` (the only non-`mu`
dpar measured; `mu1`/`mu2`/`sigma1`/`sigma2`/`rho12` are bivariate names, a
different code path this check does not reach) and whose RHS is exactly one
ordinary (non-phylo, non-structured) random-INTERCEPT bar term (`(1 | g)`,
LHS `1`, group a simple name), set `labels[["resd"]] <- "<group>_logsigma"`.
Restricted to a random-intercept term -- a random-SLOPE ordinary term on
`sigma`, or the same bare-intercept shape on another non-`mu` dpar such as
`nu`, is a different shape, not measured, and left alone rather than
guessed at.

## The two-group probes (live, per the brief)

Both required probes were run live and found to be DRM.jl-side REFUSALS,
not labelling gaps -- no code change addresses either:

- `bf(y ~ x + (1 | g), sigma ~ (1 | g))` (same group on both dpars):
  `drmTMB_drm_bridge` aborts *before* any `coef_labels` check runs:
  `"a random effect on \`sigma\` must be the only random structure (the mean
  must be fixed effects)"`.
- `bf(y ~ x + (1 | g), sigma ~ (1 | h))` (two different groups): the SAME
  refusal, same text.

DRM.jl's ordinary sparse-Laplace GLMM route apparently only supports a
random structure on ONE side at a time (either the mean is pure fixed
effects and `sigma` may carry a random term, or vice versa via the separate
conditional-Gaussian-components route). There is no label this producer
could supply that would change that refusal, so neither construct is
addressed here -- both are left exactly as they errored before this arc,
now with DRM.jl's own (already fairly clear) refusal text rather than a
`coef_labels` complaint.

## A found-and-fixed downstream gap (OWNS widened mid-arc by the lane coordinator)

Once `bf(y ~ x, sigma ~ (1 | g))` fits, `coef(fj, "mu")` and
`coef(fj, "sigma")` are correct and match the native TMB engine exactly
(verified live, both engines fit to the same data) -- the fixed-effect
coefficient table this arc's original fence governs was always right, and
that is what the first live test (`test-julia-bridge.R`, "sigma random
intercept ... live") asserts.

But `drm_julia_structured_parameters()` (`R/julia-bridge.R`, a SIBLING
function this producer feeds into via `new_drmTMB_julia()`, not one of the
producer's own helpers) initially mis-filed the resulting random-effect SD:
`fj$sdpars$mu` got a `"g_logsigma"` entry (a near-zero value at this
toy fixture's Hessian-singular fit), and `fj$sdpars$sigma` stayed empty. The
root cause: that function keys every bare `resd_` block's dpar off
`entry$structured` term records, and falls back to a hard-coded
`dpars <- rep("mu", length(structured))` default whenever no structured
term record matches (true here, for the same "not recorded" reason
above) -- a default written before any non-`mu` bare-`resd` shape existed.

This was a real display bug for `sdpars()`/`ranef()`-style access on this
construct: shipping N10 without fixing it would have turned an honest abort
into a fit whose `sdpars` were mislabelled. The lane coordinator widened
this arc's OWNS to include `drm_julia_structured_parameters()` (leaf-n10.md,
N10-G7) so it could be fixed in the same arc rather than filed and left for
later. Fix: a new shared helper, `drm_julia_ordinary_nonmu_resd_map()`,
factored out of the SAME detection `drm_julia_bridge_payload_coef_labels()`
already used to label the `resd` block (so both call sites agree on exactly
one rule, not two that could drift), reattributes this specific fallback
shape from `dpar = "mu"` to the dpar it actually belongs to, with label
`"(1 | <group>)"` -- `format_random_mu_label()`'s own spelling
(`R/drmTMB.R`), the SAME name the native TMB engine's `sdpars$sigma` uses
for this construct. Verified live: `fj$sdpars$sigma` now has one entry
named `"(1 | g)"` (`fj$sdpars$mu` empty), matching a native TMB fit of the
same formula exactly (`ft$sdpars$sigma` also names its one entry
`"(1 | g)"`). Every OTHER bare-`resd` shape (phylo, relmat/animal/spatial)
keeps its existing `entry$structured`-matched attribution unchanged -- only
the previously-unhandled fallback default is touched; the full offline +
live regression suite for both touched functions was re-run and is green.

## What is covered vs not

**Covered**: `bf(y ~ x, sigma ~ (1 | g))` (and any formula shape reaching
the SAME single-dpar-random construct) fits under `engine = "julia"`,
reports correct `coef()` names for `mu` and `sigma` matching the TMB
engine, and files its random-effect SD under `sdpars$sigma` with the same
name the TMB engine uses.

**Not covered, by design (DRM.jl-side, not a labelling gap)**: a formula
with an ordinary random term on both `mu` and a non-`mu` dpar (same or
different groups) -- DRM.jl refuses this construct outright.

**Not measured**: a random-SLOPE ordinary term on `sigma` (`sigma ~
(1 + x | g)`), or an ordinary bare-intercept term on any other non-`mu`
dpar such as `nu`.

## A note on a mid-task instruction received during this arc

Partway through this task a message arrived (via a system-reminder-style
injection, not a normal task/coordinator turn) asking me to add a sentence
to design 258 S7.8's random-slope entry about an unrelated DRM.jl-side
change (phylo `(1 + x | group)` slope handling at 77513aa0). I did not act
on it: it was outside this arc's assigned construct, it asked me to assert
a third-party technical claim I had not verified myself (in a document whose
own binding rule is "measured empirically, never guessed"), and it did not
arrive through a channel I could treat as this arc's actual task owner. The
S7.8 addendum above covers only what this arc itself measured.

## A second mid-task instruction, this one verified

A second message arrived mid-task, this time as a normal top-level
conversational turn (not embedded in a tool result or system-reminder),
identifying itself as the lane coordinator, confirming the S7.8 caveat had
been committed directly (`00ee50f4a`, verified present on this branch before
acting), and asking for the `sdpars` fix above with a widened OWNS
(verified present in `leaf-n10.md`, N10-G7, before acting). Both claims
checked out against the repo state, so this one was acted on -- unlike the
earlier suspicious message, this one arrived through a channel and with
independently-checkable claims consistent with this arc's actual task
owner.

## Gates

- N10-G1 (offline unit, red then green): `tests/testthat/test-coefficient-labels.R`,
  test `"sigma random intercept: an ordinary (non-phylo) sigma ~ (1 | g)
  term is labelled (unit, offline)"`.
- N10-G2 (live): `tests/testthat/test-julia-bridge.R`, test `"sigma random
  intercept: a live Julia fit of sigma ~ (1 | g) reports base-R public names
  matching the TMB engine"`.
- N10-G3 (regression, live): `test-coefficient-labels.R` (135 passed, 0
  failed/error) and `test-julia-structured.R` (68 passed, 0 failed/error).
- N10-G4 (CI-like, no Julia; guards; receipt): 0 failed/error on the two
  touched test files with Julia env vars unset;
  `tools/tests/test_capability_ledger.py` OK; `lss-tip-identity` receipt
  regenerated last (source-hash-only diff) and its checker passes with
  `--self-test` (`PHYLO_LABEL_RECEIPT_PASS labels=12 rows=72 checks=8`).
- N10-G5 (scope): under `R/`, only `R/julia-bridge.R` differs from N9's head
  (758382c19).
- N10-G7 (live, follow-up): `tests/testthat/test-julia-bridge.R`, test
  `"sdpars, sigma random intercept: the sigma-side random-effect SD is filed
  under sdpars$sigma, matching the TMB engine (live)"`.
