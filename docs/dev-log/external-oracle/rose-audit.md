# Rose audit — external-oracle harness (PRs #1030, #1031)

Auditor: Rose (`systems_auditor`). Worktree
`/Users/z3437171/Dropbox/Github Local/drmTMB/.worktrees/external-oracle`, branch
`claude/external-oracle-intervals` at `9dad2fc92`, base `origin/main@6637b9f01`.
Working tree clean at audit time. R 4.6 arm64, `lme4` 2.0.1, `glmmTMB` 1.1.14,
`testthat` 3.3.2, `waldo` 0.6.2, package version 0.7.0 loaded from this worktree
via `devtools::load_all()`.

Everything below was re-run by me. I did not take any number from the commit
message, the check-log, the PR body, or `estimator-alignment.md` on trust.

---

## Verdict

| # | Claim | Verdict |
|---|---|---|
| 1 | Profile intervals agree with `fm1P` within 5e-4 on all four variance components; valid SAME-ESTIMATOR (ML-vs-ML) comparison | **NOT-DONE** |
| 2 | `fm1P`/`fm1B` are ML-derived, established by reconstruction | **NOT-DONE** |
| 3 | The 5e-4 tolerance discriminates rather than merely permits | **NOT-DONE** |
| 4 | No REML interval-parity claim is made anywhere | **DONE** |
| 5 | No ledger row added, per design/242 | **PARTIAL** |
| 6 | The landed reader baseline is intact | **DONE** |
| 7 | None of the five receipt-pinned files changed | **DONE** |

Counts: **3 P0**, **5 P1**, **4 P2**.

The harness is real, it runs, it is not vacuous, and it would catch the most
likely regression. What fails audit is the *prose around it*: three separate
statements of verified fact are wrong, and one of them leaves a false capability
claim sitting in the repo.

---

## P0 — blocking

### P0-1. `candidates.tsv` was **not** corrected; three documents claim it was, and a false capability claim is left in the repo

The commit message (`9dad2fc92`) states:

> `fm_nest` was dropped from the matched-twin set because drmTMB rejects nested
> `(1 | Subject/fDays)` grouping; **the candidate matrix records the correction.**

`docs/dev-log/check-log.md:93502-93504` states:

> **The candidate matrix in `docs/dev-log/external-oracle/candidates.tsv` was
> corrected.**

The PR #1031 body states:

> Dropped from the twin set; **the candidate matrix records it.**

It does not. `docs/dev-log/external-oracle/candidates.tsv:13` is unchanged and
still reads:

```
fm_nest  Reaction ~ Days + (1 | Subject/fDays)  gaussian  ~1  TRUE  EXPRESSIBLE
  Nested random effects (1 | Subject/fDays) expand to (1 | fDays:Subject) +
  (1 | Subject). drmTMB supports nested structures via formula expansion.
  Has lmer twin fm_nest_lmer.
```

`has_lmer_twin = TRUE`, `verdict = EXPRESSIBLE`, and an affirmative sentence —
"drmTMB supports nested structures via formula expansion" — that is false. I
verified the underlying fact directly:

```
drmTMB(bf(Reaction ~ Days + (1|Subject/fDays)), gaussian(), data = fm_nest$frame)
#> Error: Random-effect grouping terms must be simple variables.
#>   Use syntax like `(1 | id)`, `(0 + x | id)`, or `(1 + x | p | id)`.
```

So the file is the *only* new artifact in the change that asserts a capability,
and the capability does not exist. This is the exact failure mode the repo's
claim discipline exists to stop, and it arrived attached to three independent
assertions that it had been fixed. Grep confirms there is no second `fm_nest`
row and no `correct`/`reject`/`NOT_EXPRESSIBLE` wording anywhere in the 33-line
file.

**Fix:** set `verdict = NOT_EXPRESSIBLE`, `has_lmer_twin = FALSE` (or keep TRUE
and say the twin is unusable), and replace the note with the actual rejection
message — or delete the three "was corrected" sentences. Do not do only one.

### P0-2. The tolerance is **relative**, not absolute — the discrimination argument is refuted by measurement

`tests/testthat/test-comparators-external-oracle.R:207` sets
`tolerance_profile <- 5e-4` and passes it to `expect_equal()`. Under
`Config/testthat/edition: 3` (`DESCRIPTION:70`), `expect_equal(tolerance = t)`
routes to `waldo::compare(tolerance = t)`, which applies a **relative**
criterion. The check-log
(`docs/dev-log/check-log.md:93478`), the commit message, and the PR body all
describe it as "`5e-4` **absolute**".

Measured on the real data (drmTMB fit vs the shipped `fm1P`), the absolute
perturbation at which each assertion actually starts to fail:

