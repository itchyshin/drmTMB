# Diagnosis: the four heaviest `unusable_interval` cells (G5 coverage campaign)

Author: Gauss (numerical/likelihood review), diagnostic slice only. No `R/`,
`src/`, or ledger changes were made. All claims below are grounded in either a
`file:line` citation, a query against
`~/g5run/g5-reconciled-final.rds` on rorqual, or a local reproduction run in
this worktree (`R_PROFILE_USER=/dev/null Rscript --no-init-file`, `devtools::load_all()`).

## Scope

Four cells, in order of raw unusable count:

| route | parm | rung | unusable | n | rate |
|---|---|---|---|---|---|
| truncated_nbinom2 | `sd:mu:(1 \| id)` | 1x | 702 | 1200 | 58.5% |
| student | `fixef:nu:(Intercept)` | 2x | 288 | 1200 | 24.0% |
| truncated_nbinom2 | `fixef:sigma:(Intercept)` | 1x | 274 | 1200 | 22.8% |
| nbinom2 | `sd:mu:(1 \| id)` | 0.5x | 120 | 1200 | 10.0% |

## Verdict per cell

### 1. `truncated_nbinom2 sd:mu:(1 | id)` 1x — IDENTIFIABILITY LIMIT

DGP: `mr_g4g5_t5_dgp()` (`inst/sim/R/sim_missing_response_g4g5.R:457-465`), 34
groups x 8 obs (n=272), true `sd:mu:(1 | id) = 0.35`. Only the 1x rung exists
for this route (no 0.5x/2x comparison inside the campaign).

Direct reproduction (`mr_g4g5_t5_dgp(1)` default seed, `mr_g4g5_fit_t5`) gives
`sd_hat = 0.31`, Wald SE `0.118` — a reasonable, non-degenerate point estimate,
more than 2.6 SEs from zero. I then re-profiled `log_sd_mu` from scratch,
outside both drmTMB profile engines, by pinning `log_sd_mu` at a grid of
values and re-optimizing the other four free parameters with `nlminb`
(generous `iter.max = eval.max = 1000`, i.e. more generous than
`TMB::tmbprofile()`'s defaults). Result: the lower-tail deviance plateaus at
`2*Δnll ≈ 2.49` even at `sd_mu = 0.0008` (essentially zero), never reaching the
`χ²₁` 95% cutoff of `3.84` (`qchisq(0.95,1)`). This is a genuine, non-crossing
profile — confirmed independent of any code in `R/profile.R`.

`profile.message` for this cell is 697/702 `near_sd_boundary` + 4
`profile_failed` ("could not extract...") + 1 `nonfinite_interval`. The 697
`near_sd_boundary` rows all went through the **endpoint engine** (0/1200 rows
in this cell used `TMB::tmbprofile`'s trace at all when restricted to the
near_sd_boundary subset; only the 5 `profile_failed` rows have a trace —
consistent with `profile_endpoint_target_supported()`,
`R/profile.R:3212-3224`, routing `random-effect-sd` targets to the endpoint
engine by default). The endpoint engine's own floor-detection
(`lower_boundary_result()`, `R/profile.R:3416-3426`, triggered via
`allow_lower_boundary`) is doing exactly what my from-scratch grid showed by
hand: it correctly recognizes the deviance never crosses before the internal
log-SD floor (`log(sqrt(.Machine$double.eps))`, `R/profile.R:3415`) and
reports `lower = 0`.

Cross-family comparison sharpens the "aggravated by design" reading:
`nbinom2 sd:mu:(1 | id)` (same target class, non-truncated) fails at 10.0%
with 24 groups (0.5x), 0.6% with 48 groups (1x), 0.0% with 96 groups (2x) — a
clean monotone decline with group count. `truncated_nbinom2` at 34 groups
(between the nbinom2 24- and 48-group points) would be expected at roughly
3-8% under that trend; it instead fails at 58.5%. Zero-truncation removes the
low counts that would otherwise anchor extra-Poisson/between-group
heterogeneity, so the truncated family carries far less information about
`sd:mu` per group than a naive group-count comparison suggests. This looks
like both a genuine family-specific identifiability weakness and an
under-powered design choice (34 groups x 8 obs, vs. 48 x 12 for the sibling
nbinom2 cell) for this specific target.

**Not owned by an engine bug**: the from-scratch reprofile used neither the
endpoint engine's code nor `TMB::tmbprofile()`, and reproduced the same
non-crossing result.

### 2. `student fixef:nu:(Intercept)` 2x — MIXED: identifiability limit (majority) + a real, separable engine bug

DGP: `mr_g4g5_t2_dgp("student", ...)` (`inst/sim/R/sim_missing_response_g4g5.R:315-370`),
true `nu` link value `log(7) = 1.946` (`df = 2 + exp(nu) = 9`).

Direct reproduction with a **known-failing seed pulled from the artifact**
(`attempt_seed = 1147532079`, `replicate = 1003`): the fitted `beta_nu`
(link-scale) landed at `13.82`, i.e. an effectively enormous `df`
(`2 + exp(13.82) ≈ 10^6`) — the simulated residuals for this replicate looked
close to Gaussian, so the optimizer ran the t-distribution's `df` parameter
out toward the region where it converges to a Normal. This is a textbook
non-identifiability: the Student-t log-density is provably flat in `nu` as
`nu → ∞`, so no LR crossing can exist there. My from-scratch grid re-profile
(same protocol as above, generous `nlminb` control) over `theta = theta_hat ±
[-4, 4]` on the link scale (`df` from ~18,000 to ~5.4x10^7, all practically
indistinguishable from Gaussian) found `|Δnll| < 0.01` everywhere — genuinely
flat, not a numerical artifact of either profile engine.

**However**, this is not the whole story for this cell. Per the sibling
diagnostic slice's finding (which I independently verified against the raw
`profile_trace` text stored in the artifact, not just re-derived it): parsing
`"Profile value: X"` entries from `profile_trace` for all 1200 rows in this
cell and comparing the first ("baseline") value against the trace minimum
shows 292/1200 rows (24.3%) with `min < baseline`, and this is **almost
perfectly enriched among unusable rows**: 287/288 unusable rows show it,
vs. 5/912 usable rows (`profile.boundary`/`interval_usable` crosstab, rorqual
query). Unlike a small numerical-noise effect, the magnitude is large: median
gap ~625 nll units among unusable rows, max 75,721 — many times the entire
model deviance (`nll_hat ≈ 719` for an 800-row dataset). That scale rules out
"TMB found a genuinely better fit"; a legitimate likelihood improvement of
tens of thousands of nll units for an 800-row student-t fit is not plausible.

