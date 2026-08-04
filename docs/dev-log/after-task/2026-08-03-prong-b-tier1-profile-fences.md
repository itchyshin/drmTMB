# After-task report — Prong B Tier 1: profile-fence deletion

**Date:** 2026-08-03. **Scope:** `R/profile.R` (edits E1-E4), a CI-wired
fence-integrity guard, four test files, six evidence-citation re-anchors,
three stale user-facing claims. **Worktree:** `/private/tmp/drmtmb-prongb`,
branch `claude/prong-b-tier1`, based on `origin/main = 25768833b`, uncommitted.
**Author of this report:** Rose (systems auditor), closing out the arc.

## 1. Task goal

Prong B Tier 1 deletes four boolean fence predicates in `R/profile.R` (edits
E1-E4, scoped in `scratchpad/2026-08-03-prong-b-scoping-decision.md`) so that
`confint(fit, method = "profile")` becomes reachable for exactly the 14
capability-ledger cells the scoping memo funded: mc-0568, mc-0576
(`zero_one_beta` `sigma`, ordinary intercept/slope); mc-0593..0597
(`zero_one_beta` `sigma`, structured: `phylo()`, `animal()`, `relmat()`,
`spatial()`, `phylo_interaction()`); mc-0418, mc-0436, mc-0446, mc-0450,
mc-0454 (`poisson`/`nbinom2` `mu`, labelled q2 intercept-slope covariance,
2 SD targets + 1 `cor:` target each); mc-0425, mc-0653 (`nbinom2`/`zi_nbinom2`
`sigma`, `phylo_interaction` q1). The arc pairs the code change with flipped
test call-sites, the package's first `se = TRUE` profile-interval tests, and
a CI-wired fence-integrity guard.

The arc promotes no cell. `evidence_tier` stays `point_fit_recovery` for all
14; the `model_surface` census is unchanged at 182 `interval_feasible` / 60
`point_fit_recovery` (frozen subset 59). Reaching a profile target is
eligibility, not a validated interval — see section 11.

## 2. Files created or changed

Eighteen tracked files carry a diff, all uncommitted:

- `R/profile.R` — E1-E4: deletes `count_labelled_q2_profile_restricted()`,
  `count_sigma_interaction_profile_restricted()`, and
  `zero_one_beta_sigma_q1_profile_restricted()` outright (with their status
  branches and the `eta_cor_phylo` special case in the correlation-target
  loop); narrows `count_point_fit_only_profile_restricted()`'s
  `zero_one_beta` `dpar` set from `c("mu", "sigma", "zoi", "coi")` to
  `c("mu", "zoi", "coi")`; leaves `zi_nbinom2_sigma_q1_profile_restricted()`
  untouched (it governs `zi_nbinom2` *ordinary* `sigma` q1, not one of the
  14); replaces the now-unreachable final branch of
  `count_point_fit_only_profile_restricted_status()` with `cli::cli_abort()`
  instead of a silent fall-through; adds a roxygen `@section` documenting the
  structured-`sigma` ML low-bias caveat (section 11).
- `R/family.R` and its regenerated `man/zero_one_beta.Rd` — corrected
  roxygen that still claimed the two now-open ordinary-`sigma` routes were
  not profile-ready.
- `vignettes/formula-grammar.Rmd` — two rows (`zero_one_beta`; the Poisson
  labelled-q2 row) corrected for the same reason.
- `man/confint.drmTMB.Rd`, `man/profile_targets.Rd` — regenerated from the
  `R/profile.R` roxygen; `profile_targets.Rd` also drops the four retired
  `point_fit_only_*` note tokens from its `@return` documentation.
- `NEWS.md` — new top entry naming all 14 routes, the retired note tokens,
  the reachability-not-inference distinction, the structured-`sigma` bias
  caveat, and the mc-0653 fixture degeneracy.
- `.github/workflows/R-CMD-check.yaml` — one new Linux-only step,
  "Profile-fence integrity (Prong B Tier 1)", placed after
  `tools/check-capability-runtime.R` so it reuses that step's already-current
  TMB `.so` instead of forcing a second compile.
