# Phase 18 Next Two-Team Plan, Slices 1619-1718

This note answers the post-closeout question: after the first fitted
`tweedie()` lane and the skew-normal source map, what should two teams do next?
The reader is an R package contributor who needs a narrow work queue, not a
broad wish list.

The plan kept the fitted and design-only surfaces separate at the time it was
written. Team A hardened the implemented Tweedie fixed-effect route. Team B
turned the skew-normal source map into a parameterization and test decision.
That Team B gate is now superseded by the fitted `skew_normal()` first slice;
use this note as historical context for the moment contract, not as a current
instruction to keep the constructor absent.

## Current Starting Point

Slices 1419-1518 added the first fitted Tweedie route:

```r
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ 1),
  family = tweedie(),
  data = dat
)
```

The fitted contract is:

```text
y_i | mu_i, sigma_i, nu_i ~ Tweedie(mu_i, phi_i, nu_i)
log(mu_i) = eta_mu_i
log(sigma_i) = eta_sigma_i
phi_i = sigma_i^2
E[y_i] = mu_i
Var[y_i] = sigma_i^2 * mu_i^nu_i
1 < nu_i < 2
```

This means `fitted()` is the unconditional response mean, public `sigma` is
the square root of Tweedie dispersion `phi`, and `nu` is still intercept-only.
Predictor-dependent `nu`, random effects, structured effects, bivariate
Tweedie, zero-inflation aliases, and hurdle aliases remain planned.

Slices 1519-1538 added a source map for a future `skew_normal()` family. That
map records the current native-location design assumption:

```r
# Planned, not fitted:
drmTMB(
  bf(y ~ x, sigma ~ z, nu ~ w),
  family = skew_normal(),
  data = dat
)
```

Here `nu` is residual or observation-level skewness. It is not latent-effect
skewness, and `skew(id) ~ x` remains outside the grammar.

## Team A: Slices 1619-1668, Tweedie Evidence Hardening

Team A should not widen Tweedie support. Its purpose is to make the fitted
fixed-effect claim harder to misread and easier to validate against external
software.

