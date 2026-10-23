# 2026-09-01 — RED tests for the public start contract (`claude/rev-parity-a1-start-tests`)

## What this is

`tests/testthat/test-start-contract.R`, ten `test_that()` blocks exercising the
"Public Start Contract (DECIDED 2026-09-01)" section of
`docs/design/35-optimizer-start-map-multistart.md`: `drm_control(start =
list("fixef:mu:(Intercept)" = ..., "sd:mu:(1 | id)" = ..., "cor:mu:cor(...)"
= ...))`. Implementation is out of scope for this task (`R/` untouched); the
file is the RED half for `claude/rev-parity-a2-start`.

## Observed red output

`Rscript -e 'devtools::load_all("."); testthat::set_max_fails(Inf);
testthat::test_file("tests/testthat/test-start-contract.R")'`:

```
[ FAIL 12 | WARN 0 | SKIP 0 | PASS 5 ]
```

Per-block breakdown (10 `test_that()` blocks, 0 fully passing):

- 8 blocks **error** outright, all with the same root cause: `drm_control()`
  has no `start` formal today, so `drm_control(start = list(...))` raises
  base R's `unused argument (start = list(...))` before the label surface is
  ever reached. These are: valid `fixef:` start, valid `sd:` start, valid
  `cor:` start, partial-start, map-preserved, provenance, and both round-trip
  tests (own-optimum, displaced-optimum).
- 2 blocks **fail** (not error) because their assertions are written to
  distinguish "feature absent" from "wrong reason to fail": the unknown-label
  test asserts the message matches `"nknown"` and does *not* match
  `NA/NaN|gradient|convergence|iteration limit`; the latent-`u` test asserts
  the message does *not* contain `"unused argument"` and does match
  `u:|latent|random effect`. Both currently see the generic "unused argument"
  message, so both assertions correctly fail — the 5 `PASS`es inside these
  two blocks are the `expect_s3_class(err, "error")` / `expect_false(grepl("unused
  argument", ...))` checks, which are true today only by the coincidence that
  *some* error is thrown; they are not disguised passes of the feature.
- 0 blocks pass fully. I deliberately caught and re-ran the "latent `u`"
  block once during authoring: its first draft used a bare `expect_error()`
  with no message check and passed today for the wrong reason (any error,
  including "unused argument", satisfies a bare `expect_error()`). I
  rewrote it with `tryCatch()` + message assertions so it fails for the
  right reason instead; the file committed is the rewritten version.

## Fixtures and scale conventions verified against the current code, not guessed

Before writing assertions I confirmed against the running package (not just
the design doc) that:

- `fit$coefficients$<dpar>` and `spec$start$beta_<dpar>` are on the same
  scale (fixef starts are used as-is, no transform), matching the doc's own
  `"fixef:sigma:(Intercept)" = log(0.5)` example.
- `sd:` labels are natural/response-scale SDs; the internal target is
  `log_sd_<dpar>`, so the recovered contract must apply `log()`.
- `cor:` labels are natural correlations in `[-1, 1]`; the internal target is
  `eta_cor_<dpar>` (Fisher-z), so the recovered contract must apply `atanh()`.
- Term-name strings match exactly what `sdpars`/`corpars` already report:
  `"(1 | id)"`, `"(1 | id2)"`, `"cor((Intercept),x | id)"`.
- The map-preserved fixture (`sd(id) ~ w` plus a second untouched `(1 |
  id2)` term) really does leave `spec$map$log_sd_mu` as `c(NA, 2)` and
  `spec$sdpars$mu` reporting only `"(1 | id2)"` — verified by fitting it
  under `devtools::load_all()` before writing the test's assertions.

## Requirement I could not express as a clean end-to-end test: (map preservation, requirement tied to (d))

I can report this one with more nuance than "untestable," because I found and
used a real fixture, but it is worth flagging precisely what it does and does
not prove. Every `spec$map` entry reachable from a real `drmTMB()` formula
today is either a whole-component `factor(NA)` (the entire vector is off) or,
in the one partial case I found (`sd(id) ~ w` alongside an untouched `(1 |
id2)` term), an element that corresponds to **no public label at all**
(`sdpars$mu` never reports the `sd(id)`-driven slot; only `fixef:sd(id):w`
addresses its regression coefficient, which is a different label entirely).
So no fixture exists today where a *valid* public label addresses an index
that is *also* map-fixed — by construction, `sdpars`/`corpars` only report
unmapped slots, so a well-formed implementation can never receive a label
that collides with a map-fixed index.

The test I wrote (`"a slot fixed by spec$map is preserved, not overwritten,
when its sibling is targeted"`) is the closest real-fixture approximation:
it targets the free sibling slot (`sd:mu:(1 | id2)`) in a *two-element*
vector whose *other* element is map-fixed, and asserts the map-fixed element
is untouched and equal to the cold-fit default. This does exercise a
genuine integration requirement — the translation layer must build the
full-length override vector without corrupting or erroring on the map-fixed
sibling — but it does not (and, given current code, cannot) test the
narrower claim "a label that names a map-fixed slot is preserved rather than
overwritten," because no such label can currently exist. I am naming this
explicitly rather than dropping it silently, per the task's own instruction.

## Files

- `tests/testthat/test-start-contract.R` (new)
- this note

## Commit

Branch `claude/rev-parity-a1-start-tests`, committed on top of `a7ccd5f25`.