- `tests/testthat/test-count-structured-mu.R`, `test-phylo-interaction.R`,
  `test-zero-one-beta.R` — flipped call-sites (12, section 3) and four new
  `se = TRUE` profile-interval smoke tests, one per opened group.
- `tests/testthat/test-profile-targets.R` — dropped two retired tokens from
  the `profile_note` allow-list; added one internal test for the new
  `cli_abort()` fall-through.
- `docs/dev-log/dashboard/estimator-surface-conformance.tsv`,
  `docs/dev-log/dashboard/capability-ledger/{cells,evidence}.tsv`,
  `docs/dev-log/dashboard/capability-census/{_master,skew_normal,student}.tsv`
  — six evidence-citation anchors re-pointed after the E1-E4 edit's own
  line-shift broke them (section 6, defect 1); the census was regenerated
  with `--write` after the ledger edit. Confirmed by direct diff: only
  `evidence_source`/`notes` citation text moved in these files, never
  `status` or `evidence_tier`.

Three new, untracked files under `tools/` (this report does not modify
`tools/`; these were shipped earlier in the arc):

- `tools/check-profile-fence-integrity.R` — the guard. Default CI/guard mode
  loads the package in place and checks a hard-coded intended-outcome table,
  exiting non-zero on any mismatch; `--diff --lib-old=... --lib-new=...` is a
  one-time two-library verification mode.
- `tools/profile-fence-fixtures.R` — pure data: 58 grid rows + 3
  `exists()`-only probes (61 enumeration rows) and 24 fitted-battery routes
  (34 target checks), each with a hand-derived expected outcome and
  file-level DGP/formula provenance.
- `tools/profile-fence-worker.R` — the only file that calls
  `library(drmTMB)`/`pkgload::load_all()`; always run as its own `Rscript`
  subprocess for library isolation.

Evidence artefacts under `scratchpad/` (not part of the shipped change):
`2026-08-03-prong-b-s2-guard-report.md`, `2026-08-03-prong-b-s7-adversarial-review.md`,
and `2026-08-03-prong-b-r1-collateral-diff.{R,tsv}` — the latter is the
scoping memo's own required pre-merge gate (its "R1 — Collateral unlock"
risk item): it reconstructs the four deleted predicates verbatim from
`origin/main` and reports every `(route, target)` pair they governed, so the
pre-edit column is derived rather than requiring a second install. All
`FENCED`/`PROBE` control rows (routes with no ledger cell, or deliberately
adjacent routes such as a zoi-plus-sigma random-effect combination) show
`flipped = FALSE`; only the 14 named cells' rows show `flipped = TRUE`.

## 3. Checks run and exact outcomes

- **`R CMD check --as-cran`, `NOT_CRAN=true`.** First completed run
  (`/private/tmp/prongb-ascran.log`, check dir `prongb-check-1`): **0
  ERRORS, 0 WARNINGS, 1 NOTE** (the benign `New submission` /
  maintainer-address note). A second confirming run on the fully settled
  tree (`prongb-check-2`, `/private/tmp/prongb-ascran-final.log`) has since
  **completed: 0 ERRORS, 0 WARNINGS, 1 NOTE**, the same benign
  `New submission` / maintainer-address note. That settled-tree run includes
  every late repair listed in section 4 — the `R/family.R` roxygen and
  `vignettes/formula-grammar.Rmd` corrections, the guard's `R_LIBS_USER`
  fix, the ledger re-anchoring, and the removal of the fixture line pins —
  so the 0/0/1 result covers the tree as it now stands, not an earlier one.
- **`python3 tools/capability_ledger.py --check`** — re-run live for this
  report: `capability-ledger: OK (30 generated outputs)`. Census confirmed
  unchanged on the `model_surface` axis: 182 `interval_feasible` / 60
  `point_fit_recovery` (frozen subset 59, enforced by
  `FROZEN_CENSUS_POINT_FIT_RECOVERY = 59` at `tools/capability_ledger.py:218`
  — the live `--check` run would have failed had any frozen cell moved). All
  14 opened cells remain `evidence_tier = point_fit_recovery`,
  `capability_status = implemented`.
