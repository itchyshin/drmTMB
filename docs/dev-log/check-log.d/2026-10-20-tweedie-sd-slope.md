# 2026-10-20: Native Tweedie independent-slope SD regression

The Tweedie builder previously rejected direct-SD targets for independent numeric slopes even though model type 16 already applies the group SD row to every ordinary `mu` random-effect term. The builder now admits one independent numeric slope target, selected with `sd(group, coef = "x") ~ w`, while retaining complete responses and fixed `sigma` and `nu`.

Checks:

- Before fix: the focused regression suite failed at the intended Tweedie slope admission.
- ` Rscript -e "devtools::test(filter = '^tweedie-sd-regression$', reporter = 'summary')" ` passed.
- ` Rscript -e "devtools::test(filter = '^tweedie-sd-integration$', reporter = 'summary')" ` passed with recovery, prediction, simulation, save/reload, and constant-SD equivalence checks.
- Targeted current-doc inventory search covered `README.md`, `NEWS.md`, `docs/dev-log/internal-roadmap.md`, `docs/dev-log/known-limitations.md`, `docs/design/01-formula-grammar.md`, `vignettes/formula-grammar.Rmd`, `vignettes/model-map.Rmd`, and `_pkgdown.yml`.
- ` Rscript -e "pkgdown::check_pkgdown()" ` reported no problems.
- ` Rscript -e "pkgdown::build_site()" ` finished successfully and rendered the formula-grammar and model-map articles.
- Status inventory stale-wording search: `rg -n -i `random-slope SDs outside.*Tweedie|Tweedie.*random slopes remain excluded|coefficient-specific targets.*rejected|until random-slope SD regression` README.md NEWS.md docs/dev-log/internal-roadmap.md docs/dev-log/known-limitations.md docs/design/01-formula-grammar.md docs/design/03-likelihoods.md vignettes/formula-grammar.Rmd vignettes/model-map.Rmd --glob `!**/evidence/**`; no stale hits.
- The independent likelihood oracle, Julia parity, and interval coverage remain open.
