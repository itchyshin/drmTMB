# DO-T3 Batch C: Atom/Mixture `{d,p,q}` Families (tweedie, zero_one_beta, zi_poisson, zi_nbinom2, truncated_nbinom2, hurdle_nbinom2)

## Purpose

This note documents the DO-T3 batch C slice of the distributional output &
adequacy layer arc (issues #747/#748; ultra-plan:
`docs/dev-log/2026-07-12-distributional-output-adequacy-layer-ultra-plan.md`;
foundation: `docs/design/81-distributional-output-adequacy-t0a-foundation.md`;
prior batches: `docs/design/82-distributional-output-adequacy-do-t3-batch-a.md`,
`docs/design/83-distributional-output-adequacy-do-t3-batch-b.md`). The reader
is a future contributor implementing DO-T3 batch D (bivariate marginal
`{d,p,q}` for `biv_gaussian`, the only remaining unimplemented `model_type`)
or a reviewer checking that batch C's atom/mixture decompositions match the
compiled density, reuse the already-promoted base families' native maps
rather than re-deriving them, and correctly generalize the Dunn-Smyth
left-limit rule beyond a single hardcoded atom at 0.

Batch C promotes six families to `status = "reference"` in `R/family-dpq.R`:
**tweedie** (the last remaining `"spike"`-status family, promoted to
`"reference"`), **zero_one_beta**, **zi_poisson**, **zi_nbinom2**,
**truncated_nbinom2**, and **hurdle_nbinom2**. Combined with DO-T0a's
gaussian and batches A/B's ten families, seventeen of eighteen `model_type`
values are now `"reference"`. Only `"biv_gaussian"` remains
`"unimplemented"`. The `{d, p, q}` closure signature `(y_or_u, params)` and
the CP1-frozen registries (`drm_family_dpq()`'s `switch()`,
`fitted_distribution_params()`'s per-family column attachment) are unchanged
by this batch -- no new family needed a `fitted_distribution_params()`
column, since every new family's dpars (`zi`, `hu`, `zoi`, `coi`) already
have a `drm_dpar_link()` entry and route through the ordinary
`predict_parameters()` path, unlike `trials`/`CPk` (batch A/B).

This batch's one genuinely new object-shape addition is **additive, not a
signature change**: an `atoms` field on each `drm_family_dpq()` entry
(numeric vector of isolated atom locations) and on the
`fitted_distribution()` return object, replacing the DO-T1/batch-A/B residual
left-limit rule's hardcoded "atom at `y == 0`" assumption
(`R/adequacy.R:drm_quantile_residual_u()`) with a generic rule driven by that
field -- required because `zero_one_beta` has TWO atoms (`0` and `1`), which
the old hardcoded rule could not express.

## Dedup prelude (Emmy's #8 for batch C)

Both duplicates batch A/B flagged and left open for a "not yet promoted"
family are now closed, since both families ARE promoted in this batch:

- **zero_one_beta's `phi <- 1 / sigma^2` inline formula.** Flagged in batch A
  ("Not consolidated"), still open after batch B (batch B closed
  `beta_binomial`'s copy but explicitly deferred `zero_one_beta`'s to "its
  own DO-T3 batch" -- this one). `simulate.drmTMB()`'s `"zero_one_beta"`
  branch (`R/methods.R`) now calls `drm_beta_shapes(mu, sigma)` (the SAME
  helper the "beta" family and, since batch B, "beta_binomial" call), rather
  than re-deriving `phi`/`shape1`/`shape2` inline. This closes the last open
  duplicate of that formula across the three routes (compiled density,
  `simulate()`, and now `drm_family_dpq_zero_one_beta()`'s `{d,p,q}`
  closures).
- **`truncated_nbinom2_p0()`'s inline `1 / sigma^2`.** Flagged in batch A
  ("the other flag"), left open through batch B since neither
  `truncated_nbinom2` nor `hurdle_nbinom2` nor `zi_nbinom2` was promoted yet.
  All three ARE promoted in this batch, and all three are built on the SAME
  nbinom2 kernel `drm_nbinom2_size(sigma) = 1 / sigma^2` (batch A's helper)
  already computes. `truncated_nbinom2_p0()` (`R/methods.R`) now calls
  `drm_nbinom2_size(sigma)`; `simulate.drmTMB()`'s `"truncated_nbinom2"`,
  `"hurdle_nbinom2"`, and `"zi_nbinom2"` branches (which previously wrote
  `size = 1 / sigma^2` inline at three separate call sites) now do too. This
  makes every route that needs the NB2 "size" parameter -- the compiled
  kernel (`src/drm_count_kernels.h`), `simulate()`, and
  `drm_family_dpq_{nbinom2,truncated_nbinom2,hurdle_nbinom2,zi_nbinom2}()`'s
  `{d,p,q}` closures -- share the one helper.

**Not newly flagged:** batch A's beta `1e-8` floor gap (compiled
`alpha`/`beta_shape` floor vs. `stats::{d,p,q}beta()`'s lack of one) carries
forward into `zero_one_beta`'s interior beta component unchanged (same
undetected-at-DG2-tolerance caveat, noted again below since it now applies to
a second family).

## Per-family atom decomposition and native maps (Noether's traps, verified against `src/drmTMB.cpp`)

- **tweedie** (`model_type == 16`, `src/drmTMB.cpp:2593-2621`): promoted from
  `"spike"` to `"reference"` with NO closure-code change -- the DO-T0a spike
  closure (`drm_tweedie_dpq()`, wrapping `tweedie::{d,p,q}tweedie()` at the
  public `(mu, sigma, nu)` -> native `(mu, phi = sigma^2, power = nu)` map)
  was already correct; this batch formalizes the atom-decomposition DG2 case
  and DG3 smoke that promotion requires. Single atom `{0}`: `P(Y = 0) =
  tweedie::dtweedie(0, mu, phi, power)` (the compound Poisson-gamma's
  zero-jump-count probability), and `d(0) == p(0)` exactly (no continuous
  density at or below 0) is the atom-mass identity; `p(huge) -> 1` is the
  normalization boundary check (same convention batch A/B use for ordinary
  continuous/discrete families). A fully package-independent series-expansion
  tweedie density reference already exists in the test suite
  (`tests/testthat/helper-tweedie-density.R`,
  `tweedie_compound_log_density_reference()`) for a future pass that wants to
  cross-check the `tweedie` package itself rather than trust it as the sole
  external comparator.
- **zero_one_beta** (`model_type == 15`, `src/drmTMB.cpp:2782-2858`): public
  `(mu, sigma, zoi, coi)`. Two atoms, `{0, 1}`: `P(Y = 0) = zoi * (1 - coi)`,
  `P(Y = 1) = zoi * coi`, interior density `(1 - zoi) * dbeta(y, shape1,
  shape2)` for `0 < y < 1` with `(shape1, shape2)` the SAME
  `drm_beta_shapes(mu, sigma)` conversion "beta"/"beta_binomial" use.
  `F(y) = P(Y = 0) + (1 - zoi) * pbeta(y, shape1, shape2)` for `0 <= y < 1`
  (this single formula already gives `F(0) = P(Y = 0)` exactly, since
  `pbeta(0, ...) = 0`), `F(y) = 1` for `y >= 1`. The quantile is a single
  closed-form expression with no atom-specific branching:
  `q(u) = qbeta((u - P(Y=0)) / (1 - zoi), shape1, shape2)` clamped to `[0,
  1]` before the `qbeta()` call -- clamped-to-0 input maps to `qbeta(0, ...)
  = 0` at/below the `y = 0` atom's threshold, clamped-to-1 input maps to
  `qbeta(1, ...) = 1` at/above `F(1-) = 1 - P(Y=1)`, so both atoms are
  handled by the SAME "fraction" transform pattern used below for
  `zi_poisson`/`zi_nbinom2`/`hurdle_nbinom2`. Noether's trap: the compiled
  kernel additionally inflates `mu` away from the exact boundary by `1e-12`
  (`mu = 1e-12 + (1 - 2e-12) * plogis(eta_mu)`, purely to keep the AD tape
  well-defined near `mu = 0`/`1`); `predict(fit, dpar = "mu")` returns the
  plain `plogis(eta_mu)`, so `alpha`/`beta_shape` computed here can differ
  from the compiled kernel's by `~1e-12 * phi` -- undetectable at DG2's
  `1e-8`/`1e-6` tolerances for the interior `mu`/modest `phi` DG2 exercises
  (same pattern as beta's `1e-8` floor gap, now noted for a second family).
- **zi_poisson** (`model_type == 8`, `src/drmTMB.cpp:3196-3258`): public
  `(mu, zi)`, both identity maps (`mu` is the Poisson rate exactly as
  "poisson" uses it; `zi` is the structural-zero probability). Fully
  discrete over the SAME non-negative-integer lattice "poisson" uses (the
  zero-inflation mixture adds mass AT an existing support point, `y = 0`,
  rather than opening an atom that breaks the lattice), so
  `drm_quantile_residual_u()`'s ordinary discrete `F(y - 1)` left-limit rule
  already handles it correctly with NO new code; `atoms = c(0)` is carried
  purely for DG2's atom-enumeration bookkeeping (the verification spec's
  "zi_\*: {0}" convention), not consumed by the residual left-limit rule (see
  the `atoms` field's doc comment at the top of `R/family-dpq.R`). `F(y) =
  zi + (1 - zi) * ppois(y, mu)` for `y >= 0` is a SINGLE formula (no separate
  `y = 0` case: `F(0) = zi + (1 - zi) * dpois(0, mu) = zi + (1 - zi) *
  ppois(0, mu)` already, since `ppois(0, mu) = dpois(0, mu)`). Quantile:
  `q(u) = qpois((u - zi) / (1 - zi), mu)`, the fraction clamped to `[0, 1]`
  before the `qpois()` call.
- **zi_nbinom2** (`model_type == 9`, `src/drmTMB.cpp:3598-3668`): the SAME
  additive zero-inflation mixture as `zi_poisson`, over the NB2 base
  (`size = drm_nbinom2_size(sigma)`) instead of Poisson. Same "fraction"
  quantile transform with `pnbinom`/`qnbinom` in place of `ppois`/`qpois`.
- **truncated_nbinom2** (`model_type == 11`, `src/drmTMB.cpp:3463-3510`):
  public `(mu, sigma)`, built on the SAME nbinom2 kernel
  (`drm_nbinom2_size(sigma)`) renormalized by the untruncated zero-mass
  `p0 = dnbinom(0, size, mu)`, matching the compiled kernel's
  `log_density(y) - log(1 - p0)` for `y >= 1` exactly (both routes share
  `drm_nbinom2_log_density()`/`drm_nbinom2_log_p0()`,
  `src/drm_count_kernels.h`). **No isolated atom** -- the support is a
  proper, if renormalized, discrete lattice starting at 1, not a jump
  breaking an otherwise-wider distribution, so `atoms = numeric(0)` and the
  ordinary discrete `F(y - 1)` left-limit rule applies unchanged (`F(0) = 0`
  below the truncated support is the correct left limit at the smallest
  supported value `y = 1`). `F(y) = (pnbinom(y, size, mu) - p0) / (1 - p0)`
  for `y >= 1`, `0` below; quantile `q(u) = qnbinom(p0 + u * (1 - p0), size,
  mu)` -- the SAME transform `simulate.drmTMB()`'s truncated_nbinom2 branch
  already draws with (as a deterministic right-inverse rather than a random
  draw).
- **hurdle_nbinom2** (`model_type == 12`, `src/drmTMB.cpp:3511-3597`): public
  `(mu, sigma, hu)`, built directly on the SAME zero-truncated-NB2 route
  `truncated_nbinom2` uses: `P(Y = 0) = hu`, `P(Y = k) = (1 - hu) *
  truncated_nb2_pmf(k)` for `k >= 1` (the hurdle mechanism REPLACES, not
  adds to, the `y = 0` mass -- unlike zero-inflation's additive mixture).
  `atoms = c(0)` for DG2 bookkeeping only (same convention as `zi_poisson`);
  the ordinary discrete `F(y - 1)` rule applies unchanged. `F(0) = hu`,
  `F(y) = hu + (1 - hu) * truncated_F(y)` for `y >= 1` where `truncated_F` is
  the SAME truncated-CDF `truncated_nbinom2` computes. Quantile:
  `q(u) = qnbinom(p0 + (1 - p0) * frac, size, mu)` where
  `frac = (u - hu) / (1 - hu)` clamped to `[0, 1]` -- composing
  `zi_poisson`'s "fraction" transform with `truncated_nbinom2`'s own
  `p0 + (1 - p0) * (...)` quantile transform.

## The `atoms` field generalization (required consequence of registering `zero_one_beta`)

DO-T1 (`R/adequacy.R`) originally hardcoded the Dunn-Smyth left-limit rule
for continuous-with-atom families as `ifelse(y == 0, 0, upper)` -- correct
for Tweedie (its one atom happens to sit at the support's exact lower
boundary, where `F(0-) = 0` identically, independent of any epsilon), but
inexpressible for `zero_one_beta`, whose second atom at `y = 1` is an
INTERIOR boundary where `F(1-) != 0`. This batch generalizes it:

1. **`atoms` is a new field on every `drm_family_dpq()` entry** (numeric
   vector of atom locations; `numeric(0)` for atom-free/purely-discrete
   families, `c(0)` for Tweedie/zi_poisson/zi_nbinom2/hurdle_nbinom2, `c(0,
   1)` for zero_one_beta). Set explicitly in EVERY family's constructor
   (not defaulted centrally), so the registry stays self-documenting; this
   is additive (existing fields `dpars`/`discrete`/`has_atom`/`status`/
   `d`/`p`/`q` are unchanged, and the frozen `(y_or_u, params)` closure
   signature is untouched).
2. **`fitted_distribution()` surfaces it** as `fd$atoms`
   (`fitted_distribution.drmTMB()`, `R/family-dpq.R`) -- an additive list
   element alongside the existing `model_type`/`status`/`discrete`/
   `has_atom`/`params`/`d`/`p`/`q`.
3. **`drm_quantile_residual_u()`'s (`R/adequacy.R`) has_atom-continuous
   branch is generalized** into a new helper, `drm_atom_left_limit(fd, y,
   upper, epsilon = 1e-8)`: away from every location in `fd$atoms`, `F` is
   continuous, so the left limit equals `F(y)` (`upper`, unchanged, and the
   Dunn-Smyth draw degenerates to the plain continuous case automatically);
   AT an atom `a`, the left limit is `F(a - epsilon)`, evaluated by shifting
   the FULL `y` vector down by `epsilon` at atom rows only (leaving
   non-atom rows untouched) and calling `fd$p()` ONCE on the shifted vector
   -- `fd$p()` is a per-row closure bound to the full `params` table (the
   frozen signature), so it must be called with a length-n vector aligned
   to that row order, never a subsetted shorter one (the same constraint
   batch A/B's test helpers document for `fd$p`/`fd$q`). For zero_one_beta's
   atom at `1`, `F(1 - epsilon)` handles the discrete generalization: `y ==
   1`'s row is shifted to `1 - 1e-8`, `fd$p()`'s `0 <= y < 1` branch
   evaluates the interior formula there, giving `F(1-)` to
   `O(density(1) * epsilon)` accuracy (an approximation, not exact -- see
   "Flagged uncertainties" below). For Tweedie's atom at `0`, `F(-epsilon) =
   0` exactly (the support starts at 0, independent of `epsilon`'s size), so
   this generalization reproduces the OLD hardcoded rule's exact numeric
   answer for Tweedie while additionally handling zero_one_beta's second
   atom.
4. **Discrete families are untouched by this generalization.**
   `drm_quantile_residual_u()`'s `fd$discrete` branch (the ordinary
   `F(y - 1)`/`F(y <= 0) = 0` rule) is unchanged and takes priority whenever
   `fd$discrete == TRUE`, regardless of `fd$atoms` -- this is why
   `zi_poisson`/`zi_nbinom2`/`hurdle_nbinom2` carry a non-empty `atoms`
   field (for DG2 bookkeeping) that the residual computation never reads:
   their zero-inflation/hurdle mass sits AT an existing point in an
   otherwise-ordinary discrete lattice, which the generic discrete rule
   already handles correctly (verified in `test-family-dpq-batchC.R`'s
   `expect_discrete_right_inverse()` checks for all three).

## DG2 results (per family; `tests/testthat/test-family-dpq-batchC.R`)

All six families pass all four DG2 checks (right-inverse identity, atom
decomposition, compiled-density agreement, external-reference agreement) at
the verification spec's tolerances (density agreement: `1e-8` for the
count-mixture families, `1e-6` for tweedie -- matching the DO-T0a spike
test's original tolerance for the `pmax(d, 1e-300)` floor guard -- and `1e-6`
for zero_one_beta, per the same `1e-8`-floor-gap caveat noted for "beta").

- **atom-decomposition normalization**: for each atom family, `d()` at every
  atom location is asserted to equal the hand-built atom-mass formula
  (`zi + (1 - zi) * d_base(0)`, `hu`, `zoi * (1 - coi)`/`zoi * coi`), and
  `p()` at the family's support boundary is asserted to reach `0`/`1` --
  since `p()` is the proper CDF, boundary normalization already certifies
  "atom masses + continuous/non-atom part sum to 1" (the same convention
  batch A/B use for ordinary families' normalization, extended here with
  the explicit atom-mass agreement the verification spec requires).
- **right-inverse convention**: tweedie/zero_one_beta (continuous-with-atom)
  use a new `expect_atom_right_inverse()` helper (`p(q(a)) >= a`,
  `p(q(a) - epsilon) < a`, `epsilon = 1e-6`) -- the continuous analogue of
  batch A/B's `expect_discrete_right_inverse()` (`p(q(a)) >= a`,
  `p(q(a) - 1) < a`), which zi_poisson/zi_nbinom2/truncated_nbinom2/
  hurdle_nbinom2 (all `discrete = TRUE`) reuse directly.
- **external references** (independent of `simulate()`/the package's own
  likelihood, per the verification spec): tweedie uses
  `tweedie::{d,p,q}tweedie()` (the DO-T0a spike test's existing external
  comparator); the five mixture/atom families with no single external
  package comparator use a hand-built mixture from the reference base
  (`{d,p,q}pois`, `{d,p,q}nbinom`, `pbeta`) plus the explicit atom/
  renormalization algebra, computed directly from `predict()`-ed dpars in
  the TEST body (not via `drm_family_dpq_*()`'s own closures, so a bug there
  cannot cancel against the assertion) -- per the spec's "hand-built mixture
  ... document the construction" convention.

## DG3 smoke results (local scale only)

One fixed-seed, known-DGP smoke test per family: simulate from the family at
a known `theta` (the mixture DGPs use the SAME explicit boundary/zero-
inflation/hurdle/truncation construction as the DG2 test, at a fresh seed),
fit the matching `drmTMB()` model, compute `residuals(fit, type =
"quantile")`, assert a Kolmogorov-Smirnov test against `N(0,1)` does not
reject (`p > 0.05`). All six pass (achieved p-values in the 0.4-0.97 range
across families, not marginal). As in batches A/B, this reuses DO-T1's
generic `residuals(type = "quantile")` machinery with NO family-specific
code beyond `drm_family_dpq()`'s entry and (for the two atom families) the
generalized `drm_atom_left_limit()` this batch adds -- once a family's
`discrete`/`has_atom`/`atoms` fields are set correctly, `R/adequacy.R`
handles the rest generically.

This is explicitly **not** the gated multi-seed DG3 power-arm campaign (type-
I control across >=20 seeds, rejection under >=2 named mis-specifications per
family) the verification spec requires before a stronger behavioural claim --
that remains a separate Curie/Grace campaign under `NOT_CRAN`, on Totoro/DRAC
per the compute directive.

## No firewall note needed

Unlike skew_normal (DO-T3 batch B), none of this batch's six families has an
existing `diagnostic_hold` entry in `check_drmTMB()`/`R/check.R` (verified by
grep before starting; `R/check.R` was not touched). The batch-B firewall
pattern ("this `{d,p,q}` promotion certifies the distributional-output axis
only, not the family's fit-quality status") therefore has nothing to
contradict here -- promoting these six families' `{d,p,q}` entries makes no
claim about (and changes nothing in) any separate inference-quality gate.

## The two "unimplemented model type" probes (required consequence)

Batch A used `poisson()` (then promoted) as its example of an unimplemented
family, swapped to `beta_binomial()`; batch B promoted `beta_binomial()` too
and swapped to `zero_one_beta()`. Batch C promotes `zero_one_beta()` (and
`tweedie()` and the count-mixture families), so both probes --
`tests/testthat/test-family-dpq.R`'s `"drm_family_dpq() aborts clearly for an
unimplemented model type"` and `tests/testthat/test-adequacy.R`'s
`"residuals(type = 'quantile') errors clearly for an unimplemented model
type"` -- now fit `biv_gaussian()` instead, the ONLY model type every batch
has left unimplemented (staged for DO-T3 batch D: bivariate marginal
distributional output). The `bf(mu1 = y1 ~ x, mu2 = y2 ~ x, sigma1 = ~1,
sigma2 = ~1, rho12 = ~1)` fixture matches the one
`test-distributional-outputs.R` already uses for `biv_gaussian`'s
`exceedance()` "out of scope" probe.

## Test files that needed updating as a consequence of promoting the last spike family

Promoting tweedie (the only `status = "spike"` family before this batch)
removes the one live family that could reach `residuals(type =
"quantile")`/`predict(type = "quantile")`/`exceedance()` with `status =
"spike"`, so three pre-existing tests that exercised the one-time spike
warning through a live tweedie fit needed reworking, not just a family swap:

- `tests/testthat/test-adequacy.R`'s `"spike-status families warn once per
  session, not on every call"` now calls `drm_warn_adequacy_spike()`
  (`R/adequacy.R`) directly with a hypothetical `status = "spike"` argument,
  rather than fitting a tweedie model -- the primitive itself (the function
  `residuals()`/`predict(type = "quantile")`/`exceedance()` all call) is
  unchanged and still fully testable without a live spike family.
- `tests/testthat/test-distributional-outputs.R`'s tweedie `exceedance()`
  test dropped its `expect_warning(..., "feasibility-grade")`/
  `expect_no_warning()` wrapping (tweedie no longer warns) and its
  now-redundant `drm_reset_adequacy_warning_state()` calls; the substantive
  atom/exceedance/Monte-Carlo assertions are unchanged.
- `tests/testthat/test-family-dpq.R`'s tweedie-specific tests (the DO-T0a
  spike density/atom-identity test and a hand-rolled Dunn-Smyth-at-the-atom
  demonstration) moved to `tests/testthat/test-family-dpq-batchC.R`,
  extended to the full DG2/DG3 suite, mirroring how batch B moved
  skew_normal's spike test out when IT was promoted.

## Flagged uncertainties (not silently resolved)

1. **zero_one_beta's atom left-limit is an epsilon approximation, not
   exact.** `drm_atom_left_limit()`'s `F(a - epsilon)` construction is exact
   for Tweedie (atom at the support's hard lower boundary, independent of
   epsilon) but an `O(density(1) * epsilon)`-accurate approximation to the
   true continuous left limit `F(1-)` for zero_one_beta's atom at `1`, at
   `epsilon = 1e-8`. Negligible for the Dunn-Smyth draw's own precision at
   the scales this batch's DG3 smoke exercises; an exact alternative (read
   the atom's point mass directly off `fd$d(a)` and subtract from `F(a)`)
   was considered and rejected in favour of a uniform epsilon-offset rule
   applied the same way across every atom family, for simplicity -- flagged
   here as the natural target if a future pass needs exact left-limit
   precision at pathological (very peaked interior beta) parameter
   combinations.
2. **zero_one_beta's `1e-12` compiled-`mu` inflation and beta's `1e-8`
   floor gap both carry forward, now doubly flagged.** See the native-map
   section above; undetected at DG2's fixed interior-theta vectors.
3. **DG3 is a local smoke pass, not the power-arm campaign** (same caveat as
   batches A/B). Type-I control across many seeds and detection power under
   named mis-specifications are not yet demonstrated for these six
   families; the verification spec's compute directive stages that for
   Curie/Grace on Totoro/DRAC.
4. **Pre-existing stale comment, not introduced by this batch** (flagged
   again, unfixed, same as batch B left it): `R/distributional-outputs.R`'s
   file-header comment (line ~18-20) still says the frozen registry "covers
   only `"gaussian"`/`"tweedie"`/`"skew_normal"`" -- stale since batch A,
   more stale now that fourteen more families are promoted. Left unedited
   (out of this batch's file scope; DO-T2 surface commentary, not the
   `{d,p,q}` registry itself).
5. **The fully package-independent tweedie density reference
   (`tests/testthat/helper-tweedie-density.R`) was not wired into this
   batch's DG2 test.** The verification spec names `tweedie::ptweedie` as
   the acceptable external comparator and the DO-T0a spike test already used
   it, so this batch reuses that convention rather than adding a second,
   stronger cross-check; noted as available for a future pass that wants to
   verify the `tweedie` package itself, not just `drm_family_dpq_tweedie()`'s
   use of it.

## Files touched

- `R/family-dpq.R`: top-of-file status-enum comment and the `atoms` field's
  contract comment updated; `drm_family_dpq()`'s roxygen and `switch()`
  extended (`zero_one_beta` after `beta`, `zi_poisson` after `poisson`,
  `truncated_nbinom2`/`hurdle_nbinom2`/`zi_nbinom2` after `nbinom2`, matching
  `drm_dpar_link()`'s canonical order); `atoms = <value>` added to every
  existing family's returned list (gaussian, tweedie, skew_normal, student,
  lognormal, gamma, beta, beta_binomial, binomial, cumulative_logit, poisson,
  nbinom2); `drm_family_dpq_tweedie()`'s `status` flipped `"spike"` ->
  `"reference"` with `atoms = c(0)` and an updated header comment;
  `drm_family_dpq_zero_one_beta()` (new); `drm_family_dpq_zi_poisson()`
  (new); `drm_family_dpq_truncated_nbinom2()`,
  `drm_family_dpq_hurdle_nbinom2()`, `drm_family_dpq_zi_nbinom2()` (new,
  appended after nbinom2); `fitted_distribution.drmTMB()` extended with
  `atoms = dpq$atoms`; `fitted_distribution()`'s roxygen updated (promoted
  family list, `atoms` in the return-value bullet); "beta"'s and
  "nbinom2"'s header comments updated to point at this batch's dedup
  closures instead of "left unconsolidated"/"deferred".
- `R/adequacy.R`: `drm_quantile_residuals()`'s roxygen left-limit-rule
  paragraph generalized (no longer named "a future zero_one_beta entry ...
  not reachable"); `drm_quantile_residual_u()`'s has_atom-continuous branch
  now calls the new `drm_atom_left_limit()` helper instead of a hardcoded
  `ifelse(y == 0, 0, upper)`.
- `R/methods.R`: `simulate.drmTMB()`'s `"zero_one_beta"` branch now calls
  `drm_beta_shapes()`; its `"truncated_nbinom2"`/`"hurdle_nbinom2"`/
  `"zi_nbinom2"` branches now call `drm_nbinom2_size()` instead of inline
  `1 / sigma^2`; `truncated_nbinom2_p0()` now calls `drm_nbinom2_size()` too.
- `tests/testthat/test-family-dpq-batchC.R` (new): DG2 + DG3-smoke tests for
  all six families, plus the shared `expect_atom_right_inverse()` helper.
- `tests/testthat/test-family-dpq.R`: header comment updated; the
  "unimplemented model type" probe fit changed from `zero_one_beta()` (now
  promoted) to `biv_gaussian()`; the tweedie spike density/atom test and the
  tweedie Dunn-Smyth demonstration test removed (moved to
  `test-family-dpq-batchC.R`, replaced with stub comments pointing there).
- `tests/testthat/test-adequacy.R`: the "unimplemented model type" probe fit
  changed from `zero_one_beta()` to `biv_gaussian()`; the "spike-status
  families warn once per session" test reworked to call
  `drm_warn_adequacy_spike()` directly (no live spike family remains).
- `tests/testthat/test-distributional-outputs.R`: the tweedie `exceedance()`
  atom test's title and warning-wrapping updated for tweedie's promoted
  status (substantive assertions unchanged).

## Out of scope for DO-T3 batch C (unchanged from the ultra-plan)

Batch D (bivariate marginal `{d,p,q}` for `biv_gaussian`); the gated DG3
power-arm campaign; calibrated coverage (DG4/DG5); RE/structured adequacy
beyond fixed effects; the `R/distributional-outputs.R` header staleness
(flagged above, not fixed); wiring the package-independent tweedie density
reference into DG2 (flagged above, not done).