- **`Rscript --no-init-file tools/check-profile-fence-integrity.R`** —
  re-run live for this report: `enumeration rows=61 battery rows=34
  violations=0`, all 24 battery routes `FIT OK` (`convergence=0
  pdHess=TRUE se_success=TRUE`), 22.5s wall-clock. The guard's own red-test
  (documented in the S2 report): re-adding one deleted disjunct
  (`count_point_fit_only_profile_restricted()`'s `zero_one_beta` `dpar` set,
  restoring `"sigma"`) produced 10 violations (5 enumeration + 5 battery,
  exactly the 5 `zero_one_beta` structured-`sigma` routes) and exit 1;
  reverting restored `violations=0`, exit 0.
- **Enumeration and the exhaustive cross-check.** The guard's 61-row
  enumeration flips exactly the 14 open-group ids on the pre/post diff — an
  EXACT MATCH, no other row moved. The S7 adversarial review reproduced this
  independently at roughly 60,000x the scale: an exhaustive
  3,757,600-combination sweep over every value the deleted predicates read
  (11 `model_type` values x 61 structured-`phylo_mu` shapes x 7
  `random$sigma` topologies x 2 `random$mu` x 2 `zoi` x 2 `coi` x 2
  `mu_sigma` x 10 `dpar` x 5 `internal`) found the identical OLD-only set of
  exactly these 14 cells' families, 0 newly-fenced rows, and 0 reachable
  `cli_abort()` rows in NEW.
- **Test call-sites.** 12 flipped assertion sites across three files —
  `test-count-structured-mu.R` (3, via one shared helper function called
  from 3 locations, covering all 5 labelled-q2 cells), `test-phylo-interaction.R`
  (2: mc-0425, mc-0653), `test-zero-one-beta.R` (7: 5 structured-`sigma`
  providers + mc-0568 + mc-0576) — plus a pure allow-list hygiene edit in a
  4th file, `test-profile-targets.R` (removes two now-unproducible tokens;
  changes nothing observable). 5 new `test_that()` blocks: 4 `se = TRUE`
  profile-interval smoke tests (one per opened group) and 1 internal test
  for the new `cli_abort()` fall-through. Targeted combined run
  (`testthat::test_dir(..., filter = "zero-one-beta|count-structured-mu|phylo-interaction|profile-targets")`):
  **`[ FAIL 0 | WARN 6 | SKIP 0 | PASS 3136 ]`**, elapsed 93.4s — confirmed
  directly from the raw log (`/private/tmp/drmtmb-s3/scratchpad/final-combined.log`);
  the four files' individual PASS counts (533 + 160 + 1581 + 862) sum to
  3136 exactly, confirming no cross-file interaction. The 6 warnings are
  pre-existing `sd_phylo1()`/`sd_phylo2()` deprecation warnings, deliberately
  triggered by one existing test to check the deprecation-warning path
  itself, unrelated to this task.
