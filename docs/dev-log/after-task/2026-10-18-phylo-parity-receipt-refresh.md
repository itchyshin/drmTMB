# Refresh the current phylogenetic parity receipt

## Task goal

Restore source-bound parity evidence after PR #1577 merged as 476afc4ceff7bb819145af1831b9e973a97d1522. The main receipt-staleness run found stale R source hashes.

## Files created or changed

Updated the lss-tip-identity public-001 receipt and its execution/checker logs. Preserved the previous receipt and logs under historical-pre-2026-10-18. Added the failed environment setup attempts, offline dependency resolution log, dependency Manifest, and red/green freshness logs in the same evidence directory. Added this report and a dedicated check log.

## Checks run and exact outcomes

The unchanged public runner fitted native TMB, bridged Julia and direct Julia versions of the same shuffled-row Gaussian phylogenetic location-scale model. Its successful attempt took 98.531 seconds with Julia 1.13.0 and DRM.jl da8b3f8711beb5ef3186b890544c2e7850c7f194. All eight checks passed over 72 rows and 12 labels. The largest native/direct coefficient difference was 7.736e-12 and likelihood difference 7.106e-14. Bridge/direct differences were zero. All three fits reported convergence.

The independent checker passed with --current --self-test. The freshness script passed with all 56 R files and all 95 Julia source entries matching, no unrecorded R file, and the runner hash matching. The separate C14 source-equivalence check also passed unchanged.

## Consistency audit

The repaired claim is current-source evidence for the existing fixture. No R, C++, runner, checker, formula, likelihood, optimizer or workflow code changed. The historical receipt remains verbatim. Source search: rg -n -m 8 'lss-tip-identity' docs/design R/julia-bridge.R found existing fixture references whose meaning is preserved.

## Tests of the tests

The old receipt failed the freshness script before replacement: 12 recorded R hashes differed and two R files were absent from its manifest. The new checker self-test rejected all 12 deliberate receipt mutations, including source, resource, row, likelihood, covariance and coefficient changes.

## What did not go smoothly

The old scratch Julia checkout was absent. A shared local clone restored its pinned commit without modifying the source repository. Two early attempts failed during Julia dependency setup, before numerical parity checks. The default Julia was 1.10.0; the recorded receipt used 1.13.0. Selecting 1.13.0 and resolving the scratch clone's cached dependencies offline restored execution. Both failures are retained rather than counted as successful runs.

## Team learning and process improvements

Run the separate main-only receipt freshness check locally before completing a change to R sources. Preserve the pinned Julia source and resolved dependency Manifest alongside the receipt so the setup can be reconstructed.

## Design-doc updates

No design changed. The existing source-bound receipt contract and verification thresholds are unchanged.

## Pkgdown and documentation updates

No public interface or site content changed. This report and the dedicated check log record the evidence repair; rebuilding documentation would not test this repair.

## GitHub issue maintenance

This repair follows PR #1577 and the existing #1150 freshness guard. No duplicate feature issue is needed. The repair PR will carry the exact validation result; the parent task handles merge and collaborator notification.

## Known limitations and next actions

This is one existing parity fixture with default native optimizer settings. It does not establish every model, direct BFGS through Julia, a real-data rescue, interval coverage or a Bayesian comparison. PR and post-merge checks remain separate evidence from this local rerun.

## Prose review

Self-review on 18 October 2026 covered this report and the repair PR draft for R package contributors. Perceived AI-like style: 2/10, medium confidence. The checks paragraph gives exact denominators and differences; the limitations paragraph bounds the claim. No repair needed for those examples. Science gate: pass for the existing bounded fixture, checked against the new JSON. Facts gate: pass against execution logs and source diff. References gate: pass for repository issue and PR identifiers checked in the parent task. This is editorial self-review, not independent numerical validation.