| target | quoted abs diff | **operative** abs slack | fraction of the real budget used |
|---|---|---|---|
| `sd_(Intercept)\|Subject` | 2.627e-4 | **2.578e-2** | **1.02 %** |
| `sd_Days\|Subject` | 1.389e-5 | **6.26e-3** | **0.22 %** |
| `cor_Days.(Intercept)\|Subject` | 3.268e-5 | **5.42e-4** | **6.03 %** |
| `sigma` | 3.114e-4 | **2.556e-2** | **1.22 %** |

(The four quoted absolute diffs reproduce exactly — the *measurements* are
correct. Only the bound is misdescribed.)

Consequence for the load-bearing sentence. Commit message and check-log:

> The bound discriminates rather than merely permits: it would still have failed
> the wrong-estimator REML reconstruction at `5.643e-4`.

I injected exactly that 5.643e-4 absolute discrepancy onto each endpoint and
re-ran the comparison as the test performs it:

```
sd_(Intercept)|Subject        -> PASS (does NOT discriminate)
sd_Days|Subject               -> PASS (does NOT discriminate)
cor_Days.(Intercept)|Subject  -> FAIL
sigma                         -> PASS (does NOT discriminate)
```

The claim fails on **three of four targets — including `sd_(Intercept)`, the one
target the argument was actually built on** (`estimator-alignment.md:57`: the
REML reconstruction's 5.643e-4 residual lives on that row and nowhere else). It
survives only via `cor`, where the REML reconstruction's residual was 6.82e-8,
i.e. where there was no discrepancy to catch. The test would **not** have failed
the REML reconstruction.

Also wrong as a direct consequence: the PR #1031 headline table's "vs 5e-4
bound" column (`53%`, `<3%`, `<7%`, `62%`). The true figures are 1.02 %, 0.22 %,
6.03 %, 1.22 %. The margin the PR presents as its tightest evidence (`sigma`, "62
% of bound") is in reality the second-*loosest*.

**Fix:** either assert absolutely (e.g.
`expect_lt(max(abs(drm - ref)), 5e-4)`) and keep the prose, or keep
`expect_equal` and rewrite every "absolute"/"discriminates"/"% of bound"
statement to match relative semantics. The first is what the argument in
`estimator-alignment.md` is actually reasoning about.

### P0-3. `fm1P` ML-provenance is **not** established — an alternative explanation reproduces the numbers as well or better

The whole ML verdict rests on one ratio (`estimator-alignment.md:55-71`): an ML
refit reproduces `fm1P` to 4.36e-5, a REML refit only to 5.64e-4, "~13x worse",
with the residual concentrated on `sd(Intercept)`. That is evidence only if the
**within-estimator** reconstruction noise floor sits well below 5.64e-4. Fisher
never measured that floor independently — he read it off the ML-vs-`fm1P`
residual itself, which is circular (`estimator-alignment.md:182-189` calls
4.36e-5 the "optimizer-path noise" floor while it is simultaneously the evidence).

I measured it. Same model, same data, same `lme4` 2.0.1, varying only the
optimizer, all fits converged, `isREML()` checked:

| reconstruction | `isREML` | `sd(Int)` | `logLik` | max abs diff vs `fm1P` |
|---|---|---|---|---|
| ML / nloptwrap | FALSE | 23.7798 | -875.9697 | 4.357e-5 |
| ML / bobyqa | FALSE | 23.7806 | -875.9697 | 5.632e-5 |
| ML / Nelder_Mead | FALSE | 23.7805 | -875.9697 | 5.730e-5 |
| REML / nloptwrap | TRUE | 24.7407 | -871.8141 | 5.643e-4 |
| **REML / bobyqa** | **TRUE** | **24.7405** | **-871.8141** | **5.626e-5** |

A genuine, converged **REML** fit reproduces `fm1P` to **5.626e-5 — better than
two of the three ML reconstructions.** The "13x" ratio is an artifact of pairing
ML/nloptwrap against REML/nloptwrap; it is 1.3x, not 13x, once the optimizer is
allowed to vary.

Supporting magnitudes:

- within-**REML** optimizer spread: **5.634e-4** — the entire claimed
  discrimination signal (5.643e-4) is the same size as noise from changing the
  optimizer inside REML;
- within-**ML** optimizer spread: **8.03e-5** — *above* the 4.36e-5 figure quoted
  as the noise floor, and above the REML/bobyqa residual;
- ML-vs-REML separation on `sd(Intercept)`: **6.079e-4**. Signal-to-noise ≈ 1.1.

`fm1P` is a bare matrix with attributes `dim, dimnames` only — no estimator
metadata — and `grep -rl "fm1P\|confint_ex"` over the entire installed `lme4`
tree returns nothing, so Fisher is right that no generating script ships. The
provenance is genuinely unrecoverable from the artifact; it is not recoverable
from reconstruction either.

Therefore "this is a same-estimator comparison rather than a coincidental
numerical match" (commit message) and "**The estimator was pinned before any
assertion was written**" (check-log, bolded) are **unsupported**. The honest
statement is the opposite of the one made: `lme4`'s ML and REML profile CIs for
this model differ by at most 6.08e-4, while the test's operative slack on that
row is 2.58e-2, so **the test cannot distinguish an ML reference from a REML
reference at all** — which is why it passes either way.

**Fix:** downgrade to "`fm1P`'s estimator could not be determined; it does not
matter here because lme4's ML and REML profile endpoints for this model differ by
<6.1e-4, far inside the assertion's slack." That is both true and sufficient.
Delete the "pinned before any assertion was written" framing.

---

## P1 — should fix

### P1-1. `library(lme4)` leaks onto the search path and breaks three landed reader test files

`tests/testthat/test-comparators-external-oracle.R:169`, `:249`, `:304` call
`library(lme4, quietly = TRUE)` and never detach. This is the **only** `library()`
call in the entire `tests/testthat/` directory — every other comparator test,
including all ~40 in `tests/testthat/test-comparators.R`, uses namespace-qualified
`lme4::` calls (`test-comparators.R:24,29,34,...`). It is a break with unanimous
repo precedent, and `sleepstudy` does not require it (`lme4::sleepstudy` works).

Measured effect, same R session, files run in the order testthat uses:

| file | run before lme4 attached | run after |
|---|---|---|
| `test-reader-public-schema.R` | 34 pass, 0 error | 26 pass, **1 error** |
| `test-reader-journeys.R` | 53 pass, 0 error | 30 pass, **1 error** |
| `test-reader-oldfit-compat.R` | 15 pass, 0 error | 6 pass, **1 error** |

All three fail identically with
`Error in UseMethod("ranef"): no applicable method for 'ranef' applied to an
object of class "drmTMB"` — `lme4` lands at search-path position 2, above
`drmTMB`, and its `ranef` generic wins.

**This does not break `R CMD check`.** Under `test_check()`/`test_dir(package =
"drmTMB")` the test environment's parent is the package *namespace*, so drmTMB's
`ranef` resolves first; I confirmed 176/176 pass there (see Claim 6). That is why
this is P1 and not P0. But it does break `devtools::test_file()` /
`testthat::test_file()` — the single most common developer workflow — for three
landed files, silently, depending on run order. Alphabetically
`test-comparators-external-oracle.R` sorts *before* every `test-reader-*.R` file,
so the leak is always upstream of the victims.

**Fix:** delete all three `library()` calls; use `lme4::sleepstudy`.

### P1-2. Skip guards check the package, not the fixture — a Suggests reorganisation turns into an `R CMD check` ERROR, not a SKIP

`skip_if_not_installed("lme4")` / `("glmmTMB")` guard package presence. The tests
then read *undocumented internal fixture paths*:

- `test-comparators-external-oracle.R:27` — `glmmTMB/test_data/models.rda`
- `test-comparators-external-oracle.R:172` — `lme4/testdata/confint_ex.rda`
- `test-profile-shape-boundary.R:30,54` — `lme4/testdata/badprof.rds`

These are the comparator packages' own test fixtures, not API. If a future
release renames, relocates, or stops installing them, `load()`/`readRDS()`
**errors** and takes the check red. Both directories exist today (I listed them:
`glmmTMB` ships 16 files including `old_fit.rds`/`oldfit.rds`; `lme4` ships 41
including `badprof.rds` and `confint_ex.rda`), so no citation has rotted — but the
guard is one level too shallow.

**Fix:** add `skip_if_not(file.exists(<path>), "<pkg> no longer ships <file>")`
next to each `skip_if_not_installed()`.

### P1-3. `docs/design/242` is now stale and was not updated

`docs/design/242-external-comparator-evidence-class.md:48-49` asserts:

> Every comparator test in the repo is single-seed and single-dataset, and **none
> asserts standard-error or confidence-interval equality across packages.**

PR #1031's own body says "no repo test previously asserted CI or SE equality
across packages. **This is the first.**" So the change knowingly falsifies a
sentence in the design doc that governs this evidence class, and leaves it
standing. The same sentence is paraphrased in the docstring of
`tools/tests/test_capability_ledger.py:2997-3002`. Nothing enforces it, so nothing
went red — which is exactly why it needs a human edit.

**Fix:** amend `242:48-49` to record the new exception, or add a dated note.

### P1-4. The Claim-5 reasoning is over-general — doc 242 explicitly licenses what Block 1 measures

The commit message and check-log justify adding no ledger row with:

> That policy requires every `external_comparator` `claim_boundary` to state it
> does not cover intervals ... This evidence is deliberately a test-only
> regression guard.

Accurate about the *interval* block. But `242:44-45` states plainly what **is**
licensed: "That `drmTMB`'s likelihood and optimizer reach the same optimum as an
independent implementation of the same model, on the dataset tested." That is
precisely Block 1 (`fm_us1`, `fm_diag2` point estimates + `logLik` vs `lme4`
twins), which is new, strong-independence comparator evidence and could carry a
row today with a conforming `claim_boundary`. The stated reason collapses two
different blocks into one and reads as if the policy forbids recording *any* of
it. `tools/tests/test_capability_ledger.py:3008-3026` requires the tokens
"interval", "coverage", "single-seed" plus a STRONG/WEAK independence
declaration — all of which Block 1 can satisfy.

Withholding is the conservative call and I do not object to it. The *reason
given* is inaccurate and will misdirect the next contributor.

### P1-5. The Bolker attribution in the PR body is unsourced

PR #1031 body:

> Ben Bolker — author of both comparator packages — independently warned that
> **confidence intervals are the least reliable part of this class of software.**

`grep -rn "Bolker"` over `docs/dev-log/external-oracle/` and
`docs/dev-log/check-log.md` returns nothing. Issue #859 says only "Direction from
external expert review of the package (2026-07-28); the audit below is our own" —
it names no one. So a paraphrased warning is attributed to a named living person,
who authors both comparator packages, with no citation anywhere in the repo. The
repo's own writing rule (`AGENTS.md`, Writing Style) requires a citation, local
evidence, or an explicit design-assumption note for factual claims.

To be fair to the author: the framing itself is careful and does **not** overstate
endorsement — "He never saw our coverage numbers, so that is corroboration of
caution already encoded, not validation of any figure" is the right disclaimer,
and it directly answers the design/242 credibility-laundering concern. The defect
is sourcing, not spin.

**Fix:** cite the 2026-07-28 review, or drop the name.

---

## P2 — nits

- **P2-1. "0 skips" is a local-only property.** Check-log
  `:93521` and the PR table both report "0 fail, 0 skip". True here. But
  `test-profile-shape-boundary.R:133-157` is guarded by `skip_if_not(file.exists(...))`
  on `docs/known-limitations.md`, and `^docs$` is `.Rbuildignore`d
  (`.Rbuildignore:11`), so under `R CMD check` from a tarball that block **does**
  skip. The test file says so itself, honestly, at `:134-140`; the check-log and
  PR do not.
- **P2-2. Two of five blocks in the "external oracle" file have no oracle.**
  `test-comparators-external-oracle.R:246-295` (confint defaults to Wald) and
  `:301-357` (transformation contract) compare drmTMB against drmTMB. The file
  header at `:6-7` declares `EVIDENCE CLASS: external_comparator` for the whole
  file. Fine tests; wrong file, or wrong header.
- **P2-3. "adopts the stored-old-fit pattern" (check-log `:93507`) reads as if
  glmmTMB's stored artifacts are exercised.** They are not — the test builds and
  round-trips a fresh fit in-process. `test-reader-oldfit-compat.R:12-14` says so
  explicitly ("with no stored binary fixture"), so this is a check-log wording
  issue only. Correctly, glmmTMB's `old_fit.rds` *cannot* test drmTMB
  backward-compatibility.
- **P2-4. The profile-shape pin catches implementation, not claims.**
  `test-profile-shape-boundary.R:77-131` fails if a future PR *adds* a trace
  argument or `monoton`/`shape` wording to `profile_interval_diagnostics()`. That
  is what its own comment says (`:82-84`) and it is a genuine tripwire, not a
  tautology. But the brief's framing — "fails if someone claims shape detection
  without implementing it" — is inverted: the claim-side guard is the
  `known-limitations.md` block, which skips under `R CMD check` (P2-1). Worth
  stating plainly so nobody relies on the wrong half.

---

## What I tried that did NOT break it

Listed so the surviving evidence is legible, not just the failures.

- **Interval-test vacuity (risk a): NOT vacuous.** Read line by line. `fm1P` is
  genuinely the stored matrix from `lme4/testdata/confint_ex.rda` (`:172`); the
  drmTMB side is genuinely recomputed via `confint(method = "profile")` (`:188`).
  Nothing compares an object to itself. The `as.numeric(ci[cond, c("lower","upper")])`
  idiom errors loudly on a 0- or 2-row match rather than passing silently.
  **Positive control:** a drmTMB `REML = TRUE` fit **fails** the test as written on
  3 of 4 targets (max abs 1.80, 0.399, 0.0193; `sigma` passes). So the test does
  catch the most likely real regression — a drmTMB-side estimator flip — even
  though it cannot catch what the prose says it catches (P0-2).
- **Does it run, or skip (risk b): it runs.** `test_dir("tests/testthat",
  package = "drmTMB", filter = "comparators-external-oracle|profile-shape-boundary|reader-")`
  → **176 pass, 0 fail, 0 skip, 0 error**, per file: external-oracle **28**,
  profile-shape **25**, journeys **53**, oldfit **15**, public-schema **34**,
  vignette-contracts 21. The three claimed tallies (28/15/25) are exact.
- **`docs`/`tools` dependence under `R CMD check`:** only the one deliberately
  skipped block (P2-1). Nothing else in the three files touches `^docs$` or
  `^tools$`.
- **Citation rot:** none. `lme4/testdata/` ships `badprof.rds` and
  `confint_ex.rda`; `glmmTMB/test_data/` ships `models.rda`, `old_fit.rds`,
  `oldfit.rds`. `badprof.rds` really is `thpr`/`data.frame`, 360x8, with no `call`
  and no `formula`/`data` attribute — issue #859's task 2 genuinely is not
  executable as written, and saying so was the right call.
- **The four quoted absolute diffs reproduce exactly:** 2.627e-4, 1.389e-5,
  3.268e-5, 3.114e-4. The measurement work is sound; only its interpretation is
  not.
- **Claim 4 — no REML interval-parity claim: holds.** I grepped every added line
  of the diff for `REML` (77 hits). Every one either disclaims parity
  (`test-comparators-external-oracle.R:11-15`; check-log `:93481-93484`), scopes
  agreement to point estimates/`logLik`, or is a `REML = FALSE` argument. No
  wording implies REML interval parity anywhere, including the PR body.
- **Claim 6 — reader baseline intact: verified independently.** 53 journey
  assertions, 34 public-schema, 21 vignette-contracts, 0 fail / 0 skip. I also
  confirmed these pass *before* the oracle file runs, which is how I isolated
  P1-1.
- **Claim 7 — receipt-pinned files: verified.**
  `git diff origin/main...HEAD --name-only -- R/methods.R R/drmTMB.R src/drmTMB.cpp
  tests/testthat/test-zero-one-beta.R tools/run-lane-c-c17c1-c14-model15-compatibility.R`
  returns empty. The full change is 9 files: `_pkgdown.yml`, `check-log.md`, 4
  notes under `docs/dev-log/external-oracle/`, 3 test files. No R, C++, `NAMESPACE`,
  `DESCRIPTION`, `man/`, vignette or capability-ledger artifact changed.
- **Claim 5, mechanical half: verified.** No capability-ledger file in the diff.
  `python3 tools/capability_ledger.py --check` → `OK (31 generated outputs)`;
  `python3 -m unittest tools/tests/test_capability_ledger.py` → **73 tests, OK**,
  with `C14 receipt equivalence: OK (3 eligible, 7 source-different retained
  receipts; C17 current-source compatibility PASS)`.
  `Rscript tools/check-reader-contracts.R` → `Reader vignette contract: OK`.
- **PR #1030:** the one-line `_pkgdown.yml` addition registering
  `native_reader_contracts` is exactly one line, in the section the check-log
  says, and nothing else. No issue found.
- **Old-fit honesty (risk d): holds.** `test-reader-oldfit-compat.R:25-29` states
  the within-version scope; the test body does exactly that and no more (build,
  `saveRDS`, `readRDS`, compare five reader verbs, assert the
  `keep_tmb_object = FALSE` path degrades to `note`). It does not read as
  stronger than its stated scope. `oldfit-compat.md:127-131` repeats the limit.
- **Profile-shape non-vacuity (risk e): holds**, with the framing caveat at P2-4.
  `expect_identical(names(formals(...)), c(...))` is a real tripwire, not a
  tautology.
- **Overclaim sweep (risk c):** `profile-shape-boundary.md` and
  `oldfit-compat.md` are appropriately scoped throughout — I found no frontier
  language, no coverage language, and no generalisation beyond one dataset in
  either. `estimator-alignment.md:217-253` ("What this licenses / does not
  licenses") is a genuinely careful boundary statement and correctly cites
  `242`'s overlap-not-frontier rule. The overclaims are concentrated in the
  commit message, check-log and PR body, not in the notes.

---

## Residual risk

- **Platform/BLAS sensitivity (the brief's question on Claim 3).** Because the
  operative bound is ~50x looser than documented on three of four targets, the
  risk of a *spurious failure* elsewhere is low, not high — the test is far more
  permissive than believed, not more fragile. The exception is
  `cor_Days.(Intercept)|Subject`, whose operative slack is 5.42e-4 against an
  observed 3.27e-5 (6.03 % used); that is the one row where a different BLAS or
  `lme4` version could plausibly move things. I tested a single platform (arm64
  macOS), a single `lme4` (2.0.1) and a single `glmmTMB` (1.1.14). If the tolerance
  is converted to a genuine absolute bound per P0-2, cross-platform behaviour must
  be re-measured — `sd(Intercept)` and `sigma` would then sit at 53 % and 62 % of
  bound as the PR already (incorrectly) claims, and *that* is genuinely tight.
- **`fm1P` provenance may be permanently unresolvable.** The artifact carries no
  estimator metadata and no generating script ships. The only decisive route is
  `lme4`'s git history / GitHub code search, which neither Fisher nor I could
  reach from here. My contribution is negative — I showed reconstruction cannot
  settle it — not a counter-verdict that `fm1P` is REML.
- **I did not run `devtools::check()` or `R CMD check` on a built tarball.** My
  `test_dir(package = "drmTMB")` run is the closest available proxy for the
  `test_check()` environment and is what I based the P1-1 severity call on. A real
  tarball check would also confirm the P2-1 skip and the P1-2 fixture-path
  exposure.
- **I did not re-derive `glmmTMB`'s stored `models.rda` objects' vintage.** They
  are fits from an older `glmmTMB`; the tests only touch `$frame` and the
  `_lmer` twins, which is the safe subset, but `lme4::VarCorr()` on a stored
  `merMod` from an older `lme4` is an unmeasured cross-version dependency.
- **Single-run measurement.** Each number above comes from one run on one
  machine. The optimizer-spread result (P0-3) is the one I would most want
  replicated, because it overturns a review verdict — though it is a
  deterministic, seed-free computation, so replication should be exact.

---

## Bottom line

The engineering is good and the tests are not vacuous — the positive control
(drmTMB `REML = TRUE` fails on 3 of 4 targets) proves the interval test has real
discriminating power, and the reader baseline, ledger, and receipt-pin claims all
verify cleanly. But three stated facts do not survive re-measurement, and one of
them (P0-1) leaves an unsupported capability claim in the repository behind a
sentence saying it was removed. Per D-43 the completion claim should be withheld
until P0-1 through P0-3 are addressed; P0-1 is a repo-state defect and must be
fixed, while P0-2 and P0-3 can be discharged either by changing the code or by
changing the prose to match what the code and the evidence actually support.

---

# Re-audit

Scope: **the three P0s only**, at the coordinator's request. The P1/P2 items are
not re-examined and are not claimed closed. Branch
`claude/external-oracle-intervals` at **`787104a9b`**, rebased onto
`origin/main@888d9108e`. Everything below was re-run at that HEAD; I did not
accept any figure from the fix report on trust.

## P0-1 — false capability claim in `candidates.tsv` — **CLOSED**

`docs/dev-log/external-oracle/candidates.tsv:13` now reads:

```
fm_nest  Reaction ~ Days + (1 | Subject/fDays)  gaussian  ~1
  TRUE (twin unusable)  NOT_EXPRESSIBLE
  Nested grouping (1 | Subject/fDays) is REJECTED by drmTMB. Verified:
  "Random-effect grouping terms must be simple variables. Use syntax like
  `(1 | id)`, `(0 + x | id)`, or `(1 + x | p | id)`." The earlier claim that
  drmTMB supports nested structures via formula expansion was WRONG and is
  corrected here. The lmer twin fm_nest_lmer exists but cannot be paired.
```

The quoted rejection text is verbatim what I observed from the package. Verdict
counts recomputed from the file itself: **18 EXPRESSIBLE / 14 NOT_EXPRESSIBLE
over 32 data rows** — matches the stated figures.

The reason this was P0 was not the row alone but that three documents asserted a
correction that had not happened. Both re-checked:

- Commit message `787104a9b` now states the sequence accurately — "The candidate
  matrix row **initially still read EXPRESSIBLE with a false supporting note
  while three documents asserted it had been corrected**; the row now reads
  NOT_EXPRESSIBLE and carries the verbatim rejection message."
- `docs/dev-log/check-log.md` carries the same correction, names the false note
  it replaced, and records the 18/14 counts.

Artifact and assertions now agree, and the failure itself is on the record rather
than quietly overwritten. Closed.

## P0-2 — relative-vs-absolute tolerance — **CLOSED**

The helper is genuinely absolute
(`tests/testthat/test-comparators-external-oracle.R:233-237`):

```r
expect_abs_close <- function(actual, expected, info) {
  testthat::expect_lt(max(abs(as.numeric(actual) - as.numeric(expected))),
                      tolerance_profile)   # 5e-4
  invisible(info)
}
```

`expect_lt()` takes no tolerance and never reaches waldo, so no relative
criterion can apply.

**Discrimination re-measured, not accepted.** Injecting exactly the 5.643e-4
absolute discrepancy that failed in the first audit:

| target | first audit (relative) | now (absolute) |
|---|---|---|
| `sd_(Intercept)\|Subject` | PASS | **FAIL** |
| `sd_Days\|Subject` | PASS | **FAIL** |
| `cor_Days.(Intercept)\|Subject` | FAIL | **FAIL** |
| `sigma` | PASS | **FAIL** |

4 of 4, against 1 of 4 before. The bound now does what the prose says.

**No relative `tolerance =` survives against `fm1P`/`fm1B`.** I grepped every
`tolerance`/`expect_equal` in the file. The remaining `tolerance = 1e-4` uses
(`:57`–`:164`) are all Block 1, comparing against the `lmerMod` twins, not
against `fm1P`/`fm1B`; `:349`–`:378` are `expect_equal` on transformation
*strings* (`"exp"`, `"tanh"`), where tolerance is inapplicable. Block 2 contains
no `expect_equal` at all.

**The REML falsification reproduces exactly**, drmTMB refit with `REML = TRUE`,
same absolute bound:

```
sd_(Intercept)|Subject   maxabs = 1.800      FAIL  (360055% of budget)
sd_Days|Subject          maxabs = 0.3985     FAIL  ( 79705% of budget)
cor_Days.(Intercept)     maxabs = 1.928e-2   FAIL  (  3855% of budget)
sigma                    maxabs = 3.114e-4   pass  (    62% of budget)
=> 3 of 4 targets FAIL
```

and ML passes at 53% / 3% / 7% / 62% of budget, 0 of 4 failing. Both match the
reported figures to the digit.

## P0-3 — ML provenance — **CLOSED on substance; one stale line must go**

The claim is withdrawn, not defended, in all four load-bearing places:
`test-comparators-external-oracle.R:12-17` (header), `:182-188` and `:222-230`
(in-test), the check-log entry, and the commit message. Each cites the
REML/`bobyqa` 5.63e-5 counter-reconstruction, the 5.63e-4 within-REML spread
against the 6.08e-4 ML-vs-REML separation, and the ~1.1 signal-to-noise. The
phrase "the estimator was pinned before any assertion was written" is gone from
the tree. The replacement wording — agreement "to within lme4's own
optimizer-to-optimizer reproducibility for this model, not a matched-estimator
proof" — is exactly what the evidence supports.

**One surviving contradiction, and it is two lines from its own retraction.**
`tests/testthat/test-comparators-external-oracle.R:190`:

```r
# Fit drmTMB model with identical formula, data, and estimator (REML = FALSE)
```

`:188` says the agreement is "not proof of a matched estimator"; `:190` asserts
the estimator is *identical*. That is the withdrawn claim, restated. It is a
stale leftover rather than a defence — every other instance was removed — but it
is the one line a reader skimming the fit call will actually see. Delete
"and estimator" (or write "and our own estimator choice"). I did not reopen P0-3
for it because the substance is unambiguous and repeated four times, but it must
not merge as-is.

## `"ML-only"` header + explicit `REML = FALSE` — consistent, and stronger than asked

Confirmed, and the answer is better than "harmless". I checked the twins:

```
fm_us1_lmer     isREML = FALSE
fm_diag2_lmer   isREML = FALSE
fm_nest_lmer    isREML = FALSE
```

So Block 1 is a genuinely **matched ML-vs-ML pairing on both sides**, and unlike
`fm1P` that is *checkable* — a `merMod` carries its estimator and answers
`isREML()`; `fm1P` is a bare matrix with attributes `dim, dimnames` only. The
`"ML-only"` header is therefore accurate in the strong sense for Block 1 and in
the weak sense for Block 2, where it describes drmTMB's own estimator choice.
That is fully consistent with a withdrawn provenance claim: the estimator is
established exactly where it is establishable, and declared unresolved where it
is not. No change needed. If anything the header could say so explicitly.

## New defects introduced by the fixes

Both minor; neither reopens a P0.

- **N-1 (P2). The bound's own justification comment names the wrong target.**
  `:220-221` reads "Observed max abs diff is 2.63e-4 (sd Intercept), so the bound
  carries a ~1.9x margin". The observed max is `sigma` at **3.114e-4**, a
  **1.61x** margin. The check-log and commit message both get this right ("worst
  case 3.11e-4", "62% of budget"), so the test file now contradicts the two
  documents that describe it, and understates its own tightness in the one
  comment whose job is to justify the number.
- **N-2 (P2). `expect_abs_close()` silently discards `info`.** The parameter is
  accepted and then thrown away (`invisible(info)`); `expect_lt()` never receives
  it. I triggered a real failure to see what a reader gets:

  ```
  Expected `max(abs(as.numeric(actual) - as.numeric(expected)))` < `tolerance_profile`.
  Actual comparison: 1.0000 >= 0.0005
  ```

  Identical for all four assertions — no target name. The previous
  `expect_equal(..., info = )` form did surface it, so this is a small diagnostic
  regression introduced by the fix. Pass `info` through to `expect_lt()`, or
  build the label into the expression.

(`library(lme4)` at `:177` is unchanged — that is original-audit P1-1,
deliberately deferred, not a new defect.)

## Call on `estimator-alignment.md`: **it needs a correction header**

`git diff 9dad2fc92 HEAD -- docs/dev-log/external-oracle/estimator-alignment.md`
is empty — the file is byte-identical to the revision whose verdict was refuted.
It still carries, as live bolded assertions:

- `:50` — "### 1. `fm1P` is ML-derived, not REML-derived"
- `:150` — "**`fm1P`/`fm1B` are ML-derived (`REML = FALSE`)**"
- `:152` — "is therefore **already a valid same-estimator pairing**"

Leaving it as "the original analysis, with the audit as its correction" does not
work here, for three reasons:

1. **Nothing inside the file points at the correction.** The citations run one
   way: the test header and check-log now cite `rose-audit.md`, but
   `estimator-alignment.md` cites nothing and warns of nothing. A reader who
   opens it directly leaves with the refuted verdict.
2. **It is the most discoverable file in the directory for this exact
   question.** It is named `estimator-alignment.md`. Someone asking "which
   estimator produced `fm1P`?" finds this file first and `rose-audit.md` second,
   if at all.
3. **It is the same defect as P0-1, in a different file.** P0-1 was blocking
   because an artifact asserted something the surrounding documents said had been
   corrected. This is an artifact asserting something the surrounding documents
   say was withdrawn. Fixing one and not the other is inconsistent.

**Recommended, and deliberately minimal: a superseded banner at the top, body
kept verbatim.** Do not rewrite it. The original reasoning is worth preserving —
it is the record of how a plausible inference went wrong, which is more useful
than a tidied file — and Fisher's Evidence #2 (the ~5% REML-vs-REML profile gap)
is untouched by the refutation and is still the basis for the no-REML-parity
boundary. Roughly:

> **SUPERSEDED IN PART (2026-08-15).** Section 1 and the ML half of the Verdict
> are **withdrawn**: a converged REML/`bobyqa` refit reproduces `fm1P` to
> 5.63e-5, better than two of three ML reconstructions, so the 13x ratio is an
> optimizer artifact and reconstruction cannot identify the estimator. See
> `rose-audit.md` P0-3. Sections 2, the tolerance analysis, and the
> licenses/does-not-license boundary are unaffected.

That is one block, it is honest about which parts survive, and it costs nothing.

## Do the overall verdicts on claims 1–3 move off NOT-DONE?

**Yes, all three.**

| # | Original claim | Now |
|---|---|---|
| 1 | Intervals agree within 5e-4 on all four components; valid SAME-ESTIMATOR (ML-vs-ML) comparison | **DONE** — as reworded. The 5e-4 half is now a real absolute bound and holds (worst case 3.11e-4, 62% of budget). The SAME-ESTIMATOR half was withdrawn rather than asserted, which is the correct disposition, not a weaker version of the same claim. |
| 2 | `fm1P`/`fm1B` are ML-derived, established by reconstruction | **WITHDRAWN** — not "DONE". Nothing is claimed now, which is the only defensible state given the evidence. Recorded as withdrawn rather than passed. |
| 3 | The 5e-4 tolerance discriminates rather than merely permits | **DONE** — verified two independent ways: injection fails 4 of 4 targets (was 1 of 4), and a drmTMB `REML = TRUE` refit fails 3 of 4 by margins of 3855x to 360055x the budget. |

Gates re-run at `787104a9b` and green: `test_dir(package = "drmTMB")` over the
oracle + reader files gives **176 pass / 0 fail / 0 skip / 0 error**, per file
28 / 25 / 53 / 15 / 34 / 21 — the claimed 28 / 15 / 25 and the 34-schema,
53-journey baseline all reproduce exactly. `tools/check-reader-contracts.R` `OK`;
`capability_ledger.py --check` `OK (31 generated outputs)`; ledger unit tests
**73 OK** with `C17 current-source compatibility PASS`; all five receipt-pinned
files untouched.

**Remaining before merge:** delete "and estimator" at
`test-comparators-external-oracle.R:190`; add the superseded banner to
`estimator-alignment.md`; N-1 and N-2 at leisure. None of these is an evidence
defect — all three P0s are genuinely closed.