- **Collateral verdict (load-bearing).** The *unmodified* test suite (i.e.
  without the S3/S4 call-site flips) was run against both the PRE-edit
  (`origin/main`) and POST-edit (E1-E4 applied) package builds, to prove the
  flip set is exactly the intended routes and nothing else. Pre-edit
  baseline (`/private/tmp/prongb-baseline-suite.log`): **2 failing tests / 2
  files** — `test-estimator-surface-conformance.R` ("the conformance TSV's
  evidence citations are real and current", 4 failed expectations) and
  `test-phase18-structured-workflow-registry.R` ("Phase 18 structured
  workflow registry path prefers checkout files", 1 failed expectation),
  both pre-existing on `main`, unrelated to this arc. Post-edit
  (`/private/tmp/prongb-collateral.log`): **14 failing tests / 5 files** —
  the same 2 pre-existing file/tests, plus exactly 12 newly-failing tests
  across `test-count-structured-mu.R` (3), `test-phylo-interaction.R` (2),
  and `test-zero-one-beta.R` (7). The difference, 12 tests across 3 files, is
  precisely the set the S3/S4 call-site flips exist to fix; none of the 12
  fail on baseline, and no test outside those 3 files or the 2 pre-existing
  ones moved in either run. One timing caveat, found while verifying this
  for the present report: the post-edit collateral log's mtime (~19:20)
  precedes the citation-anchor fix to `estimator-surface-conformance.tsv`
  (~19:23), so its conformance-test failed-expectation count (5, versus
  baseline's 4) reflects an interim tree state, not the currently
  re-anchored worktree. This affects only the failed-expectation count
  inside that one pre-existing test, not the file/test-identity arithmetic
  the collateral verdict rests on (14 vs 2, difference 12/3), which is
  unchanged either way since the same 2 files were already failing under
  both builds at the time the logs were captured.

## 4. Consistency audit

Two stale-claim locations were caught and fixed inside the arc, both by the
S7 adversarial review: `R/family.R`'s roxygen (rendering to
`man/zero_one_beta.Rd`) and two rows of `vignettes/formula-grammar.Rmd`
still asserted "not profile-ready" / "direct targets are not profile-ready"
for cells the same arc had just made profile-ready. Both are corrected in
the current diff (section 2).

For this report, I re-checked the two other places CLAUDE.md's status
inventory names — `README.md` and `docs/dev-log/known-limitations.md` — for
the same "not profile-ready"/`point_fit_only_*` phrasing near the 14 cells'
families. `README.md:207`'s "`coi ~ x + (0 + x | id)`; none is profile-ready"
remains accurate (`coi` is untouched by this arc). `README.md:342` mentions
"the count one-slope cells have point-fit/extractor evidence only" in the
same table row as the labelled-q2 language this arc touched; on inspection
this refers to *unlabelled* single-slope Poisson/NB2 `mu` cells (q1, one
random term), a different, untouched cell class from the *labelled* q2
intercept-plus-slope covariance cells (mc-0418 etc.) this arc opened — not a
missed stale claim, but close enough in wording that a future reader
cross-checking this table should verify the q-gate, not just the family
name, before reusing this row as a citation.

No `_pkgdown.yml`, `ROADMAP.md`, or `docs/design/*.md` file has a pending
diff in this worktree (confirmed by `git status`); see sections 8-9 for why
that is expected here.

## 5. Tests of the tests

The arc's own verification is unusually layered, and each layer caught a
real defect rather than passing trivially:

- The new guard was red-tested before being trusted (S2): mutate the thing
  it protects, confirm the guard fires (10 violations, exit 1), revert,
  confirm it clears (0 violations, exit 0). I re-ran the clean state live for
  this report (section 3) rather than trusting the S2 transcript alone.
- The guard's own provenance stamp (`exists()` of the four deleted
  predicates, TRUE-in-OLD/FALSE-in-NEW) was independently re-derived in
  fresh subprocesses rather than taken from a value supplied mid-task by a
  message purporting to be from "the coordinator" (S2's own account) — the
  independently-derived values happened to agree, which is what independent
  verification is supposed to produce, not what it is allowed to assume.
- The S7 review explicitly separated *classification* (does `profile_ready`
  flip to `TRUE`?) from *computability* (does a call to
  `confint(method = "profile")` actually return two finite ordered
  endpoints?). The guard's battery only proves the former; S7 ran real
  profiles on 5 of the 14 routes the S2 guard did not test end to end and
  found one, mc-0653, that fails under some option spellings — see section
  11. S3/S4 then added real `se = TRUE` profile-interval assertions for one
  representative cell per opened *group* (4 tests), which is a computability
  check for the groups but not an exhaustive one for all 14 individual
  cells; that remains the campaign arc's job (handover).
- The collateral-verdict run (section 3) is itself a "test of the tests" for
  the S3/S4 call-site edits: running the suite *before* those edits against
  the *after*-E1-E4 build is what proves the 12 flips were necessary and
  sufficient, rather than trusting that the diff "looks right".

## 6. What did not go smoothly

1. **Self-inflicted citation drift.** The E1-E4 edit net-changed
   `R/profile.R`'s line count non-uniformly (an 18-line roxygen `@section`
   inserted early in the file; several functions deleted later in the file),
   which broke three evidence citations in
   `estimator-surface-conformance.tsv` and three ranges in
   `capability-ledger/{cells,evidence}.tsv` (propagating into the census
   once regenerated). All six were re-anchored; verified directly in this
   report's own diff read (the shifts are not uniform: +21 lines at one
   citation, +21 at a second, +11 at a third, reflecting where in the file
   each citation sits relative to the deletions). This is not a new failure
   mode for this file: `docs/dev-log/after-task/2026-07-25-estimator-surface-anchor-hygiene.md`
   repaired 7 different anchors in the same TSV nine days earlier, for the
   same underlying reason (unrelated edits shifting absolute line numbers),
   and closed with an explicit recommendation — "If these anchors drift
   again, prefer a more durable citation form (a stable marker or a
   grep-based locator) over another manual line-number refresh" — that this
   arc did not act on. See section 7.
