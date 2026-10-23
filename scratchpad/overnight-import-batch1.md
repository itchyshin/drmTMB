# Overnight import audit — batch 1 (11 cells)

Lane: `drmTMB-interval-truth-audit`, branch `claude/lane-overnight-0815`, read-only except
this file. Cells: mc-0025, mc-0027, mc-0029, mc-0031, mc-0177, mc-0178, mc-0179, mc-0180,
mc-0181, mc-0210, mc-0211. All 11 sit at `evidence_tier = interval_feasible`,
`location_checked = unchecked`, `primary_evidence_id = ev-mc-00NN-legacy`
(`docs/dev-log/dashboard/capability-ledger/cells.tsv`), consistent with the 2026-07-11
migration import.

Contract in force: `docs/design/255-interval-feasible-tier-contract.md` — shape-only:
"a named interval method runs to completion on this exact cell and returns a well-formed
interval — finite, ordered, unclamped, from a converged fit with a positive-definite
Hessian." A test that asserts only `confint()` row **labels** (`parm`, `tmb_parameter`,
`conf.status`) does **not** meet this bar (§3.2 of doc 255); a test that never calls
`confint()`/`tmbprofile()` at all meets it even less.

## Cross-cutting queries run for every cell (negative unless noted per-row)

- `grep -rlF "mc-00NN" docs/dev-log/interval-campaign-bindings/` — 0 hits for all 11 cell
  ids (checked individually with `-F` fixed-string grep).
- `grep -cF "mc-00NN" docs/dev-log/check-log.md` (94,041 lines) — 0 for all 11.
- `grep -rlF "mc-00NN" docs/dev-log/after-task/` — 0 for all 11.
- `grep -l "beta_binomial" docs/dev-log/interval-campaign-bindings/*.tsv` — **zero files**;
  the entire `beta_binomial` family has no campaign-binding registry entry at all
  (checked for mc-0025/0027/0029/0031).
- `grep -l "beta_binomial" docs/dev-log/simulation-artifacts/**` — only
  `2026-08-10-beta-binomial-fixture-identifiability/` (dgp diagnostics only, no
  `coverage`/`interval` string in its `.R` files — confirmed by grep) and unrelated
  cross-family manifests (SHA lists, DG3 power arms). No coverage/interval campaign.
- `git log --all --oneline -S"mc-00NN"` for all 11 — hits are only ledger/lane
  administration commits (`36ec0bb8d` render `location_checked`, `9ee8c9fc4` Wave-1
  classification, `2d033a7d3` census, `ae529ade2` tier-separation) or unrelated
  `missing-data`/`phase19` commits that happen to touch shared test files. No campaign
  commit for any of the 11.
