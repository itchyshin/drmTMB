# drmTMB 0.8.2 candidate preparation

The candidate updates the version and groups post-0.8.1 changes under a new release heading. It retains the source snapshot's historical NEWS section and adds the two prior fragments. An independent reviewer checked the split and the supported two-intercept scope.

The merged prior integration passed its reported checks. DESCRIPTION parsing and `git diff --check` passed on the candidate. Full candidate checks, release-wide claims and artifact review, platform evidence, and the companion Julia release remain open. No release is claimed.

The release review corrected the transformed-predictor NEWS example to refer to negative inputs and `NA` or `NaN`. An R check confirmed the behavior of both functions at negative inputs and zero. Candidate CI on the correction remains open.

The first candidate's source-tree CI found stale 0.8.1 labels in README, the pkgdown banner and the main vignette. Those labels now match DESCRIPTION, and the focused release-identity test passes 20 assertions. Other lanes' branches were left unchanged. The full corrected-candidate CI remains open.
