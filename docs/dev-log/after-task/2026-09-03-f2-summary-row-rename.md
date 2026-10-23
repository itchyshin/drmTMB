# f2: rename summary()'s derived "repeatability"/"phylogenetic_signal" rows (D-213 #1)

**Reader**: anyone reading `summary(fit)$derived` output, matching on the row
name `"repeatability"`/`"phylogenetic_signal"` or the profile-target `parm`
string `"derived:repeatability(<group>)"`/`"derived:phylogenetic_signal(<group>)"`,
or comparing `summary()`'s derived rows against the `icc()`/`repeatability()`/
`heritability()` accessors (`R/heritability.R`, design 259).

## The collision (owner's framing, D-213 #1, decided this morning)

`R/methods.R`'s `drm_derived_summary_rows()` prints one row per structured
`mu` random-effect component, with formula
`re_variance / (total_re_var + residual_variance)` -- the denominator is the
TOTAL variance: every `mu` random-effect variance in the fit, summed, plus
the residual variance (deliberately, since issue #695: summing only the
current term's variance overstates the ratio when multiple `mu` random
effects are present).

`icc()`/`repeatability()` (arc N2, design 259, added the night before this
arc) use a DIFFERENT denominator: the focal component's variance over that
component plus the residual only (DRM.jl's definition,
`src/heritability.jl:305-306,312,326-330`).

On a fit with exactly one structured `mu` component the two formulas
coincide. With two or more, they disagree -- and before this arc, both wore
the same label, `"repeatability"` (and `"phylogenetic_signal"` for the phylo
variant), so the disagreement was invisible unless you read the source.
`heritability()` already uses the TOTAL-variance denominator too (same as
`summary()`'s rows), so this was specifically a naming collision between
`summary()`'s rows and `icc()`/`repeatability()`, not a three-way one.

The owner's decision: `icc()`/`repeatability()` keep the canonical
(focal-vs-residual) meaning -- they are the newer, deliberately-ported
DRM.jl-aligned accessors. `summary()`'s pre-existing row is renamed to state
what it actually computes. Arithmetic is unchanged in both places; only the
`summary()` row's label and its documentation change. drmTMB is pre-CRAN
(D-164), so the rename lands now.

## The chosen label

`"total_variance_share"` for the ordinary-group-term row (previously
`"repeatability"`), and `"phylo_total_variance_share"` for the phylogenetic
row (previously `"phylogenetic_signal"`) -- both applied to the `quantity`
column and the `parm` profile-target string
(`"derived:total_variance_share(<group>)"` /
`"derived:phylo_total_variance_share(<group>)"`).

Reasoning: of the three candidates offered (`variance_explained`,
`total_variance_share`, `variance_fraction`), `total_variance_share` is the
only one that names the specific denominator rather than gesturing at a
generic ratio concept. `variance_explained` reads as an R^2-style claim
(proportion of variance accounted for by a model, a different statistical
object) and would mislead readers coming from a regression background.
`variance_fraction` states that it is a fraction but not a fraction *of
what*, so it does not resolve the ambiguity the rename exists to fix. Next
to the other printed summary rows -- `sd:mu:(1 | site)`,
`covariance:phylo:...` -- `total_variance_share` reads as one more
descriptive-quantity name, and a reader who already knows `heritability()`
uses the total-variance denominator will recognise the family resemblance
(`heritability()` is TOTAL-variance too; see below). It does not collide
with `heritability`, `icc`, `repeatability`, or `phylogenetic_signal`.

## `phylogenetic_signal`: renamed too, and why

Yes, renamed to `phylo_total_variance_share`, for the same reason as the
group-term row: it shares the identical TOTAL-variance denominator, so
leaving it as `"phylogenetic_signal"` while its sibling row lost its old
name would have left one row in the same table stating its denominator and
the other not -- an inconsistency inside a single `summary()` call, and a
label that (like the old `"repeatability"`) does not say what it divides
by. There is currently no `phylogenetic_signal()` accessor to collide with,
but the naming *pattern* that caused this collision (a row name that reads
like a self-contained statistical concept rather than stating its
denominator) is exactly what would reproduce the collision if such an
accessor were ever added with DRM.jl's focal-vs-residual convention, the
way `icc()`/`repeatability()` were. Renaming both rows now, consistently,
closes that path rather than leaving a matching landmine next to the one
just defused.

The two renamed rows keep distinct labels (`total_variance_share` vs.
`phylo_total_variance_share`) rather than collapsing to one string, because
the `parm` profile-target string embeds the group name
(`"derived:total_variance_share(species)"` vs.
`"derived:phylo_total_variance_share(species)"`), and a fit can in principle
carry both an ordinary `(1 | species)` term and a `phylo(1 | species, tree =
tree)` term on the same grouping variable; a shared label would make the two
`parm` strings collide. The existing `level` column (`"group"` vs.
`"phylogenetic"`) already carries this distinction for callers who want to
group the two row kinds together.

## What was renamed

- `R/methods.R`: `derived_summary_random_effect_kind()` (`quantity`/`parm`
  construction), the guard comment above it, and the `summary.drmTMB`
  roxygen block describing the `derived` component.
- `R/profile.R`: the roxygen paragraph in `profile_targets()` describing
  derived variance-ratio summaries (the only prose in this file naming the
  row labels; the file's other "repeatability" hit is a literature citation
  title, left untouched).
- `tests/testthat/test-summary.R`, `tests/testthat/test-profile-targets.R`:
  updated the `parm`/`quantity` string literals that exercise these rows so
  the existing suites keep passing under the new names. These two files are
  outside this arc's strict OWNS list, but leaving them referencing the old
  strings would have left the test suite broken by this rename, which
  contradicts both the task's "update every consumer" instruction and gate
  f2-G4's grep-clean requirement; noted here as a deliberate scope
  extension, confined to string literals only (no new assertions, no
  unrelated edits).
- `vignettes/implementation-map.Rmd`, `vignettes/articles/model-workflow.Rmd`:
  the two passages that describe `summary()`'s derived row by name (as
  distinct from the many vignettes that use "repeatability" as the general
  English/ecology term for a manually-computed `between^2/(between^2 +
  within^2)` ratio -- those are unrelated to this row and left alone; see
  "what was deliberately not renamed" below).