| Slice | Task | Done when |
| --- | --- | --- |
| 1619 | Rehydrate the Tweedie fitted lane | The branch, issue #2, check-log, after-task report, and current uncommitted diff agree on the narrow fixed-effect claim. |
| 1620 | Decide PR boundary for Tweedie versus skew-normal | Ada records whether the current branch publishes both lanes together or splits the fitted Tweedie code from skew-normal design evidence. |
| 1621 | Review the `glmmTMB::tweedie()` comparator contract | The note names `glmmTMB`'s `phi` and power semantics and the required `sigma^2` transform from `drmTMB`. |
| 1622 | Add a small comparator fixture design | A source note specifies one deterministic data set, formula, tolerances, and skip rules when `glmmTMB` is unavailable. |
| 1623 | Add comparator dependency guard | Tests or design text make clear that `glmmTMB` remains optional and no new hard dependency is introduced. |
| 1624 | Check coefficient naming across packages | The comparator plan maps `mu`, `sigma`, `phi`, and `nu` or power names before any numeric assertions are added. |
| 1625 | Check log-likelihood scale expectations | The plan says whether log-likelihoods are comparable directly or only after matching constants and weights. |
| 1626 | Add a low-zero comparator cell | The first comparator cell covers non-negative semicontinuous data with a small exact-zero fraction. |
| 1627 | Add a high-zero comparator cell | The second comparator cell covers a larger exact-zero fraction without placing `nu` on the boundary. |
| 1628 | Add public-scale assertions | Tests compare `drmTMB::sigma(fit)^2` to comparator `phi`, not `sigma` to `phi`. |
| 1629 | Add `fitted()` semantic assertions | Tests confirm that `fitted()` remains the unconditional mean `mu`, not the positive conditional mean. |
| 1630 | Add `predict(dpar = "nu")` semantic assertions | Tests confirm `predict(..., dpar = "nu", type = "response")` stays in `(1, 2)`. |
| 1631 | Check weighted likelihood behaviour | Either add a small weighted comparator cell or record why weights wait for a later Tweedie task. |
| 1632 | Check offsets or exposure syntax | Either add a source-only offset boundary decision or record why offsets are outside the first comparator pass. |
| 1633 | Check missing-row filtering against comparator data | The comparator fixture documents when negative response validation occurs relative to model-frame filtering. |
| 1634 | Add a stale-claim scan for Tweedie status | Source and rendered scans catch old "Tweedie not fitted" wording. |
| 1635 | Add a stale-claim scan for unsupported neighbours | Source and rendered scans catch accidental claims for Tweedie random effects, `nu ~ x`, bivariate support, `zi`, or `hu`. |
| 1636 | Extend family-link contract if comparator semantics reveal friction | The contract records any additional wording needed for `sigma = sqrt(phi)`. |
| 1637 | Extend likelihood design only if needed | `docs/design/03-likelihoods.md` gains comparator-scale wording without changing the likelihood. |
| 1638 | Extend Tweedie family page examples cautiously | The example shows fitted fixed-effect syntax only and does not imply random effects. |
| 1639 | Add a small simulation reproducibility check | The test confirms exact zeros can be simulated and positive values remain positive. |
| 1640 | Check Pearson residual wording | Docs state the residual scale used by the implemented method and avoid coverage claims. |
| 1641 | Check `simulate()` output shape | Tests confirm one simulated response vector per requested replicate with no negative draws. |
| 1642 | Check `model.frame()` and `na.action` behaviour | Tests or design text record the behaviour for missing response and predictor rows. |
| 1643 | Check rank-deficient design handling | Either add a small unsupported or diagnostic test, or record that rank-deficient formula handling is shared infrastructure. |
| 1644 | Add `tweedie_fixed_effect` artifact-lane design | A design note names DGP, estimands, summary columns, and failure fields before runner code. |
| 1645 | Add DGP sketch only if schema is ready | The DGP sketch includes `mu`, `sigma`, `nu`, zero fraction, factor predictors, and predictor correlation. |
| 1646 | Add summariser sketch only if schema is ready | The summariser sketch records bias, RMSE, convergence, Hessian status, runtime, and Monte Carlo error columns. |
| 1647 | Decide whether the first artifact lane belongs before or after PR publish | Ada and Grace choose local comparator first or PR first, based on branch size. |
| 1648 | Check issue #2 labels and body | The GitHub issue remains the tracking surface; no duplicate Tweedie issue is opened. |
| 1649 | Add NEWS wording only after comparator evidence exists | NEWS says what is actually fitted and avoids saying "validated against glmmTMB" until the test lands. |
| 1650 | Run focused Tweedie tests | `test-tweedie-location-scale` passes locally. |
| 1651 | Run comparator-focused tests | Comparator tests pass or skip cleanly with an explicit optional-package reason. |
| 1652 | Run full package tests | `devtools::test()` passes or the failure is recorded as unrelated and reproducible. |
| 1653 | Run documentation generation if roxygen changed | `devtools::document()` updates only expected files. |
| 1654 | Run pkgdown check if user-facing docs changed | `pkgdown::check_pkgdown()` reports no new problems. |
| 1655 | Run full local check before publish | `devtools::check()` has 0 errors and 0 warnings; any NOTE is named. |
| 1656 | Render the relevant pkgdown pages | `reference/tweedie.html` and edited articles render. |
| 1657 | Scan rendered Tweedie pages | Rendered HTML contains the fitted fixed-effect claim and lacks unsupported-neighbour claims. |
| 1658 | Record first failures honestly | Any failed comparator, check, or pkgdown run appears in check-log with the fix or blocker. |
| 1659 | Write or update after-task report | The report states exactly whether this was comparator evidence, artifact design, or publish-only hardening. |
| 1660 | Decide whether Team A may start `nu ~ x` design later | The decision is "not in this 50-slice lane" unless comparator and fixed-effect evidence are already clean. |
| 1661 | Decide whether Team A may start Tweedie random-effect design later | The decision is "not in this 50-slice lane"; random effects need their own DGP and weak-SD diagnostics. |
| 1662 | Check branch size before staging | The diff is small enough for one reviewable PR or is split before staging. |
| 1663 | Stage only the chosen Tweedie scope | Files unrelated to the chosen PR boundary remain unstaged. |
| 1664 | Commit the Tweedie hardening slice | The commit message names Tweedie fixed-effect comparator or evidence hardening. |
| 1665 | Push the branch | The pushed branch matches the local commit. |
| 1666 | Open or update the PR | The PR references issue #2 and states unsupported Tweedie neighbours plainly. |
| 1667 | Watch GitHub Actions | Grace records whether CI passes, fails, or is waiting. |
| 1668 | Stop before the next Tweedie surface | Team A does not start `nu ~ x`, random effects, or bivariate Tweedie until this PR state is known. |

