# Fisher inference audit — `capability-and-limits.Rmd`

**Audit basis:** `vignettes/capability-and-limits.Rmd` on
`codex/site-audit-capability-limits-20260721`, checked against the 2026-07-20
release-scope manifest (including its 2026-07-21 correction) and the generated
capability ledger/census. Source files were read only; no compute was run.

## Verdict

**REPAIR BEFORE THE SITE CLAIM IS ACCEPTED.** The page has one false statement
about an interval's existence and three material omissions/over-generalised
domains. Its otherwise important distinction is sound: callable output is not
an interval claim; finite profile/Wald endpoints are not coverage-certified;
and `inference_ready_with_caveats` is not `supported`.

## Findings, ordered by inference risk

### P1 — `rho12 ~ x` intervals are incorrectly called unavailable

- **Vignette:** `vignettes/capability-and-limits.Rmd:367-374` says that
  supplying `newdata` still gives `NA` bounds and tells readers to refit
  `rho12 ~ 1` if they need an interval.
- **Contrary evidence:** the scope manifest at
  `docs/dev-log/release-audits/2026-07-20-0.6.0-release-scope-manifest.md:172-185`
  documents finite, row-specific profile and Wald intervals when `newdata` is
  supplied; the ledger remains deliberately narrower on certification
  (`mc-0181` is `interval_feasible`, not coverage-backed).
- **Why this threatens inference:** it converts a callable, finite interval
  into a claimed non-capability and gives incorrect analysis advice. The
  replacement must say: `corpairs(..., conf.int = TRUE)` without `newdata`
  reports `newdata_required`; `confint(..., newdata = grid, method =
  "profile")` and `predict_parameters(..., newdata = grid, conf.int = TRUE)`
  compute row-specific intervals; neither has coverage evidence. Only the
  constant `rho12 ~ 1` profile target is coverage-certified.

### P2 — certified Gamma `sigma` random-intercept profile interval is absent from the reader path

- **Vignette:** the at-a-glance table at
  `vignettes/capability-and-limits.Rmd:68-85`, Tier 1 at `:206-265`, and
  interval guidance at `:476-496` omit `gamma` `sigma ~ (1 | id)` entirely.
  It is visible only as an unexplained highest-evidence token in the generated
  family map (`vignettes/includes/capability-ledger-family-map.md:7`).
- **Contrary evidence:** manifest `:76-90` and ledger cell `mc-0242`
  (`docs/dev-log/dashboard/capability-ledger/cells.tsv:246`) certify the
  **ML-Laplace profile** interval for a Gamma `sigma` random intercept at true
  SD 0.40 and `n_each = 12`, with tested `M = {16,32,64}`; `M = 16` is
  borderline, `M = 8` is excluded, and the firm reporting floor is `M >= 32`.
  This is mildly anti-conservative, not nominal, and is neither a Wald claim
  nor evidence for a slope, a combined `mu`+`sigma` RE, REML, or `supported`.
- **Why this threatens inference:** a user cannot distinguish this
  coverage-certified profile interval from the unverified/unsupported
  positive-continuous routes. Add a dedicated row and a short Tier-1 paragraph
  preserving its exact floor and negative space.

### P2 — the fixed-effect Wald statement turns three simulated sample sizes into a universal `n >= 50` floor

- **Vignette:** `vignettes/capability-and-limits.Rmd:72` says the four
  unstructured families have a Wald interval "from `n >= 50`"; `:208-217`
  reinforces this with the broad reassurance that a scarce/noisy field data
  set is not by itself a reason to distrust the intervals.
- **Evidence boundary:** manifest `:94-100` confines the campaign to
  binomial/Poisson/beta/nbinom2 mean coefficients at exactly
  `n in {50,150,500}` (and beta/nbinom2 location-scale coefficients), not all
  `n >= 50`, all designs, or other families.
- **Why this threatens inference:** the direction is reassuring but the
  continuous-threshold wording erases the tested-DGP boundary. Replace it
  with the discrete grid and retain the rare-event/low-count fixtures as the
  particular stress conditions tested, not a general field-data guarantee.

### P2 — two other `inference_ready_with_caveats` cells lack their method/domain caveats

- **Vignette:** `vignettes/capability-and-limits.Rmd:462-505` embeds a family
  map that labels lognormal `mc-0382` and beta-phylogenetic `mc-0017` as
  `inference_ready_with_caveats`, but the at-a-glance/Tier-1 discussion gives
  neither a method nor a certified domain. The closest prose instead says
  structured effects for lognormal are unavailable (`:311-320`), which is
  compatible with the *structured* boundary but does not direct the reader to
  lognormal's ordinary `sigma` RE exception.
- **Ledger boundaries:** `mc-0382` (ledger `cells.tsv:386`) is an **ML-Laplace
  profile** interval for the lognormal `sigma` random intercept only at true
  SD 0.4, `n_each = 12`, and exact `M = {16,32,64}`; it is mildly
  anti-conservative and does not establish a continuous `M` floor. `mc-0017`
  (ledger `cells.tsv:20`) is a **profile** claim only for the two exact
  beta-phylogenetic direct-latent-SD-regression arms (`g = 1024, m = 4`), not
  a `g >= 1024` rule or a family-`sigma`/general phylogenetic capability; its
  shared arm retains one predeclared non-finite profile exclusion and the
  recovery and coverage banks partly share seeds.
- **Why this threatens inference:** the exhaustive table presents both as
  reportable without exposing the conditions needed to avoid false extension.
  Add concise reader-facing boundary notes (or direct, visible links to them);
  do not infer a universal floor from either row.

## Checks that passed

- The five ordinary non-Gaussian `mu` random-slope cells are correctly
  separated from point-bias/Wald claims at
  `vignettes/capability-and-limits.Rmd:231-265`: skew-normal/Tweedie/
  zero-one-beta `M >= 16`, binomial `M >= 32`, and cumulative-logit `M >= 80`
  with `M = 40` explicitly exploratory. The estimator distinction is also
  correct: ML-Laplace profile except AGHQ(25)+Cox-Reid for cumulative-logit.
- The page correctly keeps ordinary Gaussian/bivariate-Gaussian RE intervals
  as planned rather than coverage-certified (`:55-62`, `:193-204`), and keeps
  q1 Gaussian `sigma` profile output diagnostic-only at `g = 8` (`:123-133`,
  `:476-489`).
- The zero-one-beta generator qualification is retained (`:247-265`), so its
  `M >= 16` profile-coverage claim is not silently recast as evidence for the
  intended strictly-interior DGP.

## Disposition

**Counts:** P1 = 1; P2 = 3; P3 = 0.

**Docs-only repair authority:** **Yes, conditionally.** Codex may make the
four evidence-synchronisation repairs above without a new owner decision if it
copies the manifest/ledger boundaries exactly: no tier promotion, no new
continuous floor, no assertion that finite intervals are coverage-certified,
and no expansion of `rho12 ~ x` beyond computed-but-uncertified row-specific
intervals. Any change to the coverage gate, `supported` status, tested DGP, or
scope of a Beta-phylogenetic/positive-continuous cell requires an owner
decision.