2. **Stale user-facing claims** (section 4): two roxygen/vignette locations
   asserted the pre-edit fence after the code no longer enforced it. Caught
   by the S7 adversarial review, not by the code-editing pass itself.
3. **Guard silently discarded a caller's library.** `run_worker()` in the
   new guard defaulted `r_libs_user = NULL` for its guard-mode call site,
   which emitted a literally empty `R_LIBS_USER=` to the worker subprocess.
   R's own `Renviron` default substitution
   (`R_LIBS_USER=${R_LIBS_USER:-'%U'}`) treats an empty value as "unset" and
   substitutes R's *default* user library, so a caller running the guard
   under a non-default library (an `renv` project, a pre-set `R_LIBS_USER`)
   would have had it silently ignored. This happened to work on GitHub
   Actions only because `r-lib/actions/setup-r-dependencies@v2` exports R's
   own default back into `R_LIBS_USER`, masking the bug in exactly the
   environment it was about to ship into. Caught by S7 (finding G3); fixed
   by falling back to `Sys.getenv("R_LIBS_USER")` when no library is pinned
   — verified present in the current `tools/check-profile-fence-integrity.R:92-98`.
4. **The new guard's own provenance citations went stale in the same
   commit.** `tools/profile-fence-fixtures.R` originally cited 29 individual
   test-file line numbers as proof each route's DGP/formula matches an
   already-passing test. The *same* commit's test-file edits (the 12
   call-site flips, 5 new tests) shifted those line numbers, so by the time
   the guard shipped, 7 of the cited ranges pointed at unrelated content
   (one example: a citation intended for an "animal q1 sigma gate" landed on
   a block of "coi phylo" assertions instead). Caught by S7 (finding R4);
   fixed by dropping to file-name + cell-id citations for the three
   co-edited test files, while keeping line-numbered citations to
   `tools/run-lane-c-c17c1-c14-model15-compatibility.R`, a file this arc did
   not touch and whose citations are therefore stable. Confirmed in this
   report: only 1 line-numbered test-file citation remains in
   `tools/profile-fence-fixtures.R`, and it is a seed/DGP-derivation comment
   inside a single self-contained helper, not a cross-file provenance pin.

## 7. Team learning and process improvements

The headline pattern across items 1 and 4 above: **this arc produced its own
version of the exact defect class its immediate predecessor documented and
asked to be prevented.** `2026-07-25-estimator-surface-anchor-hygiene.md`
named the fragile-line-number citation style as the root cause of a 7-anchor
repair and recommended a durable citation form; nine days later, the same
file needed a further 6-span repair, and a brand-new file
(`tools/profile-fence-fixtures.R`) shipped with 29 more fragile line-number
pins that went stale before the commit was even finished. **Concrete next
safeguard:** either build the durable-citation mechanism the 2026-07-25
report asked for once (a grep-based locator, or a stable named anchor
comment near each cited site, checked by a test rather than eyeballed), or
explicitly accept that every future `R/`-file diff will need a citation-anchor
pass and make that pass a standing item in this project's after-task
checklist rather than something each arc has to rediscover for itself.