## Team B: Slices 1669-1718, Skew-Normal Decision Gate

Team B should still avoid C++ likelihood code unless Ada explicitly promotes a
later implementation lane. Its purpose is to decide the parameterization and
the first test contract so the future `skew_normal()` branch is not ambiguous.

| Slice | Task | Done when |
| --- | --- | --- |
| 1669 | Rehydrate the skew-normal source map | Historical gate: issue #3, `docs/design/123...`, likelihood design, family registry, and roadmap agreed that skew-normal was design-only before the fixed-effect first slice landed. |
| 1670 | Name the reader-facing question | The note says the first family models residual asymmetry after `mu` and `sigma`, not latent-effect skewness. |
| 1671 | Compare native and moment parameterizations | The decision note contrasts `mu = xi`, `sigma = omega`, `nu = alpha` with response mean, response SD, and `alpha`. |
| 1672 | Decide the default parameterization for the next implementation lane | Ada, Boole, Gauss, Noether, Fisher, and Pat record whether to keep native parameters or switch to moment parameters. |
| 1673 | Record consequences for `fitted()` | The decision says whether `fitted()` should return native location or transformed response mean. |
| 1674 | Record consequences for `sigma()` | The decision says whether public `sigma` is native scale or response SD. |
| 1675 | Record consequences for `predict(dpar = "nu")` | The decision says `nu` is the shape or slant parameter and keeps the identity link unless changed explicitly. |
| 1676 | Record normal-limit tests | The future implementation must match Gaussian likelihood, fitted values, and simulation at `nu = 0` under the chosen semantics. |
| 1677 | Record sign-convention tests | Positive and negative `nu` must produce the documented residual skew directions. |
| 1678 | Record density comparator source | The first comparator set is `sn` plus `RTMBdist` or `glmmTMB`/`brms`, not a broad comparator zoo. |
| 1679 | Check `sn` density availability | The plan says whether `sn::dsn()` can be used in optional tests without adding a hard dependency. |
| 1680 | Check `RTMBdist` density availability | The plan says whether `RTMBdist::dskewnorm()` or `dskewnorm2()` is used only as a comparator, not as copied code. |
| 1681 | Check `glmmTMB::skewnormal()` comparator fit | The plan says whether comparator fitting is valid under the chosen parameterization. |
| 1682 | Check `brms` comparator role | The plan likely keeps `brms` as documentation precedent, not a routine test dependency. |
| 1683 | Add provenance warning | If any density code is ported later, `inst/COPYRIGHTS` must be updated before completion. |
| 1684 | Decide starting values for `nu` | The implementation plan says whether exact zero starts are safe or whether a small nonzero start avoids flat derivatives. |
| 1685 | Decide support and missingness checks | The plan covers finite continuous responses and model-frame filtering before support validation. |
| 1686 | Decide rank-deficiency behaviour | The plan records whether shared fixed-effect rank handling is enough or family-specific diagnostics are needed. |
| 1687 | Replace no-fit boundary scan | Source and rendered scans should now catch stale absence claims and unsupported-neighbour overclaims. |
| 1688 | Constructor absence superseded | Tests now expect the exported `skew_normal()` first slice and explicit rejection of unsupported neighbours. |
| 1689 | Keep formula grammar unchanged | `docs/design/01-formula-grammar.md` stays unchanged unless the canonical syntax changes. |
| 1690 | Keep family registry honest | The registry should say fixed-effect first slice for `skew_normal()` and planned for random, structured, bivariate, covariance, and alias neighbours. |
| 1691 | Keep likelihood design honest | The likelihood design may claim code exists only for the fitted first slice. |
| 1692 | Keep README and pkgdown examples bounded | User-facing examples must remain inside the fixed-effect first slice until richer code exists. |
| 1693 | Draft first implementation checklist | The checklist covers constructor, builder, TMB branch, extractors, simulation, residuals, docs, and tests. |
| 1694 | Draft first density tests | Tests compare log density at negative, zero, and positive `nu`, including tail points. |
| 1695 | Draft first recovery tests | Tests include intercept-only `nu`, then `nu ~ w`, with positive and negative skew. |
| 1696 | Draft false-positive tests | Gaussian data with `sigma ~ z` must not spuriously require `nu ~ w`. |
| 1697 | Draft confounding tests | Predictors in `mu`, `sigma`, and `nu` have controlled correlations. |
| 1698 | Draft interval-status plan | The first implementation records whether `nu` Wald or profile intervals are available, unavailable, or unsafe. |
| 1699 | Draft diagnostic plan | The plan names gradient, Hessian, boundary, and skewness-detection diagnostics for first recovery. |
| 1700 | Draft runtime benchmark plan | Benchmarks compare Gaussian, Student-t, and skew-normal fixed-effect fits at small and moderate `n`. |
| 1701 | Draft simulation DGP plan | The DGP plan names `mu`, `sigma`, `nu`, skew direction, predictor correlation, and sample size cells. |
| 1702 | Draft simulation summary plan | The summary plan includes bias, RMSE, convergence, Hessian status, false-positive skew, runtime, and Monte Carlo error. |
| 1703 | Check local papers again only for the decision point | Jason reuses the source map and reads only missing sections needed for the parameterization decision. |
| 1704 | Update issue #3 with the decision if publishing | The issue receives the parameterization decision only after the local note is clean. |
| 1705 | Decide whether `skew` alias is postponed | The answer should remain yes: canonical public syntax is `nu`, and `skew` is at most a later alias. |
| 1706 | Decide whether latent skewness is postponed | The answer should remain yes: `skew(id) ~ x` needs separate simulations and grammar review. |
| 1707 | Decide whether skew-t belongs now | The answer should remain no: skew-t follows skew-normal after normal-limit and skewness recovery evidence. |
| 1708 | Decide whether phylogenetic shape belongs now | The answer should remain no: phylogenetic skewness waits for fixed-effect density and recovery evidence. |
| 1709 | Run focused boundary tests | The skew-normal boundary test passes. |
| 1710 | Run family-registry or documentation tests if edited | Focused tests pass for any touched registry or doc boundary. |
| 1711 | Run stale-claim scans | Source and rendered scans find no fitted skew-normal claim. |
| 1712 | Run prose review on the decision note | Pat and Rose can follow the syntax, equations, and unsupported-boundary wording. |
| 1713 | Write or update after-task report | The report says this is a parameterization decision gate, not fitted support. |
| 1714 | Decide branch split | If Team A publishes Tweedie code, Team B design notes should split unless the PR is still small and reviewer-friendly. |
| 1715 | Stage only the chosen skew-normal scope | No shared family constructor, TMB, or exported docs are staged unless the implementation lane was explicitly promoted. |
| 1716 | Commit the skew-normal decision gate | The commit message names a design gate, not family implementation. |
| 1717 | Push or hold according to the Team A PR state | Do not open a second PR until the current branch boundary is clear. |
| 1718 | Stop before C++ implementation | Team B does not add `skew_normal()` until the parameterization decision, comparator contract, and first tests are accepted. |

## Serial Integration Rules

Ada owns the integration boundary. Shared files such as `ROADMAP.md`,
`NEWS.md`, `_pkgdown.yml`, `docs/design/02-family-registry.md`,
`docs/design/03-likelihoods.md`, `docs/design/19-family-link-contract.md`,
and exported roxygen pages should change only after Team A or Team B has
finished its narrow evidence gate.

Grace owns the validation gate: focused tests first, then full tests, pkgdown
checks, full local check when exported code or compiled code changes, rendered
HTML scans for user-facing wording, and GitHub Actions after pushing.

Rose owns the discrepancy gate: current fitted surfaces, planned surfaces,
issues, roadmap rows, after-task notes, and stale wording must agree before
the team calls the next branch publishable.

## Recommended Next Move

The next safest slice is Team A Slices 1619-1623: decide whether to split the
current branch, then add the Tweedie comparator contract without changing the
fitted surface. Team B can work in parallel only on Slices 1669-1672, the
skew-normal parameterization decision. If the current branch remains large,
publish the Tweedie fitted-support PR first and keep skew-normal decision work
as a follow-up.