- **Prior-wave duplicate check** (today's proven lesson): `git show 9ee8c9fc4:scratchpad/wave1-classification.json`
  and `git show 9ee8c9fc4:scratchpad/uncovered-cohort-A.md` — all 11 cells are already
  filed there as class **(c)** ("legacy import with no run") with
  `run_id/command/replicates blank`, in the `rerun` (73-cell) bucket. This is an
  independent confirmation from an earlier pass, not new evidence — cited so the boundary
  between "prior classification" and "this audit's findings" stays clear.
- `grep -l "biv_gaussian" docs/dev-log/interval-campaign-bindings/*.tsv` — many hits, but
  none bind cell ids mc-0177–0181 or mc-0210/0211 (see per-cell rows for the near-miss
  detail on mc-0210/0211).

---

## Per-cell table

| cell | family / dpar / effect | Q1 campaign | Q2 shape assertion today | Verdict |
|---|---|---|---|---|
| mc-0025 | beta_binomial / mu / fixed | No | Yes — finite+ordered | **B** |
| mc-0027 | beta_binomial / sigma / fixed | No | Yes — finite+ordered (same block) | **B** |
| mc-0029 | beta_binomial / mu / ordinary_re_intercept | No | No — flag only, no `confint()` | **C** |
| mc-0031 | beta_binomial / mu / ordinary_re_slope | No | No — existence check only, no `confint()` | **C** |
| mc-0177 | biv_gaussian / mu1 / fixed | No | No — cited tests never call `confint()` | **C** |
| mc-0178 | biv_gaussian / mu2 / fixed | No | No (same evidence as mc-0177) | **C** |
| mc-0179 | biv_gaussian / sigma1 / fixed | No | No (same evidence) | **C** |
| mc-0180 | biv_gaussian / sigma2 / fixed | No | No (same evidence) | **C** |
| mc-0181 | biv_gaussian / rho12 / fixed | No | No (same evidence) | **C** |
| mc-0210 | biv_gaussian / mu1 / structured phylo (direct `sd_phylo1(sp)~x`, REML, q4) | No (near-miss route mismatch, see below) | No — finite **SE** only, no `confint()` | **C** |
| mc-0211 | biv_gaussian / mu2 / structured phylo (direct `sd_phylo2(sp)~x`, REML, q4) | No (near-miss route mismatch, see below) | No — finite **SE** only, no `confint()` | **C** |

---

## Evidence detail

### mc-0025, mc-0027 — beta_binomial mu/sigma, fixed

Ledger `legacy_evidence_source`: `src/drmTMB.cpp:2797-2852; R/drmTMB.R:4717-4881; R/methods.R:5050; tests/testthat/test-beta-binomial.R:72-110`.

**Q1.** No campaign (cross-cutting queries above; `beta_binomial` has zero campaign-binding
files at all).

**Q2.** Read `tests/testthat/test-beta-binomial.R:72-111` (current file). The single
`test_that("drmTMB fits fixed-effect beta-binomial models", ...)` block fits mu and sigma
together, then at lines 93–110:

```r
93   ci <- confint(fit)
95:  ci$parm  == c("fixef:mu:(Intercept)", "fixef:mu:x",
                   "fixef:sigma:(Intercept)", "fixef:sigma:z")
104: ci$tmb_parameter == c("beta_mu","beta_mu","beta_sigma","beta_sigma")
107: expect_true(all(ci$conf.status == "wald"))
108: expect_true(all(is.finite(ci$lower)))
109: expect_true(all(is.finite(ci$upper)))
110: expect_true(all(ci$lower < ci$upper))
```

Lines 108–110 are the 2026-08-15 addition from commit `7c62279e5` ("test: assert finite
ordered endpoints at the 14 label-only confint sites"), whose commit message explicitly
names `mc-0025/0027` as 2 of its 14 target cells. `git show 7c62279e5 -- tests/testthat/test-beta-binomial.R`
confirms the 3-line diff at exactly this site (`+expect_true(all(is.finite(ci$lower)))`
etc.). This is a finite + ordered assertion on a real `confint()` call covering both the
mu row (mc-0025) and sigma row (mc-0027) — the shape bar in design/255 is met.

**Verdict: (B) SHAPE-JUSTIFIED.**

### mc-0029 — beta_binomial mu, ordinary_re_intercept

Ledger cites `tests/testthat/test-beta-binomial.R:113-161`.

**Q1.** No campaign (cross-cutting queries).

**Q2.** Read `tests/testthat/test-beta-binomial.R:113-160`
(`test_that("beta-binomial mu supports ordinary random intercepts", ...)`). The block does
recovery checks (`expect_lt(abs(...sdpars...truth), 0.35)`, `expect_gt(cor(...), 0.40)`)
and, at 151–155:

```r
151  targets <- profile_targets(fit)
152  sd_target <- targets[targets$parm == "sd:mu:(1 | id)", , drop = FALSE]
153  expect_equal(nrow(sd_target), 1L)
154  expect_equal(sd_target$tmb_parameter, "log_sd_mu")
155  expect_true(sd_target$profile_ready)
```

This checks that a target row **exists** and is flagged `profile_ready = TRUE`. It never
calls `confint()` or `tmbprofile()`, so no interval is ever computed in this test — there
is no `lower`/`upper` pair to check finiteness or ordering on. `grep -n "confint(" tests/testthat/test-beta-binomial.R`
returns only the one hit inside the mc-0025/0027 block (line 93); nothing in the 113–160
range. `mc-0029` is **not** one of the 14 cells commit `7c62279e5` touched.

**Verdict: (C) NOT EVEN SHAPE** — the tier is unearned even under the shape-only contract;
this is weaker than the label-only `confint()` case doc 255 flagged, since no interval is
computed at all.

### mc-0031 — beta_binomial mu, ordinary_re_slope

Ledger cites `tests/testthat/test-nongaussian-mu-random-slopes.R:38-46,95-99,145-160`.

**Q1.** No campaign (cross-cutting queries).

**Q2.** Read `tests/testthat/test-nongaussian-mu-random-slopes.R:1-161` in full (the whole
file). `beta_binomial` is one of 6 families run through a shared helper
`expect_nongaussian_mu_slope_fit()` (lines 112–144), called from
`test_that("non-Gaussian mu supports independent numeric random slopes", ...)` at
146–161. The only profile-adjacent assertion is:

```r
137  targets <- profile_targets(fit)
138  expect_equal(any(targets$parm == paste0("sd:mu:", slope_label)), TRUE)
```

— an existence check on the target list, again with zero `confint()`/`tmbprofile()` calls
anywhere in the file (`grep -n "confint(" tests/testthat/test-nongaussian-mu-random-slopes.R`
returns nothing). `mc-0031` is not in the 14-cell `7c62279e5` list either.

**Verdict: (C) NOT EVEN SHAPE.**

### mc-0177 – mc-0181 — biv_gaussian mu1/mu2/sigma1/sigma2/rho12, fixed (base route)

Ledger cites, identically for all five cells: `tests/testthat/test-biv-gaussian.R:956-980;
tests/testthat/test-summary.R:437-470`. Claim boundary text: "recovers all five dpars
within 0.12 abs-error tolerance at n=900, and Wald SEs via summary()/sdreport are
demonstrated. No committed CI-coverage simulation found... so this stops short of
'supported'."

**Q1.** No campaign. `grep -rlF "mc-017[7-9]\|mc-018[01]"` across
`interval-campaign-bindings/` — 0 hits. `grep -l "biv_gaussian"` on the same directory
returns 31 files, but every one binds a *different* cell id (mc-0182–0209, mc-0212+,
association/spatial/animal/relmat cohorts) — none is the plain fixed-effect base route.
`docs/dev-log/simulation-artifacts/` has no `biv_gaussian`-fixed coverage directory (the
two `biv-lognormal-rho12-*` directories are a different family). `docs/design/52-phase-18-bivariate-rho12-ademp.md`
is cited in the ledger's own claim_boundary as an ADEMP design sheet whose simulation was
never implemented (per its own after-task report) — the ledger's own prose already
concedes no campaign exists here.

**Q2.** Read both cited ranges in the current files:

- `tests/testthat/test-biv-gaussian.R:956-986` — `test_that("drmTMB fits bivariate
  Gaussian models with constant rho12", ...)`. Fits `mu1~x, mu2~x, sigma1~z1, sigma2~z2,
  rho12~1`, then only point checks: `expect_abs_error_below(coef(...), sim$beta_..., 0.12)`
  for all five dpars (lines 973–977), `expect_length`, and a `rho12` range check. **Zero**
  `confint()` calls in this block. `grep -n "confint(" tests/testthat/test-biv-gaussian.R`
  returns exactly one hit in the whole 3000+ line file, at line 1419, inside an unrelated
  labelled random-intercept-covariance test (`test_that("bivariate Gaussian supports
  labelled mu1/mu2 random-intercept covariance blocks", ...)`, starting line 988) — not
  this route.
- `tests/testthat/test-summary.R:437-470` — this range sits inside
  `test_that("summary() separates bivariate group covariance from residual rho12",
  ...)` (starts line 419), which fits `mu1 = y1 ~ x + (1 | p | id), mu2 = y2 ~ x + (1 | p
  | id), sigma1 = ~1, sigma2 = ~1, rho12 = ~1` — a **labelled random-intercept covariance**
  model, not the plain-fixed base route mc-0177–0181 claim. Lines 437–470 check
  `summary()` table structure (`component`, `estimate`, `term` columns) only. The one place
  in this same test that does assert finite/ordered profile endpoints is lines 505–514
  (`is.finite(cor_row$conf.low)`, `cor_row$conf.low < estimate < cor_row$conf.high`) — but
  that is **outside** the cited 437–470 range, and even if included it targets
  `cor:mu:cor(mu1:(Intercept),mu2:(Intercept)|p|id)` and `sd:mu:mu1:(1|p|id)` — random-
  intercept covariance targets, not the fixed `mu1/mu2/sigma1/sigma2/rho12` coefficients
  mc-0177–0181 claim.

So across both citations, for the actual fixed-effect base route there is no `confint()`
call anywhere — not even a labels-only one.

**Verdict for all five (mc-0177, mc-0178, mc-0179, mc-0180, mc-0181): (C) NOT EVEN SHAPE.**

### mc-0210, mc-0211 — biv_gaussian mu1/mu2, structured phylo (direct `sd_phylo(sp)~x`, REML, q4)

Ledger cites `tests/testthat/test-reml-bivariate.R:190-210`.

**Q1.** No direct campaign for this cell id or this exact route (0 hits for `mc-0210`,
`mc-0211` in `interval-campaign-bindings/`). **Near-miss worth flagging explicitly**: four
campaign-binding registries do cover `biv_gaussian` phylo `mu1`/`mu2` SD targets —
`2026-07-28-phylo-q2-canonical-registry.tsv` (binds mc-0083/mc-0084 [ML] and
mc-0208/mc-0209 [REML]), `2026-07-29-phylo-q4-location-targetwise-authorization.tsv`
(binds mc-0212/mc-0213), `2026-07-29-phylo-dense-q4-high-information-canonical-contracts.tsv`
(binds mc-0216–mc-0219), and `2026-07-29-q2plus-phylo-canonical-contracts.tsv` (binds
mc-0089/mc-0090). **All of these use the random-effect formula
`phylo(1 | p | sp, tree = tree)`** (a q2/q4 RE-covariance route), confirmed by reading each
file's `formula` column. mc-0210/mc-0211 instead use the **direct fixed-formula legacy
parameterization** `sd_phylo1(sp) ~ x, sd_phylo2(sp) ~ x` (ledger `route_variant =
legacy_01`; confirmed in the cited test at line 204:
`sd_phylo1(sp) ~ x, sd_phylo2(sp) ~ x`). Same family, same nominal dpar (mu1/mu2), same
`structure_provider = phylo`, but a genuinely different formula surface/route — none of
these campaigns bind or test the direct-SD-formula cells.

**Q2.** Read `tests/testthat/test-reml-bivariate.R:193-214`
(`test_that("bivariate REML ADMITS phylogenetic direct-SD scale (rung 2)", ...)` — this is
the block the 190–210 citation actually resolves to, since 166–191 is a prior, separate
test). The relevant assertion is:

```r
209  cf <- summary(fit)$coefficients
210  sd_rows <- grep("^sd_phylo", rownames(cf))
211  expect_true(length(sd_rows) >= 1L)
212  expect_true(all(is.finite(cf[sd_rows, "std_error"])))
```

(comment at line 208-209 in the source: "sd_phylo coefficient SEs must be finite under
REML (vcov cov.fixed fallback)"). This checks that a **standard error** column is finite —
it is not a `confint()`/`tmbprofile()` call and there is no `lower`/`upper` pair to test
for ordering or unclamped-ness. `grep -n "confint(\|tmbprofile(" tests/testthat/test-reml-bivariate.R`
returns no hits at all in the file. This is a weaker instrument than even the label-only
`confint()` case doc 255 already ruled insufficient — there is no interval object here at
all, only a point-estimate SE.

**Verdict for both (mc-0210, mc-0211): (C) NOT EVEN SHAPE.**

---

## Summary line per cell

- mc-0025: B — finite+ordered `confint()` assert added 2026-08-15.
- mc-0027: B — same block as mc-0025 covers sigma row.
- mc-0029: C — only a `profile_ready` flag, no `confint()`.
- mc-0031: C — only a target-existence check, no `confint()`.
- mc-0177: C — cited tests never call `confint()` for this route.
- mc-0178: C — same evidence gap as mc-0177.
- mc-0179: C — same evidence gap as mc-0177.
- mc-0180: C — same evidence gap as mc-0177.
- mc-0181: C — same evidence gap as mc-0177.
- mc-0210: C — finite SE only, no `confint()`; nearest campaigns bind a different RE route.
- mc-0211: C — same as mc-0210, mu2 side.
