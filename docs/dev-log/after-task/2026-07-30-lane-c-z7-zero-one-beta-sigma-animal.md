# After-task — Lane C Z7 zero-one-beta sigma animal q1

## 1. Goal

Recover only `mc-0594`: ordinary ML zero-one-beta with an unlabelled `Ainv`
animal q1 random intercept on `sigma`.

## 2. Implemented

The parser, structured carrier, extraction, target-status fence, independent
oracle, and retained local fixture now support the exact q1 formula only.

## 3a. Decisions and Rejected Alternatives

Only `animal(1 | species, Ainv = Ainv)` is admitted.  `A`, pedigree, slopes,
other dpars, ordinary RE combinations, covariance, and structured alternatives
remain rejected.

## 4. Files Touched

`R/drmTMB.R`, `tests/testthat/test-zero-one-beta.R`, the scoped local runner,
and its receipt are the implementation evidence.  Ledger and reader changes
are deferred until the completion panel returns GO.

## 5. Checks Run

Focused zero-one-beta tests passed.  The full mixture-plus-Ainv oracle agreed
with TMB objective and AD/central-FD gradient.  Four fixed local seeds passed
the predeclared recovery rule.

## 6. Tests of the Tests

The oracle uses deliberately reversed `Ainv` row order, verifies the mapping,
and changes `log_sd_phylo` to establish objective dependency.  Profile,
endpoint, and direct dispatch are fenced before refitting.

## 7a. Issue Ledger

The candidate is not promoted in this receipt.  A later, reviewed ledger move
may claim point-fit recovery only.

## 8. Consistency Audit

The formula, `tau_sigma = exp(log_sd_phylo)` extraction, C++ structured
precision path, dense oracle, and local DGP use the same reporting scale.

## 9. What Did Not Go Smoothly

Rose identified missing explicit direct-target, `profile()`, endpoint no-refit,
and representation-neighbour checks.  They were added before closeout.

## 10. Known Residuals

This does NOT cover profile intervals, coverage, bootstrap, other animal
representations, random slopes, or any claim above technical point recovery.

## 11. Team Learning

For structured non-mean endpoints, an independent precision oracle must prove
both level ordering and determinant normalization; a converged fit alone is not
enough.

## 12. Cross-Product Coverage

No Lane A association, Lane B scale/interval work, Future-extension audit, or
public default/API surface was changed.