Inspecting the raw trace text for the worst record (`replicate = 318`,
`attempt_seed = 231430375`, gap = 75,721) shows why: the profile is smooth and
monotonically increasing for 47 consecutive steps (`751.14 → 752.60`, a
well-behaved bracket search), and then the single last point in that
direction's search abruptly reads `"Profile value: -74970"` before the
direction flips and the sequence restarts near the baseline. This is a
numerically pathological point — `TMB::tmbprofile()`'s bracket-search steps
out along the (genuinely flat) large-`nu` ridge and, at some outlying grid
value, the constrained inner optimization lands somewhere that returns a
spurious, physically implausible NLL. `stats::confint(profile)`'s spline-based
endpoint extraction (`drm_tmbprofile_confint()`, `R/profile.R:3700-3716`) then
either throws `"need at least two non-NA values to interpolate"` (the
dominant `profile_failed` message for this cell, 286/1200 rows) or silently
returns an NA/garbage endpoint (`nonfinite_interval`, 1 row).

**Verdict**: the *statistical* answer ("no upper bound available for `nu`
here") is correct for the majority of these 288 records — a flat likelihood in
`nu` cannot be validly bounded by a two-sided `χ²₁` profile. But the *engine's
handling* of that flatness is broken: instead of gracefully detecting the
plateau the way the endpoint engine does for SD targets
(`allow_lower_boundary`/`lower_boundary_result`), `TMB::tmbprofile()`'s
bracket search runs into a numerically degenerate region and returns a
corrupted sentinel value, which is what actually produces the opaque
`approx()` crash users see. This is a genuine, fixable engine defect,
separable from the (also genuine) `nu → ∞` non-identifiability.

### 3. `truncated_nbinom2 fixef:sigma:(Intercept)` 1x — predominantly IDENTIFIABILITY LIMIT (same mechanism as #1), small (~1%) engine-noise contribution

Same fit object as #1 (default-seed reproduction). Direct from-scratch grid
reprofile of `beta_sigma[1]` (the sigma intercept) shows the same qualitative
shape: the lower tail plateaus at `Δnll ≈ 1.78`, just under the `1.921` cutoff,
as the dispersion parameter is pushed toward `sigma → 0` (near-Poisson limit,
`sigma ≈ 0.02` at the grid edge tested). This is a genuine boundary-adjacent
flatness in the same truncated-count family, not a copy-paste of #1's
mechanism by coincidence: dispersion and the `mu`-random-intercept SD both
absorb extra-Poisson variance in this model, and truncation weakens the
signal for both simultaneously.

`profile.engine` for this target is always `tmbprofile` (fixed effects are not
endpoint-supported, `profile_endpoint_target_supported()` excludes
`target_class == "distributional-scale"` fixef rows structurally — confirmed
directly: `confint(fit, parm = "fixef:sigma:(Intercept)", profile_engine =
"endpoint")` on my reproduction returned
`conf.status = "profile_failed"`, `profile.message = "endpoint engine
unsupported for this target class"`). I checked whether this cell shares
cell #2's overflow-sentinel bug: parsing `profile_trace` for all 1200 rows
finds only 10/1200 rows with `min < baseline` by more than `0.01`, and the
gaps are small (`0.01`–`0.73`, several of which are still `interval_usable =
TRUE`) — nothing resembling the `-74970` sentinel. So this cell's failures are
overwhelmingly the genuine-flatness mechanism, with only a minor,
probably-benign numerical-precision contribution.

### 4. `nbinom2 sd:mu:(1 | id)` 0.5x — clean IDENTIFIABILITY LIMIT

24 groups (`mr_g4g5_group_count(48, 12, 0.5) = 24`), true `sd = 0.45`. 100% of
rows in this cell went through the endpoint engine (`profile_trace` is empty
for all 1200 rows — zero tmbprofile fallback), so this cell has zero exposure
to the `TMB::tmbprofile()` bracket-search bug described in #2. Within the same
family, the failure rate falls monotonically with group count: 10.0% at 24
groups, 0.6% at 48 groups, 0.0% at 96 groups — the standard small-`g`
variance-component profile-CI boundary problem, already reasoned about
elsewhere in this codebase (`R/profile.R:1870-1881`, the `warn_profile_boundary()`
comment citing measured 0.07-0.86 conditional coverage at a profile boundary,
same phenomenon lme4 reproduces on the same seeds:
`docs/dev-log/simulation-artifacts/2026-08-04-d117-10group-profile-gate/`).

## Whether `near_sd_boundary` and `nonfinite_interval` share a root cause

Yes, for the two dominant SD-boundary-adjacent cells (#1, #4): they are two
different terminal representations of the identical event — the profile
likelihood for a variance-component-type parameter does not cross the
standard `χ²₁` LR threshold before the internal SD floor (or before diverging
outward). `near_sd_boundary` is the endpoint engine's own graceful detection
of that event (`profile_interval_diagnostics()`, `R/profile.R:3736-3742`,
triggered when the transformed interval's lower bound is `<= sqrt(.Machine$double.eps)`
after the endpoint engine reports `theta = -Inf`). `nonfinite_interval` is the
same non-crossing event surfacing through the `TMB::tmbprofile → stats::confint(profile)`
spline route, where it produces `NA` (out-of-range `approx()` interpolation)
instead of a coded `0` floor (`R/profile.R:3726-3727`).

Evidence: `boundary_or_clamp` (`inst/sim/R/sim_missing_response_g4g5.R:1224`,
literally `isTRUE(profile.boundary) || conf.status == "clamp_limited"`) tracks
`interval_usable == FALSE` with population near-100% agreement in all four
cells (only the small `profile_failed` slice — which never sets
`profile.boundary`, since it returns early — sits outside that
correspondence). This is a direct consequence of the diagnostic function's own
logic, not independent new evidence, but it is a useful sanity check that the
harness's derived flag is behaving as designed.

For the `fixef` targets (#2, #3), which only ever reach `TMB::tmbprofile()`,
the correspondence is looser: most of their `nonfinite_interval` /
`profile_failed` records are the same genuine-flatness mechanism, but cell #2
additionally carries a distinct, large-magnitude numerical-overflow bug in
`TMB::tmbprofile()`'s own bracket search (see verdict #2) that is not present
at all in #1/#4 (which never invoke `TMB::tmbprofile()` for the bulk of their
failures) and is only a minor (~1%, small-magnitude) contributor in #3.

## The `student fixef:nu` ruling

"No interval" is the statistically correct answer for the majority of these
288 records: `nu`'s Student-t density is flat as `df → ∞`, and a two-sided
`χ²₁` profile genuinely cannot bound a flat likelihood. This is not a
too-narrow grid or a too-tight `parm.range` in the ordinary sense — my
from-scratch reprofile spanned `df` from ~18,000 to ~5.4x10^7 and found no
crossing, because none exists at any finite `df` once the data look
close-to-Gaussian.

What is wrong is the *mechanism by which the engine fails*: `TMB::tmbprofile()`'s
bracket search, while exploring that flat ridge, occasionally lands on a
numerically pathological point (the raw trace shows a smooth 47-point
monotone climb followed by an isolated `-74970`), and that corrupted value
then breaks `stats::confint(profile)`'s spline extraction with an opaque
`approx()` error. A user reading `"Could not extract a profile confidence
interval... the profile may not cross the likelihood-ratio threshold"` cannot
distinguish "your data genuinely can't bound this parameter" from "the
profile numerics broke." Both are true here, but only the first is the
message's claim.

## Fixable fraction of the 42

Directly evidenced, only for these 4 cells:

- **nbinom2 sd:mu (120 records, cell #4)**: 0% engine-fixable. Clean small-`g`
  statistical boundary, zero exposure to `TMB::tmbprofile()`.
- **truncated_nbinom2 sd:mu (702, #1) and fixef:sigma (274, #3)**:
  predominantly (>95%+) not engine-fixable — genuine flat/boundary-adjacent
  profiles confirmed by independent from-scratch reprofiling. A small slice
  (~1% of #3's records, likely similar for #1) shows minor numerical
  imprecision that a more generous `nlminb` control (mirroring
  `profile_endpoint_inner_control()`, `R/profile.R:3262-3271`) inside the
  `tmbprofile` bracket search might tighten, but the affected records mostly
  already succeed (`interval_usable = TRUE`) or fail by a small margin — not
  enough to flip either cell's pass/fail status.
- **student fixef:nu (288, #2)**: a large fraction (~24% of the cell, ~97% of
  its unusable records) show the overflow-sentinel signature and are
  plausibly convertible from a hard crash to a *clean, correctly labelled*
  one-sided/boundary report by hardening the bracket search (bounding the
  search range for runaway link-scale fixed effects, or rejecting/discarding
  implausible objective values before they reach `confint(profile)`, or
  reusing the endpoint engine's graceful-stop pattern for tmbprofile-driven
  targets too). That is a genuine, worthwhile engine fix on its own
  correctness/legibility merits. It would **not**, by itself, flip this cell
  from FAIL to PASS under the campaign's current all-1200-must-be-usable rule,
  because the underlying `nu → ∞` ridge is real and would still frequently
  produce a legitimately one-sided (not two-sided-usable) interval — unless
  the campaign's definition of "usable" is separately extended to accept a
  correctly flagged one-sided/boundary interval as usable, which is a policy
  decision outside this diagnostic's scope.

Not directly evidenced (would need a targeted look at the other 39 cells to
confirm): the `near_sd_boundary`/`nonfinite_interval` reason-code
concentration (835 + 470 of ~1,470-ish total unusable records project-wide,
per the task brief) and the highly skewed per-cell distribution (median 7.5,
75th pct 21 out of 1200) are both consistent with the same small-sample
variance-component/weakly-identified-shape-parameter boundary phenomenon
recurring at a low, genuinely-expected incidence across most of the 43
cells — not concentrated bugs. A boundary-adjacent profile-CI procedure will,
by construction, occasionally fail to cross on *some* fraction of replicates
even in a healthy cell; requiring zero such occurrences across 1200 attempts
is a very strict bar that a correctly-functioning profile-CI procedure can
fail purely from binomial variation once the true per-draw failure rate is
non-zero (see cell #4: 0.6% at 48 groups is "healthy" by any recovery
standard, yet would fail this all-1200 bar with high probability if 1x had
been sampled at exactly this cell's rate over many campaigns). This is a
structural observation about the gate, not a request to change it — that
decision belongs to the coordinator.

**My honest overall estimate**: of the 42 `unusable_interval` failing cells,
I would guess (not measured) that a majority are like #1/#3/#4 —
predominantly genuine small-sample/boundary-adjacent statistical limits,
non-fixable by an engine change and correctly reported as unavailable rather
than fabricated — with a minority resembling #2, where a real but narrower
`TMB::tmbprofile()` bracket-search hardening would improve error legibility
and reduce (but not eliminate) unusable counts for cells that profile
runaway-link-scale fixed effects (shape/df-type parameters are the most
likely other candidates: `skew_normal`'s `nu`, possibly other family shape
parameters that share `nu`'s unconstrained-link, flat-at-extreme-values
structure — this list is a hypothesis, not evidence; it was not checked here).

## What I would change (recommendation, not implemented)

1. Harden `TMB::tmbprofile()`-driven bracket search for fixed-effect targets
   against numerically pathological grid points: sanity-check that a newly
   evaluated `value` is not implausibly far below the fitted objective
   (e.g. more than, say, 2x the model's total deviance) before accepting it
   into the trace, and stop/flag the search direction as boundary-touching
   instead of continuing to step outward. This directly targets cell #2's
   `-74970`-style sentinel.
2. Consider giving fixed-effect profile targets whose link scale is
   unconstrained-and-unbounded (like a log/exp-linked shape/df parameter) the
   same graceful one-sided/boundary reporting the endpoint engine already has
   for SD targets (`allow_lower_boundary`), rather than only reporting a hard
   `profile_failed` crash. This is a legibility fix, not a fix to the
   underlying non-identifiability.
3. I would **not** try to "fix" cells #1, #3, #4 by adjusting profile
   engine internals — the from-scratch reprofiling in this diagnosis shows the
   non-crossing is genuine given the DGP as specified, and any engine change
   that fabricated a finite bound there would be actively wrong. The only
   legitimate levers for those cells are (a) redesigning the DGP with more
   groups/replication if the goal is to demonstrate the profile CI *can*
   succeed at adequate information, or (b) accepting and clearly documenting
   that profile CIs will legitimately fail some nonzero fraction of the time
   near a variance-component or weakly-identified-shape boundary, and
   loosening the campaign's "all 1200 must be usable" pass rule accordingly.

## What needs a targeted re-run to confirm

- I only directly reproduced **one** failing seed each for cells #1/#3 (shared
  fit) and #2. The magnitude/frequency findings for #2's overflow bug and the
  #1/#3 flatness are from the artifact's stored `profile_trace` text
  (aggregate evidence across all 1200 rows per cell), which I trust, but a
  from-scratch independent reprofile of a *sample* of additional failing
  seeds (say 10-20 per cell) would strengthen the "not a per-seed fluke"
  claim. **Estimated time: under 30 minutes locally** (each single-fit
  reproduction + grid reprofile took roughly 30-60s in this session; 10-20
  seeds x 4 cells is well inside the 30-minute local-run line, no
  Totoro/DRAC needed).
- I did **not** check whether the `-74970`-style overflow bug appears in any
  of the other 39 failing cells, or in cells that currently pass (it may be
  present but rare enough not to break `confint(profile)` there). Answering
  "how many of the 42 are like #2" would require parsing `profile_trace` for
  all 43 failing cells the same way I did for #2 here — a single aggregate
  query against the existing artifact (no new fitting), well under 30
  minutes.
- The "aggravated by design" claim for truncated_nbinom2 (cell #1) rests on a
  cross-family comparison (nbinom2's group-count trend), not a same-family
  0.5x/2x trend, because only the 1x rung was run for this route in this
  campaign. Confirming that a larger truncated_nbinom2 design (e.g. 68 or 136
  groups) meaningfully reduces the failure rate would need new fits — a
  small grid of DGP sizes x a few hundred replicates each, which I estimate
  at 1-2 hours on Totoro (not attempted here, per the no-campaign
  instruction).