A second, structural finding worth recording prominently, because it
explains *why* the citation guard has not been able to prevent this pattern
from repeating even though it exists specifically to catch it:
`tests/testthat/test-estimator-surface-conformance.R` exists, per its own
header comment, to stop evidence citations rotting silently. But
`.Rbuildignore:10` excludes `^docs$`, so the TSV it reads
(`docs/dev-log/dashboard/estimator-surface-conformance.tsv`) is absent from
the built tarball, and the test's own `skip_if_not(file.exists(path), ...)`
guard SKIPS the entire test under `R CMD check` — which is the only checked
environment CI runs. The guard only fires when someone runs the full test
suite directly from a checkout (as the collateral-verdict run in section 3
did), which is not what `R-CMD-check.yaml` does. This is precisely why 4
pre-existing `R/drmTMB.R` citations were found rotted-and-unnoticed during
this arc (left alone; see section 10) while CI stayed green the whole time:
the enforcement mechanism is invisible exactly where it would need to fire.
Fixing the citation form (the first safeguard above) reduces how often
drift happens; it does not fix this — a test that is invisible to CI will
eventually rot again regardless of how sturdy the citations are, because
nothing forces anyone to run it. **Concrete next safeguard:** either stop
excluding `docs/` from the build so this test can run under `R CMD check`
without a bespoke exception, or move the fixture TSV (or a generated summary
of it) somewhere the tarball retains, or add an explicit non-`R-CMD-check`
CI step (this project already has a precedent for that shape: the new
Prong B fence-integrity guard runs directly from the checkout, not from the
tarball, for exactly this reason).

