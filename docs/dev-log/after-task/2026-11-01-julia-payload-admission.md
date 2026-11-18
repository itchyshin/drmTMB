## 1. Goal

Classify and resolve four Totoro R CMD check failures where a Julia payload test expected admission or a refusal message that the current R code does not produce. Worktree base: codex/general-sd-regression at bee7f6c4f.

## 2. Findings per failure

| test:line | cause class | evidence | fix |
|---|---|---|---|
| test-julia-binomial-relmat-slope-sd-bridge.R:16 | (b) real bug | `drm_julia_binomial_relmat_sd_route_admitted()` returned FALSE for `y ~ x + relmat(0 + x \| id, K = K)` with `sd(id, level = "relmat") ~ z`. `parse_sd_lhs()` gives `target_coef = NA` for this unselected SD target, but the slope-only branch required `target_coef` to equal the slope name. The sibling animal gate (`target_coef_matches`) accepts NA or an exact match. Native test-binomial-relmat-slope-sd.R uses the same formula, so NA must be admitted. | In R/julia-bridge.R the slope-only condition is now `is.na(target$target_coef) \|\| identical(target$target_coef, term$coef_names[[1L]])`. Intercept-plus-slope and extra-IID formulas stay refused (the two existing expect_false assertions still pass). |
| test-julia-binomial-relmat-slope-sd-bridge.R:17 | (b) same bug | Payload refused because the gate at line 16 returned FALSE; the refusal text is the generic structured-slope message. | Same fix. Payload assertions now pass. |
| test-julia-structured.R:239 | (a) stale message text | Gaussian `relmat(1 + x \| id)` with `sigma ~ 1` is still refused (Gaussian is not an admitted slope family), but the message now reads "explicitly admitted animal-, relmat-, or fixed-coordinate spatial-slope SD routes". The test regex was the older "only explicitly admitted animal-slope SD routes". | Regex updated to the current text; the refusal assertion is kept. |
| test-julia-poisson-animal-ainv-sd-parity.R:34 | (a) stale message text | Poisson `animal(1 \| id, Ainv = Ainv)` without an SD formula is still refused; the message is now "admits animal `Ainv` only for supported Poisson or Binomial animal SD regression routes". The test pinned "only for Poisson or Binomial animal-intercept SD models". | Regex updated; refusal assertion kept. |

## 3. Merge-loss question

Not a merge loss. `drm_julia_binomial_relmat_sd_route_admitted` does not exist on origin/main. `git log --all -S` finds it only in b87566680, and its body there is identical to HEAD, so the NA-target defect was present from the first commit that carried the function. The 2026-10-27 after-task report claims 7 marshalling assertions passed, so the original lane copy probably differed; that copy is not in any reachable commit.

## 4. Checks run (Totoro, no Julia, one core each)

Files run with pkgload::load_all and testthat::test_file, silent reporter (passed/failed/error/skipped):

- test-julia-binomial-relmat-slope-sd-bridge.R: 7/0/0/1
- test-julia-poisson-animal-ainv-sd-parity.R: 4/0/0/1
- test-julia-binomial-relmat-sd-parity.R (neighbour): 14/0/0/1
- test-binomial-relmat-slope-sd.R (neighbour): 23/0/0/0
- test-julia-structured.R: 76/0/0/1 with one failure at line 176 ("unsupported structured forms are rejected with a tmb pointer"). It is outside this group and was already in the original failure list. The line 239 test now passes.

The skipped item in each Julia file is the live block, which needs Julia. The live Binomial relmat slope test was not run on the Mac; the gate change only widens admission to the formula already admitted by the 2026-10-27 live evidence.

## 5. Residuals

Does NOT cover live Julia parity, the line 176 failure, or any other group's failures.
