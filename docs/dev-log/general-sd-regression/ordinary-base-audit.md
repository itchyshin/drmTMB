# Ordinary random-effect base audit

This is a pinned source audit of ordinary scalar random-intercept and independent numeric-slope admission, not evidence that random-effect standard-deviation regression is implemented. The row key expands every declared family endpoint × admitted link variant plus the explicit blocked Julia binomial link-union obligations × the two effect forms × both engines from `family-endpoints.tsv` and `family-links.tsv`. The result contains 224 rows: 112 native and 112 Julia. The four added Julia probit/cloglog rows are explicitly `base_blocked` because those links are absent from the pinned Julia constructor; they are union obligations, not admitted base routes. Statuses describe only base plumbing: `base_source_admitted`, `base_blocked`, and `needs_review`.

The source snapshots are native drmTMB `d89db50975d96d9c2bcb13046453ae34c7fcf49b` and Julia `b1832c7a686decf4e3d7a06ad8382bf164b9d8d4`. All paths and spans in the TSV refer to those pins. The audit did not inspect uncommitted candidate code or run fits.

The row counts are:

| Engine | Base source admitted | Base blocked | Needs review |
| --- | ---: | ---: | ---: |
| Native | 52 | 60 | 0 |
| Julia | 16 | 96 | 0 |

The native source evidence now resolves the review rows and corrects clear non-location mismatches. Univariate Gaussian mu and sigma intercepts/slopes are extracted and passed to ordinary random-effect structure builders (`R/drmTMB.R:3899-4585`, especially `:4390-4393`; parser spans `:12330-12530`). Ordinary Poisson mu admits intercept/slope terms only when `has_zi=FALSE` (`:8143-8145,10674-10732`). Student and skew-normal sigma/nu, Tweedie sigma/nu, beta sigma, and beta-binomial sigma are blocked by their family validators (`:4773-4786,10508-10563,11279-11289,11315-11325,11848-11859,12184-12194,12220-12230`). Positive-continuous Gamma/lognormal sigma admits only an independent intercept (`:11789-11822`); the family mu validators admit ordinary intercepts and slopes (`:11741-11787`). Family-specific wrappers and simultaneous-term constraints remain part of each status; an admitted endpoint does not imply that multiple endpoints can be active together.

At the Julia pin, visible dispatch admits Gaussian ordinary mean effects (`src/gaussian_core.jl:572-620, 1120-1203`), Tweedie mean intercept and independent slope (`src/tweedie.jl:125-181`), and cumulative-logit mean intercept/slope (`src/cumulative.jl:136-214`). Other audited methods commonly admit an intercept but explicitly reject independent slopes or random effects outside the mean; exact method spans are retained in the TSV. A second pinned-source pass resolved the 44 Julia review rows without importing native claims: the Julia total is now 16 admitted, 96 blocked, and 0 review. A detailed receipt records the route evidence and distinctions between independent slopes and correlated intercept–slope blocks.

This audit is deliberately not G0 closure. It does not classify every provider, block shape, cross-parameter composition, missing-data condition, estimator, downstream inference route, or direct SD-regression prerequisite. Bivariate ordinary-effect rows are blocked where the pinned Julia dispatcher exposes only the residual route or structured-marker routes; this does not classify structured effects or arbitrary matched block layouts. The four blocked Julia link rows point to `family-links.tsv` rather than adding claims about Julia ordinary-effect dispatch. These statuses describe base model plumbing only and must not be promoted to SD support based on candidate tests.
