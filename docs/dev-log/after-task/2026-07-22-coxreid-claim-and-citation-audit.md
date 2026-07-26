# After-task report — Cox–Reid claim and citation audit

**Date:** 2026-07-22  
**Scope:** documentation and code comments only

## 1. Purpose

Make the O3 documentation precise: describe it as drmTMB's nested AGHQ + Cox–Reid-style
observed-information profile, not as a generic non-Gaussian REML equivalence.

## 2. Boundary

No estimator, public API, simulation campaign, coverage status, capability tier, CRAN work, or
deployment changed.

## 3. Evidence consulted

Cox & Reid (1987) supplies the adjusted-profile and orthogonality context; Patterson–Thompson and
Harville remain the classical Gaussian REML references; Jiang (1996) is reserved for REML
asymptotics; Liu & Pierce (1994) supports the AGHQ construction only.

## 4. Changes made

Updated O3 terminology in `docs/design/224-aghq-coxreid-nongaussian-reml-alignment.md`,
`vignettes/capability-and-limits.Rmd`, and explanatory comments. Added Cox–Reid, Jiang, and
Liu–Pierce entries to `REFERENCES.bib`; retained the existing classical REML citations.

## 5. Adjacent consistency repair

The design record still described the tracked O3 wrapper as pre-code. It now distinguishes the
implemented package-private wrapper from a public `drmTMB()` control and preserves the separation
between deterministic checks and coverage certification.

## 6. Validation

- `NOT_CRAN=true R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'devtools::load_all(quiet = TRUE); testthat::test_file("tests/testthat/test-aghq-coxreid.R", reporter = "summary")'` — 13 expectations passed.
- `R_PROFILE_USER=/dev/null Rscript --no-init-file -e 'pkgdown::build_article("capability-and-limits", lazy = FALSE)'` — rendered successfully.
- `git diff --check` — passed.

## 7. Claim discipline

The audit explicitly withholds a formal Cox–Reid orthogonality claim, generic non-Gaussian REML
equivalence, an AGHQ convergence-rate claim, and every interval or coverage promotion.

## 8. Review

Rose's systems audit identified the stale pre-code wording in doc 224 and two O2 shorthand comments;
both were repaired. Rose's final verdict was **CLEAR**.

## 9. Risks and limitations

This is a wording and provenance repair. It neither proves the O3 estimator's inferential properties
nor substitutes for a compute-gated campaign.

## 10. Follow-up

Future work that needs an O3 promotion must separately establish the relevant inferential evidence
and obtain the stipulated approval; do not infer it from this citation audit.

## 11. Handoff

The changed files are documentation, bibliography, and non-executable comments. They are not
staged or committed by this task.
