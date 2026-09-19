# D-269: recertify the phylogenetic-label receipt for DRModels

## 1. Goal

Replace the stale public phylogenetic-label bridge receipt after the Julia
package renamed from DRM to DRModels, without changing the fitted-model API or
the wider bridge surface.

## 2. Implemented

The runner and independent receipt verifier now import and identify
`DRModels` and `src/DRModels.jl`. The generated JSON receipt and its raw log
record a fresh run against DRModels commit
`90fbb0e28306fa09a68dc2b03d74c981a74fe908`. This report and the matching
check-log entry record the evidence boundary.

## 3a. Decisions and Rejected Alternatives

Use a fresh detached checkout of merged DRModels `origin/main` and record only
the generated artifact from a passing run. Rejected reusing the old DRM receipt
or manually updating its hashes because neither proves the renamed module ran.

## 4. Files Touched

`tools/run-julia-phylo-labels-public.R`,
`tools/check-julia-phylo-labels-receipt.R`, the generated `public-001.json`
and `public-001.log`, and this report plus its check-log entry.

## 5. Checks Run

The bounded run used Julia 1.13.0, one Julia thread, and one BLAS thread:

```sh
JULIA_HOME=/Users/z3437171/.julia/juliaup/julia-1.13.0+0.aarch64.apple.darwin14/Julia-1.13.app/Contents/Resources/julia/bin \
  Rscript --no-init-file tools/run-julia-phylo-labels-public.R \
  /Users/z3437171/local-scratch/lanes/drmodels-receipt-origin-main \
  /private/tmp/d269-lss-tip-identity-90fbb0e-final.json tree
```

It passed in 38.454 seconds. The independent verifier passed its 12
in-memory mutation-rejection controls and reported
`PHYLO_LABEL_RECEIPT_PASS labels=12 rows=72 checks=8 tolerance=4e-06`.
With `DRM_JL_PATH` set to that exact checkout,
`bash tools/ci-receipt-staleness.sh` reported 54/54 R files and 95/95
DRModels-side entries current, then passed the structural receipt and C14/C17
compatibility checks.

## 8. Consistency Audit

The active runner and verifier were searched through their generated evidence
path. The only shipping package-name substitutions are `using DRModels`,
`DRModels.sigma_phy_dense`, `pathof(DRModels)`, and `src/DRModels.jl`; no
public R modelling call or formula spelling changed. Historical evidence was
not edited.

## 6. Tests of the Tests

The independent verifier deliberately rejects changed order contracts, labels,
rows, coefficients, likelihoods, source paths, resource limits, Newick,
covariance, fitted values, non-finite values, and malformed shapes. All 12
negative controls were rejected before it accepted the generated receipt.

## 9. What Did Not Go Smoothly

The fresh merged DRModels checkout initially lacked instantiated Julia 1.13
dependencies. `Pkg.instantiate()` was run only in that disposable detached
checkout; no DRModels source was modified. The first failed output was not
used as evidence. The final tracked receipt and raw log come only from the
subsequent passing run.

## 11. Team Learning

For a package rename, receipt runners must import the new module before
evaluating Julia macros and must validate the module source filename, not just
the checkout directory.

## Design-document updates

None. This is provenance and compatibility maintenance, not a modelling or
formula-design change.

## pkgdown/documentation updates

None. The changed files are an executable internal evidence runner, verifier,
and their generated receipt; no reader-facing page was rebuilt or deployed.

## 7a. Issue Ledger

No issue was created, closed, or edited. A focused pull request will carry
this recertification for review.

## 10. Known Residuals

This proves one deterministic public receipt only. It is not a full R package
check, fresh multi-platform validation, release, registry publication, or
Pages deployment. The pull request remains unmerged for review.

## 12. Cross-Product Coverage

The receipt covers native drmTMB, the optional Julia bridge, and direct
DRModels execution for a shuffled-row Gaussian phylogenetic LSS fit with 12
adversarial tip labels. It does not cover other families, bivariate fits,
multi-platform package checks, releases, Pages, or registry publication.
