# drmTMB 0.8.2 release preparation

The candidate starts at merged main `5d53eae0ba3ede53b3f43a78f690694e7f1133f0`. DESCRIPTION now declares 0.8.2, and NEWS separates the post-0.8.1 changes from the existing history. It includes the two prior fragments and names the two-intercept, mixed-prior and inference limits. An independent reviewer checked the proposed split and scope before these files were applied.

DESCRIPTION parsing and `git diff --check` passed. The prior integration PR passed its ten reported checks before merging. Release-candidate checks, artifact and platform review, release-wide claims review, and the compatible Julia release remain open. No release is claimed.

A release review corrected the transformed-predictor NEWS example: negative inputs to `log` and `sqrt` produce `NaN`; the missing-value checks retain zero for both functions. An R check of those four examples passed. The published candidate CI predates this local documentation correction.

The source-tree CI on `cd45e90a2` failed three release-identity assertions because README, the pkgdown banner and the main vignette still named 0.8.1. Their version labels now match 0.8.2; the focused `release-identity` test passes 20 assertions with no failures, warnings or skips. The three public files also occur in older open branches; their unrelated changes were not altered. Full CI on the corrected release candidate remains open.