On the positive side, three things worked as designed and are worth naming
so they are repeated rather than only implied: the red-test discipline ("a
guard that has never failed is not a guard") was applied to the new guard
before it was trusted, and caught real failures when deliberately broken;
process isolation plus independently-re-derived provenance stamps resisted
a mid-task message purporting to supply authoritative `exists()`/md5 values
without those values being taken on trust; and the collateral-verdict
methodology (run the unmodified suite against both builds) gives a
falsifiable, cheap answer to "did we change anything we did not mean to"
that a diff review alone cannot provide.

## 8. Design-doc updates

None. This arc changes which already-implemented targets are reachable by
`confint(method = "profile")`; it does not change grammar, likelihoods,
random-effect structure, family definitions, or the phylogenetic/spatial/
meta-analysis machinery itself, so it does not trigger CLAUDE.md's
design-doc update list. `docs/design/248-zero-one-beta-structured-atom-q1-symbolic-alignment.md`
mentions the relevant symbols but documents the already-implemented
structured-atom alignment, not the profiling gate; it has no pending diff in
this worktree (confirmed by `git status`).

## 9. pkgdown/documentation updates

`man/zero_one_beta.Rd`, `man/confint.drmTMB.Rd`, `man/profile_targets.Rd`
were regenerated from roxygen; `vignettes/formula-grammar.Rmd` and
`NEWS.md` were edited directly (sections 2-4). `_pkgdown.yml` has no pending
diff and needs none: no exported function or vignette was added or removed,
only existing documentation content.

## 10. GitHub issue maintenance

I searched the open and closed issue tracker (`gh issue list --repo
itchyshin/drmTMB`) for terms matching the two defects named in sections 6-7
— `"conformance"`, `"citation"`, `"estimator-surface"`, `"Rbuildignore"`,
`"invisible"`, `"skip_if_not"` — and for issues created 2026-08-03..2026-08-04.
**No matching issue was found** for either (a) the 4 pre-existing
`R/drmTMB.R` citation rots left untouched by this arc, or (b) the
newly-identified structural finding that the conformance guard is invisible
under `R CMD check`. This report does not file one — writing the three
named closeout documents is this task's explicit scope — but records the
gap here rather than silently letting the claim "a separate task was filed"
go unverified: either it exists under wording this search did not match, it
was tracked only in a dev-log note this search did not cover, or it remains
outstanding. Recorded as an open action in the handover
(`docs/dev-log/handover/2026-08-03-prong-b-tier1-to-campaign-handover.md`).

## 11. Known limitations and next actions

- **Reachability, not inference.** Opening a fence grants profile
  eligibility only. No coverage, calibration, or interval-validity claim is
  made anywhere in the change — confirmed directly: `NEWS.md`, the new
  roxygen `@section`, and every new `test_that()` description disclaim this
  explicitly, and the S7 review (finding R6) read all of `NEWS.md`, the
  roxygen, and every changed test description and found no implicit
  coverage/calibration/promotion claim anywhere.
- **mc-0653's fixture is degenerate.** `zi_nbinom2`, `phylo_interaction`,
  `sigma`: the ML estimate is `4.95e-05` against a generating value of
  `0.60` (the variance component has collapsed near the lower boundary).
  Its profile returns `conf.status = "profile_failed"` under some `ystep`
  settings and a lower endpoint of `0` with a `near_sd_boundary` message
  under others (S7 finding F3, independently reproduced against the guard's
  own fixture). This is pre-existing — the same seed is used at
  `tests/testthat/test-phylo-interaction.R:555`, which asserts only
  classification, not a regression introduced by this arc — but **the
  campaign arc must repair this fixture before mc-0653 can be promoted.**
- **Structured-`sigma` ML low bias, carried forward as a locked owner
  decision.** 7 of the 14 opened cells profile a `sigma`-axis random-effect
  SD under a provider structure for `zero_one_beta`/`nbinom2`/`zi_nbinom2`;
  the underlying ML point estimate is documented as biased low, measured
  only for the 4 `nbinom2` sibling provider cells (11 of 12 retained
  estimates below truth; fit-level one-sided sign test p = 0.0032). This is
  now stated in `NEWS.md`, the `R/profile.R` roxygen (rendering to
  `man/confint.drmTMB.Rd`), and the two corrected man/vignette locations.
  Per the Arc 7b owner decision this arc inherits: every structured-`sigma`
  cell's `claim_boundary` text must eventually name this bias and state that
  REML is unavailable for its family (`drm_validate_reml_spec()` admits only
  Gaussian and binomial models) — not yet written, because no `claim_boundary`
  text changes in this arc (it promotes nothing).
- **Frozen-census constant will need a one-line change at promotion time**:
  `FROZEN_CENSUS_POINT_FIT_RECOVERY = 59` at `tools/capability_ledger.py:218`
  must move to `45` if/when these 14 cells promote (60 - 14 = 46
  whole-model, 59 - 14 = 45 frozen). Not changed here; changing it now would
  make `--check` fail against the current, correct, un-promoted state.
- **Second `R CMD check --as-cran` confirming run**: COMPLETE, 0/0/1 on the
  fully settled tree (section 3, updated after this report was first drafted).
- **GitHub issue for the citation-rot / CI-invisibility finding**: not filed.
  It was raised as a working-session task chip, not a repository issue, so a
  `gh issue list` search correctly finds nothing. Anyone who wants it tracked
  in GitHub must open it.
- **This arc repeated a fix its own project had already warned against.**
  `docs/dev-log/after-task/2026-07-25-estimator-surface-anchor-hygiene.md:79-80`
  says: *"If these anchors drift again, prefer a more durable citation form
  (a stable marker or a grep-based locator) over another manual line-number
  refresh."* The anchors drifted again — this arc's ~70-line shift in
  `R/profile.R` broke `R/profile.R:896` — and this arc re-anchored them by
  hand anyway (860->881, 896->917, 3078->3089), which is the second manual
  refresh and exactly what that recommendation ruled out. The hand repair is
  correct and the test now passes, but it treats the symptom. The durable
  form is still unbuilt. Notably the same arc met the identical problem in a
  file it was *introducing* (`tools/profile-fence-fixtures.R`, 29 test-file
  line pins already stale from its own commit) and there did the right thing
  — deleted the line numbers, kept file name and cell id. The conformance
  table did not get the same treatment because changing that test's contract
  was out of this arc's scope; that is a reason, not a justification, and the
  gap is now carried as a task with the 2026-07-25 citation attached.

Full detail on all of the above, including the campaign's exact scope (14
cells x 5-8 seeds, ~135 profile traces), its ten-clause evidence contract,
and six ranked risks, is in `scratchpad/2026-08-03-prong-b-scoping-decision.md`
and carried forward in the handover document named above.