- `docs/design/37-worked-example-inventory.md`: one table cell describing
  `model-workflow.Rmd`'s content, for consistency with that vignette's own
  updated text.
- `docs/design/259-heritability-icc-repeatability.md`: section 3 item 5
  rewritten to state the rename and both denominators (`heritability()` vs.
  `icc()`/`repeatability()` vs. `summary()`'s renamed rows), and which
  function/row owns which denominator.
- `NEWS.md`: user-facing entry naming the old and new labels, the two `parm`
  strings, and pointing to design 259 for the denominator table.
- `tests/testthat/test-summary-derived-rows.R` (new): a "renamed" test
  asserting the new label appears and no row/quantity is called
  `"repeatability"`; a "denominator" test on a Gaussian fit with two
  structured `mu` components asserting `icc()` and the renamed summary row
  disagree, and that each reports the value its own denominator predicts.

## What was deliberately NOT renamed

- `icc()`, `repeatability()`, `heritability()`, and their tests
  (`R/heritability.R`, `tests/testthat/test-heritability.R`): untouched in
  value and name, per the owner's decision. `test-heritability.R` was
  already clean of the old row-label strings (it only names the accessor
  functions), so it needed no edit; confirmed by re-running the suite
  (48/48 passed, 0 failed/errored).
- `R/heritability.R`'s own roxygen (line 21) and `man/heritability.Rd`,
  which still describe the *pre-rename* collision in the present tense
  ("`summary()`'s existing derived `"repeatability"`/`"phylogenetic_signal"`
  rows..."). This is now stale, but `R/heritability.R` is outside this
  arc's fence (gate f2-G6: only `R/methods.R` and `R/profile.R` may differ
  under `R/`), so it was left as-is. **Flagged as a follow-up**: whoever
  next touches `R/heritability.R` should update that paragraph to reflect
  the new row names.
- Generic English/ecology usage of "repeatability" describing a manually
  computed variance ratio, not `summary()`'s row: `vignettes/model-map.Rmd`,
  `vignettes/animal-models.Rmd`, `vignettes/location-scale-scale.Rmd`,
  `vignettes/articles/phylogenetic-spatial.Rmd`, and several design docs
  (`docs/design/12-profile-likelihood-cis.md`,
  `docs/design/34-validation-debt-register.md`,
  `docs/design/153-public-bootstrap-interval-closeout.md`,
  `docs/design/28-double-hierarchical-endpoint.md`,
  `docs/design/226-reader-learning-path.md`,
  `docs/design/capability-status.md` (names the accessor family, not the
  row), `docs/design/53-structural-dependence-article-split.md`,
  `docs/design/41-phase-18-simulation-programme.md`,
  `docs/design/68-gllvmtmb-profile-ci-audit.md`,
  `docs/design/20-coscale-correlation-pairs.md`. None of these quote a
  machine-readable row label or code-format the word; they use
  "repeatability" as the domain term the way a behavioural-ecology paper
  would, independent of what `summary()` happens to print.
- Local variable names in `tests/testthat/test-profile-targets.R`
  (`repeatability_bootstrap_error`, `repeatability_index`, etc.) -- these
  name R objects, not the row label; renaming them would be cosmetic churn
  outside this arc's scope.

## Verification

- `tests/testthat/test-summary-derived-rows.R`: 2/2 `test_that()` blocks
  pass (5 expectations each), including the "denominator" test showing
  `icc()` and the renamed summary row disagree on a two-component fit.
- `tests/testthat/test-heritability.R`: 48/48 passed, 0 failed/errored
  (unchanged file, confirms G3).
- `tests/testthat/test-summary.R`: 200/200 passed. `tests/testthat/test-profile-targets.R`:
  973/973 passed (both after updating their string literals to the new
  labels).
- Grep sweep (gate f2-G4 evidence) across `R/`, `tests/`, `vignettes/`,
  `docs/design/`: no quoted/code-formatted occurrence of `"repeatability"`
  or `"derived:repeatability(...)"` as a row label remains, except (a)
  `R/heritability.R` describing the accessor function itself (untouched by
  design, flagged above), and (b) this after-task note and design 259,
  which quote the *old* label historically while describing the rename.
- `python3 tools/recertify-c17.py --label followup-f2`: zero drift on all
  three graded fields (`mc-0568`/`mc-0569`/`mc-0576` `mean_tau_relative_error`,
  `|change| 0.000e+00` on each), receipt rewired to
  `docs/dev-log/implementation-recovery/2026-09-03-followup-f2-c17c2-c14-final-source-compatibility`.
- `tools/run-julia-phylo-labels-public.R` regenerated
  `docs/dev-log/evidence/julia-r-parity/lss-tip-identity/public-001.json`
  (`PHYLO_LABEL_PUBLIC_PASS`); `tools/check-julia-phylo-labels-receipt.R
  --current --self-test` passes current-source verification and rejects all
  12 mutated self-test variants (`PHYLO_LABEL_RECEIPT_PASS`).
- `python3 -m unittest tools/tests/test_capability_ledger.py`: OK (80
  tests).

## Deviation from the literal OWNS list

The ledger's OWNS field names `R/methods.R`, `R/profile.R`,
`tests/testthat/test-heritability.R`, `tests/testthat/test-summary-derived-rows.R`,
`NEWS.md`, design 259, and this after-task note. This work additionally
touched `tests/testthat/test-summary.R`, `tests/testthat/test-profile-targets.R`,
`vignettes/implementation-map.Rmd`, `vignettes/articles/model-workflow.Rmd`,
and `docs/design/37-worked-example-inventory.md` -- all string/prose edits
only, none touching `R/` (gate f2-G6 still holds: only `R/methods.R` and
`R/profile.R` differ under `R/`). This was necessary to satisfy the task's
explicit "update every consumer... grep must find no stale row label" and
gate f2-G4, and to avoid landing a rename that leaves two existing test
files broken.

A separate accidental slip, caught and fixed before any further work: the
first `summary.drmTMB` roxygen edit was applied with a malformed relative
path that resolved into the main checkout
(`/Users/z3437171/Dropbox/Github Local/drmTMB`) instead of this worktree.
Caught immediately via `git status`/`git diff` in the main checkout, which
showed exactly the 9-line diff just written; reverted with a scoped `Edit`
restoring the pre-edit text read from `git show HEAD:R/methods.R` (not
`git checkout`, which the destructive-command guard correctly blocked as
capable of discarding another lane's in-flight work in that shared
checkout). Confirmed clean (`git diff R/methods.R` empty) before redoing the
edit at the correct absolute worktree path.
